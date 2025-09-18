# Frequent Pushes API Availability Fix

## Date: 2025-09-10

### Error Fixed
```
Type 'Activity<TimerActivityAttributes>' has no member 'frequentPushEnablementUpdates'
```

### Root Cause
The `frequentPushEnablementUpdates` and `frequentPushesEnabled` APIs are only available in iOS 17.2+, not iOS 16.2+ as originally coded.

## API Availability

### iOS 17.2+ APIs
- `Activity.frequentPushesEnabled` - Check if user enabled frequent updates
- `Activity.frequentPushEnablementUpdates` - Observe setting changes

### iOS 16.2+ Support
- `NSSupportsLiveActivitiesFrequentUpdates` Info.plist key still works
- The system handles frequent updates automatically
- No runtime API to check user preference

## Implementation Strategy

### 1. Conditional Compilation
```swift
@available(iOS 16.2, *)
private func observeFrequentPushesSettings() {
    if #available(iOS 17.2, *) {
        // Use iOS 17.2+ APIs
        self.frequentPushesEnabled = Activity<TimerActivityAttributes>.frequentPushesEnabled
        
        // Observe changes
        for await enabled in Activity<TimerActivityAttributes>.frequentPushEnablementUpdates {
            // Handle setting changes
        }
    } else {
        // For iOS 16.2 - 17.1, assume enabled
        self.frequentPushesEnabled = true
    }
}
```

### 2. Graceful Degradation
- **iOS 17.2+**: Full functionality with user preference detection
- **iOS 16.2-17.1**: Assume frequent pushes enabled, rely on Info.plist key
- **iOS 16.0-16.1**: Basic Live Activity support without frequent updates

### 3. Computed Property Fix
```swift
var isFrequentPushesEnabled: Bool {
    if #available(iOS 17.2, *) {
        return Activity<TimerActivityAttributes>.frequentPushesEnabled
    } else {
        return self.frequentPushesEnabled // Default to true
    }
}
```

## Testing Matrix

| iOS Version | Frequent Updates Support | Runtime Detection |
|------------|-------------------------|------------------|
| 16.0-16.1  | ❌ No                    | ❌ No            |
| 16.2-17.1  | ✅ Yes (Info.plist only) | ❌ No            |
| 17.2+      | ✅ Yes (Full)            | ✅ Yes           |

## Info.plist Configuration
Still required for all iOS versions that support it:
```xml
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

## Server-Side Handling
The Firebase function receives `frequentPushesEnabled` parameter:
- **iOS 17.2+**: Actual user preference
- **iOS 16.2-17.1**: Always `true` (assumed)
- Adjusts APNs priority accordingly

## User Experience

### iOS 17.2+ Users
- Can control setting in Settings → App → Live Activities
- App detects and respects preference
- Shows prompt if disabled

### iOS 16.2-17.1 Users
- Frequent updates work automatically
- No user-facing setting
- Optimal experience by default

### iOS 16.0-16.1 Users
- Basic Live Activity support
- Standard update frequency
- No frequent updates option

## Summary
The fix ensures compatibility across all iOS versions while leveraging advanced features where available. The app gracefully degrades on older iOS versions while providing the best experience on iOS 17.2+.