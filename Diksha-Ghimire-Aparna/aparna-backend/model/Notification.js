const pool = require('../config/database');

class Notification {
    /**
     * Create a new notification record
     * @param {number} userId 
     * @param {string} title 
     * @param {string} body 
     * @param {string} type 
     * @param {object} data
     */
    static async create(userId, title, body, type, data = {}) {
        try {
            const query = `
                INSERT INTO notifications (user_id, title, body, type, data) 
                VALUES ($1, $2, $3, $4, $5) 
                RETURNING *
            `;
            const result = await pool.query(query, [userId, title, body, type, data]);
            return result.rows[0];
        } catch (error) {
            console.error('Error creating notification:', error);
            throw error;
        }
    }

    /**
     * Create notification for multiple users (Bulk Insert)
     * @param {number[]} userIds 
     * @param {string} title 
     * @param {string} body 
     * @param {string} type 
     * @param {object} data 
     */
    static async createBulk(userIds, title, body, type, data = {}) {
        if (!userIds || userIds.length === 0) return;

        try {
        
            // Let's use individual inserts in transaction or a constructed query string for safety.

            const client = await pool.connect();
            try {
                await client.query('BEGIN');

                // Use a prepared statement in a loop (batched) or just loop await

                // To avoid parameter limit issues (65535 parameters), we chunk it.
                const chunkSize = 1000;
                for (let i = 0; i < userIds.length; i += chunkSize) {
                    const chunk = userIds.slice(i, i + chunkSize);

                    const values = [];
                    const placeholders = [];
                    let idx = 1;

                    chunk.forEach(uid => {
                        placeholders.push(`($${idx}, $${idx + 1}, $${idx + 2}, $${idx + 3}, $${idx + 4})`);
                        values.push(uid, title, body, type, data);
                        idx += 5;
                    });

                    const query = `
                        INSERT INTO notifications (user_id, title, body, type, data) 
                        VALUES ${placeholders.join(', ')}
                    `;

                    await client.query(query, values);
                }

                await client.query('COMMIT');
                return true;
            } catch (e) {
                await client.query('ROLLBACK');
                throw e;
            } finally {
                client.release();
            }
        } catch (error) {
            console.error('Error creating bulk notifications:', error);
            // Don't throw, just log to prevent crashing the main flow
        }
    }

    /**
     * Get notifications for a user
     * @param {number} userId 
     * @param {number} limit 
     * @param {number} offset 
     */
    static async getByUserId(userId, limit = 20, offset = 0) {
        try {
            const query = `
                SELECT * FROM notifications 
                WHERE user_id = $1 
                ORDER BY created_at DESC 
                LIMIT $2 OFFSET $3
            `;
            const result = await pool.query(query, [userId, limit, offset]);
            return result.rows;
        } catch (error) {
            console.error('Error fetching notifications:', error);
            throw error;
        }
    }

    /**
     * Get unread count for a user
     * @param {number} userId 
     */
    static async getUnreadCount(userId) {
        try {
            const query = 'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = FALSE';
            const result = await pool.query(query, [userId]);
            return parseInt(result.rows[0].count);
        } catch (error) {
            console.error('Error fetching unread count:', error);
            return 0;
        }
    }

    /**
     * Mark notification as read
     * @param {number} id 
     * @param {number} userId - validation to ensure user owns notification
     */
    static async markAsRead(id, userId) {
        try {
            const query = `
                UPDATE notifications 
                SET is_read = TRUE 
                WHERE id = $1 AND user_id = $2 
                RETURNING *
            `;
            const result = await pool.query(query, [id, userId]);
            return result.rows[0];
        } catch (error) {
            console.error('Error marking notification as read:', error);
            throw error;
        }
    }

    /**
     * Mark all notifications as read for a user
     * @param {number} userId 
     */
    static async markAllAsRead(userId) {
        try {
            const query = `
                UPDATE notifications 
                SET is_read = TRUE 
                WHERE user_id = $1 AND is_read = FALSE
            `;
            await pool.query(query, [userId]);
            return true;
        } catch (error) {
            console.error('Error marking all as read:', error);
            throw error;
        }
    }
}

module.exports = Notification;
