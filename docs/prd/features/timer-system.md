# Timer System - Feature Specification
<!-- Powered by BMAD™ Core -->

## Feature Overview

The Timer System is the core feature of the Growth Training App, providing precise timing for pelvic floor exercises with sophisticated Live Activities integration and multi-mode support.

## User Stories

### As a user, I want to:
1. Start and control timers with minimal friction
2. See my timer continue when I leave the app
3. View timer progress in Dynamic Island and Lock Screen
4. Choose between different timer modes for various exercises
5. Have audio/haptic feedback at key moments

## Functional Requirements

### Timer Modes

#### 1. Stopwatch Mode
- **Purpose**: Track total exercise duration
- **Controls**: Start, Pause, Resume, Stop
- **Display**: MM:SS format with milliseconds during active timing
- **Use Case**: Open-ended exercise sessions

#### 2. Countdown Mode
- **Purpose**: Fixed duration exercises
- **Controls**: Set duration, Start, Pause, Resume, Stop
- **Duration Range**: 1 second to 99:59 minutes
- **Alerts**: Visual, audio, and haptic at completion
- **Use Case**: Timed holds and contractions

#### 3. Interval Mode
- **Purpose**: Alternating work/rest periods
- **Configuration**:
  - Work duration (1 sec - 60 min)
  - Rest duration (1 sec - 60 min)
  - Total sets (1 - 100)
- **Indicators**: Current set, time remaining, total progress
- **Transitions**: Automatic with alerts
- **Use Case**: Kegel exercises, progressive training

### Quick Practice Timer
- **Lightweight Timer**: Simplified UI for quick sessions
- **Duration Limits**:
  - Free tier: 5 minutes maximum
  - Trial/Premium: Unlimited
- **No Live Activity**: Reduces complexity for casual use
- **One-tap Start**: Minimal setup required

## Live Activities Integration

### Dynamic Island
- **Compact View**: Timer icon + remaining time
- **Expanded View**:
  - Current time remaining
  - Pause/Resume button
  - Stop button
  - Progress indicator

### Lock Screen
- **Full Display**:
  - Exercise name
  - Timer display (native iOS timer view)
  - Current set (if interval)
  - Control buttons
- **Always Visible**: Updates even when phone is locked

### Implementation Details
- **Push-to-Start**: iOS 17.2+ feature for remote start
- **Native Timer Display**: `Text(timerInterval:)` for efficiency
- **State Management**: startedAt/pausedAt pattern for accurate pause/resume
- **Background Updates**: Via Firebase Functions and APNS

## Timer Controls

### Primary Controls
1. **Start Button**
   - Validates permissions (trial/subscription)
   - Initiates timer and Live Activity
   - Logs session start

2. **Pause/Resume Toggle**
   - Maintains accurate time tracking
   - Updates Live Activity state
   - Preserves progress

3. **Stop Button**
   - Shows confirmation for active sessions
   - Options: Log Session, Discard, Cancel
   - Cleans up Live Activity

### Secondary Controls
- **Reset**: Clear timer to initial state
- **Settings**: Quick access to timer preferences
- **Sound Toggle**: Enable/disable audio cues
- **Haptic Toggle**: Enable/disable vibration feedback

## Business Rules

### Trial System Integration
1. **Trial Period (First 3 Days)**
   - Unlimited timer duration
   - All timer modes available
   - Full Live Activity support

2. **Free Tier (Post-Trial)**
   - 5-minute maximum duration
   - Upgrade prompt when limit reached
   - Basic timer modes only

3. **Premium Tier**
   - Unlimited duration
   - All timer modes
   - Advanced features (custom intervals)

### Session Logging
- **Automatic Logging**: Sessions > 30 seconds
- **Manual Override**: User can choose not to log
- **Required Data**:
  - Start/end timestamps
  - Total duration
  - Pause count and duration
  - Exercise method (if selected)
  - Timer mode used

## Technical Implementation

### State Management
```swift
enum TimerState {
    case idle
    case running(startedAt: Date)
    case paused(startedAt: Date, pausedAt: Date, totalPauseTime: TimeInterval)
    case finished
}
```

### Live Activity Updates
```swift
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let timerState: String
        let startedAt: Date?
        let pausedAt: Date?
        let totalPauseTime: TimeInterval
        let duration: TimeInterval?
        let currentSet: Int?
        let totalSets: Int?
    }
}
```

### Performance Requirements
- **Update Frequency**: 10Hz for active display
- **Background Efficiency**: Minimal battery impact
- **Accuracy**: <10ms timing deviation
- **Launch Speed**: <500ms to timer ready

## Analytics Events

### Tracked Events
- `timer_started`: Mode, duration, method
- `timer_paused`: Duration at pause
- `timer_resumed`: Total pause time
- `timer_completed`: Total time, completion rate
- `timer_cancelled`: Time at cancel, reason
- `limit_reached`: Free tier limit hit
- `upgrade_prompted`: From timer limit

## Error Handling

### Common Scenarios
1. **Live Activity Failure**
   - Fallback to in-app timer only
   - Log error for debugging
   - Notify user if critical

2. **Background Termination**
   - Restore state on app launch
   - Reconcile with Live Activity
   - Maintain accuracy

3. **Permission Denied**
   - Explain feature limitations
   - Provide settings deep link
   - Continue with reduced functionality

## Future Enhancements

### Phase 2
- Apple Watch companion app
- Siri Shortcuts integration
- Custom alert sounds
- Timer templates/presets

### Phase 3
- Heart rate integration
- Exercise form detection (using camera)
- Social challenges
- Coaching cues during exercises

---

## Related Documentation
- [Live Activities Architecture](../../architecture/live-activities.md)
- [Subscription System](./subscription-system.md)
- [Session Logging](./progress-tracking.md)