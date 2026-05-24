/**
 * FCM Controller
 * Handles FCM token management and notification sending
 */

const pool = require('../config/database');
const FCMService = require('../utils/fcmService');




/**
 * Save or update FCM token for a user
 */

exports.saveFCMToken = async function saveFCMToken(req, res) {
    try {
        const { userId, fcmToken } = req.body;

        // Validate input
        if (!userId || !fcmToken) {
            return res.status(400).json({
                success: false,
                error: 'userId and fcmToken are required'
            });
        }

        // Validate FCM token format
        if (typeof fcmToken !== 'string' || fcmToken.length < 100) {
            return res.status(400).json({
                success: false,
                error: 'Invalid FCM token format'
            });
        }

        // Save to database
        const query = `
      UPDATE users 
      SET fcm_token = $1, fcm_token_updated_at = NOW() 
      WHERE id = $2
      RETURNING id, email
    `;

        const result = await pool.query(query, [fcmToken, userId]);

        // If user not found, return error
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        console.log(`Successfully FCM token saved for user ${userId}`);

        // If user found, return success
        res.json({
            success: true,
            message: 'FCM token saved successfully',
            user: result.rows[0]
        });

    } catch (error) {
        console.error('Error saving FCM token:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
}

/**
 * Get FCM token for a user
 */
exports.getFCMToken = async function getFCMToken(req, res) {
    try {
        const { userId } = req.params;

        

        const query = 'SELECT fcm_token, fcm_token_updated_at FROM users WHERE id = $1';
        const result = await pool.query(query, [userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        const fcmToken = result.rows[0].fcm_token;

        if (!fcmToken) {
            return res.status(404).json({
                success: false,
                error: 'FCM token not found for this user'
            });
        }

        res.json({
            success: true,
            fcmToken: fcmToken,
            updatedAt: result.rows[0].fcm_token_updated_at
        });

    } catch (error) {
        console.error('Error retrieving FCM token:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
}

/**
 * Delete FCM token for a user (on logout)
 */
exports.deleteFCMToken = async function deleteFCMToken(req, res) {
    try {
        const { userId } = req.params;

        const query = `
      UPDATE users 
      SET fcm_token = NULL, fcm_token_updated_at = NULL 
      WHERE id = $1
      RETURNING id
    `;

        const result = await pool.query(query, [userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        console.log(`✅ FCM token deleted for user ${userId}`);

        res.json({
            success: true,
            message: 'FCM token deleted successfully'
        });

    } catch (error) {
        console.error('Error deleting FCM token:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
}

/**
 * Send notification to a specific user
 */
exports.sendNotificationToUser = async function sendNotificationToUser(req, res) {
    try {
        const { userId, notification, data } = req.body;

        // Validate input
        if (!userId || !notification || !notification.title || !notification.body) {
            return res.status(400).json({
                success: false,
                error: 'userId and notification (with title and body) are required'
            });
        }

        // Get user's FCM token from database
        const query = 'SELECT fcm_token FROM users WHERE id = $1';
        const result = await pool.query(query, [userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        const fcmToken = result.rows[0].fcm_token;

        if (!fcmToken) {
            return res.status(404).json({
                success: false,
                error: 'FCM token not found for this user'
            });
        }

        // Send notification
        const response = await FCMService.sendToDevice(fcmToken, notification, data);

        if (response.success) {
            res.json({
                success: true,
                messageId: response.messageId
            });
        } else {
            res.status(500).json({
                success: false,
                error: response.error
            });
        }

    } catch (error) {
        console.error('Error sending notification:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
}

/**
 * Send notification to multiple users
 */
exports.sendBulkNotification = async function sendBulkNotification(req, res) {
    try {
        const { userIds, notification, data } = req.body;

        // Validate input
        if (!userIds || !Array.isArray(userIds) || !notification) {
            return res.status(400).json({
                success: false,
                error: 'userIds (array) and notification are required'
            });
        }

        // Get FCM tokens for all users
        const query = 'SELECT fcm_token FROM users WHERE id = ANY($1) AND fcm_token IS NOT NULL';
        const result = await pool.query(query, [userIds]);

        const fcmTokens = result.rows.map(row => row.fcm_token);

        if (fcmTokens.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'No valid FCM tokens found for the provided users'
            });
        }

        // Send multicast notification
        const response = await FCMService.sendToMultipleDevices(fcmTokens, notification, data);

        res.json({
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount
        });

    } catch (error) {
        console.error('Error sending bulk notification:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
}

/**
 * Send period reminder to a user
 */
exports.sendPeriodReminder = async function sendPeriodReminder(req, res) {
    try {
        const { userId, daysUntil } = req.body;

        // Get user's FCM token
        const query = 'SELECT fcm_token FROM users WHERE id = $1';
        const result = await pool.query(query, [userId]);

        if (result.rows.length === 0 || !result.rows[0].fcm_token) {
            return res.status(404).json({
                success: false,
                error: 'User or FCM token not found'
            });
        }

        const response = await FCMService.sendPeriodReminder(
            result.rows[0].fcm_token,
            daysUntil
        );

        res.json(response);

    } catch (error) {
        console.error('Error sending period reminder:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
}


