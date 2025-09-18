/**
 * Main entry point for Growth App Firebase Functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const functions = require('firebase-functions');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// App Store Connect configuration is loaded on-demand in functions that need it
// Don't load at module level to prevent deployment timeouts

// Lazy load heavy dependencies to prevent deployment timeouts
let vertexAIProxy;
let getFallbackResponse;

// AI Coach function - requires authenticated users only
exports.generateAIResponse = onCall(
  { 
    cors: true,  // Enable CORS for all origins
    region: 'us-central1',  // Explicitly set region
    // Disable App Check requirement for this function
    consumeAppCheckToken: false,
    // Set to 2nd gen function to ensure proper configuration
    cpu: 1,
    memory: '256MiB',
    maxInstances: 100,
    timeoutSeconds: 60
    // Note: IAM bindings must be set via gcloud after deployment
  },
  async (request) => {
    // Require authentication
    if (!request.auth) {
      console.error('Unauthenticated request attempted');
      throw new HttpsError('unauthenticated', 'Authentication required to use AI Coach');
    }
    
    // Log request details for debugging
    const userId = request.auth.uid;
    const isAnonymous = request.auth.token?.firebase?.sign_in_provider === 'anonymous';
    
    console.log(`generateAIResponse called:
      - User ID: ${userId}
      - Is Anonymous: ${isAnonymous}
      - App Check present: ${request.app !== undefined}
      - Request data: ${JSON.stringify(request.data)}`);
    
    // Validate request
    if (!request.data || typeof request.data.query !== 'string') {
      console.error('Invalid request: missing or invalid query parameter');
      throw new HttpsError('invalid-argument', 'Query parameter is required and must be a string');
    }
    
    const query = request.data.query.trim();
    if (query.length === 0) {
      throw new HttpsError('invalid-argument', 'Query cannot be empty');
    }
    
    try {
      // Use Vertex AI to generate response
      console.log(`Calling Vertex AI for user ${userId} with query: "${query}"`);
      
      // Extract conversation history if provided
      const conversationHistory = request.data.conversationHistory || [];
      
      // Lazy load dependencies
      if (!vertexAIProxy) {
        vertexAIProxy = require('./vertexAiProxy');
      }
      
      // Call the Vertex AI proxy
      const aiResponse = await vertexAIProxy.generateAIResponse({
        query: query,
        conversationHistory: conversationHistory
      }, {
        auth: request.auth,
        app: request.app
      });
      
      // Add metadata to the response
      const response = {
        text: aiResponse.text,
        sources: aiResponse.sources || null,
        metadata: {
          userId: userId,
          isAuthenticated: true,
          timestamp: new Date().toISOString(),
          model: 'vertex-ai-gemini'
        }
      };
      
      console.log(`Vertex AI response generated successfully for user ${userId}`);
      return response;
      
    } catch (error) {
      console.error(`Error generating AI response: ${error}`);
      
      // If Vertex AI fails, fall back to comprehensive knowledge base
      console.log('Falling back to knowledge base responses due to Vertex AI error');
      
      // Lazy load fallback knowledge
      if (!getFallbackResponse) {
        getFallbackResponse = require('./fallbackKnowledge').getFallbackResponse;
      }
      
      // Try to get a specific response from fallback knowledge
      let fallbackText = getFallbackResponse(query);
      
      // If no specific match, provide a helpful default
      if (!fallbackText) {
        if (query.toLowerCase().includes('hello') || query.toLowerCase().includes('hi')) {
          fallbackText = `Hello! I'm your Growth Coach, here to help you with Growth Methods, techniques, and app navigation. You can ask me about:

• Specific Growth Methods (AM1, AM2, Vascion, etc.)
• Technique instructions and tips
• Common abbreviations and terminology
• Progression timelines
• Safety guidelines

What would you like to know about?`;
        } else {
          fallbackText = `I'm your Growth Coach. While I'm having trouble with my full knowledge base, I can still help with Growth Methods basics. 

Try asking about:
• Specific methods: "What is AM1?" or "Explain Angion Method 2.0"
• Techniques: "How do I perform Vascion?" or "What are SABRE techniques?"
• Terms: "What does CS mean?" or "What is BFR?"
• Progression: "What's the timeline for results?"

Please be specific with your question and I'll do my best to help.`;
        }
      }
      
      // Return fallback response
      const response = {
        text: fallbackText,
        sources: null,
        metadata: {
          userId: userId,
          isAuthenticated: true,
          timestamp: new Date().toISOString(),
          model: 'fallback',
          error: error.message || 'Vertex AI unavailable'
        }
      };
      
      return response;
    }
  }
);

// Live Activity update functions - use the main version with our fixes
const liveActivityFunctions = require('./liveActivityUpdates');
exports.updateLiveActivityTimer = liveActivityFunctions.updateLiveActivityTimer;
exports.onTimerStateChange = liveActivityFunctions.onTimerStateChange;
exports.updateLiveActivity = liveActivityFunctions.updateLiveActivity;
exports.testAPNsConnection = liveActivityFunctions.testAPNsConnection;
exports.registerLiveActivityPushToken = liveActivityFunctions.registerLiveActivityPushToken;
exports.registerPushToStartToken = liveActivityFunctions.registerPushToStartToken;

// Import and export manageLiveActivityUpdates - OPTIMIZED VERSION
const manageLiveActivityUpdates = require('./manageLiveActivityUpdates-optimized');
exports.manageLiveActivityUpdates = manageLiveActivityUpdates.manageLiveActivityUpdates;
exports.notifyLiveActivityStateChange = manageLiveActivityUpdates.notifyLiveActivityStateChange;

// Import and export fixTimerDates utility
const fixTimerDates = require('./fix-timer-dates');
exports.fixTimerDates = fixTimerDates.fixTimerDates;

// Import and export simplified Live Activity update function
const updateLiveActivitySimplified = require('./updateLiveActivitySimplified');
exports.updateLiveActivitySimplified = updateLiveActivitySimplified.updateLiveActivitySimplified;

// Test deployment function
exports.testDeployment = onCall(
  {
    region: 'us-central1',
    consumeAppCheckToken: false
  },
  async (request) => {
    return {
      success: true,
      message: 'Deployment successful',
      timestamp: new Date().toISOString()
    };
  }
);

// Username availability check function
exports.checkUsernameAvailability = onCall(
  {
    region: 'us-central1',
    consumeAppCheckToken: false,
    maxInstances: 100,
    timeoutSeconds: 10
  },
  async (request) => {
    const { username } = request.data;
    
    // Validate input
    if (!username || typeof username !== 'string') {
      throw new HttpsError('invalid-argument', 'Username is required');
    }
    
    const lowercaseUsername = username.toLowerCase().trim();
    
    // Validate username format
    const usernameRegex = /^[a-zA-Z0-9_]{3,20}$/;
    if (!usernameRegex.test(lowercaseUsername)) {
      throw new HttpsError('invalid-argument', 'Username must be 3-20 characters, letters, numbers, and underscores only');
    }
    
    try {
      // Query Firestore for users with this username
      const db = admin.firestore();
      const usersSnapshot = await db.collection('users')
        .where('username', '==', lowercaseUsername)
        .limit(1)
        .get();
      
      // If no documents found, username is available
      const isAvailable = usersSnapshot.empty;
      
      console.log(`Username check: ${lowercaseUsername} - Available: ${isAvailable}`);
      
      return {
        available: isAvailable,
        username: lowercaseUsername
      };
    } catch (error) {
      console.error('Error checking username availability:', error);
      throw new HttpsError('internal', 'Failed to check username availability');
    }
  }
);

// Subscription Functions
const { validateSubscriptionReceipt } = require('./src/subscriptionValidation');
const { handleAppStoreNotification } = require('./src/appStoreNotifications');
exports.validateSubscriptionReceipt = validateSubscriptionReceipt;
exports.handleAppStoreNotification = handleAppStoreNotification;

// Educational Resources Functions
const { updateEducationalResourceLocalImages, updateEducationalResourceLocalImagesCallable } = require('./updateEducationalResourceLocalImages');
exports.updateEducationalResourceLocalImages = updateEducationalResourceLocalImages;
exports.updateEducationalResourceLocalImagesCallable = updateEducationalResourceLocalImagesCallable;