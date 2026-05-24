const express = require('express');
const router = express.Router();
const notificationController = require('../controller/notificationController');
const authenticateToken = require('../middleware/jwtmiddleware');

// Device registration
router.post('/device', notificationController.registerDevice);
router.delete('/device', authenticateToken, notificationController.unregisterDevice);

// Get notifications (supports query param userId)
router.get('/', notificationController.getNotifications);

// Get unread count
router.get('/unread-count', notificationController.getUnreadCount);

// Mark as read
router.put('/:id/read', notificationController.markAsRead);

// Mark all as read
router.put('/mark-all-read', notificationController.markAllAsRead);

module.exports = router;
