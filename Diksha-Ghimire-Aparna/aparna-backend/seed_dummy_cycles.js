const pool = require('./config/database');

async function seedDummyData(email) {
    try {
        const userResult = await pool.query('SELECT uid FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) {
            console.error(`User ${email} not found.`);
            return;
        }
        const uid = userResult.rows[0].uid;

        // Clear existing data for a clean test
        await pool.query('DELETE FROM user_cycles WHERE uid = $1', [uid]);

        const today = new Date();
        const dates = [
            new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
            new Date(Date.now() - 31 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
            new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        ];

        console.log(`Seeding 3 cycles for user ${email} (UID: ${uid})...`);

        // Insert cycles with 29-31 day gaps
        await pool.query(
            'INSERT INTO user_cycles (uid, period_start_date, menses_length, cycle_length, mood_score, emotions, flow_level) VALUES ($1, $2, $3, $4, $5, $6, $7)',
            [uid, dates[0], 5, null, 3, ['Cramps'], 4]
        );

        await pool.query(
            'INSERT INTO user_cycles (uid, period_start_date, menses_length, cycle_length, mood_score, emotions, flow_level) VALUES ($1, $2, $3, $4, $5, $6, $7)',
            [uid, dates[1], 5, 29, 2, ['Mood Swings'], 2]
        );

        await pool.query(
            'INSERT INTO user_cycles (uid, period_start_date, menses_length, cycle_length, mood_score, emotions, flow_level) VALUES ($1, $2, $3, $4, $5, $6, $7)',
            [uid, dates[2], 5, 29, 4, ['Fatigue'], 5]
        );
        console.log(' Dummy data seeded successfully!');
        process.exit(0);
    } catch (error) {
        console.error(' Error seeding data:', error);
        process.exit(1);
    }
}

seedDummyData('test@test.com');
