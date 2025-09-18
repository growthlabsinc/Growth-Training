# Live Activity Timer - Complete Implementation Guide

## Overview
This guide provides step-by-step instructions to integrate the new simplified Live Activity timer implementation into your Growth app.

## Implementation Steps

### 1. Update TimerService.swift

Apply the changes from `TimerService_LiveActivity_Update.patch`:

```bash
# Option 1: Apply patch file
patch Growth/Features/Timer/Services/TimerService.swift < TimerService_LiveActivity_Update.patch

# Option 2: Manual updates
```

Key changes in TimerService:
1. Replace `LiveActivityManager` with `LiveActivityManagerSimplified`
2. Add Darwin notification observers
3. Update start/pause/resume/stop methods
4. Remove TimerStateSync calls

### 2. Add LiveActivityManagerSimplified to Project

```bash
# Copy the new manager to your project
cp Growth/Features/Timer/Services/LiveActivityManagerSimplified.swift \
   Growth/Features/Timer/Services/
```

Add to Xcode:
1. Open Growth.xcodeproj
2. Navigate to Growth > Features > Timer > Services
3. Right-click > Add Files to "Growth"
4. Select LiveActivityManagerSimplified.swift
5. Ensure "Growth" target is checked

### 3. Update Widget Extension

The widget bundle has already been updated to use the new implementation:
- `GrowthTimerWidget/GrowthTimerWidgetBundle.swift` now uses `GrowthTimerWidgetLiveActivityNew()`

Ensure the new files are added to widget target:
1. Select GrowthTimerWidgetLiveActivityNew.swift
2. In File Inspector, check "GrowthTimerWidget" target

### 4. Deploy Firebase Functions

```bash
cd functions

# Deploy only the new simplified function
firebase deploy --only functions:updateLiveActivitySimplified

# Or deploy all functions
firebase deploy --only functions
```

### 5. Update Firebase Function Calls

In `LiveActivityManagerSimplified.swift`, the function is already configured to use the new endpoint:
```swift
functions.httpsCallable("updateLiveActivitySimplified")
```

### 6. Configure App Group File Manager

Ensure `AppGroupFileManager.swift` is added to both app and widget targets:
1. Select AppGroupFileManager.swift
2. In File Inspector, check both "Growth" and "GrowthTimerWidget" targets

### 7. Update Info.plist

Add Live Activities support if not already present:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 8. Clean and Build

```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Build for testing
xcodebuild -project Growth.xcodeproj \
  -scheme Growth \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

## Testing Checklist

### Basic Functionality
- [ ] Timer starts and Live Activity appears
- [ ] Timer updates continuously without app running
- [ ] Pause button works from Live Activity
- [ ] Resume button works and time is correct
- [ ] Stop button dismisses Live Activity
- [ ] Dynamic Island displays correctly

### Background Behavior
- [ ] Lock device - timer continues updating
- [ ] Kill app - timer continues updating
- [ ] Kill app - pause/resume buttons still work
- [ ] Reboot device - Live Activity persists

### Push Notifications
- [ ] Push token is registered in Firestore
- [ ] State changes trigger push updates
- [ ] Firebase function logs show success

### Edge Cases
- [ ] Multiple pause/resume cycles
- [ ] Very short timers (< 1 minute)
- [ ] Very long timers (> 1 hour)
- [ ] Timer completion behavior

## Troubleshooting

### Live Activity Not Appearing
1. Check Live Activities enabled in Settings > Face ID & Passcode
2. Verify NSSupportsLiveActivities in Info.plist
3. Check ActivityAuthorizationInfo().areActivitiesEnabled
4. Must test on real device

### Buttons Not Working
1. Verify Darwin notifications are set up
2. Check App Group is configured correctly
3. Ensure AppIntent files are in both targets
4. Check Firebase function logs

### Timer Not Updating
1. Ensure using timerInterval in ProgressView/Text
2. Check start/end dates are valid
3. Verify not using manual calculations
4. Check pausedAt logic is correct

### Push Updates Failing
1. Check Firebase function deployment
2. Verify APNs configuration
3. Check push token in Firestore
4. Review function logs for errors

## Rollback Instructions

If you need to rollback:

1. **Revert Widget Bundle**:
```swift
// In GrowthTimerWidgetBundle.swift
// Change from:
GrowthTimerWidgetLiveActivityNew()
// To:
GrowthTimerWidgetLiveActivity()
```

2. **Revert TimerService**:
```bash
# Restore from backup
cp backup-live-activity-*/Timer/Services/TimerService.swift \
   Growth/Features/Timer/Services/
```

3. **Remove New Files**:
- LiveActivityManagerSimplified.swift
- GrowthTimerWidgetLiveActivityNew.swift
- TimerServiceUpdated.swift

4. **Redeploy Original Functions**:
```bash
firebase deploy --only functions:manageLiveActivityUpdates,updateLiveActivity
```

## Performance Monitoring

Monitor these metrics after deployment:
1. Battery usage in Settings > Battery
2. Firebase function execution time
3. Crash reports in Xcode Organizer
4. User feedback on timer accuracy

## Next Steps

1. A/B test with small user group
2. Monitor battery impact
3. Collect user feedback
4. Iterate on UI/UX based on usage

The new implementation should provide:
- 60fps timer updates
- Minimal battery impact
- Higher reliability
- Simpler codebase
- Native iOS timer behavior