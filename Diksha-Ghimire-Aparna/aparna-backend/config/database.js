const { Pool } = require('pg');

require('dotenv').config();

function getDatabaseTargetInfo() {
  if (process.env.DATABASE_URL) {
    try {
      const parsedUrl = new URL(process.env.DATABASE_URL);
      const host = parsedUrl.hostname || 'unknown-host';
      const databaseName = (parsedUrl.pathname || '').replace(/^\//, '') || 'unknown-db';
      const provider = host.includes('neon.tech')
        ? 'Neon'
        : host.includes('render.com')
        ? 'Render'
        : host.includes('localhost') || host === '127.0.0.1'
        ? 'Localhost'
        : 'External Postgres';

      return {
        source: 'DATABASE_URL',
        provider,
        host,
        databaseName,
        ssl: parsedUrl.searchParams.get('sslmode') || 'not-specified',
      };
    } catch (_err) {
      return {
        source: 'DATABASE_URL',
        provider: 'Unknown',
        host: 'invalid-url',
        databaseName: 'unknown-db',
        ssl: 'unknown',
      };
    }
  }

  const host = process.env.DB_HOST || 'localhost';
  const databaseName = process.env.DB_NAME || 'unknown-db';

  return {
    source: 'DB_* env vars',
    provider: host.includes('localhost') || host === '127.0.0.1' ? 'Localhost' : 'Custom Host',
    host,
    databaseName,
    ssl: 'not-configured',
  };
}

// Prefer DATABASE_URL if it exists (managed PostgreSQL like Neon/Render), otherwise use local config
const isUsingExternalDatabase = !!process.env.DATABASE_URL;
const databaseTargetInfo = getDatabaseTargetInfo();
const pool = new Pool(
  isUsingExternalDatabase
    ? {
        connectionString: process.env.DATABASE_URL,
        // Managed Postgres providers usually require TLS.
        ssl: { rejectUnauthorized: false },
        max: parseInt(process.env.DB_POOL_MAX, 10) || 10,
        idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT_MS, 10) || 30000,
        connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT_MS, 10) || 20000,
        keepAlive: true,
      }
    : {
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        host: process.env.DB_HOST,
        port: parseInt(process.env.DB_PORT) || 5432,
        database: process.env.DB_NAME,
        max: parseInt(process.env.DB_POOL_MAX, 10) || 10,
        idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT_MS, 10) || 30000,
        connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT_MS, 10) || 20000,
        keepAlive: true,
      }
);

console.log(`Database config: ${isUsingExternalDatabase ? 'using DATABASE_URL' : 'using local DB_* env vars'}`);
console.log(
  `Database target: provider=${databaseTargetInfo.provider}, host=${databaseTargetInfo.host}, db=${databaseTargetInfo.databaseName}, ssl=${databaseTargetInfo.ssl}`
);

pool.on('error', (error) => {
  console.error('Unexpected PostgreSQL client error:', error.message);
});

async function verifyDatabaseConnection(options = {}) {
  const retries = Number.isInteger(options.retries) ? options.retries : 3;
  const delayMs = Number.isInteger(options.delayMs) ? options.delayMs : 2000;

  for (let attempt = 1; attempt <= retries; attempt += 1) {
    try {
      const res = await pool.query('SELECT NOW()');
      console.log(
        `✅ Database connected successfully (${databaseTargetInfo.provider}@${databaseTargetInfo.host}/${databaseTargetInfo.databaseName}) at`,
        res.rows[0].now
      );
      return true;
    } catch (err) {
      console.error(`❌ Database connection attempt ${attempt}/${retries} failed:`, err.message);
      if (attempt < retries) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
  }

  if (isUsingExternalDatabase) {
    console.error('  Ensure DATABASE_URL is correct and reachable from this environment');
  } else {
    console.error('  Ensure DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME are set');
  }

  return false;
}

module.exports = pool;
module.exports.verifyDatabaseConnection = verifyDatabaseConnection;