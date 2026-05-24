const User = require('../model/User');
const { validationResult } = require('express-validator');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const { sendOTPEmail } = require('../utils/mailer');
const NotificationHelper = require('../utils/notificationHelper');

const googleClient = new OAuth2Client();
const DEFAULT_GOOGLE_WEB_CLIENT_ID = '124485235213-b9h9a11025htn0gsfqkmh001683qhmus.apps.googleusercontent.com';

function normalizeUsernameSeed(value) {
    return (value || 'user')
        .toLowerCase()
        .replace(/[^a-z0-9_]/g, '')
        .slice(0, 20) || 'user';
}

function getTokenPayload(user) {
    return {
        uid: user.uid,
        username: user.username,
        email: user.email,
        role: user.role,
    };
}

function issueAuthTokens(user) {
    const payload = getTokenPayload(user);
    const accessToken = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '30d' });
    const refreshToken = jwt.sign(
        { uid: user.uid, type: 'refresh' },
        process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
        { expiresIn: '90d' }
    );
    return { accessToken, refreshToken };
}

// Register a new user
exports.getRegister = (req, res) => {
    res.send('Register here');
};

exports.postRegister = async (req, res) => {
    const userData = req.body;
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        // Verify signup OTP - user already exists (created in send-signup-otp)
        const { otp, email } = userData;
        if (!otp || !email) {
            return res.status(400).json({ message: 'Email and verification code are required.' });
        }
        const storageKey = `signup:${email}`;
        const storedData = otpStorage.get(storageKey);
        if (!storedData) {
            return res.status(400).json({ message: 'Verification code not found. Please request a new one.' });
        }
        if (Date.now() > storedData.expiry) {
            otpStorage.delete(storageKey);
            return res.status(400).json({ message: 'Verification code has expired. Please request a new one.' });
        }
        if (storedData.otp !== otp) {
            return res.status(400).json({ message: 'Invalid verification code.' });
        }
        otpStorage.delete(storageKey);

        const user = await User.getUserByEmail(email);
        if (!user) {
            return res.status(400).json({ message: 'Account not found. Please complete registration again.' });
        }

        await User.setEmailVerified(user.uid, true);

        const { accessToken, refreshToken } = issueAuthTokens(user);

        res.cookie('token', accessToken, { httpOnly: true, maxAge: 2592000000 }); // 30 days

        res.status(200).json({
            message: 'Registration successful',
            token: accessToken,
            refreshToken,
            user: { uid: user.uid, username: user.username, email: user.email, role: user.role || 'user' }
        });
        console.log('User email verified and registered:', user.uid);

        NotificationHelper.notifyAdminsNewUserRegistered(user)
            .then((result) => {
                if (result?.success === false) {
                    console.error('⚠️ Failed to notify admins for new user:', result.error || result);
                }
            })
            .catch((notifyError) => {
                console.error('⚠️ Error notifying admins for new user:', notifyError);
            });

    }
    catch (error) {
        console.error('Error registering user:', error);

        if (error.code === '23505') {
            const constraint = error.constraint || '';
            let message = 'An account with this information already exists.';

            if (constraint.includes('username')) {
                message = 'Username is already taken. Please choose a different username.';
            } else if (constraint.includes('email')) {
                message = 'Email is already registered. Please use a different email or try logging in.';
            } else if (constraint.includes('phone')) {
                message = 'Phone number is already registered. Please use a different phone number.';
            }

            return res.status(409).json({
                error: 'Duplicate entry',
                message: message,
                field: constraint.replace('users_', '').replace('_key', '')
            });
        }

        res.status(500).json({ error: 'Internal server error' });
    }
};

exports.postLogin = async (req, res) => {
    const { identifier, password } = req.body;
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                errors: errors.array(),
                oldInput: req.body
            });
        }
        let user = await User.getUserByEmail(identifier);
        if (!user) {
            user = await User.getUserByUsername(identifier);
        }

        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        if (user.email_verified === false) {
            return res.status(403).json({
                error: 'Email not verified',
                message: 'Please verify your email with the OTP sent to your inbox before logging in.'
            });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const { accessToken, refreshToken } = issueAuthTokens(user);
        res.cookie('token', accessToken, { httpOnly: true, maxAge: 2592000000 }); // 30 days in milliseconds
        res.status(200).json({
            message: 'Login successful',
            token: accessToken,
            refreshToken,
            user: { uid: user.uid, username: user.username, email: user.email, role: user.role }
        });
    } catch (err) {
        console.error('Login error:', err.message);
        if (err.isDbConnectionIssue || err.code === 'ECONNRESET') {
            return res.status(503).json({
                error: 'Database temporarily unavailable. Please try again shortly.'
            });
        }
        // Only include internal error in non-production for debugging
        const errorMsg = process.env.NODE_ENV === 'production' 
            ? 'Internal server error' 
            : `Internal server error: ${err.message}`;
        res.status(500).json({ error: errorMsg });
    }
};

exports.googleLogin = async (req, res) => {
    const { idToken, email, displayName } = req.body;

    if (!idToken) {
        return res.status(400).json({ message: 'Google ID token is required.' });
    }

    const audience = [process.env.GOOGLE_WEB_CLIENT_ID, process.env.GOOGLE_CLIENT_ID, DEFAULT_GOOGLE_WEB_CLIENT_ID].filter(Boolean);
    if (audience.length === 0) {
        return res.status(500).json({
            message: 'Google Sign-In is not configured on the server. Set GOOGLE_WEB_CLIENT_ID.',
        });
    }

    try {
        const ticket = await googleClient.verifyIdToken({
            idToken,
            audience: audience.length === 1 ? audience[0] : audience,
        });

        const payload = ticket.getPayload();
        if (!payload || !payload.email || payload.email_verified !== true) {
            return res.status(401).json({ message: 'Invalid Google account payload.' });
        }

        if (email && payload.email.toLowerCase() !== email.toLowerCase()) {
            return res.status(401).json({ message: 'Google account mismatch.' });
        }

        let user = await User.getUserByEmail(payload.email);

        if (!user) {
            const seed = normalizeUsernameSeed(
                (displayName || payload.name || payload.email.split('@')[0] || '').replace(/\s+/g, '_')
            );

            let username = seed;
            let suffix = 1;
            while (await User.getUserByUsername(username)) {
                username = `${seed}${suffix}`;
                suffix += 1;
            }

            const randomPassword = await bcrypt.hash(`${payload.sub}:${Date.now()}`, 12);
            user = await User.createUser({
                username,
                email: payload.email,
                phone: null,
                dateofbirth: null,
                password: randomPassword,
                role: 'user',
                emailVerified: true,
            });

            NotificationHelper.notifyAdminsNewUserRegistered(user)
                .then((result) => {
                    if (result?.success === false) {
                        console.error('⚠️ Failed to notify admins for Google new user:', result.error || result);
                    }
                })
                .catch((notifyError) => {
                    console.error('⚠️ Error notifying admins for Google new user:', notifyError);
                });
        } else if (user.email_verified === false) {
            await User.setEmailVerified(user.uid, true);
            user = await User.getUserByID(user.uid);
        }

        const { accessToken, refreshToken } = issueAuthTokens(user);

        res.cookie('token', accessToken, { httpOnly: true, maxAge: 2592000000 });
        return res.status(200).json({
            message: 'Google login successful',
            token: accessToken,
            refreshToken,
            user: {
                uid: user.uid,
                username: user.username,
                email: user.email,
                role: user.role || 'user',
            },
        });
    } catch (error) {
        console.error('Google login error:', error);
        return res.status(401).json({
            message: 'Google authentication failed',
            error: process.env.NODE_ENV === 'production' ? undefined : error.message,
        });
    }
};

exports.validateToken = async (req, res) => {
    try {
        const tokenUser = req.user;
        if (!tokenUser || !tokenUser.uid) {
            return res.status(401).json({ valid: false, message: 'Invalid token payload' });
        }

        const user = await User.getUserByID(tokenUser.uid);
        if (!user) {
            return res.status(404).json({ valid: false, message: 'User not found' });
        }

        return res.status(200).json({
            valid: true,
            message: 'Token is valid',
            user: {
                uid: user.uid,
                username: user.username,
                email: user.email,
                role: user.role || 'user',
            },
        });
    } catch (error) {
        console.error('validateToken error:', error);
        return res.status(500).json({ valid: false, message: 'Internal server error' });
    }
};

exports.refreshToken = async (req, res) => {
    const incomingRefreshToken = req.body?.refreshToken;
    if (!incomingRefreshToken) {
        return res.status(400).json({ message: 'Refresh token is required' });
    }

    try {
        const decoded = jwt.verify(
            incomingRefreshToken,
            process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET
        );

        if (!decoded?.uid || decoded?.type !== 'refresh') {
            return res.status(401).json({ message: 'Invalid refresh token payload' });
        }

        const user = await User.getUserByID(decoded.uid);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const { accessToken, refreshToken } = issueAuthTokens(user);
        return res.status(200).json({
            message: 'Token refreshed',
            token: accessToken,
            refreshToken,
            user: {
                uid: user.uid,
                username: user.username,
                email: user.email,
                role: user.role || 'user',
            },
        });
    } catch (error) {
        return res.status(401).json({ message: 'Invalid or expired refresh token' });
    }
};

exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.getAllUsers();
        res.status(200).json(users);
    } catch (error) {
        console.error('Error fetching all users:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

exports.getUserById = async (req, res) => {
    const userId = req.params.id;
    try {
        const user = await User.getUserByID(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.status(200).json(user);
    } catch (error) {
        console.error('Error fetching user by ID:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// In-memory OTP storage
const otpStorage = new Map();

// Generate a 6-digit OTP
const generateOTP = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

// Forgot Password - Send OTP
exports.forgotPassword = async (req, res) => {
    const { email } = req.body;
    try {
        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
        }

        const user = await User.getUserByEmail(email);
        if (!user) {
            return res.status(404).json({ message: 'User with this email not found' });
        }

        const otp = generateOTP();

        otpStorage.set(email, {
            otp: otp,
            expiry: Date.now() + 5 * 60 * 1000, // 5 minutes
            verified: false
        });

        // Respond first for faster UX, then send email in the background.
        res.status(200).json({
            message: 'OTP sent successfully to your email'
        });

        setImmediate(async () => {
            try {
                await sendOTPEmail(email, otp, 'forgot_password');
            } catch (emailError) {
                console.error('Error sending forgot password email:', emailError);
                otpStorage.delete(email);
            }
        });
    } catch (error) {
        console.error('Error in forgot password:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Send OTP for signup (email verification) - creates unverified user, sends OTP
exports.sendSignupOTP = async (req, res) => {
    const { email, username, phone, dateofbirth, password } = req.body;
    try {
        if (!email || !username || !phone || !dateofbirth || !password) {
            return res.status(400).json({ message: 'All fields are required.' });
        }

        const existingUser = await User.getUserByEmail(email);
        if (existingUser) {
            if (existingUser.email_verified) {
                return res.status(409).json({ message: 'Email is already registered. Please use a different email or try logging in.' });
            }
            // Unverified user exists - delete and recreate with new data, or just resend OTP
            const otp = generateOTP();
            const storageKey = `signup:${email}`;
            otpStorage.set(storageKey, { otp, expiry: Date.now() + 5 * 60 * 1000, verified: false });
            console.log(`[OTP] Signup OTP for ${email}: ${otp}`);
            try {
                await sendOTPEmail(email, otp, 'signup');
            } catch (e) {
                otpStorage.delete(storageKey);
                return res.status(500).json({ message: 'Failed to send verification email.' });
            }
            return res.status(200).json({ message: 'Verification code sent to your email' });
        }

        const hashedPassword = await bcrypt.hash(password, 12);
        const newUser = await User.createUser({
            username,
            email,
            phone,
            dateofbirth,
            password: hashedPassword,
            role: 'user',
            emailVerified: false,
        });

        const otp = generateOTP();
        const storageKey = `signup:${email}`;
        otpStorage.set(storageKey, { otp, expiry: Date.now() + 5 * 60 * 1000, verified: false });
        console.log(`[OTP] Signup OTP for ${email}: ${otp}`);

        try {
            await sendOTPEmail(email, otp, 'signup');
        } catch (emailError) {
            console.error('Error sending signup OTP email:', emailError);
            otpStorage.delete(storageKey);
            await User.deleteUser(newUser.uid);
            return res.status(500).json({ message: 'Failed to send verification email. Please try again.' });
        }

        res.status(200).json({ message: 'Verification code sent to your email' });
    } catch (error) {
        console.error('Error in send signup OTP:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Verify OTP
exports.verifyOTP = async (req, res) => {
    const { email, otp } = req.body;
    try {
        if (!email || !otp) {
            return res.status(400).json({ message: 'Email and OTP are required' });
        }

        const storedData = otpStorage.get(email);

        if (!storedData) {
            return res.status(400).json({ message: 'OTP not found. Please request a new one.' });
        }

        if (Date.now() > storedData.expiry) {
            otpStorage.delete(email);
            return res.status(400).json({ message: 'OTP has expired. Please request a new one.' });
        }

        if (storedData.otp !== otp) {
            return res.status(400).json({ message: 'Invalid OTP' });
        }

        storedData.verified = true;
        otpStorage.set(email, storedData);

        res.status(200).json({ message: 'OTP verified successfully' });
    } catch (error) {
        console.error('Error in verify OTP:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Change Password (authenticated – requires current password)
exports.changePassword = async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    try {
        if (!currentPassword || !newPassword) {
            return res.status(400).json({ message: 'Current password and new password are required' });
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'New password must be at least 6 characters' });
        }

        const uid = req.user?.uid;
        if (!uid) {
            return res.status(401).json({ message: 'Unauthorized' });
        }

        const user = await User.getUserByID(uid);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const isMatch = await bcrypt.compare(currentPassword, user.password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Current password is incorrect' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 12);
        const updated = await User.updatePassword(uid, hashedPassword);
        if (!updated) {
            return res.status(500).json({ message: 'Failed to update password. Please try again.' });
        }

        res.status(200).json({ message: 'Password changed successfully' });
    } catch (error) {
        console.error('Error in change password:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

// Reset Password
exports.resetPassword = async (req, res) => {
    const { email, newPassword } = req.body;
    try {
        if (!email || !newPassword) {
            return res.status(400).json({ message: 'Email and new password are required' });
        }

        const storedData = otpStorage.get(email);

        if (!storedData || !storedData.verified) {
            return res.status(400).json({ message: 'Please verify OTP first' });
        }

        const user = await User.getUserByEmail(email);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 12);
        const updated = await User.updatePassword(user.uid, hashedPassword);
        if (!updated) {
            return res.status(500).json({ message: 'Failed to update password. Please try again.' });
        }
        otpStorage.delete(email);

        res.status(200).json({ message: 'Password reset successfully' });
    } catch (error) {
        console.error('Error in reset password:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};
