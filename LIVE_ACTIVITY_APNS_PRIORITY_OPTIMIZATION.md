# Live Activity APNs Priority Optimization

## Date: 2025-09-10

## Overview
Implemented smart APNs priority selection to prevent Live Activity update throttling while maintaining responsive user experience.

## Apple's APNs Budget System

### Priority Levels
- **Priority 10 (High)**: Immediate delivery, counts toward hourly budget
- **Priority 5 (Low)**: Can be delayed, does NOT count toward budget

### Budget Limits
- Apple enforces an hourly budget for high-priority updates
- Exceeding the budget causes throttling
- Low-priority updates have no budget limit

## Implementation Strategy

### 1. Event Classification

#### Critical Events (Always Priority 10)
- `stop` - Timer completion
- `start` - Timer initiation  
- `complete` - Session finished

These events require immediate user attention and should never be delayed.

#### Important Events (Mixed Priority)
- `pause` - User pauses timer
- `resume` - User resumes timer

Strategy with frequent pushes enabled:
- 2 out of 3 updates use priority 10 (immediate)
- 1 out of 3 uses priority 5 (can be delayed)
- This provides 66% immediate updates while conserving budget

Strategy with frequent pushes disabled:
- First 5 updates per session use priority 10
- Subsequent updates use priority 5
- Ensures critical initial updates are immediate

#### Regular Events (Always Priority 5)
- `update` - Progress updates
- `progress` - Timer ticks

These can be slightly delayed without impacting UX.

### 2. Frequent Updates Configuration

#### Info.plist Keys Added
```xml
<!-- Main App Info.plist -->
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>

<!-- Widget Extension Info.plist -->
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

This allows the app to receive more frequent updates when needed (e.g., sports apps, workout timers).

### 3. Client-Side Detection

#### Monitor User Settings
```swift
// Check if frequent pushes are enabled
self.frequentPushesEnabled = Activity<TimerActivityAttributes>.frequentPushesEnabled

// Observe setting changes
for await enabled in Activity<TimerActivityAttributes>.frequentPushEnablementUpdates {
    self.frequentPushesEnabled = enabled
    // Notify server about change
}
```

#### Store in Multiple Locations
- Memory cache for fast access
- UserDefaults for persistence
- Firebase for server-side awareness

### 4. Server-Side Priority Logic

```javascript
// Firebase Function Enhancement
if (criticalEvents.includes(eventType)) {
    apnsPriority = '10'; // Always high
} else if (importantEvents.includes(eventType)) {
    if (hasFrequentPushesEnabled) {
        // Mixed strategy: 66% high, 33% low
        apnsPriority = (updateCount % 3 === 0) ? '5' : '10';
    } else {
        // Conservative: First 5 high, rest low
        apnsPriority = sessionUpdateCount <= 5 ? '10' : '5';
    }
} else {
    apnsPriority = '5'; // Regular updates always low
}
```

## Benefits

### 1. Throttling Prevention
- Strategic use of priority 5 prevents hitting budget limits
- Critical events still delivered immediately
- System can handle unlimited pause/resume cycles

### 2. Battery Efficiency
- Lower priority updates consume less battery
- System can batch low-priority updates
- Reduced network wake-ups

### 3. User Experience
- Critical updates (stop/start) always immediate
- Most pause/resume actions feel instant (66%)
- Graceful degradation when frequent pushes disabled

### 4. Adaptive Behavior
- Adjusts strategy based on user settings
- Server aware of client capabilities
- Automatic fallback for conservative users

## Testing Recommendations

### 1. Budget Testing
```bash
# Test rapid pause/resume (20+ cycles in 5 minutes)
# Should not experience throttling with new logic
```

### 2. Priority Verification
```bash
# Check Firebase logs for priority selection
firebase functions:log --lines 100 | grep "APNs Priority"
```

### 3. Settings Toggle
1. Disable frequent pushes in iOS Settings
2. Verify conservative priority strategy activates
3. Re-enable and verify normal strategy resumes

## Monitoring

### Key Metrics
1. **Throttling Rate**: Should be near 0%
2. **Update Latency**: 
   - Priority 10: < 1 second
   - Priority 5: < 5 seconds
3. **Budget Usage**: Should stay well below limit
4. **User Settings**: Track % with frequent pushes enabled

### Log Patterns
```
📊 APNs Priority: 10 for event: pause    # Immediate
📊 APNs Priority: 10 for event: resume   # Immediate  
📊 APNs Priority: 5 for event: pause     # Can delay (every 3rd)
⚠️ Frequent pushes disabled by user     # Conservative mode
```

## Future Enhancements

### 1. Dynamic Budget Tracking
- Track actual budget usage
- Adjust strategy based on remaining budget
- Reset counters hourly

### 2. User Activity Patterns
- Learn user's typical pause/resume frequency
- Adjust priority strategy accordingly
- Optimize for individual usage

### 3. Time-Based Priority
- Higher priority during active hours
- Lower priority during night/inactive times
- Consider user's timezone

## References

- [Apple: Determine the update frequency](https://developer.apple.com/documentation/activitykit/updating-and-ending-your-live-activity-with-activitykit-push-notifications#Determine-the-update-frequency)
- [Apple: NSSupportsLiveActivitiesFrequentUpdates](https://developer.apple.com/documentation/bundleresources/information_property_list/nssupportsliveactivitiesfrequentupdates)
- [APNs Headers Reference](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns)

## Summary

The implementation provides:
- ✅ Smart priority selection preventing throttling
- ✅ Adaptive behavior based on user settings
- ✅ Maintains responsive UX for critical events
- ✅ Efficient budget usage with mixed strategy
- ✅ Full compliance with Apple's guidelines