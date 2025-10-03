# Growth App Firebase Functions

This directory contains the Firebase Cloud Functions for the Growth mobile app.

## Setup and Development

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Set Environment Variables:**
   You can set environment variables in the Firebase console or locally for testing:
   ```bash
   firebase functions:config:set vertex.region="us-central1" vertex.project_id="your-project-id"
   ```

3. **Run Emulators for Local Testing:**
   ```bash
   npm run serve
   # or
   firebase emulators:start --only functions
   ```

4. **Test Your Functions:**
   - Open the Emulator UI: http://localhost:4000
   - Use the Firebase Admin SDK in your app with environment variables:
     ```swift
     // In Swift app for testing
     FirebaseApp.configure()
     Functions.functions().useEmulator(withHost: "localhost", port: 5001)
     ```

## Deployment

1. **Deploy to Firebase:**
   ```bash
   npm run deploy
   # or
   firebase deploy --only functions
   ```

2. **Deploy Specific Functions:**
   ```bash
   firebase deploy --only functions:generateAIResponse
   ```

3. **View Function Logs:**
   ```bash
   npm run logs
   # or
   firebase functions:log
   ```

## Available Functions

- `generateAIResponse`: Cloud Function that handles AI responses using Google's Vertex AI with Gemini model
- `healthCheck`: Simple HTTP function for testing deployment status

## Troubleshooting

1. **"NOT FOUND" Error in iOS App:**
   - Check function region in both app and cloud functions
   - Verify function is deployed and accessible
   - Try resetting the Firebase instance in the app

2. **Connection Issues:**
   - Verify your API keys and permissions
   - Check for Firebase outages: https://status.firebase.google.com/
   - Check logs for specific error messages

## Architecture

The AI coaching functionality uses the following flow:
1. iOS app sends request to Firebase Cloud Functions
2. Cloud Function calls Vertex AI (Gemini)
3. Response is formatted and returned to app

## Updates and Maintenance

When updating these functions:
1. Test locally with emulators first
2. Make incremental changes
3. Update version number in package.json
4. Document significant changes in this README 