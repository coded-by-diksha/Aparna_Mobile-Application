const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');
const { RandomForestRegression } = require('ml-random-forest');

const CSV_FILENAME = 'FedCycleData071012.csv';

function resolveDatasetPath() {
    const fromUtils = path.resolve(__dirname, '..', CSV_FILENAME);
    if (fs.existsSync(fromUtils)) return fromUtils;
    const fromCwd = path.resolve(process.cwd(), CSV_FILENAME);
    if (fs.existsSync(fromCwd)) return fromCwd;
    return null;
}

class CyclePredictor {
    constructor() {
        this.model = null;
        this.isTraining = false;
        // Defer training so startup can bind the HTTP port immediately.
        setImmediate(() => {
            this.trainModel().catch(err => {
                console.error('❌ Background model training failed:', err);
            });
        });    }

    async trainModel() {
        if (this.isTraining) return;
        this.isTraining = true;
        console.log(' Training Random Forest model for cycle prediction...');

        try {
            const datasetPath = resolveDatasetPath();
            if (!datasetPath) {
                console.log('ℹ️  No cycle dataset CSV found; using personalized prediction from user history only.');
                this.isTraining = false;
                return;
            }

            const fileContent = fs.readFileSync(datasetPath, 'utf-8');
            const records = parse(fileContent, {
                columns: true,
                skip_empty_lines: true,
                cast: true
            });

            // Feature selection: MeanCycleLength, LengthofMenses, Age, BMI -> Target: LengthofCycle
            const trainingData = [];
            const labels = [];

            records.forEach(r => {
                const cycleLen = parseFloat(r.LengthofCycle);
                const meanCycle = parseFloat(r.MeanCycleLength) || 29.5;
                const mensesLen = parseFloat(r.LengthofMenses) || 5;
                const age = parseFloat(r.Age) || 25;
                const bmi = parseFloat(r.BMI) || 22;

                if (!isNaN(cycleLen) && cycleLen > 15 && cycleLen < 50) {
                    trainingData.push([meanCycle, mensesLen, age, bmi]);
                    labels.push(cycleLen);
                }
            });

            if (trainingData.length > 0) {
                this.model = new RandomForestRegression({
                    nEstimators: 50,
                    maxDepth: 10,
                    seed: 42
                });

                this.model.train(trainingData, labels);
                console.log(`✅ Model trained successfully on ${trainingData.length} samples.`);
            } else {
                console.warn('⚠️ No valid training data found.');
            }
        } catch (error) {
            console.error('❌ Error training model:', error);
        } finally {
            this.isTraining = false;
        }
    }

    predictNext(history, userProfile = {}, count = 3) {
        let predictedCycleLength = 29.5;

        // If user has history, calculate their personal moving average as a feature
        if (history && history.length > 0) {
            const validCycles = history
                .filter(h => h.cycle_length != null)
                .map(h => parseInt(h.cycle_length));

                // Calculate the average cycle length from the user's history
            if (validCycles.length > 0) {
                const sum = validCycles.reduce((a, b) => a + b, 0);
                predictedCycleLength = sum / validCycles.length;
            }
        }

        // If AI model is ready, refine the prediction
        if (this.model) {
            // Get the last cycle length from the user's history
            const lastCycleLen = (history && history.length > 0 && history[0].cycle_length) || predictedCycleLength;
            // Get the average menses length from the user's history
            const avgMenses = (history && history.length > 0 && history[0].menses_length) || 5;
            // Get the age from the user's profile
            const age = userProfile.age || 25;
            // Get the BMI from the user's profile(body mass index)
            const bmi = userProfile.bmi || 22;

            try {
                const aiPrediction = this.model.predict([[lastCycleLen, avgMenses, age, bmi]])[0];
                // Increase weight on personal history (0.8) vs AI (0.2) if user has history
                predictedCycleLength = (predictedCycleLength * 0.8) + (aiPrediction * 0.2);
            } catch (e) {
                console.error('Prediction error:', e);
            }
        }

        // Sanity check: Ensure prediction isn't wildly unrealistic (e.g., < 21 or > 45)
        if (predictedCycleLength < 21) predictedCycleLength = 28;        
        if (predictedCycleLength > 45) predictedCycleLength = 29.5; // Default cycle length if prediction is unrealistic


        // Generate predictions for the next count cycles
        const predictions = [];
        // Get the reference date from the user's history
        let referenceDate = (history && history.length > 0)
            ? new Date(history[0].period_start_date)
            : new Date();

        for (let i = 1; i <= count; i++) {
            // Calculate the next date by adding the predicted cycle length to the reference date
            const nextDate = new Date(referenceDate);
            nextDate.setDate(referenceDate.getDate() + Math.round(predictedCycleLength * i));
            // If this is the first prediction and the date is in the past, set to (today + 1)
            if (i === 1) {
                const today = new Date();
                today.setHours(0,0,0,0);
                if (nextDate < today) {
                    const tomorrow = new Date();
                    tomorrow.setDate(today.getDate() + 1);
                    predictions.push({
                        date: tomorrow.toISOString().split('T')[0],
                        confidence: this.model ? 'high (Smart)' : 'medium',
                        adjusted: true
                    });
                    continue;
                }
            }
            // Add the predicted date to the predictions array
            predictions.push({
                date: nextDate.toISOString().split('T')[0],
                confidence: this.model ? 'high (Smart)' : 'medium'
            });
        }

        // Return the predictions
        return {
            predictedDates: predictions,
            averageCycleLength: Math.round(predictedCycleLength),
            status: this.model ? 'smart_prediction' : 'personalized'
        };
    }

    // Get the analysis of the user's cycle history
    getAnalysis(history) {
        if (!history || history.length === 0) return null;

        // Get the cycle lengths from the user's history
        const cycleLengths = history
            .filter(h => h.cycle_length != null)
            .map(h => parseInt(h.cycle_length));

        const userAvgCycle = cycleLengths.length > 0
            ? cycleLengths.reduce((a, b) => a + b, 0) / cycleLengths.length
            : 29.5;

        return {
            userAverageCycle: Math.round(userAvgCycle * 10) / 10,
            globalAverageCycle: 29.5,
            regularityScore: this.calculateRegularity(cycleLengths)
        };
    }

    // Calculate the regularity of the user's cycle history
    calculateRegularity(lengths) {
        // Get the cycle lengths from the user's history
        const mean = lengths.reduce((a, b) => a + b, 0) / lengths.length;
        const variance = lengths.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / lengths.length;
        const stdDev = Math.sqrt(variance);
        if (stdDev < 2) return 'Very Regular';
        if (stdDev < 4) return 'Regular';
        return 'Irregular';
    }
}

// Export a singleton instance
module.exports = new CyclePredictor();
