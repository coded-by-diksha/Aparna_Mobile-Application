/**
 * FCM Routes
 * API endpoints for Firebase Cloud Messaging
 */

const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/jwtmiddleware');
const fcmController = require('../controller/fcmController');
// Token Management Routes
router.post('/token', authenticateToken, fcmController.saveFCMToken);
router.get('/token/:userId', authenticateToken, fcmController.getFCMToken);
router.delete('/token/:userId', authenticateToken, fcmController.deleteFCMToken);

// Notification Sending Routes
router.post('/send', authenticateToken, fcmController.sendNotificationToUser);
router.post('/send-bulk', authenticateToken, fcmController.sendBulkNotification);
router.post('/send-period-reminder', authenticateToken, fcmController.sendPeriodReminder);

module.exports = router;
