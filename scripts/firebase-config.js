import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables from project root
dotenv.config({ path: join(__dirname, '..', '.env') });

// Firebase configurations for different environments
export const firebaseConfigs = {
  production: {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN || 'growth-70a85.firebaseapp.com',
    projectId: process.env.FIREBASE_PROJECT_ID || 'growth-70a85',
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'growth-70a85.appspot.com',
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || '876570095367',
    appId: process.env.FIREBASE_APP_ID || '1:876570095367:ios:9bb52de88be4d6f95354d8',
    measurementId: process.env.FIREBASE_MEASUREMENT_ID
  },
  development: {
    apiKey: process.env.FIREBASE_DEV_API_KEY,
    authDomain: 'growth-training-app.firebaseapp.com',
    projectId: process.env.FIREBASE_DEV_PROJECT_ID || 'growth-training-app',
    storageBucket: 'growth-training-app.appspot.com',
    messagingSenderId: '750208965706',
    appId: '1:750208965706:ios:123456789abcdef'
  },
  staging: {
    apiKey: process.env.FIREBASE_STAGING_API_KEY,
    authDomain: 'angion-staging.firebaseapp.com',
    projectId: process.env.FIREBASE_STAGING_PROJECT_ID || 'angion-staging',
    storageBucket: 'angion-staging.appspot.com',
    messagingSenderId: '123456789',
    appId: '1:123456789:ios:abcdef123456'
  }
};

// Get configuration for specified environment
export function getFirebaseConfig(environment = 'production') {
  const config = firebaseConfigs[environment];

  if (!config) {
    throw new Error(`Invalid environment: ${environment}. Use 'production', 'development', or 'staging'.`);
  }

  if (!config.apiKey) {
    throw new Error(`Firebase API key not set for ${environment} environment. Please check your .env file.`);
  }

  return config;
}

// APNS Configuration
export const apnsConfig = {
  keyId: process.env.APNS_KEY_ID,
  teamId: process.env.APNS_TEAM_ID,
  keyPath: process.env.APNS_KEY_PATH,
  bundleId: process.env.APNS_BUNDLE_ID || 'com.growthlabs.growthmethod'
};

export default getFirebaseConfig;