const pool = require('../config/database');

class Device {
    /**
     * Register a device for a user
     * @param {number} userId - User ID
     * @param {string} fcmToken - FCM Token
     * @param {string} deviceType - android, ios, web
     */
    static async register(userId, fcmToken, deviceType = 'android') {
        // Try to register the device
        try {
            // Check if the token exists
            // Check if token exists
            const checkQuery = 'SELECT * FROM user_devices WHERE fcm_token = $1';
            const checkResult = await pool.query(checkQuery, [fcmToken]);

            // If the token exists, update the record
            if (checkResult.rows.length > 0) {
                // Update the existing record
                // Update existing record
                const updateQuery = `
                    UPDATE user_devices 
                    SET user_id = $1, device_type = $2, last_active = NOW() 
                    WHERE fcm_token = $3 
                    RETURNING *
                `;
                const result = await pool.query(updateQuery, [userId, deviceType, fcmToken]);
                return result.rows[0];
            } else {
                // Insert the new record
                const insertQuery = `
                    INSERT INTO user_devices (user_id, fcm_token, device_type) 
                    VALUES ($1, $2, $3) 
                    RETURNING *
                `;
                const result = await pool.query(insertQuery, [userId, fcmToken, deviceType]);
                return result.rows[0];
            }
        } catch (error) {
            console.error('Error registering device:', error);
            throw error;
        }
    }

    /**
     * Get all active tokens for a user
     * @param {number} userId 
     */
    static async getTokensByUserId(userId) {
        try {
            const query = 'SELECT fcm_token FROM user_devices WHERE user_id = $1';
            const result = await pool.query(query, [userId]);
            return result.rows.map(row => row.fcm_token);
        } catch (error) {
            console.error('Error fetching user tokens:', error);
            return [];
        }
    }

    /**
     * Remove a device token (e.g., on logout)
     * @param {string} fcmToken 
     */
    static async remove(fcmToken) {
        try {
            const query = 'DELETE FROM user_devices WHERE fcm_token = $1';
            await pool.query(query, [fcmToken]);
            return true;
        } catch (error) {
            console.error('Error removing device:', error);
            throw error;
        }
    }

    /**
     * Remove all devices for a user (e.g., when disabling notifications)
     * @param {number} userId 
     */
    static async removeByUserId(userId) {
        try {
            const query = 'DELETE FROM user_devices WHERE user_id = $1';
            await pool.query(query, [userId]);
            return true;
        } catch (error) {
            console.error('Error removing devices for user:', error);
            throw error;
        }
    }
}

module.exports = Device;
