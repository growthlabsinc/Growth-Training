# Live Activity Timer - Quick Reference

## ✅ DO's

### Timer Display
```swift
// Countdown timer
Text(timerInterval: startDate...endDate, countsDown: true)

// Count-up timer
Text(startDate, style: .timer)

// Progress bar
ProgressView(timerInterval: startDate...endDate, countsDown: false)
```

### State Changes
```swift
// Pause: Set pausedAt
ContentState(pausedAt: Date())

// Resume: Adjust startedAt
ContentState(
    startedAt: oldStart.addingTimeInterval(pauseDuration),
    pausedAt: nil
)
```

### Buttons
```swift
// iOS 17+
Button(intent: TimerControlIntent(action: .pause)) { }

// iOS 16
Button(intent: TimerControlIntentLegacy(action: .pause)) { }
```

## ❌ DON'Ts

### Avoid Manual Calculations
```swift
// DON'T
let progress = elapsedTime / totalDuration
ProgressView(value: progress)

// DON'T
Timer.scheduledTimer { 
    updateLiveActivity() 
}

// DON'T
Text("\(minutes):\(seconds)")
```

### Avoid Frequent Updates
```swift
// DON'T send push every second
// DON'T update locally in a loop
// DON'T use background tasks for timer updates
```

## 🔧 Integration Points

### 1. App → Live Activity
- Start: Create activity with current date
- Pause: Update with pausedAt set
- Resume: Update with adjusted startedAt
- Stop: End activity

### 2. Live Activity → App
- AppIntent writes to App Group
- Darwin notification wakes app
- App reads action and updates state
- Single push update sent

### 3. Push Payload
```json
{
  "aps": {
    "event": "update",
    "content-state": {
      "startedAt": "ISO-8601-date",
      "pausedAt": null | "ISO-8601-date",
      "duration": 1800,
      "methodName": "Method Name",
      "sessionType": "countdown|countup"
    }
  }
}
```

## 🐛 Debug Checklist

- [ ] Real device (not simulator)
- [ ] iOS 16.2+ for push tokens
- [ ] Notifications enabled
- [ ] Live Activities enabled
- [ ] Darwin observers set up
- [ ] App Group configured
- [ ] Firebase functions deployed
- [ ] APNs certificates valid

## 📱 Test Scenarios

1. **Basic Flow**
   - Start → Run 30s → Pause → Wait 10s → Resume → Complete

2. **Background Test**
   - Start → Lock device → Wait 1 min → Check updates
   - Start → Kill app → Pause from widget → Resume

3. **Edge Cases**
   - Pause at 00:01
   - Multiple pause/resume cycles
   - Very long pause (> 1 hour)
   - Device reboot during timer

## 🚀 Performance Tips

1. **State Updates**: Only on user action
2. **Push Frequency**: Never periodic
3. **Local Storage**: App Group for IPC
4. **Wake Strategy**: Darwin notifications
5. **Battery Impact**: Minimal (system handles updates)