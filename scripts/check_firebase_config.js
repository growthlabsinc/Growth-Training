#!/usr/bin/env node
/**
 * Check Firebase Configuration and Connection
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('🔍 Checking Firebase Configuration...\n');

// Check for service account key
const serviceAccountPath = path.join(__dirname, 'service-account-key.json');
const hasServiceAccount = fs.existsSync(serviceAccountPath);

// Check for GoogleService-Info.plist files
const plistPath = path.join(__dirname, '..', 'Growth', 'Resources', 'Plist');
const devPlist = path.join(plistPath, 'dev.GoogleService-Info.plist');
const prodPlist = path.join(plistPath, 'GoogleService-Info.plist');

console.log('📱 iOS Configuration Files:');
console.log(`  Dev plist: ${fs.existsSync(devPlist) ? '✅ Present' : '❌ Missing'}`);
console.log(`  Prod plist: ${fs.existsSync(prodPlist) ? '✅ Present' : '❌ Missing'}`);

console.log('\n🔑 Service Account Key:');
if (hasServiceAccount) {
    console.log('  ✅ service-account-key.json found');

    // Try to parse and show project info
    try {
        const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
        console.log(`  📌 Project ID: ${serviceAccount.project_id}`);
        console.log(`  📧 Client Email: ${serviceAccount.client_email}`);
        console.log('\n✅ Ready to upload PE exercises to Firebase!');
        console.log('\n📤 Run: node upload_pe_exercises_to_firebase.js upload');
    } catch (error) {
        console.log('  ⚠️ File exists but could not be parsed');
    }
} else {
    console.log('  ❌ service-account-key.json not found');
    console.log('\n📋 To get your service account key:');
    console.log('  1. Go to Firebase Console: https://console.firebase.google.com');
    console.log('  2. Select your Growth project');
    console.log('  3. Go to Project Settings > Service Accounts');
    console.log('  4. Click "Generate new private key"');
    console.log('  5. Save the downloaded file as: service-account-key.json');
    console.log('  6. Move it to this directory: /Users/tradeflowj/Desktop/Dev/growth-training/scripts/');

    // Check for existing Firebase project info from plist
    if (fs.existsSync(prodPlist)) {
        console.log('\n📌 Your Firebase Project ID (from plist): growth-training-app');
        console.log('  Use this project when selecting in Firebase Console');
    }
}

console.log('\n📚 For detailed instructions, see: FIREBASE_SETUP_GUIDE.md');