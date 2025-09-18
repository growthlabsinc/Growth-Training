// Test setup file for Jest

// Mock Firebase Admin initialization
jest.mock('firebase-admin', () => {
  const admin = {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => ({
      collection: jest.fn(),
      batch: jest.fn(),
      runTransaction: jest.fn(),
      settings: jest.fn()
    })),
    auth: jest.fn(() => ({
      verifyIdToken: jest.fn(),
      getUser: jest.fn(),
      createUser: jest.fn()
    })),
    storage: jest.fn(() => ({
      bucket: jest.fn()
    }))
  };
  
  // Initialize the app mock
  admin.initializeApp();
  
  return admin;
});

// Mock Firebase Functions
jest.mock('firebase-functions', () => ({
  config: () => ({
    appstore: {
      key_id: 'test-key-id',
      issuer_id: 'test-issuer-id',
      private_key: 'test-private-key',
      webhook_secret: 'test-webhook-secret',
      environment: 'sandbox'
    }
  }),
  https: {
    onCall: (handler) => handler,
    onRequest: (handler) => handler,
    HttpsError: class HttpsError extends Error {
      constructor(code, message, details) {
        super(message);
        this.code = code;
        this.details = details;
      }
    }
  },
  logger: {
    log: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn()
  }
}));

// Set test environment variables
process.env.FUNCTIONS_EMULATOR = 'true';
process.env.FIREBASE_CONFIG = JSON.stringify({
  projectId: 'test-project',
  databaseURL: 'https://test-project.firebaseio.com',
  storageBucket: 'test-project.appspot.com'
});

// Global test utilities
global.mockTimestamp = () => ({
  seconds: Math.floor(Date.now() / 1000),
  nanoseconds: 0
});

// Silence console during tests unless debugging
if (!process.env.DEBUG_TESTS) {
  global.console = {
    ...console,
    log: jest.fn(),
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn()
  };
}