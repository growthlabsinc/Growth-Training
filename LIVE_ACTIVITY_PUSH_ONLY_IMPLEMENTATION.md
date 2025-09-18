# Live Activity Push-Only Implementation Guide

## Date: 2025-09-10

### Executive Summary

Per Apple's best practices from WWDC 2023, Live Activity buttons should **only** use push notifications for updates. Local updates cause conflicts, permission dialog issues, and race conditions.

## Changes Implemented

### 1. TimerControlIntent.swift
- **Removed** all local Live Activity updates
- **Kept** shared state synchronization
- **Kept** Darwin notification to main app
- Intent now returns immediately without async operations

### 2. Key Benefits
- **No permission dialog freezing** - Push updates don't trigger permission requests
- **No race conditions** - Single update path through push notifications
- **Better performance** - No conflicting local/remote updates
- **Cross-device sync** - Works with paired Apple Watch

## Firebase Function Fix Required

The "INTERNAL" error in Firebase logs indicates issues with the push notification delivery. Common causes:

### 1. Add Timeout Handling
```javascript
// In liveActivityUpdates.js
const FUNCTION_TIMEOUT = 10000; // 10 seconds

exports.updateLiveActivity = functions
  .runWith({ 
    timeoutSeconds: 30,  // Increase from default 60s
    memory: '512MB'       // Increase if needed
  })
  .https.onCall(async (data, context) => {
    // ... existing code
  });
```

### 2. Add Retry Logic
```javascript
async function sendWithRetry(notification, token, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const result = await apnProvider.send(notification, token);
      if (result.sent.length > 0) {
        return result;
      }
      if (result.failed.length > 0) {
        const failure = result.failed[0];
        if (failure.status === '410') {
          // Token is invalid, don't retry
          throw new Error('Invalid token');
        }
      }
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

### 3. Validate Payload Size
```javascript
function validatePayloadSize(contentState) {
  const payloadString = JSON.stringify(contentState);
  const sizeInBytes = new TextEncoder().encode(payloadString).length;
  
  if (sizeInBytes > 4096) {
    logger.warn(`Payload too large: ${sizeInBytes} bytes`);
    // Trim unnecessary fields
    delete contentState.debugInfo;
    delete contentState.metadata;
  }
  
  return contentState;
}
```

## Testing Protocol

### 1. Clean Install Test
```bash
# Delete app from device
# Install fresh build
# Start timer
# Lock device
# Tap pause button
# Should NOT show permission dialog (or if it does, handle gracefully)
```

### 2. Push Delivery Test
```bash
# Monitor Firebase logs
firebase functions:log --only updateLiveActivity --lines 100

# Look for:
# - "🚀 Sending Live Activity update"
# - "✅ Live Activity update sent successfully"
# - No "INTERNAL" errors
```

### 3. Console.app Monitoring
```bash
# Open Console.app
# Filter by process: "Growth"
# Look for:
# - "📤 Sending push update via Firebase"
# - "✅ Push update sent successfully"
```

## Alternative Implementation (If Push Fails)

If push notifications continue to fail, implement URL-based actions:

```swift
// In GrowthTimerWidgetLiveActivity.swift
struct ControlButton: View {
    let action: String
    let activityId: String
    
    var body: some View {
        Link(destination: URL(string: "growth://timer/\(action)/\(activityId)")!) {
            HStack {
                Image(systemName: iconName)
                Text(label)
            }
        }
        .buttonStyle(.plain)
    }
}

// In MainApp.swift
.onOpenURL { url in
    if url.scheme == "growth", 
       url.host == "timer" {
        let components = url.pathComponents
        if components.count >= 3 {
            let action = components[1]
            let activityId = components[2]
            handleTimerAction(action, activityId: activityId)
        }
    }
}
```

## Production Deployment Checklist

- [ ] Remove all local Live Activity updates from TimerControlIntent
- [ ] Deploy updated Firebase Functions with retry logic
- [ ] Test on physical device (not simulator)
- [ ] Monitor Firebase Functions logs for 24 hours
- [ ] Check crash reports for permission-related crashes
- [ ] Verify push token synchronization in Firestore

## Monitoring & Debugging

### Key Metrics to Track
1. **Push notification delivery rate** - Should be >95%
2. **Live Activity update latency** - Should be <2 seconds
3. **Permission dialog appearances** - Should be minimal
4. **Firebase Function errors** - Should be <1%

### Debug Commands
```bash
# View widget logs
log stream --predicate 'subsystem == "com.growthlabs.growthmethod.widget"'

# View Live Activity updates
log stream --predicate 'category == "LiveActivity"'

# View push notification delivery
log stream --predicate 'subsystem == "com.apple.pushkit"'
```

## Key Takeaways

1. **Apple's official recommendation**: Use push notifications exclusively for Live Activity button updates
2. **Local updates are problematic**: They cause permission dialogs, race conditions, and conflicts
3. **Firebase Functions need proper configuration**: Timeout, retry logic, and payload validation are essential
4. **Always test on physical devices**: Live Activities don't work properly in simulator

## References

- [Apple: Update Live Activities with ActivityKit push notifications](https://developer.apple.com/documentation/activitykit/updating-live-activities-with-activitykit-push-notifications)
- [WWDC23: Update Live Activities with push notifications](https://developer.apple.com/videos/play/wwdc2023/10185/)
- [Firebase: Live Activity push notifications](https://firebase.google.com/docs/cloud-messaging/ios/live-activity)