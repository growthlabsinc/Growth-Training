/**
 * APNs Helper Functions
 */

const http2 = require('http2');
const jwt = require('jsonwebtoken');

/**
 * Generate JWT token for APNs authentication
 */
async function generateAPNsToken(config, useProduction = false) {
  try {
    // Use the same key for both environments (APNs keys work for both)
    const keyId = config.apnsKeyId;
    const authKey = config.apnsKey;
    
    if (!authKey || !keyId || !config.apnsTeamId) {
      throw new Error('Missing APNs configuration');
    }
    
    const token = jwt.sign(
      {},
      authKey,
      {
        algorithm: 'ES256',
        header: {
          alg: 'ES256',
          kid: keyId
        },
        issuer: config.apnsTeamId,
        expiresIn: '1h'
      }
    );
    
    console.log(`✅ [generateAPNsToken] Generated token for ${useProduction ? 'production' : 'development'} with key ID: ${keyId}`);
    return token;
  } catch (error) {
    console.error('❌ [generateAPNsToken] Failed to generate token:', error);
    throw error;
  }
}

/**
 * Determine if we should use development APNs server based on token/bundle data
 */
function shouldUseDevAPNs(tokenData) {
  // Check for development indicators
  if (tokenData.bundleId && (
    tokenData.bundleId.includes('.dev') ||
    tokenData.bundleId.includes('staging') ||
    tokenData.bundleId === 'com.growthlabs.growthmethod.LiveActivity'
  )) {
    return true;
  }
  
  // Default to development for safety
  return true;
}

/**
 * Get the appropriate APNs host
 */
function getAPNsHost(tokenData, useProduction = false) {
  if (useProduction) {
    return 'api.push.apple.com';
  }
  
  if (shouldUseDevAPNs(tokenData)) {
    return 'api.development.push.apple.com';
  }
  
  return 'api.push.apple.com';
}

/**
 * Send a Live Activity update to APNs
 */
async function sendLiveActivityUpdate(pushToken, activityId, contentState, dismissalDate = null, topicOverride = null, preferredEnvironment = 'auto') {
  console.log('📤 [sendLiveActivityUpdate] Starting update process...');
  
  // Get config from the calling function's scope
  const config = this;
  
  // Determine environments to try based on preference
  let environmentsToTry = [];
  if (preferredEnvironment === 'development') {
    environmentsToTry = ['development'];
  } else if (preferredEnvironment === 'production') {
    environmentsToTry = ['production'];
  } else {
    // Use production for TestFlight and App Store
    environmentsToTry = ['production'];
  }
  
  const tokenData = { 
    bundleId: topicOverride || config.apnsTopic,
    pushToken: pushToken 
  };
  
  // Try each environment until one succeeds
  for (const environment of environmentsToTry) {
    const useProduction = environment === 'production';
    const host = useProduction ? 'api.push.apple.com' : 'api.development.push.apple.com';
    
    console.log(`🔄 [sendLiveActivityUpdate] Trying ${environment} environment (${host})...`);
    
    try {
      const token = await generateAPNsToken(config, useProduction);
      const result = await sendToAPNs(
        config,
        host,
        token,
        pushToken,
        activityId,
        contentState,
        dismissalDate,
        topicOverride || config.apnsTopic
      );
      
      if (result.success) {
        console.log(`✅ [sendLiveActivityUpdate] Success with ${environment} environment`);
        return { 
          ...result, 
          environment,
          host 
        };
      }
      
      // If we get environment-related errors, try the other environment
      if (result.error && (
        result.error.includes('InvalidProviderToken') || 
        result.error.includes('BadDeviceToken') ||
        result.error.includes('BadEnvironmentKeyInToken')
      )) {
        console.log(`⚠️ [sendLiveActivityUpdate] ${result.error} for ${environment}, trying next environment...`);
        continue;
      }
      
      // For other errors, return the failure
      return { 
        ...result, 
        environment,
        host 
      };
      
    } catch (error) {
      console.error(`❌ [sendLiveActivityUpdate] Error with ${environment}:`, error);
      
      // If this is the last environment, return the error
      if (environment === environmentsToTry[environmentsToTry.length - 1]) {
        return {
          success: false,
          error: error.message,
          environment,
          host
        };
      }
    }
  }
  
  // Should not reach here, but just in case
  return {
    success: false,
    error: 'Failed to send update to any environment'
  };
}

/**
 * Internal function to send the actual request to APNs
 */
async function sendToAPNs(config, host, token, pushToken, activityId, contentState, dismissalDate, topic) {
  return new Promise((resolve) => {
    console.log(`🌐 [sendToAPNs] Connecting to ${host}...`);
    
    const client = http2.connect(`https://${host}`, {
      rejectUnauthorized: true,
      ALPNProtocols: ['h2']
    });
    
    client.on('error', (err) => {
      console.error('❌ [sendToAPNs] Connection error:', err);
      client.close();
      resolve({ success: false, error: `Connection error: ${err.message}` });
    });
    
    // Check if topic already contains .push-type.liveactivity to avoid duplication
    const apnsTopic = topic.includes('.push-type.liveactivity') 
      ? topic 
      : `${topic}.push-type.liveactivity`;
    
    console.log(`📱 [sendToAPNs] Using APNS topic: ${apnsTopic}`);
    
    const headers = {
      ':method': 'POST',
      ':path': `/3/device/${pushToken}`,
      ':scheme': 'https',
      'authorization': `bearer ${token}`,
      'apns-push-type': 'liveactivity',
      'apns-topic': apnsTopic,
      'apns-priority': '10',
      'content-type': 'application/json'
    };
    
    // Convert date strings in contentState to Unix timestamps
    const processedContentState = { ...contentState };
    
    // List of fields that should be converted from ISO strings to Unix timestamps
    const dateFields = ['startedAt', 'pausedAt', 'startTime', 'pauseTime', 'endTime'];
    
    for (const field of dateFields) {
      if (processedContentState[field]) {
        // Convert ISO string to Unix timestamp (seconds)
        const date = new Date(processedContentState[field]);
        if (!isNaN(date.getTime())) {
          processedContentState[field] = Math.floor(date.getTime() / 1000);
          console.log(`📅 [sendToAPNs] Converted ${field}: ${contentState[field]} -> ${processedContentState[field]}`);
        }
      }
    }
    
    // Build the payload
    const payload = {
      aps: {
        timestamp: Math.floor(Date.now() / 1000),
        event: 'update',
        'content-state': processedContentState,
        'stale-date': Math.floor((Date.now() + 30 * 60 * 1000) / 1000)
      }
    };
    
    if (dismissalDate) {
      payload.aps['dismissal-date'] = Math.floor(dismissalDate.getTime() / 1000);
    }
    
    const payloadData = JSON.stringify(payload);
    
    console.log('📋 [sendToAPNs] Request details:', {
      host,
      path: `/3/device/${pushToken.substring(0, 10)}...`,
      topic: headers['apns-topic'],
      hasToken: !!token,
      payloadSize: payloadData.length,
      hasDismissalDate: !!dismissalDate
    });
    
    const req = client.request(headers);
    
    req.on('response', (headers) => {
      const status = headers[':status'];
      console.log(`📨 [sendToAPNs] Response status: ${status}`);
      
      let responseData = '';
      
      req.on('data', (chunk) => {
        responseData += chunk;
      });
      
      req.on('end', () => {
        client.close();
        
        if (status === 200) {
          console.log('✅ [sendToAPNs] Update sent successfully');
          resolve({ 
            success: true,
            status,
            apnsId: headers['apns-id'] || null 
          });
        } else {
          console.error(`❌ [sendToAPNs] Failed with status ${status}:`, responseData);
          
          let errorInfo;
          try {
            errorInfo = JSON.parse(responseData);
          } catch (e) {
            errorInfo = { reason: responseData };
          }
          
          resolve({ 
            success: false, 
            status,
            error: errorInfo.reason || 'Unknown error',
            details: errorInfo 
          });
        }
      });
    });
    
    req.on('error', (err) => {
      console.error('❌ [sendToAPNs] Request error:', err);
      client.close();
      resolve({ success: false, error: `Request error: ${err.message}` });
    });
    
    req.write(payloadData);
    req.end();
  });
}

module.exports = {
  generateAPNsToken,
  sendLiveActivityUpdate
};