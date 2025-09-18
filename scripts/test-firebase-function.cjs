#!/usr/bin/env node
/**
 * Test Firebase Function directly
 */

const https = require('https');

// Function URL
const functionUrl = 'https://us-central1-growth-70a85.cloudfunctions.net/updateLiveActivityTimer';

// Test data
const testData = {
    activityId: 'test-activity-123',
    action: 'pause'
};

// You'll need to get a real auth token from Firebase Auth
// For now, this will test if the function responds at all
const options = {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    }
};

const req = https.request(functionUrl, options, (res) => {
    console.log(`Status: ${res.statusCode}`);
    console.log(`Headers: ${JSON.stringify(res.headers)}`);
    
    let data = '';
    res.on('data', (chunk) => {
        data += chunk;
    });
    
    res.on('end', () => {
        console.log('Response:', data);
        try {
            const parsed = JSON.parse(data);
            console.log('Parsed response:', JSON.stringify(parsed, null, 2));
        } catch (e) {
            console.log('Could not parse response as JSON');
        }
    });
});

req.on('error', (error) => {
    console.error('Request error:', error);
});

req.write(JSON.stringify({ data: testData }));
req.end();

console.log('Sending test request to:', functionUrl);
console.log('Test data:', JSON.stringify(testData, null, 2));