/**
 * Notification Helper
 * Helper functions for sending notifications to users
 */

const pool = require('../config/database');
const FCMService = require('./fcmService');
const Device = require('../model/Device');
const Notification = require('../model/Notification');

class NotificationHelper {
    static async getFCMTokensByUserIds(userIds = []) {
        try {
            if (!userIds.length) return [];
            const query = 'SELECT fcm_token FROM user_devices WHERE user_id = ANY($1)';
            const result = await pool.query(query, [userIds]);
            return result.rows.map((row) => row.fcm_token).filter(Boolean);
        } catch (error) {
            console.error('Error fetching FCM tokens by user ids:', error);
            return [];
        }
    }

    static async getAdminUserIds() {
        try {
            const result = await pool.query("SELECT uid FROM users WHERE role = 'admin'");
            return result.rows.map((row) => row.uid);
        } catch (error) {
            console.error('Error fetching admin users:', error);
            return [];
        }
    }

    static async notifyAdminsNewUserRegistered(user) {
        try {
            const adminUserIds = await this.getAdminUserIds();
            if (adminUserIds.length === 0) {
                return { success: true, message: 'No admin users found', dbCount: 0, successCount: 0, failureCount: 0 };
            }

            const username = user?.username || 'New user';
            const email = user?.email || '';
            const uid = user?.uid != null ? String(user.uid) : '';

            const notification = {
                title: '👤 New User Registered',
                body: email ? `${username} (${email}) joined Aparna.` : `${username} joined Aparna.`,
            };

            const data = {
                type: 'new_user_registered',
                userId: uid,
                username,
                email,
            };

            await Notification.createBulk(
                adminUserIds,
                notification.title,
                notification.body,
                data.type,
                data
            );

            const tokens = await this.getFCMTokensByUserIds(adminUserIds);
            if (tokens.length === 0) {
                return { success: true, dbCount: adminUserIds.length, successCount: 0, failureCount: 0 };
            }

            const pushResult = await FCMService.sendToMultipleDevices(tokens, notification, data);
            return {
                ...pushResult,
                dbCount: adminUserIds.length,
            };
        } catch (error) {
            console.error('Error notifying admins about new user registration:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Get all FCM tokens from users who have them
     * @param {string[]} excludeUserIds - Optional array of user IDs to exclude
     * @returns {Promise<string[]>} Array of FCM tokens
     */
    static async getAllFCMTokens(excludeUserIds = []) {
        try {
            // Replaced with Device table logic if needed, but for bulk sending 
            // strictly to ALL devices, we can query the user_devices table directly.
            let query = 'SELECT fcm_token FROM user_devices WHERE 1=1';
            const params = [];

            if (excludeUserIds.length > 0) {
                query += ' AND user_id != ALL($1)';
                params.push(excludeUserIds);
            }

            const result = await pool.query(query, params);
            return result.rows.map(row => row.fcm_token).filter(Boolean);
        } catch (error) {
            console.error('Error fetching FCM tokens:', error);
            return [];
        }
    }

    //notify the user about their period day starting soon before 3 days
    static async notifyAllUsersAboutPeriodDayStartingSoon(notification, data = {}, excludeUserIds = []) {
        return await this.notifyAllUsers(
            {
                title: '💫 Period Day Starting Soon',
                body: 'Your period is starting soon'
            },
            data
        );
    }


    /**
     * Send notification to all users
     * @param {object} notification - Notification payload {title, body}
     * @param {object} data - Optional data payload
     * @param {string[]} excludeUserIds - Optional array of user IDs to exclude
     */
    static async notifyAllUsers(notification, data = {}, excludeUserIds = []) {
        try {
            // 1. Fetch all User IDs (for DB insertion)
            let userQuery = 'SELECT uid FROM users';
            let userParams = [];
            if (excludeUserIds.length > 0) {
                userQuery += ' WHERE uid != ALL($1)';
                userParams.push(excludeUserIds);
            }
            const userResult = await pool.query(userQuery, userParams);
            const userIds = userResult.rows.map(row => row.uid);

            // 2. Save to Database for ALL users (bulk)
            if (userIds.length > 0) {
                console.log(`Saving notification for ${userIds.length} users...`);
                await Notification.createBulk(
                    userIds,
                    notification.title,
                    notification.body,
                    data.type || 'general',
                    data
                );
            }

            // 3. Fetch Tokens (only for those who have devices)
            const tokens = await this.getAllFCMTokens(excludeUserIds);

            if (tokens.length === 0) {
                console.log('No FCM tokens found, skipping push notification');
                // Return success because we saved to DB
                return { success: true, successCount: 0, failureCount: 0, dbCount: userIds.length };
            }

            // Send push notification to all devices
            console.log(`Sending push notification to ${tokens.length} devices...`);
            const result = await FCMService.sendToMultipleDevices(tokens, notification, data);

            // Cleanup invalid tokens
            if (result.failureCount > 0 && result.responses) {
                const invalidTokens = [];
                result.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        const errorCode = resp.error?.code;
                        const errorMessage = resp.error?.message || '';

                        // Check for specific error codes or messages indicating invalid token
                        if (errorCode === 'messaging/registration-token-not-registered' ||
                            errorCode === 'messaging/invalid-registration-token' ||
                            errorMessage.includes('Requested entity was not found') ||
                            errorMessage.includes('Not Found')) {

                            invalidTokens.push(tokens[idx]);
                        }
                    }
                });

                if (invalidTokens.length > 0) {
                    console.log(`Cleaning up ${invalidTokens.length} invalid tokens...`);
                    for (const token of invalidTokens) {
                        await Device.remove(token);
                    }
                }
            }

            return {
                ...result,
                dbCount: userIds.length
            };

        } catch (error) {
            console.error('Error notifying all users:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Send water reminder to all users.
     * Called by the scheduler every 2 hours.
     */
    static async notifyAllUsersAboutDrinkingWater(message) {
        return await this.notifyAllUsers(
            { title: '💧 Drink Water', body: message || 'Drink water to stay healthy' },
            { type: 'water_reminder' }
        );
    }

    /**
     * Notify users about a new blog post
     * @param {string} blogTitle
     * @param {string|number} blogId
     * @param {string} [authorName='Aparna']
     * @param {string} [category=''] - Category name or id for the blog
     */
    static async notifyNewBlog(blogTitle, blogId, authorName = authorName || 'Aparna', category = category || '') {
        const data = {
            type: 'new_blog',
            blogId: String(blogId),
            title: blogTitle,
            category: category || 'General'
        };
        return await this.notifyAllUsers(
            {
                title: '📝 New Blog Post',
                body: `${authorName} just published: ${blogTitle}`

            },
            data
        );
    }

    /**
     * Notify users about a new story
     */
    static async notifyNewStory(storyTitle, storyId, authorName = authorName || 'Anonymous') {
        return await this.notifyAllUsers(
            {
                title: '💬 New Story Shared',
                body: `${authorName} shared: ${storyTitle}`
            },
            {
                type: 'new_story',
                storyId: storyId.toString(),
                title: storyTitle
            }
        );
    }

    //notify the user about the new clinic added in the system
    static async notifyNewClinic(clinicName, clinicId) {
        return await this.notifyAllUsers(
            {
                title: '🏥 New Clinic Added',
                body: `A new clinic "${clinicName}" has been added to Aparna. Check it out!`
                }
                ,
        {   type: 'new_clinic',
            clinicId: clinicId.toString(),
            name: clinicName
        });
    }

    //
    static async notifyAllUsersAboutOvulation(notification, data = {}, excludeUserIds = []) {
        return await this.notifyAllUsers(
            {
                title: '💫 Ovulation Reminder',
                body: 'Your ovulation is coming up soon'
            },
            data
        );
    }

    //notify the user about the new health tip
    static async notifyAllUsersAboutHealthTip(notification, data = {}, excludeUserIds = []) {
        return await this.notifyAllUsers(
            {
                title: '💡 Health Tip',
                body: 'A new health tip has been added to Aparna. Check it out!'
            },
            data
        );
    }
    /**
     * Notify specific user
     */
    static async notifyUser(userId, notification, data = {}) {
        try {
            // 1. Save to Database
            await Notification.create(
                userId,
                notification.title,
                notification.body,
                data.type || 'general',
                data
            );

            // 2. Get User's Devices
            const tokens = await Device.getTokensByUserId(userId);

            if (tokens.length === 0) {
                console.log(`No active devices found for user ${userId}`);
                // Return success mostly because we saved to DB, failing to send push isn't critical failure
                return { success: true, message: 'Saved to DB, but no devices to push' };
            }

            // 3. Send Push
            return await FCMService.sendToMultipleDevices(tokens, notification, data);
        } catch (error) {
            console.error('Error notifying user:', error);
            return { success: false, error: error.message };
        }
    }
}

module.exports = NotificationHelper;
