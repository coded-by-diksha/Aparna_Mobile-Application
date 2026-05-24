/**
 * Firebase Cloud Messaging Service
 * Handles sending push notifications to devices
 */

const { getMessaging } = require('../config/firebase');

class FCMService {
    /**
     * Send notification to a single device
     * @param {string} fcmToken - Device FCM token
     * @param {object} notification - Notification payload {title, body, imageUrl}
     * @param {object} data - Optional data payload
     * @returns {Promise<object>} Result with success status and messageId or error
     */
    static async sendToDevice(fcmToken, notification, data = {}) {
        try {
            const messaging = getMessaging();

            const message = {
                notification: {
                    title: notification.title,
                    body: notification.body,
                    imageUrl: notification.imageUrl || undefined
                },
                data: {
                    ...data,
                    timestamp: new Date().toISOString()
                },
                token: fcmToken,
                // Android specific options
                android: {
                    priority: 'high',
                    notification: {
                        sound: 'default',
                        channelId: 'period_tracker_notifications',
                        color: '#792F2F' // App primary color
                    }
                },
                // iOS specific options
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1
                        }
                    }
                }
            };

            const response = await messaging.send(message);
            console.log('✅ Notification sent successfully:', response);

            return {
                success: true,
                messageId: response
            };

        } catch (error) {
            console.error('❌ Error sending notification:', error);
            return {
                success: false,
                error: error.message,
                errorCode: error.code
            };
        }
    }

    /**
     * Send notification to multiple devices
     * @param {string[]} fcmTokens - Array of device FCM tokens
     * @param {object} notification - Notification payload
     * @param {object} data - Optional data payload
     * @returns {Promise<object>} Result with success/failure counts
     */
    static async sendToMultipleDevices(fcmTokens, notification, data = {}) {
        try {
            const messaging = getMessaging();

            const message = {
                notification: {
                    title: notification.title,
                    body: notification.body
                },
                data: {
                    ...data,
                    timestamp: new Date().toISOString()
                },
                tokens: fcmTokens
            };

            const response = await messaging.sendEachForMulticast(message);

            console.log(`✅ ${response.successCount} messages sent successfully`);
            if (response.failureCount > 0) {
                console.log(`❌ ${response.failureCount} messages failed`);

                // Log failed tokens for debugging
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Failed token ${fcmTokens[idx]}:`, resp.error?.message);
                    }
                });
            }

            return {
                success: true,
                successCount: response.successCount,
                failureCount: response.failureCount,
                responses: response.responses
            };

        } catch (error) {
            console.error('❌ Error sending multicast notification:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Send period reminder notification
     */
    static async sendPeriodReminder(fcmToken, daysUntil) {
        return await this.sendToDevice(
            fcmToken,
            {
                title: '🩸 Period Starting Soon',
                body: `Your period is expected to start in ${daysUntil} day${daysUntil > 1 ? 's' : ''}`
            },
            {
                type: 'period_reminder',
                daysUntil: daysUntil.toString()
            }
        );
    }

    /**
     * Send ovulation reminder notification
     */
    static async sendOvulationReminder(fcmToken) {
        return await this.sendToDevice(
            fcmToken,
            {
                title: '🌸 Fertile Window',
                body: 'You are in your fertile window today'
            },
            {
                type: 'ovulation_reminder'
            }
        );
    }

    /**
     * Send health tip notification
     */
    static async sendHealthTip(fcmToken, tip) {
        return await this.sendToDevice(
            fcmToken,
            {
                title: '💡 Health Tip',
                body: tip
            },
            {
                type: 'health_tip'
            }
        );
    }

    /**
     * Send symptom tracking reminder
     */
    static async sendSymptomTrackingReminder(fcmToken) {
        return await this.sendToDevice(
            fcmToken,
            {
                title: '📝 Track Your Symptoms',
                body: 'Don\'t forget to log your symptoms today'
            },
            {
                type: 'symptom_reminder'
            }
        );
    }

    /**
     * Send custom notification
     */
    static async sendCustomNotification(fcmToken, title, body, data = {}) {
        return await this.sendToDevice(
            fcmToken,
            { title, body },
            data
        );
    }
}

module.exports = FCMService;
