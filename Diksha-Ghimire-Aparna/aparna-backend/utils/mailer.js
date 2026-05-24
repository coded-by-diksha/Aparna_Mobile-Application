const path = require('path');
const nodemailer = require('nodemailer');

if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
}

// Email transporter - will be initialized
let transporter = null;

function normalizeEnvValue(value) {
    if (typeof value !== 'string') {
        return '';
    }

    let normalized = value.trim();

    // Remove wrapping quotes repeatedly (handles values like "'foo'" or '"foo"').
    while (
        normalized.length >= 2 &&
        ((normalized.startsWith('"') && normalized.endsWith('"')) ||
            (normalized.startsWith("'") && normalized.endsWith("'")))
    ) {
        normalized = normalized.slice(1, -1).trim();
    }

    return normalized;
}

// Initialize email transporter
const initializeTransporter = async () => {
    const emailUser = normalizeEnvValue(process.env.EMAIL_USER);
    const emailPass = normalizeEnvValue(process.env.EMAIL_PASS).replace(/\s+/g, '');

    // If credentials are provided, try to use them (Gmail or other SMTP)
    if (emailUser && emailPass) {
        transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: emailUser,
                pass: emailPass
            }
        });

        // Verify connection immediately; if it fails, fall back to Ethereal in dev
        try {
            await transporter.verify();
            console.log('📧 Email transporter initialized with provided credentials.');
            return;
        } catch (error) {
            console.warn('📧 Provided email credentials failed to verify:', error && error.message ? error.message : error);
            transporter = null;
            // continue to Ethereal only in non-production below
        }
    }

    // Only if NO credentials are found at all, we use Ethereal (Dev mode only)
    if (process.env.NODE_ENV !== 'production') {
        try {
            const testAccount = await nodemailer.createTestAccount();
            transporter = nodemailer.createTransport({
                host: 'smtp.ethereal.email',
                port: 587,
                secure: false,
                auth: {
                    user: testAccount.user,
                    pass: testAccount.pass
                }
            });
            console.log('📧 Test account ready (Ethereal) — host: smtp.ethereal.email, port: 587');
        } catch (err) {
            console.error('📧 Email initialization failed entirely.');
        }
    }
};

// Initialize on startup
initializeTransporter();

/**
 * Function to send OTP email
 * @param {string} email - Recipient email
 * @param {string} otp - 6-digit OTP code
 * @param {string} purpose - 'signup' | 'forgot_password'
 */
const sendOTPEmail = async (email, otp, purpose = 'forgot_password') => {
    if (!transporter) {
        console.error('Email transporter is not ready. Attempting re-initialization...');
        await initializeTransporter();
    }

    if (!transporter) {
        const configError = 'Email service is not configured (check EMAIL_USER/EMAIL_PASS).';
        console.error(`CANNOT SEND OTP: ${configError}`);
        throw new Error(configError);
    }

    const isSignup = purpose === 'signup';
    const subject = isSignup ? 'Verify Your Email - Aparna' : 'Password Reset OTP - Aparna';
    const title = isSignup ? 'Email Verification' : 'Password Reset Request';
    const bodyText = isSignup
        ? 'Please verify your email address by entering the OTP below to complete your registration:'
        : 'You have requested to reset your password. Use the OTP below to verify your identity:';
    const footerText = isSignup
        ? "If you didn't create an account with Aparna, please ignore this email."
        : "If you didn't request this password reset, please ignore this email or contact support.";

    const fromEmail = normalizeEnvValue(process.env.EMAIL_USER) || 'noreply@aparna.app';

    const mailOptions = {
        from: `"Aparna App" <${fromEmail}>`,
        to: email,
        subject,
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="text-align: center; margin-bottom: 30px;">
                    <h1 style="color: #8B3A3A;">Aparna</h1>
                </div>
                <div style="background-color: #FFF5F5; border-radius: 10px; padding: 30px;">
                    <h2 style="color: #333; margin-bottom: 20px;">${title}</h2>
                    <p style="color: #666; font-size: 16px;">
                        ${bodyText}
                    </p>
                    <div style="background-color: #8B3A3A; color: white; font-size: 32px; font-weight: bold;
                                text-align: center; padding: 20px; border-radius: 10px; margin: 20px 0;
                                letter-spacing: 8px;">
                        ${otp}
                    </div>
                    <p style="color: #666; font-size: 14px;">
                        This OTP will expire in <strong>5 minutes</strong>.
                    </p>
                    <p style="color: #999; font-size: 12px; margin-top: 30px;">
                        ${footerText}
                    </p>
                </div>
                <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
                    © 2026 Aparna. All rights reserved.
                </div>
            </div>
        `
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log(`✅ ACTUAL EMAIL SENT TO: ${email}`);
        return info;
    } catch (error) {
        console.error(`❌ FAILED TO SEND EMAIL TO ${email}:`, error.message);
        throw error;
    }
};

const sendTestEmail = async (email = 'test@example.com', otp = '123456', purpose = 'forgot_password') => {
    const info = await sendOTPEmail(email, otp, purpose);

    try {
        const previewUrl = nodemailer.getTestMessageUrl(info);
        return {
            info,
            previewUrl: previewUrl || null,
        };
    } catch (error) {
        return {
            info,
            previewUrl: null,
        };
    }
};

if (require.main === module) {
    (async () => {
        const recipient = process.argv[2] || 'test@example.com';
        try {
            const result = await sendTestEmail(recipient);
            console.log('Send result:', result.info);
            if (result.previewUrl) {
                console.log('Preview URL:', result.previewUrl);
            }
            process.exit(0);
        } catch (error) {
            console.error('Test send failed:', error && error.message ? error.message : error);
            process.exit(1);
        }
    })();
}

module.exports = {
    sendOTPEmail,
    sendTestEmail
};
