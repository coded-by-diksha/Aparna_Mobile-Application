/**
 * Firebase Admin SDK Configuration
 * Initializes Firebase Admin for FCM push notifications
 */

const admin = require('firebase-admin');
const path = require('path');

let firebaseInitialized = false;

function normalizePrivateKey(rawKey) {
    if (!rawKey || typeof rawKey !== 'string') return '';

    let key = rawKey.trim();

    // Some platforms inject surrounding quotes for multiline secrets.
    if ((key.startsWith('"') && key.endsWith('"')) || (key.startsWith("'") && key.endsWith("'"))) {
        key = key.slice(1, -1);
    }

    // Handle both literal \n sequences and escaped variations
    // This covers: \\n, \n, actual newlines, and \\r\\n patterns
    key = key.split('\\n').join('\n');
    key = key.split('\\r\\n').join('\n');
    key = key.replace(/\\r\\n/g, '\n');

    return key;
}

function extractPrivateKeyFromPossibleJson(input) {
    const normalized = normalizePrivateKey(input);
    if (!normalized) return '';

    const trimmed = normalized.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        try {
            const parsed = JSON.parse(trimmed);
            if (parsed && typeof parsed.private_key === 'string') {
                return normalizePrivateKey(parsed.private_key);
            }
        } catch (_) {
            // Fallback for service-account-like payloads that are not valid JSON.
            const privateKeyFieldMatch = trimmed.match(/"private_key"\s*:\s*"([\s\S]*?)"\s*,\s*"client_email"/);
            if (privateKeyFieldMatch && privateKeyFieldMatch[1]) {
                return normalizePrivateKey(privateKeyFieldMatch[1]);
            }

            const pemBlockMatch = trimmed.match(/-----BEGIN PRIVATE KEY-----[\s\S]*?-----END PRIVATE KEY-----/);
            if (pemBlockMatch && pemBlockMatch[0]) {
                return normalizePrivateKey(pemBlockMatch[0]);
            }

            // Not parseable as JSON and no detectable key block.
        }
    }

    return normalized;
}

/**
 * Initialize Firebase Admin SDK
 */
function initializeFirebase() {
    if (firebaseInitialized) {
        console.log('Firebase Admin already initialized');
        return admin;
    }

    try {
        const projectId = process.env.FIREBASE_PROJECT_ID;
        const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
        const privateKeyRaw = process.env.FIREBASE_PRIVATE_KEY;
        const privateKeyBase64 = process.env.FIREBASE_PRIVATE_KEY_BASE64;

        let privateKey = extractPrivateKeyFromPossibleJson(privateKeyRaw);
        let keySource = 'FIREBASE_PRIVATE_KEY';

        // If raw key is not valid, try base64 decoding
        if ((!privateKey || !privateKey.includes('-----BEGIN')) && privateKeyBase64) {
            try {
            const decoded = Buffer.from(privateKeyBase64, 'base64').toString('utf8');
            const extracted = extractPrivateKeyFromPossibleJson(decoded);
            if (extracted && extracted.includes('-----BEGIN PRIVATE KEY-----') && extracted.includes('-----END PRIVATE KEY-----')) {
                privateKey = extracted;
                    keySource = 'FIREBASE_PRIVATE_KEY_BASE64 (decoded)';
                    console.log('✓ Decoded FIREBASE_PRIVATE_KEY_BASE64 successfully');
                } else {
                    console.warn('⚠️  FIREBASE_PRIVATE_KEY_BASE64 decoded but does not appear to be a valid PEM key');
                }
            } catch (decodeError) {
                console.warn('⚠️  FIREBASE_PRIVATE_KEY_BASE64 is present but could not be decoded:', decodeError.message);
            }
        }

        // Try initializing from Environment Variables first (ideal for Render production)
        if (projectId && clientEmail && privateKey) {
        if (!privateKey.includes('-----BEGIN PRIVATE KEY-----') || !privateKey.includes('-----END PRIVATE KEY-----')) {
                console.warn('⚠️  Private key from', keySource, 'does not look like a valid PEM format');
                console.warn('Expected to contain "-----BEGIN PRIVATE KEY-----" and "-----END PRIVATE KEY-----"');
                throw new Error('Invalid PEM formatted private key');
            }

            admin.initializeApp({
                credential: admin.credential.cert({
                    projectId: projectId,
                    clientEmail: clientEmail,
                    privateKey: privateKey,
                })
            });
            console.log('✅ Firebase Admin SDK initialized successfully from environment variables (' + keySource + ')');
            firebaseInitialized = true;
            return admin;
        }

        // Log which variables are missing
        if (!projectId) console.warn('⚠️  FIREBASE_PROJECT_ID not set');
        if (!clientEmail) console.warn('⚠️  FIREBASE_CLIENT_EMAIL not set');
        if (!privateKey) console.warn('⚠️  FIREBASE_PRIVATE_KEY and FIREBASE_PRIVATE_KEY_BASE64 not set or invalid');

        // Fallback to local file logic (ideal for local development)
        const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
            path.join(__dirname, 'serviceAccountKey.json');

        const fs = require('fs');
        if (!fs.existsSync(serviceAccountPath)) {
            console.warn('⚠️  Firebase service account key not found at:', serviceAccountPath);
            console.warn('⚠️  FCM notifications will not work until you add the service account key or set Firebase environment variables.');
            return null;
        }

        const serviceAccount = require(serviceAccountPath);

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });

        firebaseInitialized = true;
        console.log('✅ Firebase Admin SDK initialized successfully from local file');
        return admin;

    } catch (error) {
        console.error('❌ Error initializing Firebase Admin SDK:', error.message);
        console.warn('⚠️  FCM notifications will not work until Firebase is properly configured');
        console.warn('\nTo fix this on Render, set one of:');
    console.warn('1. Use FIREBASE_PRIVATE_KEY_BASE64: base64 of serviceAccount JSON OR base64 of private_key PEM text');
        console.warn('2. Use FIREBASE_PRIVATE_KEY with proper newline escaping (\\\\n, not \\n)');
        return null;
    }
}

/**
 * Get Firebase Admin instance
 */
function getFirebaseAdmin() {
    if (!firebaseInitialized) {
        return initializeFirebase();
    }
    return admin;
}

/**
 * Get Firebase Messaging instance
 */
function getMessaging() {
    const firebaseAdmin = getFirebaseAdmin();
    if (!firebaseAdmin) {
        throw new Error('Firebase Admin not initialized. Cannot access messaging service.');
    }
    return firebaseAdmin.messaging();
}

module.exports = {
    initializeFirebase,
    getFirebaseAdmin,
    getMessaging
};
