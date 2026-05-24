const Notification = require('../model/Notification');
const Device = require('../model/Device');

/**
 * Unregister all devices for the authenticated user (disable notifications)
 */
exports.unregisterDevice = async (req, res) => {
    try {
        const userId = req.user?.uid || req.body.userId || req.query.userId;

        if (!userId) {
            return res.status(400).json({ success: false, error: 'User ID is required' });
        }

        await Device.removeByUserId(userId);

        res.json({
            success: true,
            message: 'Device unregistered successfully'
        });
    } catch (error) {
        console.error('Error unregistering device:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * Register a user device for FCM
 */
exports.registerDevice = async (req, res) => {
    try {
        const { userId, fcmToken, deviceType } = req.body;

        if (!userId || !fcmToken) {
            return res.status(400).json({ success: false, error: 'User ID and FCM Token are required' });
        }

        const device = await Device.register(userId, fcmToken, deviceType);

        res.json({
            success: true,
            message: 'Device registered successfully',
            device
        });
    } catch (error) {
        console.error('Error registering device:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * Get notifications for a user
 */
exports.getNotifications = async (req, res) => {
    try {
        const userId = req.params.userId || req.query.userId;
        const limit = parseInt(req.query.limit) || 20;
        const offset = parseInt(req.query.offset) || 0;

        if (!userId) {
            return res.status(400).json({ success: false, error: 'User ID is required' });
        }

        const notifications = await Notification.getByUserId(userId, limit, offset);

        res.json({
            success: true,
            notifications
        });
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * Get unread notification count
 */
exports.getUnreadCount = async (req, res) => {
    try {
        const userId = req.params.userId || req.query.userId;

        if (!userId) {
            return res.status(400).json({ success: false, error: 'User ID is required' });
        }

        const count = await Notification.getUnreadCount(userId);

        res.json({
            success: true,
            count
        });
    } catch (error) {
        console.error('Error fetching unread count:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * Mark a notification as read
 */
exports.markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId } = req.body; // In a real app, get this from auth middleware

        if (!id || !userId) {
            return res.status(400).json({ success: false, error: 'Notification ID and User ID are required' });
        }

        const notification = await Notification.markAsRead(id, userId);

        if (!notification) {
            return res.status(404).json({ success: false, error: 'Notification not found or access denied' });
        }

        res.json({
            success: true,
            message: 'Notification marked as read',
            notification
        });
    } catch (error) {
        console.error('Error marking notification as read:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * Mark all notifications as read
 */
exports.markAllAsRead = async (req, res) => {
    try {
        const { userId } = req.body;

        if (!userId) {
            return res.status(400).json({ success: false, error: 'User ID is required' });
        }

        await Notification.markAllAsRead(userId);

        res.json({
            success: true,
            message: 'All notifications marked as read'
        });
    } catch (error) {
        console.error('Error marking all as read:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};
