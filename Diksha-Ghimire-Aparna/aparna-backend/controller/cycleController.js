const pool = require('../config/database');
const Cycle = require('../model/Cycle');
const User = require('../model/User');
const CyclePredictor = require('../utils/cycle_predictor');

class CycleController {

    // --- Legacy-style cycle endpoints (user_cycles only) ---

    static async startCycle(req, res) {
        const uid = req.body.uid != null ? req.body.uid : req.user?.uid;
        const { startdate } = req.body;
        if (!startdate) {
            return res.status(400).json({ error: 'startdate is required' });
        }
        try {
            const record = await Cycle.recordPeriod(uid, {
                period_start_date: startdate,
                menses_length: 1,
                notes: null,
                mood_score: null,
                emotions: null,
                flow_level: null
            });
            await CycleController.recalculateCycleLengths(uid);
            res.status(201).json(record);
        } catch (error) {
            console.error('Error starting cycle:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async getCyclesByUser(req, res) {
        const uid = req.params.uid || req.user?.uid;
        try {
            const cycles = await Cycle.getHistory(uid);
            res.status(200).json(cycles);
        } catch (error) {
            console.error('Error fetching cycles by user:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async getStartDate(req, res) {
        const { cid } = req.params;
        try {
            const row = await pool.query('SELECT period_start_date as startdate FROM user_cycles WHERE id = $1', [cid]);
            res.status(200).json(row.rows[0] || {});
        } catch (error) {
            console.error('Error fetching start date:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async setEndDate(req, res) {
        const { cid, startdate, enddate } = req.body;
        try {
            const diff = enddate && startdate
                ? Math.ceil((new Date(enddate) - new Date(startdate)) / (1000 * 60 * 60 * 24))
                : null;
            await pool.query('UPDATE user_cycles SET cycle_length = $1 WHERE id = $2', [diff, cid]);
            const row = await pool.query('SELECT * FROM user_cycles WHERE id = $1', [cid]);
            res.status(200).json({ updatedCycle: row.rows[0], updatedLength: diff });
        } catch (error) {
            console.error('Error ending cycle:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async getEndDate(req, res) {
        const { cid } = req.params;
        try {
            const row = await pool.query('SELECT cycle_length FROM user_cycles WHERE id = $1', [cid]);
            res.status(200).json(row.rows[0] ? { EndDate: row.rows[0].cycle_length } : {});
        } catch (error) {
            console.error('Error fetching end date:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async getPatterns(req, res) {
        const { cid } = req.params;
        try {
            const row = await pool.query('SELECT cycle_length as pattern FROM user_cycles WHERE id = $1', [cid]);
            res.status(200).json(row.rows);
        } catch (error) {
            console.error('Error fetching patterns:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async deleteCycle(req, res) {
        const { cid } = req.params;
        const uid = req.user?.uid;
        try {
            const deleted = await Cycle.deletePeriod(cid, uid);
            if (!deleted) {
                return res.status(404).json({ message: 'Cycle not found' });
            }
            await CycleController.recalculateCycleLengths(uid);
            res.status(200).json({ message: 'Cycle deleted successfully' });
        } catch (error) {
            console.error('Error deleting cycle:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    // --- Main cycle API (record, history, prediction, delete period) ---
    static async recalculateCycleLengths(uid) {
        const cycles = await Cycle.getCycleDates(uid);

        for (let i = 1; i < cycles.length; i++) {
            const prevStart = new Date(cycles[i - 1].period_start_date);
            const currentStart = new Date(cycles[i].period_start_date);
            const diffTime = Math.abs(currentStart - prevStart);
            const length = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

            await Cycle.updateCycleLength(cycles[i].id, length);
        }

        if (cycles.length > 0) {
            await Cycle.updateCycleLength(cycles[0].id, null);
        }
    }

    static async recordPeriod(req, res) {
        const uid = req.user.uid;
        if (!req.body.period_start_date) {
            return res.status(400).json({ error: 'period_start_date is required' });
        }

        try {
            const record = await Cycle.recordPeriod(uid, req.body);
            await CycleController.recalculateCycleLengths(uid);
            
            // Clear any pending prediction adjustments since a new period was logged
            console.log(`[recordPeriod] Clearing prediction shifts for uid ${uid}`);
            await pool.query(
                'DELETE FROM daily_logs WHERE uid = $1 AND feeling = \'PREDICTION_SHIFT\'',
                [uid]
            );
            
            res.status(201).json(record);
        } catch (error) {
            console.error('Error recording period:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async addDailyLog(req, res) {
        const uid = req.user.uid;
        if (!req.body.log_date || !req.body.feeling) {
            return res.status(400).json({ error: 'log_date and feeling are required' });
        }

        try {
            const log = await Cycle.addDailyLog(uid, req.body);
            res.status(201).json(log);
        } catch (error) {
            console.error('Error adding daily log:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async getHistory(req, res) {
        const uid = req.user.uid;
        try {
            await Cycle.recalculateCycleLengthsForUser(uid);
            const history = await Cycle.getHistory(uid);
            res.status(200).json(history);
        } catch (error) {
            console.error('Error fetching history:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async getPrediction(req, res) {
        const uid = req.user.uid;
        try {
            const cycles = await Cycle.getRecentCycles(uid, 6);
            const profile = await User.getUserByID(uid);

            const age = profile && profile.dateofbirth
                ? new Date().getFullYear() - new Date(profile.dateofbirth).getFullYear()
                : 25;

            const prediction = CyclePredictor.predictNext(cycles, { age });
            const analysis = CyclePredictor.getAnalysis(cycles);

            // Check if there's a pending prediction adjustment
            if (prediction && prediction.predictedDates && prediction.predictedDates.length > 0) {
                const adjustmentQuery = `
                    SELECT flow_level FROM daily_logs 
                    WHERE uid = $1 AND feeling = 'PREDICTION_SHIFT'
                    ORDER BY log_date DESC LIMIT 1
                `;
                const adjustmentResult = await pool.query(adjustmentQuery, [uid]);
                
                if (adjustmentResult.rows.length > 0) {
                    const shiftedDate = adjustmentResult.rows[0].flow_level;
                    const parsedShiftedDate = new Date(shiftedDate);
                    const today = new Date();
                    today.setHours(0, 0, 0, 0);
                    const tomorrow = new Date(today);
                    tomorrow.setDate(tomorrow.getDate() + 1);

                    let effectiveDate = shiftedDate;
                    if (!Number.isNaN(parsedShiftedDate.getTime()) && parsedShiftedDate > tomorrow) {
                        effectiveDate = tomorrow.toISOString().split('T')[0];
                    }

                    console.log(`[getPrediction] Using shifted date: ${effectiveDate}`);
                    prediction.predictedDates[0].date = effectiveDate;
                    prediction.status = 'pending_verification';
                }
            }

            // If first predicted date is today or in the past, move prediction window forward.
            if (prediction && Array.isArray(prediction.predictedDates) && prediction.predictedDates.length > 0) {
                const today = new Date();
                today.setHours(0, 0, 0, 0);

                const originalFirst = new Date(prediction.predictedDates[0].date);
                if (!Number.isNaN(originalFirst.getTime())) {
                    originalFirst.setHours(0, 0, 0, 0);

                    if (originalFirst <= today) {
                        const targetFirst = new Date(today);
                        targetFirst.setDate(targetFirst.getDate() + 1);

                        const msPerDay = 1000 * 60 * 60 * 24;
                        const shiftDays = Math.round((targetFirst - originalFirst) / msPerDay);

                        prediction.predictedDates = prediction.predictedDates.map((entry) => {
                            const d = new Date(entry.date);
                            if (Number.isNaN(d.getTime())) return entry;
                            d.setDate(d.getDate() + shiftDays);
                            return {
                                ...entry,
                                date: d.toISOString().split('T')[0]
                            };
                        });

                        prediction.status = 'pending_verification';
                    }
                }
            }

            res.status(200).json({
                ...prediction,
                analysis: analysis
            });
        } catch (error) {
            console.error('Error getting prediction:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async deletePeriod(req, res) {
        const { id } = req.params;
        const uid = req.user.uid;

        try {
            const record = await Cycle.deletePeriod(id, uid);
            if (!record) {
                return res.status(404).json({ error: 'Record not found or unauthorized' });
            }
            await CycleController.recalculateCycleLengths(uid);
            res.status(200).json({ message: 'Record deleted successfully' });
        } catch (error) {
            console.error('Error deleting period:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async adjustPrediction(req, res) {
        const uid = req.user.uid;
        const { predictedDate, dayShift = 1 } = req.body;

        if (!predictedDate) {
            return res.status(400).json({ error: 'predictedDate is required' });
        }

        try {
            // Ensure minimum 1 day shift
            const shift = Math.max(1, dayShift);
            console.log(`📋 [adjustPrediction] Period didn't come on ${predictedDate}, shifting by ${shift} day(s)`);

            // Parse the predicted date
            const predicted = new Date(predictedDate);
            if (isNaN(predicted.getTime())) {
                return res.status(400).json({ error: 'Invalid predictedDate format' });
            }

            // Shift the date by the specified days (minimum 1)
            const newDate = new Date(predicted);
            newDate.setDate(newDate.getDate() + shift);
            const newDateStr = newDate.toISOString().split('T')[0];

            console.log(`✅ [adjustPrediction] New shifted date: ${newDateStr}`);

            // Store the shifted prediction in daily_logs with special marker
            // This allows getPrediction to return the shifted date instead of recalculating
            const today = new Date().toISOString().split('T')[0];
            const query = `
                INSERT INTO daily_logs (uid, log_date, feeling, mood_score, flow_level)
                VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT(uid, log_date) DO UPDATE SET feeling = EXCLUDED.feeling, flow_level = EXCLUDED.flow_level
                RETURNING *
            `;
            await pool.query(query, [
                uid,
                today,
                'PREDICTION_SHIFT',  // Marker for prediction adjustment tracking
                3,                    // neutral mood
                newDateStr            // Store the shifted date in flow_level field
            ]);

            res.status(200).json({
                message: 'Prediction shifted by 1 day',
                adjustedDate: newDateStr,
                note: `Predicted date shifted from ${predictedDate} to ${newDateStr}. User will log period once it starts.`,
                predictedDates: [{ date: newDateStr }]
            });
        } catch (error) {
            console.error('Error adjusting prediction:', error);
            res.status(500).json({ error: 'Internal server error', details: error.message });
        }
    }
}

// Ensure database column exists

module.exports = CycleController;
