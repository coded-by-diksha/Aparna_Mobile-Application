require('dotenv').config();
const { initializeFirebase } = require('../config/firebase');
const FCMService = require('../utils/fcmService');

// Initialize Firebase
initializeFirebase();

// IMPORTANT: Replace this with an actual FCM token from your Flutter app
const TEST_FCM_TOKEN = 'PASTE_YOUR_FCM_TOKEN_HERE';

async function testNotifications() {
    console.log('\n🧪 Testing FCM Notifications...\n');

    // Test 1: Simple notification
    console.log('Test 1: Sending simple notification...');
    const result1 = await FCMService.sendCustomNotification(
        TEST_FCM_TOKEN,
        'Test Notification',
        'This is a test notification from the backend'
    );
    console.log('Result:', result1);
    console.log('---\n');

    // Wait a bit between notifications
    await sleep(2000);

    // Test 2: Period reminder
    console.log('Test 2: Sending period reminder...');
    const result2 = await FCMService.sendPeriodReminder(TEST_FCM_TOKEN, 2);
    console.log('Result:', result2);
    console.log('---\n');

    await sleep(2000);

    // Test 3: Health tip
    console.log('Test 3: Sending health tip...');
    const result3 = await FCMService.sendHealthTip(
        TEST_FCM_TOKEN,
        'Stay hydrated and get enough sleep during your cycle!'
    );
    console.log('Result:', result3);
    console.log('---\n');

    await sleep(2000);

    // Test 4: Ovulation reminder
    console.log('Test 4: Sending ovulation reminder...');
    const result4 = await FCMService.sendOvulationReminder(TEST_FCM_TOKEN);
    console.log('Result:', result4);
    console.log('---\n');

    await sleep(2000);

    // Test 5: Symptom tracking reminder
    console.log('Test 5: Sending symptom tracking reminder...');
    const result5 = await FCMService.sendSymptomTrackingReminder(TEST_FCM_TOKEN);
    console.log('Result:', result5);
    console.log('---\n');

    console.log('✅ All tests completed!\n');
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Run tests
if (TEST_FCM_TOKEN === 'PASTE_YOUR_FCM_TOKEN_HERE') {
    console.error('\n❌ ERROR: Please replace TEST_FCM_TOKEN with an actual FCM token from your Flutter app');
    console.log('\nTo get the FCM token:');
    console.log('1. Run your Flutter app');
    console.log('2. Check the console output for "FCM Token: ..."');
    console.log('3. Copy the token and paste it in this file\n');
    process.exit(1);
} else {
    testNotifications()
        .then(() => {
            console.log('Tests finished successfully');
            process.exit(0);
        })
        .catch(error => {
            console.error('Test failed:', error);
            process.exit(1);
        });
}
