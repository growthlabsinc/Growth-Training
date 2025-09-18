# Live Activity Push Notification Implementation

## Overview
This implementation fixes Live Activity issues by using Firebase push notifications for reliable background updates and App Intents for button actions.

## Architecture

### 1. Push Token Registration
- When a Live Activity starts, it registers for push token updates
- Push tokens are stored in Firestore under `liveActivityTokens` collection
- Each token is linked to the user ID and activity ID

### 2. State Synchronization
- Timer state is synced to Firestore in the `activeTimers` collection
- Changes trigger Cloud Functions to send push updates
- Live Activities receive updates even when app is backgrounded

### 3. Button Actions
- Uses App Intents instead of deep links for reliable button handling
- Actions are stored in App Group shared UserDefaults
- Main app observes these changes and updates timer accordingly

## Components

### iOS App
1. **LiveActivityManager.swift** - Manages Live Activity lifecycle and push token registration
2. **TimerStateSync.swift** - Syncs timer state with Firestore
3. **TimerControlIntent.swift** - App Intent for button actions
4. **TimerIntentObserver.swift** - Observes and processes intent actions
5. **LiveActivityActionHandler.swift** - Handles fallback deep links
6. **AppGroupConstants.swift** - Shared data between app and widget

### Firebase Functions
1. **liveActivityUpdates.js** - Handles push notifications to Live Activities
2. **updateLiveActivityTimer** - Cloud function to send updates
3. **onTimerStateChange** - Firestore trigger for automatic updates

### Widget
1. **GrowthTimerWidgetLiveActivity.swift** - Updated to use App Intents for buttons
2. **TimerControlIntent.swift** - Shared App Intent definition

## Setup Instructions

### 1. Configure App Groups
1. In Xcode, select your project
2. For both the main app and widget targets:
   - Go to Signing & Capabilities
   - Add "App Groups" capability
   - Create/select group: `group.com.growth.shared`

### 2. Configure Push Notifications
1. Ensure Push Notifications capability is enabled
2. Add "Remote notifications" to Background Modes

### 3. Set up APNs for Firebase Functions
1. Create an APNs authentication key in Apple Developer Portal
2. Copy `functions/.env.example` to `functions/.env`
3. Fill in your APNs credentials:
   ```
   APNS_TEAM_ID=YOUR_TEAM_ID
   APNS_KEY_ID=YOUR_KEY_ID
   APNS_AUTH_KEY="-----BEGIN PRIVATE KEY-----
   YOUR_KEY_CONTENT_HERE
   -----END PRIVATE KEY-----"
   ```

### 4. Deploy Firebase Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 5. Update Firestore Rules
Add rules for the new collections:
```javascript
// Live Activity tokens
match /liveActivityTokens/{activityId} {
  allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
}

// Active timers
match /activeTimers/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## How It Works

### Starting a Timer
1. Timer starts → Live Activity created with push token registration
2. Push token stored in Firestore
3. Timer state synced to Firestore
4. Live Activity shows timer with working buttons

### Background Updates
1. Timer state changes in Firestore
2. Cloud Function triggered
3. Push notification sent to Live Activity
4. Live Activity updates even when app is closed

### Button Actions
1. User taps button on Live Activity
2. App Intent executed, stores action in App Group
3. TimerIntentObserver detects change
4. Timer state updated accordingly
5. State synced to Firestore for push update

## Testing

### Local Testing
1. Run the app on a physical device (Live Activities don't work in simulator)
2. Start a timer
3. Background the app
4. Verify Live Activity appears and updates continue
5. Test pause/resume/stop buttons

### Push Testing
1. Use Firebase Console to test push updates
2. Monitor Firestore for state changes
3. Check Cloud Function logs for push delivery

## Troubleshooting

### Live Activity Not Updating
1. Check if push token is stored in Firestore
2. Verify Cloud Functions are deployed
3. Check function logs for errors
4. Ensure APNs credentials are correct

### Buttons Not Working
1. Verify App Groups are configured correctly
2. Check if TimerIntentObserver is running
3. Look for intent actions in shared UserDefaults
4. Ensure widget has latest code

### Push Token Issues
1. Make sure Live Activity is created with `.token` push type
2. Check for push token updates in console logs
3. Verify Firestore write permissions

## Known Limitations
- Live Activities expire after 8 hours
- Push updates have a rate limit
- App Intents require iOS 16+
- Background updates depend on network connectivity