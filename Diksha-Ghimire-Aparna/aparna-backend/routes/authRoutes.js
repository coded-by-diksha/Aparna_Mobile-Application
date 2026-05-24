const express = require('express');
const router = express.Router();
const authController = require('../controller/auth');
const authenticateToken = require('../middleware/jwtmiddleware');

router.get('/register', authController.getRegister);
router.post('/send-signup-otp', authController.sendSignupOTP);
router.post('/register', authController.postRegister);
router.post('/login', authController.postLogin);
router.post('/google-login', authController.googleLogin);
router.post('/refresh-token', authController.refreshToken);
router.get('/validate-token', authenticateToken, authController.validateToken);
router.get('/user', authenticateToken, authController.getAllUsers);
router.get('/users/:id', authenticateToken, authController.getUserById);

// Change password (authenticated)
router.post('/change-password', authenticateToken, authController.changePassword);

// Forgot password
router.post('/forgot-password', authController.forgotPassword);
router.post('/verify-otp', authController.verifyOTP);
router.post('/reset-password', authController.resetPassword);



module.exports = router;
