/**
 * Main entry point for Growth App Firebase Functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const functions = require('firebase-functions');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

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

// Temporarily export the addMissingRoutines function
exports.addMissingRoutines = onCall(
  { 
    cors: true,
    region: 'us-central1',
    consumeAppCheckToken: false
  },
  async (request) => {
    console.log('Adding missing routines via Cloud Function...');
    const { addMissingRoutines } = require('./addMissingRoutines');
    await addMissingRoutines();
    return { success: true, message: 'Missing routines added successfully' };
  }
);

// Live Activity update functions - lazy load to prevent timeout
let liveActivityFunctions;
const getLiveActivityFunctions = () => {
  if (!liveActivityFunctions) {
    liveActivityFunctions = require('./liveActivityUpdates');
  }
  return liveActivityFunctions;
};

exports.updateLiveActivityTimer = (...args) => getLiveActivityFunctions().updateLiveActivityTimer(...args);
exports.onTimerStateChange = (...args) => getLiveActivityFunctions().onTimerStateChange(...args);
exports.updateLiveActivity = (...args) => getLiveActivityFunctions().updateLiveActivity(...args);
exports.testAPNsConnection = (...args) => getLiveActivityFunctions().testAPNsConnection(...args);

// New server-side timer management function - lazy load
exports.manageLiveActivityUpdates = (...args) => {
  const { manageLiveActivityUpdates } = require('./manageLiveActivityUpdates');
  return manageLiveActivityUpdates(...args);
};

// APNs Diagnostic Function - lazy load
exports.collectAPNsDiagnostics = (...args) => {
  const { collectAPNsDiagnostics } = require('./collectAPNsDiagnostics');
  return collectAPNsDiagnostics(...args);
};

// Educational resource image update functions - lazy load
let educationalResourceFunctions;
const getEducationalResourceFunctions = () => {
  if (!educationalResourceFunctions) {
    educationalResourceFunctions = require('./updateEducationalResourceImages');
  }
  return educationalResourceFunctions;
};

exports.updateEducationalResourceImages = (...args) => getEducationalResourceFunctions().updateEducationalResourceImages(...args);
exports.updateEducationalResourceImagesCallable = (...args) => getEducationalResourceFunctions().updateEducationalResourceImagesCallable(...args);

// Community moderation functions - lazy load
let moderationFunctions;
const getModerationFunctions = () => {
  if (!moderationFunctions) {
    moderationFunctions = require('./moderation');
  }
  return moderationFunctions;
};

exports.moderateNewRoutine = (...args) => getModerationFunctions().moderateNewRoutine(...args);
exports.processReport = (...args) => getModerationFunctions().processReport(...args);
exports.banUser = (...args) => getModerationFunctions().banUser(...args);
exports.moderateContent = (...args) => getModerationFunctions().moderateContent(...args);
exports.cleanupOldReports = (...args) => getModerationFunctions().cleanupOldReports(...args);
exports.checkUserBanned = (...args) => getModerationFunctions().checkUserBanned(...args);

// Additional community functions
// Track routine downloads
exports.trackRoutineDownload = onCall(
  {
    cors: true,
    region: 'us-central1',
    consumeAppCheckToken: false
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { routineId } = request.data;
    const userId = request.auth.uid;

    if (!routineId) {
      throw new HttpsError('invalid-argument', 'Routine ID is required');
    }

    try {
      const db = admin.firestore();
      
      // Update download count
      await db.collection('routines').doc(routineId)
        .collection('statistics').doc('stats').set({
          downloads: admin.firestore.FieldValue.increment(1),
          lastDownload: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      // Track individual download
      await db.collection('routines').doc(routineId)
        .collection('downloads').doc(userId).set({
          userId,
          downloadedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      return { success: true };
    } catch (error) {
      console.error('Error tracking download:', error);
      throw new HttpsError('internal', 'Failed to track download');
    }
  }
);

// Update routine statistics when ratings change
exports.updateRoutineStats = onDocumentWritten(
  'routines/{routineId}/ratings/{ratingId}',
  async (event) => {
    const routineId = event.params.routineId;
    const db = admin.firestore();
    
    try {
      // Get all ratings for this routine
      const ratingsSnapshot = await db.collection('routines')
        .doc(routineId)
        .collection('ratings')
        .get();

      let totalRating = 0;
      let ratingCount = 0;

      ratingsSnapshot.forEach(doc => {
        const rating = doc.data().rating;
        if (rating) {
          totalRating += rating;
          ratingCount++;
        }
      });

      const averageRating = ratingCount > 0 ? totalRating / ratingCount : 0;

      // Update routine document
      await db.collection('routines').doc(routineId).update({
        averageRating,
        ratingCount,
        lastRatingUpdate: admin.firestore.FieldValue.serverTimestamp(),
      });

    } catch (error) {
      console.error('Error updating routine stats:', error);
    }
  }
);