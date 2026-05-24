const pool = require('../config/database');

class Cycle {

    // Record a new cycle period for a user
    static async recordPeriod(uid, data) {
        // Get the data from the request body
        const { period_start_date, menses_length, notes, mood_score, emotions, flow_level } = data;
        const insertQuery = `
            INSERT INTO user_cycles (uid, period_start_date, menses_length, notes, mood_score, emotions, flow_level)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (uid, period_start_date) 
            DO UPDATE SET menses_length = EXCLUDED.menses_length, notes = EXCLUDED.notes, mood_score = EXCLUDED.mood_score, emotions = EXCLUDED.emotions, flow_level = EXCLUDED.flow_level
            RETURNING *
        `;
        const result = await pool.query(insertQuery, [uid, period_start_date, menses_length, notes, mood_score, emotions, flow_level]);
        return result.rows[0];
    }
    // Add a daily log for a user
    static async addDailyLog(uid, data) {
        // Get the data from the request body
        const { log_date, feeling, mood_score, flow_level } = data;
        const query = `
            INSERT INTO daily_logs (uid, log_date, feeling, mood_score, flow_level)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (uid, log_date) 
            DO UPDATE SET feeling = EXCLUDED.feeling, mood_score = EXCLUDED.mood_score, flow_level = EXCLUDED.flow_level
            RETURNING *
        `;
        const result = await pool.query(query, [uid, log_date, feeling, mood_score, flow_level]);
        return result.rows[0];
    }

    // Get cycle history for a user
    static async getHistory(uid) {
        // Get the cycle history for the user
        const query = `SELECT * FROM user_cycles 
            WHERE uid = $1 
            AND (menses_length IS NOT NULL AND menses_length > 0) 
            ORDER BY period_start_date DESC`;
        const result = await pool.query(query, [uid]);
        return result.rows;
    }

    // Get the recent cycles for a user
    static async getRecentCycles(uid, limit = 6) {
        // Get the recent cycles for the user
        const query = 'SELECT period_start_date, cycle_length, menses_length, flow_level, mood_score FROM user_cycles WHERE uid = $1 ORDER BY period_start_date DESC LIMIT $2';
        const result = await pool.query(query, [uid, limit]);
        return result.rows;
    }

    // Delete a cycle period for a user
    static async deletePeriod(id, uid) {
        const query = 'DELETE FROM user_cycles WHERE id = $1 AND uid = $2 RETURNING *';
        const result = await pool.query(query, [id, uid]);
        return result.rows[0];
    }

    // Get the cycle dates for a user
    static async getCycleDates(uid) {
        const query = 'SELECT id, period_start_date FROM user_cycles WHERE uid = $1 ORDER BY period_start_date ASC';
        const result = await pool.query(query, [uid]);
        return result.rows;
    }

    // Update the cycle length for a cycle
    static async updateCycleLength(id, length) {
        await pool.query('UPDATE user_cycles SET cycle_length = $1 WHERE id = $2', [length, id]);
    }

    // Recalculate the cycle length for all cycles of a user from period_start_date
    static async recalculateCycleLengthsForUser(uid) {
        const result = await pool.query(
            `SELECT id, period_start_date FROM user_cycles 
             WHERE uid = $1 AND (menses_length IS NOT NULL AND menses_length > 0) 
             ORDER BY period_start_date ASC`,
            [uid]
        );
        const rows = result.rows;
        if (rows.length === 0) return { updated: 0 };
        await Cycle.updateCycleLength(rows[0].id, null);
        for (let i = 1; i < rows.length; i++) {
            const prevStart = new Date(rows[i - 1].period_start_date);
            const newStart = new Date(rows[i].period_start_date);
            const days = Math.round((newStart - prevStart) / (1000 * 60 * 60 * 24));
            await Cycle.updateCycleLength(rows[i].id, days);
        }
        return { updated: rows.length };
    }

    // Get all user ids that have at least one cycle (for batch recalc)
    static async getAllUserIdsWithCycles() {
        const result = await pool.query('SELECT DISTINCT uid FROM user_cycles ORDER BY uid');
        return result.rows.map(r => r.uid);
    }

    // Update the cycle pattern for a cycle
    static async updateCyclePattern(cid, pattern) {
        const query = 'UPDATE user_cycles SET cycle_length = $1 WHERE id = $2 RETURNING *';
        const result = await pool.query(query, [pattern, cid]);
        return result.rows[0];
    }
}

module.exports = Cycle;