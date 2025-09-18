const axios = require('axios');

async function testUpdateLiveActivity() {
  try {
    console.log('Testing updateLiveActivity function...\n');
    
    // Test 1: Call with missing parameters (should fail)
    console.log('Test 1: Calling with empty data (should fail)...');
    try {
      const response1 = await axios.post(
        'https://us-central1-growth-70a85.cloudfunctions.net/updateLiveActivity',
        {
          data: {}
        },
        {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('❌ Test 1 should have failed but succeeded');
    } catch (error) {
      console.log('✅ Test 1 correctly failed:', error.response?.data?.error?.message || error.message);
    }
    
    console.log('\n---\n');
    
    // Test 2: Call with all required parameters (mock data)
    console.log('Test 2: Calling with all required parameters (mock data)...');
    try {
      const response2 = await axios.post(
        'https://us-central1-growth-70a85.cloudfunctions.net/updateLiveActivity',
        {
          data: {
            pushToken: 'test-push-token-12345',
            activityId: 'test-activity-id-12345',
            contentState: {
              isActive: true,
              isPaused: false,
              isCompleted: false,
              startTime: new Date().toISOString(),
              totalDuration: 3600,
              elapsedTime: 0,
              lastUpdated: new Date().toISOString()
            }
          }
        },
        {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('Response:', JSON.stringify(response2.data, null, 2));
    } catch (error) {
      console.log('Error:', error.response?.data || error.message);
    }
    
    console.log('\n---\n');
    
    // Test 3: Call without pushToken (should look it up)
    console.log('Test 3: Calling without pushToken (should attempt lookup)...');
    try {
      const response3 = await axios.post(
        'https://us-central1-growth-70a85.cloudfunctions.net/updateLiveActivity',
        {
          data: {
            // No pushToken provided - function should look it up
            activityId: 'test-activity-id-12345',
            contentState: {
              isActive: true,
              isPaused: false,
              isCompleted: false,
              startTime: new Date().toISOString(),
              totalDuration: 3600,
              elapsedTime: 0,
              lastUpdated: new Date().toISOString()
            }
          }
        },
        {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('Response:', JSON.stringify(response3.data, null, 2));
    } catch (error) {
      console.log('Error:', error.response?.data?.error || error.message);
    }
    
  } catch (error) {
    console.error('Unexpected error:', error);
  }
}

// Run the test
testUpdateLiveActivity();