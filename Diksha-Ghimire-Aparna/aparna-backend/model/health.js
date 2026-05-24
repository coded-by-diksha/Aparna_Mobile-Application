const pool = require('../config/database');


class Health {
    // Convert activity intensity string to integer
    // low = 1, moderate = 2, high = 3
    static _convertActivityIntensity(intensity) {
        if (typeof intensity === 'number') return intensity;
        if (typeof intensity === 'string') {
            const lower = intensity.toLowerCase();
            if (lower === 'low') return 1;
            if (lower === 'moderate') return 2;
            if (lower === 'high') return 3;
            // Default to moderate if unknown
            return 2;
        }
        return 2; // Default
    }

    // Convert healthDataHistory object to JSON string if needed
    static _prepareHealthDataHistory(history) {
        if (!history) {
            return JSON.stringify({
                steps: 0,
                calories: 0,
                distance: 0,
                sleep_hours: 0,
                water_intake: 0
            });
        }
        
        if (typeof history === 'string') {
            try {
                // Ensure it's valid JSON
                JSON.parse(history);
                return history;
            } catch (e) {
                console.error('Invalid JSON string for health_data_history:', e);
                return JSON.stringify({
                    steps: 0,
                    calories: 0,
                    distance: 0,
                    sleep_hours: 0,
                    water_intake: 0
                });
            }
        }
        
        if (typeof history === 'object') {
            // Ensure all expected fields are present
            const normalized = {
                steps: parseInt(history.steps) || 0,
                calories: parseInt(history.calories) || 0,
                distance: parseFloat(history.distance) || 0,
                sleep_hours: parseFloat(history.sleep_hours) || 0,
                water_intake: parseInt(history.water_intake) || 0,
                ...history // Preserve any additional fields
            };
            return JSON.stringify(normalized);
        }
        
        // Return default JSON object as fallback
        return JSON.stringify({
            steps: 0,
            calories: 0,
            distance: 0,
            sleep_hours: 0,
            water_intake: 0
        });
    }
 
    static async recordHealthData(userId, heartRate, activityIntensity, healthDataHistory, activityRecognition, location, deviceName, deviceType, deviceToken) {
        const query = 'INSERT INTO health(user_id, heart_rate, activity_intensity, health_data_history, activity_recognition, location, device_name, device_type, device_token, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW()) RETURNING *';
        const values = [
            userId, 
            heartRate, 
            this._convertActivityIntensity(activityIntensity), 
            this._prepareHealthDataHistory(healthDataHistory), 
            activityRecognition || '', 
            location || '', 
            deviceName || '', 
            deviceType || '', 
            deviceToken || ''
        ];
        const result = await pool.query(query, values);
        return result.rows[0];
    }

    // Get health data for a user
    static async getHealthData(userId) {
        const query = 'SELECT * FROM health WHERE user_id = $1';
        const values = [userId];
        const result = await pool.query(query, values);
        return result.rows[0];
    }

    // Update health data for a user
    static async updateHealthData(userId, heartRate, activityIntensity, healthDataHistory, activityRecognition, location, deviceName, deviceType, deviceToken) {
        const query = 'UPDATE health SET heart_rate = $1, activity_intensity = $2, health_data_history = $3, activity_recognition = $4, location = $5, device_name = $6, device_type = $7, device_token = $8, updated_at = NOW() WHERE user_id = $9 RETURNING *';
        const values = [
            heartRate, 
            this._convertActivityIntensity(activityIntensity), 
            this._prepareHealthDataHistory(healthDataHistory), 
            activityRecognition || '', 
            location || '', 
            deviceName || '', 
            deviceType || '', 
            deviceToken || '',
            userId
        ];
        const result = await pool.query(query, values);
        return result.rows[0];
    }

    // Delete health data for a user
    static async deleteHealthData(userId) {
        const query = 'DELETE FROM health WHERE user_id = $1 RETURNING *';
        const values = [userId];
        const result = await pool.query(query, values);
        return result.rows[0];
    }

    // Get all health data
    static async getAllHealthData() {
        const query = 'SELECT * FROM health RETURNING *';
        const result = await pool.query(query);
        return result.rows;
    }
    
    // Get health data by id
    static async getHealthDataById(id) {
        const query = 'SELECT * FROM health WHERE id = $1 RETURNING *';
        const values = [id];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    // Get health data by user id
    static async getHealthDataByUserId(userId) {
        const query = 'SELECT * FROM health WHERE user_id = $1 RETURNING *';
        const values = [userId];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    // Get health data by device name
    static async getHealthDataByDeviceName(deviceName) {
        const query = 'SELECT * FROM health WHERE device_name = $1 RETURNING *';
        const values = [deviceName];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    // Get health data by device type
    static async getHealthDataByDeviceType(deviceType) {
        const query = 'SELECT * FROM health WHERE device_type = $1 RETURNING *';
        const values = [deviceType];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    // Get health data by device token
    static async getHealthDataByDeviceToken(deviceToken) {
        const query = 'SELECT * FROM health WHERE device_token = $1 RETURNING *';
        const values = [deviceToken];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    // Get health data by activity recognition
    static async getHealthDataByActivityRecognition(activityRecognition) {
        const query = 'SELECT * FROM health WHERE activity_recognition = $1 RETURNING *';
        const values = [activityRecognition];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    // Get health data by location
    static async getHealthDataByLocation(location) {
        const query = 'SELECT * FROM health WHERE location = $1 RETURNING *';
        const values = [location];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    // Get health data by device name
    static async getHealthDataByDeviceName(deviceName) {
        const query = 'SELECT * FROM health WHERE device_name = $1 RETURNING *  ';
        const values = [deviceName];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
    // Get health data by device type
    static async getHealthDataByDeviceType(deviceType) {
        const query = 'SELECT * FROM health WHERE device_type = $1 RETURNING *';
        const values = [deviceType];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
    
   
    
    // Get health data by activity recognition
    static async getHealthDataByActivityRecognition(activityRecognition) {
        const query = 'SELECT * FROM health WHERE activity_recognition = $1 RETURNING *';
        const values = [activityRecognition];
        const result = await pool.query(query, values);
        return result.rows[0];
    }
}   


module.exports = Health;