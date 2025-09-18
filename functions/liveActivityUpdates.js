/**
 * Firebase Cloud Functions for Live Activity Push Updates
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const EnhancedLogger = require('./utils/enhancedLogger');

// Define the secrets - production only
const apnsAuthKeyProdSecret = defineSecret('APNS_AUTH_KEY_DQ46FN4PQU'); // Production key only
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
    
    // APNs configuration constants - production only
    config.APNS_HOST = 'api.push.apple.com';  // Production server only
    config.APNS_PORT = 443;
    config.APNS_PATH_PREFIX = '/3/device/';
    
    // Use environment variables from secrets and add logging
    logger.log('🔐 Loading APNs credentials...');
    logger.log('Available env vars:', Object.keys(process.env).filter(k => k.includes('APNS')));
    
    // Load APNs credentials from secrets
    config.apnsTeamId = process.env.APNS_TEAM_ID?.trim();
    config.apnsTopic = process.env.APNS_TOPIC?.trim();
    
    // Load production key only
    const prodKey = process.env.APNS_AUTH_KEY_DQ46FN4PQU;
    
    // Set production credentials only
    config.apnsKey = prodKey;
    config.apnsKeyId = 'DQ46FN4PQU';
    
    logger.log('- Production Key available:', !!prodKey ? '✅ DQ46FN4PQU' : '❌ Not found');
    logger.log('- Using Key:', config.apnsKeyId);
    
    if (!config.apnsKey) {
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
 * Generate JWT token for APNs authentication - production only
 */
async function generateAPNsToken() {
  await initialize();
  
  // Use production credentials only
  const keyId = config.apnsKeyId || 'DQ46FN4PQU';
  const authKey = config.apnsKey;
  const teamId = config.apnsTeamId; // Team ID
  
  if (!authKey || !keyId || !teamId) {
    throw new Error(`APNs not configured properly - missing ${!authKey ? 'auth key' : !keyId ? 'key ID' : 'team ID'}`);
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
    
    logger.log(`🔑 Generated PRODUCTION JWT token (first 20 chars):`, token.substring(0, 20) + '...');
    return token;
  } catch (error) {
    logger.error(`Failed to generate APNs JWT token:`, error);
    throw new Error(`Failed to generate APNs token: ${error.message}`);
  }
}

/**
 * Determine event type from content state changes
 * @param {Object} contentState - The content state
 * @returns {string} The event type
 */
function determineEventType(contentState) {
  // Check for explicit event field (temporary, for backward compatibility)
  if (contentState.event) {
    return contentState.event;
  }
  
  // Detect event from state changes
  if (contentState.pausedAt && !contentState._wasPaused) {
    return 'pause';
  } else if (!contentState.pausedAt && contentState._wasPaused) {
    return 'resume';
  } else if (contentState.sessionType === 'completed') {
    return 'end';
  }
  
  return 'update';
}

/**
 * Send push update to Live Activity with intelligent retry logic
 * @param {string} pushToken - The push token for the Live Activity
 * @param {string} activityId - The activity identifier
 * @param {object} contentState - The content state to update
 * @param {Date} dismissalDate - Optional dismissal date
 * @param {string} topicOverride - Optional topic override
 * @param {string} preferredEnvironment - deprecated, always uses production
 */
async function sendLiveActivityUpdate(pushToken, activityId, contentState, dismissalDate = null, topicOverride = null, preferredEnvironment = 'auto', frequentPushesEnabled = true) {
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
  
  // Initialize payload variables outside the blocks
  let payload;
  let payloadString;
  
  // Check if we have the new simplified format
  if (contentState.startedAt !== undefined) {
    logger.log('🆕 Using new simplified Live Activity format');
    
    // CRITICAL: ActivityKit push notifications use Apple's reference date (2001-01-01)
    // NOT Unix epoch (1970-01-01). The difference is 978,307,200 seconds.
    const APPLE_REFERENCE_DATE = new Date('2001-01-01T00:00:00Z');
    const SECONDS_BETWEEN_EPOCHS = 978307200; // Seconds between 1970-01-01 and 2001-01-01
    
    const startedAtISO = toISOString(contentState.startedAt);
    if (!startedAtISO) {
      logger.error('❌ Failed to convert startedAt timestamp, using current time');
      // Current time in Apple reference (seconds since 2001-01-01)
      convertedContentState.startedAt = (Date.now() / 1000) - SECONDS_BETWEEN_EPOCHS;
    } else {
      // Convert ISO string to Apple reference timestamp (seconds since 2001-01-01)
      const startedAtDate = new Date(startedAtISO);
      const unixSeconds = startedAtDate.getTime() / 1000;
      convertedContentState.startedAt = unixSeconds - SECONDS_BETWEEN_EPOCHS;
      logger.log(`📅 startedAt: ${startedAtISO} -> ${convertedContentState.startedAt} seconds (Apple ref)`);
    }
    
    // Only include pausedAt if it exists
    if (contentState.pausedAt) {
      const pausedAtISO = toISOString(contentState.pausedAt);
      if (pausedAtISO) {
        // Convert ISO string to Apple reference timestamp (seconds since 2001-01-01)
        const pausedAtDate = new Date(pausedAtISO);
        const unixSeconds = pausedAtDate.getTime() / 1000;
        convertedContentState.pausedAt = unixSeconds - SECONDS_BETWEEN_EPOCHS;
        logger.log(`📅 pausedAt: ${pausedAtISO} -> ${convertedContentState.pausedAt} seconds (Apple ref)`);
      } else {
        // If pausedAt is explicitly null, keep it null
        convertedContentState.pausedAt = null;
      }
    } else {
      // Explicitly set to null if not paused
      convertedContentState.pausedAt = null;
    }
    
    // Required fields ONLY - match exactly what's in TimerActivityAttributes.ContentState
    convertedContentState.duration = contentState.duration || 300; // Default 5 minutes
    convertedContentState.methodName = contentState.methodName || 'Timer';
    convertedContentState.sessionType = contentState.sessionType || 'countdown';
    
    // NO LEGACY FIELDS - The widget handles all calculations
    // DO NOT add: startTime, endTime, elapsedTimeAtLastUpdate, remainingTimeAtLastUpdate, etc.
    // IMPORTANT: Do NOT include event or _wasPaused fields in convertedContentState
    // These fields are for internal event detection only
    delete convertedContentState.event;
    delete convertedContentState._wasPaused;
    
    logger.log('📋 Converted contentState for iOS (Unix timestamps in seconds):', JSON.stringify(convertedContentState, null, 2));
    
    // Return early to prevent any legacy field processing
    // Detect event type from state changes using the shared function
    const eventType = determineEventType(contentState);
    
    // CRITICAL: APNs timestamp field also uses Apple reference date
    const SECONDS_BETWEEN_EPOCHS_PAYLOAD = 978307200;
    payload = {
      'aps': {
        'timestamp': Math.floor(Date.now() / 1000) - SECONDS_BETWEEN_EPOCHS_PAYLOAD,
        'event': eventType,
        'content-state': convertedContentState
      }
    };
    
    // Log the actual payload to verify event is NOT in content-state
    logger.log('📦 APNS Payload structure:', {
      hasEvent: 'event' in payload.aps,
      eventLocation: 'aps.event',
      contentStateFields: Object.keys(convertedContentState),
      eventInContentState: 'event' in convertedContentState
    });
    
    if (contentState.staleDate) {
      // Stale date also uses Apple reference
      const staleDateUnix = Math.floor(new Date(contentState.staleDate).getTime() / 1000);
      payload.aps['stale-date'] = staleDateUnix - SECONDS_BETWEEN_EPOCHS_PAYLOAD;
    }
    
    if (contentState.relevanceScore !== undefined) {
      payload.aps['relevance-score'] = contentState.relevanceScore;
    }
    
    if (contentState.alert) {
      payload.aps.alert = contentState.alert;
    }
    
    payloadString = JSON.stringify(payload);
    
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
  if (contentState.startedAt === undefined) {
    // Legacy format payload
    logger.log('📋 Converted contentState for iOS (legacy):', JSON.stringify(convertedContentState, null, 2));
    
    // CRITICAL: APNs timestamp field also uses Apple reference date
    const SECONDS_BETWEEN_EPOCHS_LEGACY = 978307200;
    const legacyPayload = {
      'aps': {
        'timestamp': Math.floor(Date.now() / 1000) - SECONDS_BETWEEN_EPOCHS_LEGACY,
        'event': 'update',
        'content-state': convertedContentState
      }
    };

    if (dismissalDate) {
      // Dismissal date also uses Apple reference
      const dismissalUnix = Math.floor(dismissalDate.getTime() / 1000);
      legacyPayload.aps['dismissal-date'] = dismissalUnix - SECONDS_BETWEEN_EPOCHS_LEGACY;
    }

    payloadString = JSON.stringify(legacyPayload);
  }
  
  // Always use production environment
  const apnsHost = config.APNS_HOST;
  
  logger.log(`📱 Using PRODUCTION environment`);
  logger.log(`  Host: ${apnsHost}`);
  logger.log(`  Key ID: ${config.apnsKeyId}`);
  
  let token;
  try {
    // Generate production token
    token = await generateAPNsToken();
  } catch (error) {
    logger.error(`❌ Failed to generate APNs token:`, error.message);
    throw error;
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

        // Smart priority determination to avoid throttling
        // Priority 10 (high): Immediate delivery, counts toward budget
        // Priority 5 (low): Can be delayed, doesn't count toward budget
        
        const eventType = determineEventType(contentState);
        
        // Critical events that require immediate attention
        const criticalEvents = ['stop', 'start', 'complete'];
        
        // Important events that should be delivered quickly
        const importantEvents = ['pause', 'resume'];
        
        // Regular updates that can be delayed slightly
        const regularEvents = ['update', 'progress'];
        
        let apnsPriority = '5'; // Default to low priority
        
        // If user has disabled frequent pushes, use more conservative priority
        const hasFrequentPushesEnabled = frequentPushesEnabled !== false;
        
        if (criticalEvents.includes(eventType)) {
            // Always use high priority for critical events
            apnsPriority = '10';
        } else if (importantEvents.includes(eventType)) {
            if (hasFrequentPushesEnabled) {
                // With frequent pushes enabled, use mixed strategy
                // Every 3rd pause/resume uses low priority to conserve budget
                const updateCount = global.liveActivityUpdateCount || 0;
                global.liveActivityUpdateCount = updateCount + 1;
                apnsPriority = (updateCount % 3 === 0) ? '5' : '10';
            } else {
                // Without frequent pushes, be more conservative
                // Use high priority only for first 5 updates per session
                const sessionUpdateCount = global.sessionUpdateCount || 0;
                global.sessionUpdateCount = sessionUpdateCount + 1;
                apnsPriority = sessionUpdateCount <= 5 ? '10' : '5';
            }
        } else {
            // Regular updates always use low priority
            apnsPriority = '5';
        }
        
        if (!hasFrequentPushesEnabled) {
            logger.log('⚠️ Frequent pushes disabled by user, using conservative priority');
        }
        
        logger.log(`📊 APNs Priority: ${apnsPriority} for event: ${eventType}`);
        
        const req = client.request({
          ':method': 'POST',
          ':path': `${config.APNS_PATH_PREFIX}${pushToken}`,
          'authorization': `bearer ${token}`,
          'apns-topic': topicOverride || config.apnsTopic,
          'apns-push-type': 'liveactivity',
          'apns-priority': apnsPriority,
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
            logger.log(`✅ Live Activity update sent successfully`);
            resolve({ 
              success: true, 
              environment: 'production',
              response: responseBody 
            });
          } else {
            const errorInfo = {
              statusCode,
              response: responseBody,
              headers: responseHeaders,
              environment: 'production'
            };
            
            if (statusCode === 400 && responseBody.includes('BadDeviceToken')) {
              logger.error(`❌ BadDeviceToken - Token/server mismatch`);
            } else if (statusCode === 403) {
              logger.error(`❌ 403 Forbidden - Invalid authentication`, errorInfo);
            } else if (statusCode === 410) {
              logger.error(`❌ 410 Gone - Token is no longer valid`);
            }
            
            reject(new Error(`APNs error: ${statusCode} - ${responseBody}`));
          }
        });

        req.on('error', (error) => {
          logger.error(`❌ APNs request error:`, error.message);
          client.close();
          reject(new Error(`APNs request failed: ${error.message}`));
        });

        try {
          req.write(payloadString);
          req.end();
        } catch (error) {
          logger.error(`❌ Failed to send APNs request:`, error.message);
          client.close();
          reject(new Error(`Failed to send request: ${error.message}`));
        }
      });
      
      // Return the result
      return result;
      
    } catch (error) {
      logger.error(`❌ APNs request failed:`, error.message);
      throw error;
    }
}

/**
 * Update Live Activity with new content state format
 */
exports.updateLiveActivity = onCall(
  { 
    region: 'us-central1',
    secrets: [
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret
    ],
    consumeAppCheckToken: false  // Disable App Check for Live Activity updates
  },
  async (request) => {
    const enhancedLogger = new EnhancedLogger('updateLiveActivity');
    const requestId = enhancedLogger.startRequest('updateLiveActivity', request);
    
    // Log initial request details
    enhancedLogger.logLiveActivity('REQUEST_RECEIVED', {
      activityId: request.data?.activityId,
      contentState: request.data?.contentState,
      pushToken: request.data?.pushToken,
      environment: request.data?.environment
    });
    
    try {
      const startInit = Date.now();
      await initialize();
      enhancedLogger.logPerformance('initialization', startInit);
    } catch (error) {
      enhancedLogger.error('Failed to initialize function', error);
      enhancedLogger.endRequest(false, { error: error.message });
      throw new HttpsError('internal', 'Failed to initialize function: ' + error.message);
    }
    
    if (!request.auth) {
      logger.error('❌ No authentication provided');
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { activityId, contentState, pushToken, frequentPushesEnabled } = request.data;

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
      
      // Detect event type based on pause state changes
      let eventType = 'update';
      
      // Check if this is a pause/resume event by comparing with stored state
      const storedStateDoc = await modules.admin.firestore()
        .collection('activeTimers')
        .doc(request.auth.uid)
        .get();
      
      if (storedStateDoc.exists) {
        const storedData = storedStateDoc.data();
        const wasPaused = storedData?.contentState?.pausedAt || storedData?.contentState?.isPaused;
        const isPaused = contentState.pausedAt || contentState.isPaused;
        
        logger.log(`📊 [updateLiveActivity] Comparing pause states:`, {
          storedPausedAt: storedData?.contentState?.pausedAt,
          storedIsPaused: storedData?.contentState?.isPaused,
          wasPaused: wasPaused,
          newPausedAt: contentState.pausedAt,
          newIsPaused: contentState.isPaused,
          isPaused: isPaused
        });
        
        if (!wasPaused && isPaused) {
          eventType = 'pause';
        } else if (wasPaused && !isPaused) {
          eventType = 'resume';
        }
      }
      
      logger.log(`🎯 Detected event type: ${eventType}`);
      
      // Don't modify contentState - determineEventType will handle event detection
      // contentState.event = eventType; // REMOVED - don't send event to iOS
      
      // The new sendLiveActivityUpdate function handles retries internally
      await sendLiveActivityUpdate(finalPushToken, activityId, contentState, null, topicOverride, preferredEnvironment, frequentPushesEnabled);

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
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret
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
      
      // Don't set event on contentState - determineEventType will handle it
      // contentState.event = action; // REMOVED - don't send event to iOS
      
      // Store previous state for event detection
      const wasPaused = !!contentState.pausedAt;
      
      switch (action) {
        case 'pause':
          contentState.isPaused = true;
          contentState.pausedAt = new Date().toISOString();
          contentState._wasPaused = wasPaused; // For event detection
          logger.log('⏸️ Setting pause state with pausedAt:', contentState.pausedAt);
          break;
        case 'resume':
          contentState.isPaused = false;
          contentState._wasPaused = wasPaused; // For event detection
          // Adjust startedAt to account for pause duration when resuming
          if (contentState.pausedAt) {
            const pausedAt = new Date(contentState.pausedAt);
            const pauseDuration = Date.now() - pausedAt.getTime();
            const originalStartedAt = new Date(contentState.startedAt || contentState.startTime);
            contentState.startedAt = new Date(originalStartedAt.getTime() + pauseDuration).toISOString();
            delete contentState.pausedAt;
            logger.log('▶️ Resuming with adjusted startedAt:', contentState.startedAt);
          }
          break;
        case 'stop':
          // Don't add event to contentState - determineEventType will handle it
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
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret
    ],
    consumeAppCheckToken: false
  },
  async (request) => {
    logger.log('🧪 testAPNsConnection called');
    
    try {
      await initialize();
      
      // Test JWT generation for production only
      const results = {
        production: {
          jwt: null,
          connection: null,
          keyId: config.apnsKeyId,
          hasKey: !!config.apnsKey
        },
        config: {
          teamId: config.apnsTeamId,
          topic: config.apnsTopic
        }
      };
      
      // Test production JWT
      try {
        const prodToken = await generateAPNsToken();
        results.production.jwt = 'Generated successfully';
      } catch (error) {
        results.production.jwt = `Failed: ${error.message}`;
      }
      
      // Test production endpoint only
      try {
        const prodClient = modules.http2.connect(`https://${config.APNS_HOST}:${config.APNS_PORT}`);
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
      apnsAuthKeyProdSecret, 
      apnsKeyIdSecret, 
      apnsTeamIdSecret, 
      apnsTopicSecret
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
    
    // Check if this is a significant state change
    const isPauseStateChange = beforeData?.contentState?.isPaused !== afterData.contentState?.isPaused;
    const isActionChange = beforeData?.action !== afterData.action;
    const isNewTimer = !beforeData && afterData;
    const isTimerDeleted = beforeData && !afterData;
    const isPushUpdateTrigger = afterData?.lastPushUpdate && beforeData?.lastPushUpdate !== afterData?.lastPushUpdate;
    
    // Check for pause state changes in the new format
    const wasPaused = beforeData?.contentState?.pausedAt || beforeData?.contentState?.isPaused;
    const isPaused = afterData?.contentState?.pausedAt || afterData?.contentState?.isPaused;
    const pauseStateChanged = !!wasPaused !== !!isPaused;
    
    logger.log('📊 State change detection:', {
      wasPaused,
      isPaused,
      pauseStateChanged,
      isPauseStateChange,
      isActionChange,
      isNewTimer,
      isTimerDeleted,
      isPushUpdateTrigger,
      beforeAction: beforeData?.action,
      afterAction: afterData?.action
    });
    
    // Only skip if there's truly no change
    const hasSignificantChange = pauseStateChanged || isPauseStateChange || isActionChange || 
                                  isNewTimer || isTimerDeleted || isPushUpdateTrigger;
    
    if (!hasSignificantChange) {
      logger.log('No significant state change, skipping Live Activity update');
      return;
    }
    
    logger.log('✅ Significant state change detected, proceeding with Live Activity update');

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
      // NEW FORMAT: startedAt/pausedAt (preferred)
      if (contentState.startedAt) {
        // Already an ISO string, keep it as-is
        logger.log(`📅 onTimerStateChange: Found startedAt: ${contentState.startedAt}`);
      }
      
      if (contentState.pausedAt) {
        // Already an ISO string, keep it as-is
        logger.log(`📅 onTimerStateChange: Found pausedAt: ${contentState.pausedAt}`);
      }
      
      // LEGACY FORMAT: startTime/endTime (fallback)
      if (!contentState.startedAt && contentState.startTime) {
        if (contentState.startTime?.toDate) {
          contentState.startTime = contentState.startTime.toDate().toISOString();
        } else if (contentState.startTime?.seconds) {
          contentState.startTime = new Date(contentState.startTime.seconds * 1000).toISOString();
        } else if (contentState.startTime?._seconds) {
          contentState.startTime = new Date(contentState.startTime._seconds * 1000).toISOString();
        }
      }
      
      if (!contentState.startedAt && contentState.endTime) {
        if (contentState.endTime?.toDate) {
          contentState.endTime = contentState.endTime.toDate().toISOString();
        } else if (contentState.endTime?.seconds) {
          contentState.endTime = new Date(contentState.endTime.seconds * 1000).toISOString();
        } else if (contentState.endTime?._seconds) {
          contentState.endTime = new Date(contentState.endTime._seconds * 1000).toISOString();
        }
      }
      
      if (contentState.lastUpdateTime?.toDate) {
        contentState.lastUpdateTime = contentState.lastUpdateTime.toDate().toISOString();
      } else if (contentState.lastUpdateTime?.seconds) {
        contentState.lastUpdateTime = new Date(contentState.lastUpdateTime.seconds * 1000).toISOString();
      } else if (contentState.lastUpdateTime?._seconds) {
        contentState.lastUpdateTime = new Date(contentState.lastUpdateTime._seconds * 1000).toISOString();
      }
      
      // CRITICAL: Include required fields for new format
      if (contentState.startedAt) {
        // Ensure all required fields are present for new format
        contentState.duration = contentState.duration || afterData.duration || 300;
        contentState.methodName = contentState.methodName || afterData.methodName || 'Timer';
        contentState.sessionType = contentState.sessionType || afterData.sessionType || 'countdown';
        logger.log(`📊 Using new format with duration: ${contentState.duration}s, method: ${contentState.methodName}, type: ${contentState.sessionType}`);
      }
      
      // CRITICAL: Preserve totalDuration if available to prevent 1-hour default (legacy format)
      if (!contentState.startedAt && afterData.totalDuration) {
        contentState.totalDuration = afterData.totalDuration;
        logger.log(`📊 Preserving total duration (legacy): ${contentState.totalDuration}s`);
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
      
      // Determine event type for priority
      let eventType = 'update';
      if (pauseStateChanged) {
        // isPaused represents the NEW state (afterData)
        // If isPaused is true, timer was just paused
        // If isPaused is false, timer was just resumed
        eventType = isPaused ? 'pause' : 'resume';
        logger.log(`📊 Pause state change detected: wasPaused=${wasPaused}, isPaused=${isPaused}, event=${eventType}`);
      } else if (isNewTimer) {
        eventType = 'start';
      } else if (isTimerDeleted || afterData?.action === 'stop') {
        eventType = 'stop';
      }
      
      logger.log(`🎯 Event type for Live Activity: ${eventType}`);
      
      // Don't pass event to contentState - determineEventType will handle it
      // contentState.event = eventType; // REMOVED - don't send event to iOS
      
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