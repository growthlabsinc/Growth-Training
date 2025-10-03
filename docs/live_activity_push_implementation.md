# Live Activity Push Updates Implementation

## Overview
This implementation uses Apple Push Notification service (APNs) to update Live Activities when the app is in the background, solving the issue where timers stop updating after the app is backgrounded.

## Architecture

### 1. **Client-Side Components**

#### LiveActivityManager.swift
- Creates and manages Live Activities
- Stores push tokens in Firestore
- Initiates push update service when activity starts

#### LiveActivityPushUpdateService.swift
- Manages periodic push update triggers
- Calls Firebase Functions every 30 seconds while timer is running
- Handles background task to keep updates running

#### TimerStateSync.swift
- Syncs timer state to Firestore `activeTimers` collection
- Changes trigger Firebase Function to send push updates

### 2. **Server-Side Components (Firebase Functions)**

#### updateLiveActivityTimer
- Callable function to manually trigger Live Activity updates
- Authenticates users and validates activity ownership
- Sends push notifications via APNs

#### onTimerStateChange
- Firestore trigger that fires when `activeTimers` document changes
- Automatically sends push updates when timer state changes
- Ensures Live Activities stay in sync with app state

### 3. **Widget Implementation**

#### GrowthTimerWidgetLiveActivity.swift
- Uses `Text(Date()...Date(), style: .timer)` for automatic time updates
- Properly handles countdown and stopwatch modes
- Updates continue even when app is backgrounded

## Push Notification Flow

1. **Activity Creation**
   - App creates Live Activity with push token support
   - Push token is stored in Firestore `liveActivityTokens` collection

2. **State Updates**
   - Timer state changes are written to `activeTimers` collection
   - Firestore trigger detects changes and sends push update
   - Additionally, periodic updates are sent every 30 seconds

3. **Push Delivery**
   - APNs delivers update to device
   - Live Activity widget updates its content state
   - Timer continues counting accurately

## Configuration Requirements

### APNs Setup
1. Create an APNs authentication key in Apple Developer portal
2. Configure Firebase Functions with APNs credentials:
   ```bash
   firebase functions:config:set \
     apns.team_id="YOUR_TEAM_ID" \
     apns.key_id="YOUR_KEY_ID" \
     apns.topic="com.growth.push-type.liveactivity"
   ```

3. Store APNs key securely (see setup-apns.sh script)

### Firebase Setup
- Ensure Firebase Functions are deployed
- Configure proper authentication rules for Firestore
- Enable App Check for security (optional but recommended)

## Testing

1. Start a timer in the app
2. Background the app
3. Observe Live Activity continues updating on lock screen and Dynamic Island
4. Timer should continue counting for the full duration

## Troubleshooting

### Live Activity stops updating
- Check Firebase Functions logs for errors
- Verify APNs configuration is correct
- Ensure push tokens are being stored in Firestore
- Check device has network connectivity

### Push updates not received
- Verify APNs topic matches bundle ID format: `{bundle-id}.push-type.liveactivity`
- Check push token is valid and not expired
- Ensure Firebase Function has proper authentication

### Timer accuracy issues
- Push updates are sent every 30 seconds
- Widget uses system timer between updates for smooth display
- Small discrepancies (<1 second) are normal due to network latency