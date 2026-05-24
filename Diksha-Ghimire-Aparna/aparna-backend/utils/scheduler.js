const cron = require('node-cron'); //for scheduling the jobs
const NotificationHelper = require('./notificationHelper');
const Health = require('../model/health');
const Cycle = require('../model/Cycle');
const User = require('../model/User');
const CyclePredictor = require('./cycle_predictor');
const pool = require('../config/database');

//water reminder messages
const WATER_MESSAGES = [
    '💧 Time to hydrate! Drink a glass of water.',
    '💧 Stay hydrated! Have you had water recently?',
    '💧 Water break! Your body needs hydration.',
    '💧 Reminder: Drink water to keep your energy up!',
    '💧 Hydration check! Grab a glass of water now.',
    '💧 Don\'t forget to drink water — your body will thank you!',
    '💧 A glass of water can boost your focus. Drink up!',
];

//get a random item from an array
function randomItem(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
}

//start the scheduled jobs
function startScheduledJobs() {
    // ─── Water reminder: every 2 hours between 7 AM – 9 PM ───
    // Cron: minute 0, every 2nd hour from 7 through 21
    cron.schedule('0 7-21/2 * * *', async () => {
        console.log('[Scheduler] Sending water reminder...');
        try {
            const msg = randomItem(WATER_MESSAGES);
            await NotificationHelper.notifyAllUsers(
                { title: '💧 Drink Water', body: msg },
                { type: 'water_reminder' }
            );
            console.log('[Scheduler] Water reminder sent.');
        } catch (err) {
            console.error('[Scheduler] Water reminder failed:', err.message);
        }
    });

    // ─── Daily health summary: once per day at a random hour (8 AM – 8 PM) ───
    // We schedule a check every minute at XX:00, but only fire once per day
    // by picking the random hour at midnight.
    let todaysHealthHour = pickRandomHour();
    let lastHealthDate = null;

    // Pick a new random hour at midnight each day
    cron.schedule('0 0 * * *', () => {
        todaysHealthHour = pickRandomHour();
        lastHealthDate = null;
        console.log(`[Scheduler] Today's health summary will fire at ${todaysHealthHour}:00`);
    });

    // Check every hour if it's time to send the daily health summary
    cron.schedule('0 * * * *', async () => {
        const now = new Date();
        const today = now.toISOString().slice(0, 10);
        const currentHour = now.getHours();

        if (currentHour === todaysHealthHour && lastHealthDate !== today) {
            lastHealthDate = today;
            console.log('[Scheduler] Sending daily health summary...');
            try {
                await sendHealthSummaryToAll();
                console.log('[Scheduler] Daily health summary sent.');
            } catch (err) {
                console.error('[Scheduler] Health summary failed:', err.message);
            }
        }
    });

    // ─── Period reminders: daily at 3:42 PM ───
    cron.schedule('42 15 * * *', async () => {
        console.log('[Scheduler] Checking period reminders...');
        try {
            await checkPeriodReminders();
            console.log('[Scheduler] Period reminders done.');
        } catch (err) {
            console.error('[Scheduler] Period reminders failed:', err.message);
        }
    });

    // Run once at startup so users don't need to wait for the next cron tick.
    setTimeout(async () => {
        console.log('[Scheduler] Initial period reminder check...');
        try {
            await checkPeriodReminders();
            console.log('[Scheduler] Initial period reminders done.');
        } catch (err) {
            console.error('[Scheduler] Initial period reminders failed:', err.message);
        }
    }, 5000);

    console.log(`[Scheduler] Jobs started — water every 2h (7–21), health summary today at ${todaysHealthHour}:00, period check daily at 15:42`);
}

//pick a random hour between 8 AM and 8 PM
function pickRandomHour() {
    return 8 + Math.floor(Math.random() * 13); // 8..20
}

// Parse date-like values into a UTC midnight date to avoid timezone drift.
function toUtcDateOnly(value) {
    if (value instanceof Date) {
        return new Date(Date.UTC(value.getUTCFullYear(), value.getUTCMonth(), value.getUTCDate()));
    }

    if (typeof value === 'string') {
        const match = value.match(/^(\d{4})-(\d{2})-(\d{2})/);
        if (match) {
            const year = Number(match[1]);
            const month = Number(match[2]);
            const day = Number(match[3]);
            return new Date(Date.UTC(year, month - 1, day));
        }
    }

    const parsed = new Date(value);
    return new Date(Date.UTC(parsed.getUTCFullYear(), parsed.getUTCMonth(), parsed.getUTCDate()));
}

function diffUtcDays(fromDate, toDate) {
    const msPerDay = 1000 * 60 * 60 * 24;
    return Math.floor((toDate - fromDate) / msPerDay);
}


/**
 * Check every user's cycle data and send:
 *  - "Period starting soon" if predicted next period is ~3 days away
 *  - "Period ending soon"   if the user is currently on their period
 *    and it's expected to end tomorrow
 */
async function checkPeriodReminders() {
    const userIds = await Cycle.getAllUserIdsWithCycles();

    const today = toUtcDateOnly(new Date());

    for (const uid of userIds) {
        try {
            const cycles = await Cycle.getRecentCycles(uid, 6);
            if (!cycles || cycles.length === 0) continue;

            const latest = cycles[0];
            const latestStart = toUtcDateOnly(latest.period_start_date);
            const profile = await User.getUserByID(uid);
            const age = profile && profile.dateofbirth
                ? new Date().getFullYear() - new Date(profile.dateofbirth).getFullYear()
                : 25;

            const avgMensesLength = latest.menses_length || 5;

            // Use the same predictor as the API so reminders match UI dates.
            const prediction = CyclePredictor.predictNext(cycles, { age }, 1);
            if (prediction && prediction.predictedDates && prediction.predictedDates.length > 0) {
                let predictedNextStart = toUtcDateOnly(prediction.predictedDates[0].date);

                // Apply pending day-shift adjustment if it exists.
                const adjustmentQuery = `
                    SELECT flow_level FROM daily_logs 
                    WHERE uid = $1 AND feeling = 'PREDICTION_SHIFT'
                    ORDER BY log_date DESC LIMIT 1
                `;
                const adjustmentResult = await pool.query(adjustmentQuery, [uid]);
                if (adjustmentResult.rows.length > 0) {
                    const shiftedDate = toUtcDateOnly(adjustmentResult.rows[0].flow_level);
                    const tomorrow = new Date(today);
                    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
                    predictedNextStart = shiftedDate > tomorrow ? tomorrow : shiftedDate;
                }

                // Keep period-start reminders future-facing (tomorrow+), same behavior as API.
                if (predictedNextStart <= today) {
                    predictedNextStart = new Date(today);
                    predictedNextStart.setUTCDate(predictedNextStart.getUTCDate() + 1);
                }

                const daysUntilNext = diffUtcDays(today, predictedNextStart);

                if ([3, 2, 1].includes(daysUntilNext)) {
                    const shouldSend = await shouldSendPeriodReminderToday(uid, daysUntilNext);
                    if (shouldSend) {
                        const body = daysUntilNext === 1
                            ? 'Your period is expected to start tomorrow. Get ready!'
                            : `Your period is expected to start in about ${daysUntilNext} days. Stay prepared!`;

                        await NotificationHelper.notifyUser(
                            uid,
                            {
                                title: '🩸 Period Starting Soon',
                                body
                            },
                            { type: 'period_starting_soon', daysUntil: String(daysUntilNext) }
                        );
                        console.log(`[Scheduler] Period-starting-soon (${daysUntilNext} days) sent to user ${uid}`);
                    }
                }
            }

            // ── Period ending soon (1 day before predicted end) ──
            const predictedEnd = new Date(latestStart);
            predictedEnd.setUTCDate(predictedEnd.getUTCDate() + avgMensesLength);

            const daysUntilEnd = diffUtcDays(today, predictedEnd);

            if (daysUntilEnd === 1) {
                await NotificationHelper.notifyUser(
                    uid,
                    {
                        title: '🌸 Period Ending Soon',
                        body: 'Your period is expected to end tomorrow. Hang in there!'
                    },
                    { type: 'period_ending_soon', daysUntil: '1' }
                );
                console.log(`[Scheduler] Period-ending-soon sent to user ${uid}`);
            }
        } catch (err) {
            console.error(`[Scheduler] Period check for user ${uid} failed:`, err.message);
        }
    }
}

//get the average cycle length from the cycles
function getAverageCycleLength(cycles) {
    const lengths = cycles
        .map(c => c.cycle_length)
        .filter(l => l != null && l > 0);
    if (lengths.length === 0) return 28;
    return Math.round(lengths.reduce((a, b) => a + b, 0) / lengths.length);
}

async function shouldSendPeriodReminderToday(userId, daysUntil) {
        const query = `
                SELECT 1
                FROM notifications
                WHERE user_id = $1
                    AND type = 'period_starting_soon'
                    AND created_at::date = CURRENT_DATE
                    AND data->>'daysUntil' = $2
                LIMIT 1
        `;
        const result = await pool.query(query, [userId, String(daysUntil)]);
        return result.rows.length === 0;
}

//send the health summary to all users
async function sendHealthSummaryToAll() {
    //get all the users with health data
    const usersResult = await pool.query(
        'SELECT DISTINCT h.user_id FROM health h WHERE h.device_name IS NOT NULL AND h.device_name != \'\''
    );

    for (const row of usersResult.rows) {
        try {
            const healthRow = await Health.getHealthData(row.user_id);
            if (!healthRow) continue;

            const h = typeof healthRow.health_data_history === 'string'
                ? JSON.parse(healthRow.health_data_history)
                : healthRow.health_data_history;

            const steps = h?.steps ?? 0;
            const sleep = h?.sleep_hours ?? 0;
            const calories = h?.calories ?? 0;
            const water = h?.water_intake ?? 0;

            const parts = [];
            if (steps > 0) parts.push(`${steps} steps`);
            if (sleep > 0) parts.push(`${sleep}h sleep`);
            if (calories > 0) parts.push(`${calories} cal`);
            if (water > 0) parts.push(`${water} ml water`);

            const body = parts.length > 0
                ? `Today so far: ${parts.join(' · ')}. Keep it up! 💪`
                : 'Sync your device to see today\'s health stats. Stay active! 💪';

            await NotificationHelper.notifyUser(
                row.user_id,
                { title: '📊 Your Daily Health Update', body },
                { type: 'health_summary' }
            );
        } catch (err) {
            console.error(`[Scheduler] Health summary for user ${row.user_id} failed:`, err.message);
        }
    }
}

module.exports = { startScheduledJobs };
