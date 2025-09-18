# Live Activity Integration Guide

## Overview
This guide explains how to integrate the simplified Live Activity implementation with your existing Growth timer app, following Apple's best practices.

## What's Been Created

### 1. `GrowthTimerLiveActivitySimplified.swift`
- Simplified Live Activity implementation following Apple's official guidelines
- Clean, minimal UI for Lock Screen and Dynamic Island
- Proper data size management (under 4KB limit)
- Uses native SwiftUI timer views for smooth updates

### 2. `SimplifiedLiveActivityManager.swift`
- Easy-to-use manager for Live Activity lifecycle
- Integrates with your existing `AppGroupConstants`
- Handles app crashes and cleanup gracefully
- Simple API for start, update, and stop operations

### Key Features Following Apple Best Practices:

✅ **Data Size Optimization**: Under 4KB for static + dynamic data
✅ **Proper State Management**: Uses Apple's recommended pause/resume logic
✅ **Clean UI Design**: Follows Apple's Live Activity design guidelines
✅ **Performance Optimized**: Long stale dates prevent freezing
✅ **Error Handling**: Graceful failure handling
✅ **iOS Version Support**: iOS 16.1+ with iOS 17+ App Intents

## Integration with Your Existing Timer Service

### Step 1: In your Timer Service/ViewModel
```swift
import ActivityKit

class YourTimerService {
    private let liveActivityManager = SimplifiedLiveActivityManager.shared
    
    // When starting a timer
    func startTimer(methodName: String, methodId: String) async {
        // Your existing timer logic...
        
        // Start Live Activity (iOS 16.1+)
        if #available(iOS 16.1, *) {
            do {
                let activityId = try await liveActivityManager.startActivity(
                    methodName: methodName,
                    methodId: methodId
                )
                print("Live Activity started: \(activityId)")
            } catch {
                print("Failed to start Live Activity: \(error)")
                // Continue with timer even if Live Activity fails
            }
        }
    }
    
    // When pausing/resuming timer
    func updateTimerState(isPaused: Bool, elapsedTime: TimeInterval) async {
        // Your existing timer logic...
        
        // Update Live Activity
        if #available(iOS 16.1, *) {
            await liveActivityManager.updateActivity(
                isPaused: isPaused,
                elapsedTime: elapsedTime
            )
        }
    }
    
    // When stopping timer
    func stopTimer() async {
        // Your existing timer logic...
        
        // End Live Activity
        if #available(iOS 16.1, *) {
            await liveActivityManager.endActivity()
        }
    }
}
```

### Step 2: In your App Delegate/Scene Delegate
```swift
// Handle app launches and clean up stale activities
func applicationDidFinishLaunching() {
    if #available(iOS 16.1, *) {
        Task {
            await SimplifiedLiveActivityManager.shared.cleanupStaleActivities()
            // Resume existing activity if needed
            SimplifiedLiveActivityManager.shared.resumeExistingActivity()
        }
    }
}

// Handle widget actions when app becomes active
func applicationDidBecomeActive() {
    if #available(iOS 16.1, *) {
        // Check for pending widget actions
        if let sharedDefaults = AppGroupConstants.sharedDefaults {
            if let lastAction = sharedDefaults.string(forKey: AppGroupConstants.Keys.lastTimerAction),
               let activityId = sharedDefaults.string(forKey: AppGroupConstants.Keys.currentTimerActivityId) {
                
                Task {
                    await SimplifiedLiveActivityManager.shared.handleWidgetAction(lastAction, activityId: activityId)
                    
                    // Clear the action after handling
                    sharedDefaults.removeObject(forKey: AppGroupConstants.Keys.lastTimerAction)
                }
            }
        }
    }
}
```

### Step 3: Usage Example
```swift
// Starting a timer session
func startAngionMethod() async {
    if #available(iOS 16.1, *) {
        do {
            let activityId = try await SimplifiedLiveActivityManager.shared.startActivity(
                methodName: "Angion Method 1.0",
                methodId: "am1"
            )
            print("✅ Live Activity started: \(activityId)")
        } catch {
            print("❌ Live Activity failed: \(error)")
            // Continue with normal timer functionality
        }
    }
}

// Updating timer state
func handleTimerUpdate(isPaused: Bool, elapsedTime: TimeInterval) async {
    if #available(iOS 16.1, *) {
        await SimplifiedLiveActivityManager.shared.updateActivity(
            isPaused: isPaused,
            elapsedTime: elapsedTime
        )
    }
}
```

## Important Implementation Notes

### 1. Foreground Requirement
- Live Activities can ONLY be started when your app is in the foreground
- This is an Apple requirement - no workaround exists

### 2. User Authorization
- Users can disable Live Activities in Settings
- Always check `SimplifiedLiveActivityManager.shared.areActivitiesEnabled`
- Gracefully handle disabled state

### 3. Error Handling
- Live Activities can fail for various reasons (system limits, authorization, etc.)
- Always implement proper error handling
- Your app should work normally even if Live Activities fail

### 4. Data Size Limits
- Total data (static + dynamic) must be under 4KB
- Current implementation is well under this limit
- Be careful when adding more data fields

### 5. Widget Extension Target
- Make sure `GrowthTimerLiveActivitySimplified.swift` is added to your widget extension target
- Verify the widget bundle includes the new Live Activity

## Testing Checklist

- [ ] Live Activity starts when timer begins (app in foreground)
- [ ] Timer updates correctly on Lock Screen and Dynamic Island  
- [ ] Pause/Resume buttons work from Live Activity
- [ ] Stop button ends the activity immediately
- [ ] Activity cleans up properly when app relaunches
- [ ] Works correctly when Live Activities are disabled in Settings
- [ ] Handles network connectivity issues gracefully

## Apple Best Practices Implemented

✅ **Simple, Clean Design**: Minimal UI focusing on essential information
✅ **Proper Content Hierarchy**: Most important info in compact view
✅ **Consistent Branding**: Uses your app colors and iconography  
✅ **Performance Optimized**: Long stale dates prevent UI freezing
✅ **Accessibility**: Proper labels and semantic elements
✅ **Error Resilience**: Graceful failure handling
✅ **Resource Efficient**: Minimal data transfer and processing

## Next Steps

1. Import the Live Activity files into your Xcode project
2. Add them to your widget extension target
3. Integrate the manager into your existing timer service
4. Test thoroughly on device (Simulator works too on Apple Silicon Macs)
5. Submit to App Store (Live Activities are allowed)

## Troubleshooting

**Live Activity not showing?**
- Check that `NSSupportsLiveActivities` is `true` in Info.plist (✅ already set)
- Verify user hasn't disabled Live Activities in Settings
- Ensure app is in foreground when starting
- Try rebooting device if testing on simulator

**Timer not updating?**
- Check that stale dates are set far in the future (✅ implemented)
- Verify ActivityKit updates are being called
- Check console for ActivityKit error messages

**Widget buttons not working?**
- Ensure iOS 17+ for App Intents (older versions won't show buttons)
- Verify App Group is configured correctly (✅ already configured)
- Check that intent actions are being handled in main app