const healthModel = require('../model/health');

function resolveRequestedUserId(req) {
    return req.params.userId || req.body.userId || req.body.userid || null;
}

function resolveAuthorizedUserId(req) {
    const requestedUserId = resolveRequestedUserId(req);
    const tokenUserId = req.user?.uid != null ? String(req.user.uid) : null;
    const tokenRole = req.user?.role;

    // Admin can access requested userId; fallback to token uid if not provided.
    if (tokenRole === 'admin') {
        return requestedUserId || tokenUserId;
    }

    // Non-admin can only access their own health data.
    if (requestedUserId && tokenUserId && String(requestedUserId) !== tokenUserId) {
        return null;
    }

    return tokenUserId || requestedUserId;
}

// Helper to transform DB response to API response format
function transformHealthData(dbRow) {
    if (!dbRow) return null;
    
    let healthDataHistory = dbRow.health_data_history;
    
    // Parse health_data_history JSON if it's a string
    if (typeof healthDataHistory === 'string') {
        try {
            healthDataHistory = JSON.parse(healthDataHistory);
        } catch (e) {
            console.error('❌ Error parsing health_data_history:', e);
            healthDataHistory = {};
        }
    }
    
    console.log('📊 Raw DB row:', {
        user_id: dbRow.user_id,
        sleep_hours: healthDataHistory.sleep_hours,
        steps: healthDataHistory.steps,
        calories: healthDataHistory.calories,
        water_intake: healthDataHistory.water_intake
    });
    
    // Return in format expected by Flutter app (camelCase)
    const response = {
        userId: dbRow.user_id,
        heartRate: dbRow.heart_rate,
        activityIntensity: dbRow.activity_intensity,
        healthDataHistory: healthDataHistory,
        activityRecognition: dbRow.activity_recognition,
        location: dbRow.location,
        deviceName: dbRow.device_name,
        deviceType: dbRow.device_type,
        deviceToken: dbRow.device_token,
        updatedAt: dbRow.updated_at,
        // Also include snake_case for backwards compatibility
        health_data_history: healthDataHistory,
        device_name: dbRow.device_name,
        device_type: dbRow.device_type,
        device_token: dbRow.device_token
    };
    
    console.log('✅ API Response about to send:', JSON.stringify(response));
    return response;
}

module.exports = {
    async recordHealthData(req, res) {
        try {
            console.log('📝 recordHealthData called');
            console.log('req.body:', req.body);
            
            // Get userId from JWT token (more secure) or fallback to request body
            const userId = req.user?.uid || req.body.userId || req.body.userid;
            
            console.log('userId:', userId);
            
            if (!userId) {
                return res.status(400).json({ error: 'User ID is required' });
            }

            const { heartRate, activityIntensity, healthDataHistory, activityRecognition, location, deviceName, deviceType, deviceToken } = req.body;
            console.log('📥 healthDataHistory received:', healthDataHistory);
            
            const healthData = await healthModel.recordHealthData(userId, heartRate, activityIntensity, healthDataHistory, activityRecognition, location, deviceName, deviceType, deviceToken);
            const transformedData = transformHealthData(healthData);
            
            console.log('✅ Health data recorded and transformed:', transformedData);
            res.status(200).json(transformedData);
        } catch (error) {
            console.error('❌ Error recording health data:', error.message);
            console.error('Stack:', error.stack);
            res.status(500).json({ error: 'Internal server error', details: error.message });
        }
    },
    async getHealthData(req, res) {
        try {
            const userId = resolveAuthorizedUserId(req);
            if (!userId) {
                return res.status(403).json({ error: 'Forbidden: cannot access requested health data' });
            }
            
            console.log(' Fetching health data for userId:', userId, '| token uid:', req.user?.uid, '| role:', req.user?.role);
            const healthData = await healthModel.getHealthData(userId);
            
            if (!healthData) {
                console.log(' No health data found for userId:', userId);
                return res.status(200).json(null);
            }
            
            const transformedData = transformHealthData(healthData);
            console.log('Health data retrieved and transformed:', transformedData);
            
            res.status(200).json(transformedData);
        } catch (error) {
            console.error('Error getting health data:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
    async updateHealthData(req, res) {
        try {
            const userId = resolveAuthorizedUserId(req);
            
            if (!userId) {
                return res.status(403).json({ error: 'Forbidden: cannot update requested health data' });
            }

            const { heartRate, activityIntensity, healthDataHistory, activityRecognition, location, deviceName, deviceType, deviceToken } = req.body;
            console.log('Updating health data for userId:', userId);
            console.log('healthDataHistory received:', healthDataHistory);
            
            const healthData = await healthModel.updateHealthData(userId, heartRate, activityIntensity, healthDataHistory, activityRecognition, location, deviceName, deviceType, deviceToken);
            const transformedData = transformHealthData(healthData);
            
            console.log('Health data updated and transformed:', transformedData);
            res.status(200).json(transformedData);
        } catch (error) {
            console.error('Error updating health data:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
    async deleteHealthData(req, res) {
        try {
            const { userId } = req.params;
            console.log('Deleting health data for userId:', userId);
            
            const healthData = await healthModel.deleteHealthData(userId);
            const transformedData = transformHealthData(healthData);
            
            console.log('Health data deleted');
            res.status(200).json(transformedData);
        } catch (error) {
            console.error('Error deleting health data:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
    async insertTestSleepData(req, res) {
        try {
            const { userId } = req.params;
            const { sleepHours = 7.5, steps = 0, calories = 0, distance = 0, waterIntake = 0 } = req.body;
            
            console.log('TEST ENDPOINT: Inserting test sleep data for userId:', userId);
            console.log('Test data:', { sleepHours, steps, calories, distance, waterIntake });
            
            if (!userId) {
                return res.status(400).json({ error: 'User ID is required' });
            }

            // Get existing health data or use defaults
            const existingData = await healthModel.getHealthData(userId);
            
            const testHistoryData = {
                steps: steps || (existingData?.health_data_history?.steps || 0),
                calories: calories || (existingData?.health_data_history?.calories || 0),
                distance: distance || (existingData?.health_data_history?.distance || 0),
                sleep_hours: sleepHours,
                water_intake: waterIntake || (existingData?.health_data_history?.water_intake || 0)
            };
            
            console.log('🧪 Test health_data_history:', testHistoryData);
            
            // If no existing data, create new record
            if (!existingData) {
                const newData = await healthModel.recordHealthData(
                    userId,
                    existingData?.heart_rate || 0,
                    existingData?.activity_intensity || 'Low',
                    testHistoryData,
                    existingData?.activity_recognition || '',
                    existingData?.location || 'Test Location',
                    existingData?.device_name || 'Test Device',
                    existingData?.device_type || 'Test',
                    existingData?.device_token || ''
                );
                const transformedData = transformHealthData(newData);
                console.log('✅ Test sleep data created:', transformedData);
                return res.status(200).json({ message: 'Test sleep data created', data: transformedData });
            }
            
            // Update existing record with test sleep data
            const updatedData = await healthModel.updateHealthData(
                userId,
                existingData.heart_rate,
                existingData.activity_intensity,
                testHistoryData,
                existingData.activity_recognition,
                existingData.location,
                existingData.device_name,
                existingData.device_type,
                existingData.device_token
            );
            
            const transformedData = transformHealthData(updatedData);
            console.log('✅ Test sleep data updated:', transformedData);
            res.status(200).json({ message: 'Test sleep data inserted', data: transformedData });
            
        } catch (error) {
            console.error('❌ Error inserting test sleep data:', error);
            res.status(500).json({ error: 'Internal server error', details: error.message });
        }
    }
};