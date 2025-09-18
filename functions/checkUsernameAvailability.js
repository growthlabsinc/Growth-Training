/**
 * Firebase Cloud Function for checking username availability
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Initialize admin if not already done
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Check if a username is available
 * @param {string} username - The username to check
 * @returns {Object} Available status and message
 */
exports.checkUsernameAvailability = onCall({
  region: 'us-central1',
  cors: true,
  consumeAppCheckToken: false, // Disable App Check for now
  memory: '256MiB',
  timeoutSeconds: 30,
  maxInstances: 100
}, async (request) => {
  try {
    // Validate request
    if (!request.data || !request.data.username) {
      throw new HttpsError('invalid-argument', 'Username is required');
    }

    const username = request.data.username.trim().toLowerCase();
    
    // Validate username format
    if (username.length < 3) {
      return {
        available: false,
        message: 'Username must be at least 3 characters long'
      };
    }
    
    if (username.length > 20) {
      return {
        available: false,
        message: 'Username must be 20 characters or less'
      };
    }
    
    // Check if username contains only valid characters (alphanumeric and underscore)
    const validUsernamePattern = /^[a-zA-Z0-9_]+$/;
    if (!validUsernamePattern.test(username)) {
      return {
        available: false,
        message: 'Username can only contain letters, numbers, and underscores'
      };
    }
    
    // Check for reserved usernames
    const reservedUsernames = ['admin', 'root', 'user', 'test', 'growth', 'app', 'api', 'system'];
    if (reservedUsernames.includes(username)) {
      return {
        available: false,
        message: 'This username is reserved'
      };
    }

    console.log(`Checking availability for username: ${username}`);

    // Check if username exists in users collection
    const usersSnapshot = await db.collection('users')
      .where('username', '==', username)
      .limit(1)
      .get();
    
    if (!usersSnapshot.empty) {
      console.log(`Username ${username} is already taken`);
      return {
        available: false,
        message: 'Username is already taken'
      };
    }

    // Also check in usernames collection (for reserved/blocked usernames)
    const usernamesDoc = await db.collection('usernames').doc(username).get();
    
    if (usernamesDoc.exists) {
      const data = usernamesDoc.data();
      if (data.reserved || data.blocked) {
        console.log(`Username ${username} is reserved or blocked`);
        return {
          available: false,
          message: 'Username is not available'
        };
      }
      
      // If document exists but not reserved/blocked, check if it's owned by someone
      if (data.userId) {
        console.log(`Username ${username} is owned by user ${data.userId}`);
        return {
          available: false,
          message: 'Username is already taken'
        };
      }
    }

    console.log(`Username ${username} is available`);
    return {
      available: true,
      message: 'Username is available'
    };

  } catch (error) {
    console.error('Error checking username availability:', error);
    
    if (error instanceof HttpsError) {
      throw error;
    }
    
    throw new HttpsError('internal', 'Failed to check username availability');
  }
});