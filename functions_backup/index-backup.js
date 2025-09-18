/**
 * Main entry point for Growth App Firebase Functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK once
if (!admin.apps.length) {
  admin.initializeApp();
}

// Import required modules
const vertexAIProxy = require('./vertexAiProxy');
const { getFallbackResponse } = require('./fallbackKnowledge');
const { addMissingRoutines } = require('./addMissingRoutines');
const liveActivityFunctions = require('./liveActivityUpdates');
const { manageLiveActivityUpdates } = require('./manageLiveActivityUpdates');
const { updateEducationalResourceImages, updateEducationalResourceImagesCallable } = require('./updateEducationalResourceImages');
const moderationFunctions = require('./moderation');

// AI Coach function - requires authenticated users only
exports.generateAIResponse = onCall({ 
  cors: true,
  region: 'us-central1',
  consumeAppCheckToken: false,
  cpu: 1,
  memory: '256MiB',
  maxInstances: 100,
  timeoutSeconds: 60
}, async (request) => {
  // Require authentication
  if (!request.auth) {
    console.error('Unauthenticated request attempted');
    throw new HttpsError('unauthenticated', 'Authentication required to use AI Coach');
  }
  
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
    console.log(`Calling Vertex AI for user ${userId} with query: "${query}"`);
    
    const conversationHistory = request.data.conversationHistory || [];
    
    const aiResponse = await vertexAIProxy.generateAIResponse({
      query: query,
      conversationHistory: conversationHistory
    }, {
      auth: request.auth,
      app: request.app
    });
    
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
    console.log('Falling back to knowledge base responses due to Vertex AI error');
    
    let fallbackText = getFallbackResponse(query);
    
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
});

// Add missing routines function
exports.addMissingRoutines = onCall({ 
  cors: true,
  region: 'us-central1',
  consumeAppCheckToken: false
}, async (request) => {
  console.log('Adding missing routines via Cloud Function...');
  await addMissingRoutines();
  return { success: true, message: 'Missing routines added successfully' };
});

// Live Activity update functions
exports.updateLiveActivityTimer = liveActivityFunctions.updateLiveActivityTimer;
exports.onTimerStateChange = liveActivityFunctions.onTimerStateChange;
exports.updateLiveActivity = liveActivityFunctions.updateLiveActivity;
exports.startLiveActivity = liveActivityFunctions.startLiveActivity;

// Server-side timer management function
exports.manageLiveActivityUpdates = manageLiveActivityUpdates;

// Educational resource image update functions
exports.updateEducationalResourceImages = updateEducationalResourceImages;
exports.updateEducationalResourceImagesCallable = updateEducationalResourceImagesCallable;

// Community moderation functions
exports.moderateNewRoutine = moderationFunctions.moderateNewRoutine;
exports.processReport = moderationFunctions.processReport;
exports.banUser = moderationFunctions.banUser;
exports.moderateContent = moderationFunctions.moderateContent;
exports.cleanupOldReports = moderationFunctions.cleanupOldReports;
exports.checkUserBanned = moderationFunctions.checkUserBanned;

// Track routine downloads
exports.trackRoutineDownload = onCall({
  cors: true,
  region: 'us-central1',
  consumeAppCheckToken: false
}, async (request) => {
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
});

// Update routine statistics when ratings change
exports.updateRoutineStats = onDocumentWritten({
  document: 'routines/{routineId}/ratings/{ratingId}',
  region: 'us-central1'
}, async (event) => {
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
});

console.log('Functions index.js loaded successfully');