const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

// Validate required env vars before starting
const requiredEnvVars = [
  'JWT_SECRET',
  'CLOUDINARY_CLOUD_NAME',
  'CLOUDINARY_API_KEY',
  'CLOUDINARY_API_SECRET',
];
const missing = requiredEnvVars.filter((key) => !process.env[key]);
if (missing.length > 0) {
  console.error('ERROR: Missing required environment variables:', missing.join(', '));
  console.error('Please set them in your .env file. See .env.example for reference.');
  process.exit(1);
}

// Initialize Firebase Admin SDK
const { initializeFirebase } = require('./config/firebase');
initializeFirebase();

const express = require('express');
const session = require('express-session');
const pgSession = require('connect-pg-simple')(session);
const pool = require('./config/database');
const { verifyDatabaseConnection } = require('./config/database');
const helmet = require('helmet'); // Security headers
const rateLimit = require('express-rate-limit'); // Rate limiting
const authRoutes = require('./routes/authRoutes');
const aamaRoutes = require('./routes/Aama');
const adminRoutes = require('./routes/adminRoutes');
const ProfileRoutes = require('./routes/profileRoutes');
const blogRoutes = require('./routes/blogRoutes');
const cycleRoutes = require('./routes/cycleRoutes');
const fcmRoutes = require('./routes/fcmRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const expertHelpRoutes = require('./routes/expertHelpRoutes');
const healthRoutes = require('./routes/healthRoutes');
const os = require('os');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const isProduction = process.env.NODE_ENV === 'production';

// Security headers
app.use(helmet({ contentSecurityPolicy: false }));

// CORS - restrict origins in production
const configuredOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin: (origin, cb) => {
      // Allow requests with no origin (like mobile apps, curl, postman)
      if (!origin) return cb(null, true);
      // Always allow localhost / 127.0.0.1 with any port (Flutter web, local dev)
      if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
        return cb(null, true);
      }
      if (configuredOrigins.length === 0) return cb(null, true);
      if (configuredOrigins.includes(origin)) return cb(null, true);
      cb(new Error('Not allowed by CORS'));
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  })
);

// Global rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: isProduction ? 100 : 1000, // stricter in production
  skip: (req) => req.path.startsWith('/health'),
  message: { error: 'Too many requests, please try again later.' },
});
  app.use(limiter); // Apply global rate limiting to all routes

// Health endpoints can sync frequently from mobile clients.
const healthLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: isProduction ? 600 : 3000,
  message: { error: 'Too many health sync requests, please try again shortly.' },
});

// Stricter rate limit for auth routes (login, register, etc.)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many login attempts, please try again later.' },
});

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const sessionSecret = process.env.SESSION_SECRET || process.env.JWT_SECRET;
if (!sessionSecret) {
  console.error('ERROR: SESSION_SECRET or JWT_SECRET must be set for session');
  process.exit(1);
}

app.use(
  session({
    store: new pgSession({
      pool,
      tableName: 'session',
    }),
    secret: sessionSecret,
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: isProduction,
      httpOnly: true,
      maxAge: 60000,
    },
  })
);
app.use('/auth', authLimiter, authRoutes);
app.use('/health', healthLimiter, healthRoutes);
app.use('/aama', aamaRoutes);
app.use('/admin', adminRoutes);
app.use('/profile', ProfileRoutes);
app.use('/blogs', blogRoutes);
app.use('/cycles', cycleRoutes);
app.use('/fcm', fcmRoutes);
app.use('/notifications', notificationRoutes);
app.use('/experthelp', expertHelpRoutes);


app.get('/', (req, res) => {
  res.send('Welcome to Aparna API');
});

// Temporary endpoint to initialize the render database tables internally
app.get('/setup-db', async (req, res) => {
  try {
    const fs = require('fs');
    const sql = fs.readFileSync(path.join(__dirname, 'scripts', 'schema.sql'), 'utf8');
    await pool.query(sql);
    res.send('Database tables created successfully.');
  } catch (error) {
    console.error('Setup DB error:', error);
    res.status(500).send('Error creating tables: ' + error.message);
  }
});

// Health check for monitoring
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({
      error: 'Invalid JSON in request body. Check for trailing commas and use double quotes.'
    });
  }

  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

const getLocalIP = () => {
  const interfaces = os.networkInterfaces();
  for (let name of Object.keys(interfaces)) {
    for (let iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
};


const { startScheduledJobs } = require('./utils/scheduler');


app.listen(PORT, '0.0.0.0', () => {
  const ip = getLocalIP();
  console.log(`Server is running on http://${ip}:${PORT}/`);
  (async () => {
    await verifyDatabaseConnection({ retries: 3, delayMs: 2500 });
    startScheduledJobs();
  })();
});  
