/**
 * Firebase Cloud Functions for Live Activity Push Updates
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { logger } = require('firebase-functions');

// Define the secrets - dual-key strategy for dev and prod
const apnsAuthKeyDevSecret = defineSecret('APNS_AUTH_KEY_55LZB28UY2');  // Sandbox key
const apnsAuthKeyProdSecret = defineSecret('APNS_AUTH_KEY_DQ46FN4PQU'); // Production key
const apnsKeyIdSecret = defineSecret('APNS_KEY_ID');
const apnsTeamIdSecret = defineSecret('APNS_TEAM_ID');
const apnsTopicSecret = defineSecret('APNS_TOPIC');

// All initialization happens inside functions to avoid deployment timeouts
let initialized = false;
let modules = {};
let config = {};

async function initialize() {
  if (initialized) return;
  
  try {
    logger.log('🔧 [Initialize] Starting initialization...');
    
    logger.log('🔧 [Initialize] Loading modules...');
    modules.admin = require('firebase-admin');
    modules.http2 = require('http2');
    modules.jwt = require('jsonwebtoken');
    logger.log('✅ [Initialize] Modules loaded.');
    
    logger.log('🔧 [Initialize] Initializing Firebase Admin...');
    if (!modules.admin.apps.length) {
      modules.admin.initializeApp();
      logger.log('✅ [Initialize] Firebase Admin SDK initialized');
    } else {
      logger.log('ℹ️ [Initialize] Firebase Admin SDK already initialized');
    }
    
    // APNs configuration constants
    config.APNS_HOST_PROD = 'api.push.apple.com';  // Production server
    config.APNS_HOST_DEV = 'api.development.push.apple.com';  // Development server
    config.APNS_PORT = 443;
    config.APNS_PATH_PREFIX = '/3/device/';
    
    // Use environment variables from secrets and add logging
    logger.log('🔐 Loading APNs credentials...');
    logger.log('Available env vars:', Object.keys(process.env).filter(k => k.includes('APNS')));
    
    // Load APNs credentials from secrets
    config.apnsKeyId = process.env.APNS_KEY_ID?.trim();
    config.apnsTeamId = process.env.APNS_TEAM_ID?.trim();
    config.apnsTopic = process.env.APNS_TOPIC?.trim();
    
    // Load both dev and prod keys
    const devKey = process.env.APNS_AUTH_KEY_55LZB28UY2;
    const prodKey = process.env.APNS_AUTH_KEY_DQ46FN4PQU;
    
    // For development/sandbox environments, use the 55LZB28UY2 key
    config.apnsKey = devKey;
    config.apnsKeyId = '55LZB28UY2';
    
    // For production environments, use the DQ46FN4PQU key
    config.apnsKeyProd = prodKey || devKey; // Fallback to dev key if prod not available
    config.apnsKeyIdProd = prodKey ? 'DQ46FN4PQU' : '55LZB28UY2';
    
    logger.log('- Dev Key ID:', config.apnsKeyId);
    logger.log('- Prod Key ID:', config.apnsKeyIdProd);
    logger.log('- Dev Key available:', !!devKey);
    logger.log('- Prod Key available:', !!prodKey);
    
    if (!config.apnsKey && !config.apnsKeyProd) {
      logger.error('❌ [Initialize] No APNS auth keys found in environment');
      logger.error('Available env vars:', Object.keys(process.env).filter(k => k.includes('APNS')));
      throw new Error('No APNs auth keys found in environment');
    }
    
    // Validate the auth key format
    if (!config.apnsKey.includes('BEGIN PRIVATE KEY')) {
      logger.error('❌ [Initialize] APNS_AUTH_KEY appears to be invalid format');
      throw new Error('APNs auth key is not in valid PEM format');
    }
    
    // Clean up the auth key
    if (config.apnsKey.startsWith('"') && config.apnsKey.endsWith('"')) {
      config.apnsKey = config.apnsKey.slice(1, -1);
    }
    
    logger.log('✅ [Initialize] Successfully loaded APNs configuration');
    logger.log('- Key ID:', config.apnsKeyId);
    logger.log('- Team ID:', config.apnsTeamId);
    logger.log('- Topic:', config.apnsTopic);
    logger.log('- Key format valid:', config.apnsKey.includes('BEGIN PRIVATE KEY'));
    
    initialized = true;
  } catch (error) {
    logger.error('❌ [Initialize] Failed to initialize:', error.message);
    logger.error('Stack trace:', error.stack);
    throw error;
  }
}

/**
 * Generate JWT token for APNs authentication
 * @param {boolean} useProduction - Whether to use production credentials
 */
async function generateAPNsToken(useProduction = false) {
  await initialize();
  
  // Select appropriate credentials based on environment
  const keyId = useProduction ? config.apnsKeyIdProd : config.apnsKeyId;
  const authKey = useProduction ? config.apnsKeyProd : config.apnsKey;
  const teamId = config.apnsTeamId; // Team ID is same for both environments
  
  if (!authKey || !keyId || !teamId) {
    throw new Error(`APNs not configured properly for ${useProduction ? 'production' : 'development'}`);
  }
  
  try {
    const token = modules.jwt.sign(
      {
        iss: teamId,
        iat: Math.floor(Date.now() / 1000)
      },
      authKey,
      {
        algorithm: 'ES256',
        header: {
          alg: 'ES256',
          kid: keyId
        }
      }
    );
    
    logger.log(`🔑 Generated ${useProduction ? 'PRODUCTION' : 'DEVELOPMENT'} JWT token (first 20 chars):`, token.substring(0, 20) + '...');
    return token;
  } catch (error) {
    logger.error(`Failed to generate APNs JWT token for ${useProduction ? 'production' : 'development'}:`, error);
    throw new Error(`Failed to generate APNs token: ${error.message}`);
  }
}

/**
 * Send push update to Live Activity with intelligent retry logic
 * @param {string} pushToken - The push token for the Live Activity
 * @param {string} activityId - The activity identifier
 * @param {object} contentState - The content state to update
 * @param {Date} dismissalDate - Optional dismissal date
 * @param {string} topicOverride - Optional topic override
 * @param {string} preferredEnvironment - 'development', 'production', or 'auto' (default)
 */
async function sendLiveActivityUpdate(pushToken, activityId, contentState, dismissalDate = null, topicOverride = null, preferredEnvironment = 'auto') {
  await initialize();
  
  // Validate contentState has required fields
  if (!contentState || typeof contentState !== 'object') {
    throw new Error('Invalid contentState: must be an object');
  }
  
  // Check which format we're using
  if (contentState.startedAt) {
    // New format (startedAt/pausedAt pattern) - preferred
    logger.log('🆕 Using new format with startedAt/pausedAt');
    if (typeof contentState.duration !== 'number') {
      logger.error('❌ Invalid contentState - missing or invalid duration:', contentState);
      throw new Error('contentState must have duration field as a number');
    }
  } else if (contentState.startTime && contentState.endTime) {
    // Legacy format - still supported for backward compatibility
    logger.log('🔄 Using legacy format with startTime/endTime');
  } else {
    logger.error('❌ Invalid contentState:', contentState);
    throw new Error('contentState must have either startedAt (new format) or startTime/endTime (legacy format)');
  }
  
  // Convert date strings to ISO format for iOS compatibility
  const convertedContentState = { ...contentState };
  
  // Helper to convert Firestore Timestamp to JavaScript Date
  const convertTimestamp = (timestamp) => {
    if (!timestamp) return null;
    
    if (timestamp.toDate && typeof timestamp.toDate === 'function') {
      return timestamp.toDate();
    }
    
    if (timestamp._seconds !== undefined) {
      return new Date(timestamp._seconds * 1000);
    }
    
    if (timestamp.seconds !== undefined) {
      return new Date(timestamp.seconds * 1000);
    }
    
    if (typeof timestamp === 'string') {
      return new Date(timestamp);
    }
    
    if (timestamp instanceof Date) {
      return timestamp;
    }
    
    return null;
  };
  
  // Helper to convert various date formats to ISO string
  const toISOString = (dateValue) => {
    if (!dateValue) return null;
    
    try {
      // If already a string
      if (typeof dateValue === 'string') {
        // Check if it's already an ISO string
        const isoRegex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z?$/;
        if (isoRegex.test(dateValue)) {
          // Ensure it has Z suffix for UTC
          return dateValue.endsWith('Z') ? dateValue : dateValue + 'Z';
        }
        
        // Try parsing the string
        const date = new Date(dateValue);
        if (!isNaN(date.getTime())) {
          // Validate the date is within reasonable bounds (year 2000 to 2100)
          const year = date.getFullYear();
          if (year >= 2000 && year <= 2100) {
            return date.toISOString();
          }
        }
        logger.error('Invalid date string:', dateValue);
        return null; // Return null instead of current date
      }
      
      // If it's a number (Unix timestamp)
      if (typeof dateValue === 'number') {
        // Validate the number is reasonable
        if (dateValue < 0 || dateValue > 4102444800000) { // Year 2100
          logger.error('Invalid timestamp:', dateValue);
          return null;
        }
        
        // Check if seconds or milliseconds
        const date = dateValue < 10000000000 ? new Date(dateValue * 1000) : new Date(dateValue);
        
        // Validate the resulting date
        if (!isNaN(date.getTime()) && date.getFullYear() >= 2000 && date.getFullYear() <= 2100) {
          return date.toISOString();
        }
        logger.error('Invalid timestamp conversion:', dateValue);
        return null;
      }
      
      // If it's a Date object
      if (dateValue instanceof Date) {
        if (!isNaN(dateValue.getTime()) && dateValue.getFullYear() >= 2000 && dateValue.getFullYear() <= 2100) {
          return dateValue.toISOString();
        }
        logger.error('Invalid Date object:', dateValue);
        return null;
      }
      
      // If it's a Firestore timestamp
      if (dateValue.toDate && typeof dateValue.toDate === 'function') {
        try {
          const date = dateValue.toDate();
          if (!isNaN(date.getTime()) && date.getFullYear() >= 2000 && date.getFullYear() <= 2100) {
            return date.toISOString();
          }
        } catch (e) {
          logger.error('Error converting Firestore timestamp:', e);
        }
        return null;
      }
      
      // If it has _seconds property (Firestore timestamp in JSON)
      if (dateValue._seconds !== undefined) {
        const seconds = Number(dateValue._seconds);
        if (!isNaN(seconds) && seconds > 946684800 && seconds < 4102444800) { // Year 2000 to 2100
          return new Date(seconds * 1000).toISOString();
        }
        logger.error('Invalid Firestore timestamp seconds:', dateValue._seconds);
        return null;
      }
      
      // If it has seconds property (Firestore timestamp)
      if (dateValue.seconds !== undefined) {
        const seconds = Number(dateValue.seconds);
        if (!isNaN(seconds) && seconds > 946684800 && seconds < 4102444800) { // Year 2000 to 2100
          return new Date(seconds * 1000).toISOString();
        }
        logger.error('Invalid timestamp seconds:', dateValue.seconds);
        return null;
      }
      
      // Unknown format
      logger.error('Unknown date format:', dateValue);
      return null;
      
    } catch (error) {
      logger.error('Error converting date:', error, 'Value:', dateValue);
      return null;
    }
  };
  
  // Check if we have the new simplified format
  if (contentState.startedAt !== undefined) {
    logger.log('🆕 Using new simplified Live Activity format');
    
    // ONLY send the exact fields that ContentState expects - nothing more!
    const startedAtISO = toISOString(contentState.startedAt);
    if (!startedAtISO) {
      logger.error('❌ Failed to convert startedAt timestamp, using current time');
      convertedContentState.startedAt = new Date().toISOString();
    } else {
      convertedContentState.startedAt = startedAtISO;
    }
    
    // Only include pausedAt if it exists
    if (contentState.pausedAt) {
      const pausedAtISO = toISOString(contentState.pausedAt);
      if (pausedAtISO) {
        convertedContentState.pausedAt = pausedAtISO;
      }
    }
    
    // Required fields ONLY - match exactly what's in TimerActivityAttributes.ContentState
    convertedContentState.duration = contentState.duration || 300; // Default 5 minutes
    convertedContentState.methodName = contentState.methodName || 'Timer';
    convertedContentState.sessionType = contentState.sessionType || 'countdown';
    
    // NO LEGACY FIELDS - The widget handles all calculations
    // DO NOT add: startTime, endTime, elapsedTimeAtLastUpdate, remainingTimeAtLastUpdate, etc.
    logger.log('📋 Simplified contentState for iOS:', JSON.stringify(convertedContentState, null, 2));
    
    // Return early to prevent any legacy field processing
    const payload = {
      'aps': {
        'timestamp': Math.floor(Date.now() / 1000),
        'event': contentState.event || 'update',
        'content-state': convertedContentState
      }
    };
    
    if (contentState.staleDate) {
      payload.aps['stale-date'] = Math.floor(new Date(contentState.staleDate).getTime() / 1000);
    }
    
    if (contentState.relevanceScore !== undefined) {
      payload.aps['relevance-score'] = contentState.relevanceScore;
    }
    
    if (contentState.alert) {
      payload.aps.alert = contentState.alert;
    }
    
    const payloadString = JSON.stringify(payload);
    
    // Continue with sending logic below...
    // (This will be handled after the else block to avoid duplication)
  } else {
    // Legacy format - convert all timestamps to ISO strings
    logger.log('🔄 Using legacy Live Activity format');
    const startTimeISO = toISOString(contentState.startTime);
    const endTimeISO = toISOString(contentState.endTime);
    
    // Provide defaults if conversion fails
    if (!startTimeISO || !endTimeISO) {
      logger.error('❌ Failed to convert legacy timestamps, using defaults');
      const now = new Date();
      convertedContentState.startTime = startTimeISO || now.toISOString();
      convertedContentState.endTime = endTimeISO || new Date(now.getTime() + 300000).toISOString(); // 5 min default
    } else {
      convertedContentState.startTime = startTimeISO;
      convertedContentState.endTime = endTimeISO;
    }
  }
  
  if (contentState.lastUpdateTime) {
    const lastUpdateISO = toISOString(contentState.lastUpdateTime);
    if (lastUpdateISO) {
      convertedContentState.lastUpdateTime = lastUpdateISO;
    }
  }
  
  if (contentState.lastKnownGoodUpdate) {
    const lastKnownGoodISO = toISOString(contentState.lastKnownGoodUpdate);
    if (lastKnownGoodISO) {
      convertedContentState.lastKnownGoodUpdate = lastKnownGoodISO;
    }
  }
  
  if (contentState.expectedEndTime) {
    const expectedEndISO = toISOString(contentState.expectedEndTime);
    if (expectedEndISO) {
      convertedContentState.expectedEndTime = expectedEndISO;
    }
  }
  
  // Build payload only if we haven't already (for new format)
  let payloadString;
  if (contentState.startedAt !== undefined) {
    // Already built above in the new format section
    payloadString = JSON.stringify(payload);
  } else {
    // Legacy format payload
    logger.log('📋 Converted contentState for iOS (legacy):', JSON.stringify(convertedContentState, null, 2));
    
    const legacyPayload = {
      'aps': {
        'timestamp': Math.floor(Date.now() / 1000),
        'event': 'update',
        'content-state': convertedContentState
      }
    };

    if (dismissalDate) {
      legacyPayload.aps['dismissal-date'] = Math.floor(dismissalDate.getTime() / 1000);
    }

    payloadString = JSON.stringify(legacyPayload);
  }
  
  // Determine environments to try based on preference
  let environmentsToTry = [];
  if (preferredEnvironment === 'development') {
    environmentsToTry = ['development', 'production'];
  } else if (preferredEnvironment === 'production') {
    environmentsToTry = ['production', 'development'];
  } else {
    // Auto mode: try development first (most common during testing)
    environmentsToTry = ['development', 'production'];
  }
  
  let lastError = null;
  
  // Try each environment
  for (const environment of environmentsToTry) {
    const useProduction = environment === 'production';
    const apnsHost = useProduction ? config.APNS_HOST_PROD : config.APNS_HOST_DEV;
    
    logger.log(`📱 Attempting ${environment.toUpperCase()} environment...`);
    logger.log(`  Host: ${apnsHost}`);
    logger.log(`  Key ID: ${useProduction ? config.apnsKeyIdProd : config.apnsKeyId}`);
    
    let token;
    try {
      token = await generateAPNsToken(useProduction);
    } catch (error) {
      logger.error(`❌ Failed to generate ${environment} APNs token:`, error.message);
      lastError = error;
      continue; // Try next environment
    }
    
    try {
      const result = await new Promise((resolve, reject) => {
        let client;
        try {
          client = modules.http2.connect(`https://${apnsHost}:${config.APNS_PORT}`);
        } catch (error) {
          logger.error('❌ Failed to connect to APNs:', error.message);
          reject(new Error(`APNs connection failed: ${error.message}`));
          return;
        }
    
        client.on('error', (err) => {
          logger.error('HTTP/2 client error:', err);
          reject(err);
        });

        const req = client.request({
          ':method': 'POST',
          ':path': `${config.APNS_PATH_PREFIX}${pushToken}`,
          'authorization': `bearer ${token}`,
          'apns-topic': topicOverride || config.apnsTopic,
          'apns-push-type': 'liveactivity',
          'apns-priority': '10',
          'apns-expiration': Math.floor(Date.now() / 1000) + 3600,
          'content-type': 'application/json',
          'content-length': Buffer.byteLength(payloadString)
        });

        let responseBody = '';
        let responseHeaders = {};

        req.on('response', (headers) => {
          responseHeaders = headers;
        });

        req.on('data', (chunk) => {
          responseBody += chunk;
        });

        req.on('end', () => {
          client.close();
          
          const statusCode = responseHeaders[':status'];
          if (statusCode === 200) {
            logger.log(`✅ Live Activity update sent successfully using ${environment} environment`);
            resolve({ 
              success: true, 
              environment: environment,
              response: responseBody 
            });
          } else {
            const errorInfo = {
              statusCode,
              response: responseBody,
              headers: responseHeaders,
              environment: environment
            };
            
            if (statusCode === 400 && responseBody.includes('BadDeviceToken')) {
              logger.error(`❌ BadDeviceToken in ${environment} - Token/server mismatch`);
            } else if (statusCode === 403) {
              logger.error(`❌ 403 Forbidden in ${environment} - Invalid authentication`, errorInfo);
            } else if (statusCode === 410) {
              logger.error(`❌ 410 Gone - Token is no longer valid`);
            }
            
            reject(new Error(`APNs ${environment} error: ${statusCode} - ${responseBody}`));
          }
        });

        req.on('error', (error) => {
          logger.error(`❌ APNs request error in ${environment}:`, error.message);
          client.close();
          reject(new Error(`APNs request failed: ${error.message}`));
        });

        try {
          req.write(payloadString);
          req.end();
        } catch (error) {
          logger.error(`❌ Failed to send APNs request in ${environment}:`, error.message);
          client.close();
          reject(new Error(`Failed to send request: ${error.message}`));
        }
      });
      
      // Success! Return the result
      return result;
      
    } catch (error) {
      logger.log(`❌ ${environment} attempt failed:`, error.message);
      lastError = error;
      
      // Check if we should skip the retry
      if (error.message.includes('403') || error.message.includes('InvalidProviderToken')) {
        logger.log(`⚠️  Skipping retry for 403 error - key issue needs to be resolved`);
        break;
      }
      
      // Continue to next environment
      continue;
    }
  }
  
  // All attempts failed
  throw lastError || new Error('Failed to send push notification to any environment');
}

/**
 * Update Live Activity with new content state format
 */
exports.updateLiveActivity = onCall(
  { 
    region: 'us-central1',
    secrets: [
      apnsAuthKeyDevSecret,
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret
    ],
    consumeAppCheckToken: false  // Disable App Check for Live Activity updates
  },
  async (request) => {
    logger.log('📥 updateLiveActivity called with:', {
      hasAuth: !!request.auth,
      userId: request.auth?.uid,
      activityId: request.data?.activityId,
      hasContentState: !!request.data?.contentState,
      hasPushToken: !!request.data?.pushToken
    });
    
    try {
      await initialize();
    } catch (error) {
      logger.error('❌ Failed to initialize:', error);
      throw new HttpsError('internal', 'Failed to initialize function: ' + error.message);
    }
    
    if (!request.auth) {
      logger.error('❌ No authentication provided');
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { activityId, contentState, pushToken } = request.data;

    if (!activityId || !contentState) {
      logger.error('❌ Missing required parameters:', { activityId, hasContentState: !!contentState });
      throw new HttpsError('invalid-argument', 'activityId and contentState are required');
    }
    
    // Log the received contentState for debugging
    logger.log('📋 Received contentState:', JSON.stringify(contentState, null, 2));
    
    // Check for invalid dates and log warnings
    const checkDate = (dateStr, fieldName) => {
      if (!dateStr) return;
      const date = new Date(dateStr);
      const year = date.getFullYear();
      if (year < 2000 || year > 2100) {
        console.warn(`⚠️ Invalid ${fieldName} detected: ${dateStr} (year: ${year})`);
      }
    };
    
    checkDate(contentState.startTime, 'startTime');
    checkDate(contentState.endTime, 'endTime');
    checkDate(contentState.lastUpdateTime, 'lastUpdateTime');
    checkDate(contentState.lastKnownGoodUpdate, 'lastKnownGoodUpdate');
    checkDate(contentState.expectedEndTime, 'expectedEndTime');

    let finalPushToken = pushToken;  // Define outside try block
    let tokenData = null;

    try {
      
      if (!finalPushToken) {
        const tokenDoc = await modules.admin.firestore()
          .collection('liveActivityTokens')
          .doc(activityId)
          .get();

        if (!tokenDoc.exists) {
          throw new HttpsError('not-found', 'Live Activity token not found');
        }

        tokenData = tokenDoc.data();
        
        if (tokenData.userId !== request.auth.uid) {
          throw new HttpsError('permission-denied', 'Not authorized to update this activity');
        }
        
        finalPushToken = tokenData.pushToken;
      }

      let topicOverride = null;
      // If APNS_TOPIC is set in environment, use it directly
      if (config.apnsTopic && config.apnsTopic.includes('.push-type.liveactivity')) {
        topicOverride = config.apnsTopic;
        logger.log(`📱 Using configured topic: ${topicOverride}`);
      } else if (tokenData?.bundleId) {
        // Otherwise, construct topic from bundle ID
        topicOverride = `${tokenData.bundleId}.push-type.liveactivity`;
        logger.log(`📱 Using dynamic topic: ${topicOverride}`);
      }

      // Determine preferred environment based on token data
      let preferredEnvironment = 'auto';
      if (tokenData?.environment === 'dev' || 
          tokenData?.environment === 'development' ||
          tokenData?.bundleId?.includes('.dev')) {
        preferredEnvironment = 'development';
      } else if (tokenData?.environment === 'prod' || 
                 tokenData?.environment === 'production' ||
                 tokenData?.bundleId === 'com.growthlabs.growthmethod') {
        preferredEnvironment = 'production';
      }
      
      logger.log(`🔧 APNs Environment Detection:
        - Token Environment: ${tokenData?.environment}
        - Bundle ID: ${tokenData?.bundleId}
        - Preferred Environment: ${preferredEnvironment}`);
      
      // The new sendLiveActivityUpdate function handles retries internally
      await sendLiveActivityUpdate(finalPushToken, activityId, contentState, null, topicOverride, preferredEnvironment);

      await modules.admin.firestore()
        .collection('activeTimers')
        .doc(request.auth.uid)
        .set({
          activityId,
          contentState,
          lastUpdate: modules.admin.firestore.FieldValue.serverTimestamp(),
          // Add a flag to trigger state-based updates only
          lastPushUpdate: Date.now()
        }, { merge: true });

      return { success: true, activityId };

    } catch (error) {
      logger.error('❌ [updateLiveActivity] Error:', error.message);
      logger.error('Stack trace:', error.stack);
      logger.error('Error details:', {
        activityId,
        hasContentState: !!contentState,
        hasPushToken: !!finalPushToken,
        errorType: error.constructor.name
      });
      
      if (error.message?.includes('APNs not configured')) {
        throw new HttpsError('failed-precondition', 'APNs configuration error. Please contact support.');
      }
      
      if (error.message?.includes('BadDeviceToken')) {
        throw new HttpsError('invalid-argument', 'Invalid device token. The app may need to be reinstalled.');
      }
      
      if (error.message?.includes('not found')) {
        throw new HttpsError('not-found', `Live Activity token not found for activity: ${activityId}`);
      }
      
      if (error.message?.includes('jwt') || error.message?.includes('JWT')) {
        throw new HttpsError('internal', `JWT generation error: ${error.message}`);
      }
      
      // Include more detail in the error response
      throw new HttpsError('internal', `Live Activity update failed: ${error.message}`);
    }
  }
);

/**
 * Cloud Function to update Live Activity timer state
 */
exports.updateLiveActivityTimer = onCall(
  {
    cors: true,
    region: 'us-central1',
    consumeAppCheckToken: false,
    memory: '256MiB',
    timeoutSeconds: 30,
    secrets: [
      apnsAuthKeyDevSecret,
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret,
    ]
  },
  async (request) => {
    await initialize();
    
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { activityId, action, endTime } = request.data;

    if (!activityId || !action) {
      throw new HttpsError('invalid-argument', 'activityId and action are required');
    }

    try {
      const tokenDoc = await modules.admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .get();

      if (!tokenDoc.exists) {
        throw new HttpsError('not-found', 'Live Activity token not found');
      }

      const tokenData = tokenDoc.data();
      
      if (tokenData.userId !== request.auth.uid) {
        throw new HttpsError('permission-denied', 'Not authorized to update this activity');
      }
      
      let topicOverride = null;
      // If APNS_TOPIC is set in environment, use it directly
      if (config.apnsTopic && config.apnsTopic.includes('.push-type.liveactivity')) {
        topicOverride = config.apnsTopic;
      } else if (tokenData.bundleId) {
        // Otherwise, construct topic from bundle ID
        topicOverride = `${tokenData.bundleId}.push-type.liveactivity`;
      }

      const timerDoc = await modules.admin.firestore()
        .collection('activeTimers')
        .doc(request.auth.uid)
        .get();

      // Default content state - avoid hardcoding 1 hour duration
      let contentState = {
        startTime: new Date().toISOString(),
        endTime: endTime || new Date(Date.now() + 300000).toISOString(), // Default to 5 minutes instead of 1 hour
        methodName: tokenData.methodName || 'Timer',
        sessionType: 'countdown',
        isPaused: false,
        elapsedTimeAtLastUpdate: 0,
        remainingTimeAtLastUpdate: 0
      };

      if (timerDoc.exists) {
        const timerData = timerDoc.data();
        if (timerData.contentState) {
          contentState = {
            ...contentState,
            ...timerData.contentState
          };
          
          // Convert Firestore timestamps to ISO strings
          if (contentState.startTime?.toDate) {
            contentState.startTime = contentState.startTime.toDate().toISOString();
          } else if (contentState.startTime?.seconds) {
            contentState.startTime = new Date(contentState.startTime.seconds * 1000).toISOString();
          } else if (contentState.startTime?._seconds) {
            contentState.startTime = new Date(contentState.startTime._seconds * 1000).toISOString();
          }
          
          if (contentState.endTime?.toDate) {
            contentState.endTime = contentState.endTime.toDate().toISOString();
          } else if (contentState.endTime?.seconds) {
            contentState.endTime = new Date(contentState.endTime.seconds * 1000).toISOString();
          } else if (contentState.endTime?._seconds) {
            contentState.endTime = new Date(contentState.endTime._seconds * 1000).toISOString();
          }
          
          if (contentState.lastUpdateTime?.toDate) {
            contentState.lastUpdateTime = contentState.lastUpdateTime.toDate().toISOString();
          } else if (contentState.lastUpdateTime?.seconds) {
            contentState.lastUpdateTime = new Date(contentState.lastUpdateTime.seconds * 1000).toISOString();
          } else if (contentState.lastUpdateTime?._seconds) {
            contentState.lastUpdateTime = new Date(contentState.lastUpdateTime._seconds * 1000).toISOString();
          }
        }
      }

      // Determine preferred environment based on token data
      let preferredEnvironment = 'auto';
      if (tokenData?.environment === 'dev' || 
          tokenData?.environment === 'development' ||
          tokenData?.bundleId?.includes('.dev')) {
        preferredEnvironment = 'development';
      } else if (tokenData?.environment === 'prod' || 
                 tokenData?.environment === 'production' ||
                 tokenData?.bundleId === 'com.growthlabs.growthmethod') {
        preferredEnvironment = 'production';
      }
      
      switch (action) {
        case 'pause':
          contentState.isPaused = true;
          break;
        case 'resume':
          contentState.isPaused = false;
          break;
        case 'stop':
          await sendLiveActivityUpdate(
            tokenData.pushToken,
            activityId,
            contentState,
            new Date(),
            topicOverride,
            preferredEnvironment
          )
          
          await tokenDoc.ref.delete();
          
          return { success: true, action: 'stopped' };
        default:
          throw new HttpsError('invalid-argument', 'Invalid action');
      }

      await sendLiveActivityUpdate(
        tokenData.pushToken,
        activityId,
        contentState,
        null,
        topicOverride,
        preferredEnvironment
      );

      await modules.admin.firestore()
        .collection('activeTimers')
        .doc(request.auth.uid)
        .set({
          contentState,
          activityId,
          updatedAt: modules.admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

      return { success: true, action, contentState };

    } catch (error) {
      logger.error('❌ [updateLiveActivityTimer] Error:', error.message);
      logger.error('Stack trace:', error.stack);
      logger.error('Error details:', {
        activityId,
        action,
        hasEndTime: !!endTime,
        errorType: error.constructor.name
      });
      
      if (error.message?.includes('APNs not configured')) {
        throw new HttpsError('failed-precondition', 'APNs configuration error. Please contact support.');
      }
      
      if (error.message?.includes('BadDeviceToken')) {
        throw new HttpsError('invalid-argument', 'Invalid device token. The app may need to be reinstalled.');
      }
      
      if (error.message?.includes('not found')) {
        throw new HttpsError('not-found', `Live Activity token not found for activity: ${activityId}`);
      }
      
      if (error.message?.includes('jwt') || error.message?.includes('JWT')) {
        throw new HttpsError('internal', `JWT generation error: ${error.message}`);
      }
      
      // Include more detail in the error response
      throw new HttpsError('internal', `Live Activity update failed: ${error.message}`);
    }
  }
);

/**
 * Test APNs connectivity and configuration
 */
exports.testAPNsConnection = onCall(
  {
    region: 'us-central1',
    secrets: [
      apnsAuthKeyDevSecret,
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret,
    ],
    consumeAppCheckToken: false
  },
  async (request) => {
    logger.log('🧪 testAPNsConnection called');
    
    try {
      await initialize();
      
      // Test JWT generation for both environments
      const results = {
        development: {
          jwt: null,
          connection: null,
          keyId: config.apnsKeyId,
          hasKey: !!config.apnsKey
        },
        production: {
          jwt: null,
          connection: null,
          keyId: config.apnsKeyIdProd,
          hasKey: !!config.apnsKeyProd
        },
        config: {
          teamId: config.apnsTeamId,
          topic: config.apnsTopic
        }
      };
      
      // Test development JWT
      try {
        const devToken = await generateAPNsToken(false);
        results.development.jwt = 'Generated successfully';
      } catch (error) {
        results.development.jwt = `Failed: ${error.message}`;
      }
      
      // Test production JWT (if different key exists)
      if (config.apnsKeyProd !== config.apnsKey) {
        try {
          const prodToken = await generateAPNsToken(true);
          results.production.jwt = 'Generated successfully';
        } catch (error) {
          results.production.jwt = `Failed: ${error.message}`;
        }
      } else {
        results.production.jwt = 'Using same key as development';
      }
      
      // Test development endpoint
      try {
        const devClient = modules.http2.connect(`https://${config.APNS_HOST_DEV}:${config.APNS_PORT}`);
        await new Promise((resolve, reject) => {
          devClient.on('connect', () => {
            logger.log('✅ Connected to development APNs');
            results.development.connection = 'Connected successfully';
            devClient.close();
            resolve();
          });
          devClient.on('error', (err) => {
            logger.error('❌ Development APNs error:', err.message);
            results.development.connection = `Connection failed: ${err.message}`;
            reject(err);
          });
          setTimeout(() => {
            devClient.close();
            reject(new Error('Connection timeout'));
          }, 5000);
        });
      } catch (error) {
        results.development.connection = `Connection failed: ${error.message}`;
      }
      
      // Test production endpoint
      try {
        const prodClient = modules.http2.connect(`https://${config.APNS_HOST_PROD}:${config.APNS_PORT}`);
        await new Promise((resolve, reject) => {
          prodClient.on('connect', () => {
            logger.log('✅ Connected to production APNs');
            results.production.connection = 'Connected successfully';
            prodClient.close();
            resolve();
          });
          prodClient.on('error', (err) => {
            logger.error('❌ Production APNs error:', err.message);
            results.production.connection = `Connection failed: ${err.message}`;
            reject(err);
          });
          setTimeout(() => {
            prodClient.close();
            reject(new Error('Connection timeout'));
          }, 5000);
        });
      } catch (error) {
        results.production.connection = `Connection failed: ${error.message}`;
      }
      
      return {
        success: true,
        results
      };
      
    } catch (error) {
      logger.error('❌ testAPNsConnection error:', error);
      return {
        success: false,
        error: error.message,
        stack: error.stack
      };
    }
  }
);

/**
 * Register Live Activity push token
 */
exports.registerLiveActivityPushToken = onCall(
  {
    region: 'us-central1',
    consumeAppCheckToken: false,
    secrets: [
      apnsAuthKeyDevSecret,
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret
    ]
  },
  async (request) => {
    logger.log('📱 registerLiveActivityPushToken called');
    
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }
    
    const { token, activityId, bundleId, environment } = request.data;
    
    if (!token || !activityId) {
      throw new HttpsError('invalid-argument', 'token and activityId are required');
    }
    
    try {
      await initialize();
      
      // Store token in Firestore for later use
      await modules.admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .set({
          pushToken: token,
          activityId,
          bundleId: bundleId || 'com.growthlabs.growthmethod',
          environment: environment || 'development',
          userId: request.auth.uid,
          createdAt: modules.admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: modules.admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      
      logger.log(`✅ Live Activity token registered for activity: ${activityId}`);
      
      return { success: true, activityId };
    } catch (error) {
      logger.error('❌ Failed to register Live Activity token:', error);
      throw new HttpsError('internal', `Failed to register token: ${error.message}`);
    }
  }
);

/**
 * Register push-to-start token for future Live Activities
 */
exports.registerPushToStartToken = onCall(
  {
    region: 'us-central1',
    consumeAppCheckToken: false,
    secrets: [
      apnsAuthKeyDevSecret,
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret
    ]
  },
  async (request) => {
    logger.log('📱 registerPushToStartToken called');
    
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }
    
    const { token } = request.data;
    
    if (!token) {
      throw new HttpsError('invalid-argument', 'token is required');
    }
    
    try {
      await initialize();
      
      // Store push-to-start token for user
      await modules.admin.firestore()
        .collection('users')
        .doc(request.auth.uid)
        .set({
          liveActivityPushToStartToken: token,
          pushToStartTokenUpdatedAt: modules.admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      
      logger.log(`✅ Push-to-start token registered for user: ${request.auth.uid}`);
      
      return { success: true };
    } catch (error) {
      logger.error('❌ Failed to register push-to-start token:', error);
      throw new HttpsError('internal', `Failed to register token: ${error.message}`);
    }
  }
);

/**
 * Trigger Live Activity updates when timer state changes in Firestore
 */
exports.onTimerStateChange = onDocumentWritten(
  {
    document: 'activeTimers/{userId}',
    region: 'us-central1',
    secrets: [
      apnsAuthKeyDevSecret,
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret,
    ]
  },
  async (event) => {
    await initialize();
    
    const snapshot = event.data;
    if (!snapshot) return;

    const afterData = snapshot.after.exists ? snapshot.after.data() : null;
    const beforeData = snapshot.before.exists ? snapshot.before.data() : null;

    if (!afterData?.activityId) {
      logger.log('No afterData or activityId found');
      return;
    }
    
    if (beforeData && afterData.lastPushUpdate && 
        beforeData.lastPushUpdate !== afterData.lastPushUpdate &&
        beforeData.contentState?.isPaused === afterData.contentState?.isPaused) {
      logger.log('Processing push update trigger');
    } else {
      if (beforeData && 
          beforeData.contentState?.isPaused === afterData.contentState?.isPaused &&
          beforeData.contentState?.endTime?.isEqual?.(afterData.contentState?.endTime)) {
        logger.log('No state change detected, skipping update');
        return;
      }
    }

    const userId = event.params.userId;
    const activityId = afterData.activityId;

    try {
      const tokenDoc = await modules.admin.firestore()
        .collection('liveActivityTokens')
        .doc(activityId)
        .get();

      if (!tokenDoc.exists) {
        logger.log('No Live Activity token found for activity:', activityId);
        return;
      }

      const tokenData = tokenDoc.data();
      
      let topicOverride = null;
      // If APNS_TOPIC is set in environment, use it directly
      if (config.apnsTopic && config.apnsTopic.includes('.push-type.liveactivity')) {
        topicOverride = config.apnsTopic;
      } else if (tokenData.bundleId) {
        // Otherwise, construct topic from bundle ID
        topicOverride = `${tokenData.bundleId}.push-type.liveactivity`;
      }
      
      let contentState = afterData.contentState || {};
      
      // Convert Firestore timestamps to ISO strings
      if (contentState.startTime?.toDate) {
        contentState.startTime = contentState.startTime.toDate().toISOString();
      } else if (contentState.startTime?.seconds) {
        contentState.startTime = new Date(contentState.startTime.seconds * 1000).toISOString();
      } else if (contentState.startTime?._seconds) {
        contentState.startTime = new Date(contentState.startTime._seconds * 1000).toISOString();
      }
      
      if (contentState.endTime?.toDate) {
        contentState.endTime = contentState.endTime.toDate().toISOString();
      } else if (contentState.endTime?.seconds) {
        contentState.endTime = new Date(contentState.endTime.seconds * 1000).toISOString();
      } else if (contentState.endTime?._seconds) {
        contentState.endTime = new Date(contentState.endTime._seconds * 1000).toISOString();
      }
      
      if (contentState.lastUpdateTime?.toDate) {
        contentState.lastUpdateTime = contentState.lastUpdateTime.toDate().toISOString();
      } else if (contentState.lastUpdateTime?.seconds) {
        contentState.lastUpdateTime = new Date(contentState.lastUpdateTime.seconds * 1000).toISOString();
      } else if (contentState.lastUpdateTime?._seconds) {
        contentState.lastUpdateTime = new Date(contentState.lastUpdateTime._seconds * 1000).toISOString();
      }
      
      // CRITICAL: Preserve totalDuration if available to prevent 1-hour default
      if (afterData.totalDuration) {
        contentState.totalDuration = afterData.totalDuration;
        logger.log(`📊 Preserving total duration: ${contentState.totalDuration}s`);
      }
      
      // Determine preferred environment based on token data
      let preferredEnvironment = 'auto';
      if (tokenData?.environment === 'dev' || 
          tokenData?.environment === 'development' ||
          tokenData?.bundleId?.includes('.dev')) {
        preferredEnvironment = 'development';
      } else if (tokenData?.environment === 'prod' || 
                 tokenData?.environment === 'production' ||
                 tokenData?.bundleId === 'com.growthlabs.growthmethod') {
        preferredEnvironment = 'production';
      }
      
      await sendLiveActivityUpdate(
        tokenData.pushToken,
        activityId,
        contentState,
        null,
        topicOverride,
        preferredEnvironment
      );

      logger.log('Successfully updated Live Activity:', activityId);

    } catch (error) {
      logger.error('Error in onTimerStateChange:', error);
    }
  }
);