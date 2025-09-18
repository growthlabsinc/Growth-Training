# Live Activity Enhancements Implementation Guide

## Quick Implementation Steps for 100% Apple Compliance

### 1. Add App Shortcuts Provider

Create a new file: `Growth/Features/Timer/AppShortcuts/TimerShortcutsProvider.swift`

```swift
import AppIntents
import ActivityKit

@available(iOS 17.0, *)
struct TimerShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Pause timer shortcut
        AppShortcut(
            intent: TimerControlIntent(
                action: .pause,
                activityId: "",  // Will be resolved at runtime
                timerType: "main"
            ),
            phrases: [
                "Pause \(.applicationName) timer",
                "Pause my growth timer",
                "Pause workout in \(.applicationName)"
            ],
            shortTitle: "Pause Timer",
            systemImageName: "pause.circle"
        )
        
        // Resume timer shortcut
        AppShortcut(
            intent: TimerControlIntent(
                action: .resume,
                activityId: "",
                timerType: "main"
            ),
            phrases: [
                "Resume \(.applicationName) timer",
                "Continue my growth timer",
                "Resume workout in \(.applicationName)"
            ],
            shortTitle: "Resume Timer",
            systemImageName: "play.circle"
        )
        
        // Stop timer shortcut
        AppShortcut(
            intent: TimerControlIntent(
                action: .stop,
                activityId: "",
                timerType: "main"
            ),
            phrases: [
                "Stop \(.applicationName) timer",
                "End my growth timer",
                "Finish workout in \(.applicationName)"
            ],
            shortTitle: "Stop Timer",
            systemImageName: "stop.circle"
        )
    }
}
```

### 2. Update TimerControlIntent with Dialog Response

Modify `GrowthTimerWidget/TimerControlIntent.swift`:

```swift
@available(iOS 17.0, *)
struct TimerControlIntent: LiveActivityIntent {
    // ... existing code ...
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get method name from shared state
        let appGroupIdentifier = "group.com.growthlabs.growthmethod"
        let methodName = UserDefaults(suiteName: appGroupIdentifier)?
            .string(forKey: "timerMethodName") ?? "Timer"
        
        // Update shared state
        updateSharedState()
        
        // Update Live Activity locally
        await updateLiveActivityLocally()
        
        // Notify main app
        notifyMainApp()
        
        // Create appropriate dialog based on action
        let dialog: IntentDialog
        switch action {
        case .pause:
            dialog = IntentDialog(
                full: "\(methodName) timer paused",
                supporting: "Your timer has been paused. Say 'Resume timer' to continue."
            )
        case .resume:
            dialog = IntentDialog(
                full: "\(methodName) timer resumed",
                supporting: "Your timer is now running."
            )
        case .stop:
            dialog = IntentDialog(
                full: "\(methodName) timer stopped",
                supporting: "Timer completed. Great job!"
            )
        }
        
        return .result(dialog: dialog)
    }
}
```

### 3. Add Intent Donation in TimerService

Add to `Growth/Features/Timer/Services/TimerService.swift`:

```swift
import IntentsUI

extension TimerService {
    /// Donate timer control intent to Siri for predictions
    @available(iOS 17.0, *)
    private func donateTimerIntent(action: TimerAction) {
        guard let activityId = currentActivity?.id else { return }
        
        let intent = TimerControlIntent(
            action: action,
            activityId: activityId,
            timerType: currentTimerType.rawValue
        )
        
        // Create interaction
        let interaction = INInteraction(intent: intent, response: nil)
        
        // Set properties for better predictions
        interaction.dateInterval = DateInterval(start: Date(), duration: 0)
        interaction.identifier = "\(action.rawValue)-\(activityId)"
        
        // Donate to system
        interaction.donate { error in
            if let error = error {
                logger.error("Failed to donate intent: \(error)")
            } else {
                logger.info("✅ Donated \(action.rawValue) intent to Siri")
            }
        }
    }
    
    // Call this when user performs actions
    func pause() {
        // ... existing pause logic ...
        
        if #available(iOS 17.0, *) {
            donateTimerIntent(action: .pause)
        }
    }
    
    func resume() {
        // ... existing resume logic ...
        
        if #available(iOS 17.0, *) {
            donateTimerIntent(action: .resume)
        }
    }
    
    func stop() {
        // ... existing stop logic ...
        
        if #available(iOS 17.0, *) {
            donateTimerIntent(action: .stop)
        }
    }
}
```

### 4. Add Snippet View for Visual Responses

Create `GrowthTimerWidget/TimerIntentSnippetView.swift`:

```swift
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct TimerIntentSnippetView: View {
    let action: TimerAction
    let methodName: String
    let timeRemaining: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 36))
                .foregroundColor(iconColor)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(methodName)
                    .font(.headline)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let timeRemaining = timeRemaining {
                    Text(timeRemaining)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var iconName: String {
        switch action {
        case .pause: return "pause.circle.fill"
        case .resume: return "play.circle.fill"
        case .stop: return "stop.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch action {
        case .pause: return .orange
        case .resume: return Color("MintGreen")
        case .stop: return .red
        }
    }
    
    private var statusText: String {
        switch action {
        case .pause: return "Timer Paused"
        case .resume: return "Timer Running"
        case .stop: return "Timer Completed"
        }
    }
}
```

Then update TimerControlIntent to return snippet view:

```swift
func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    // ... existing code ...
    
    // Create snippet view
    let snippet = TimerIntentSnippetView(
        action: action,
        methodName: methodName,
        timeRemaining: getFormattedTimeRemaining()
    )
    
    return .result(dialog: dialog, view: snippet)
}
```

### 5. Register App Shortcuts in Main App

Add to `Growth/Application/GrowthApp.swift`:

```swift
import AppIntents

@main
struct GrowthApp: App {
    // ... existing code ...
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    registerAppShortcuts()
                }
        }
    }
    
    private func registerAppShortcuts() {
        if #available(iOS 17.0, *) {
            // App Shortcuts are automatically registered via the provider
            // This ensures they're available immediately after app install
            _ = TimerShortcutsProvider.appShortcuts
        }
    }
}
```

### 6. Test Action Button Integration

For iPhone 15 Pro/Pro Max testing:

1. Build and install the app
2. Go to Settings → Action Button
3. Select "Shortcut" as the action
4. Choose your app's timer shortcuts
5. Test pause/resume with physical Action button

### Implementation Checklist

- [ ] Create TimerShortcutsProvider.swift
- [ ] Update TimerControlIntent with dialog responses
- [ ] Add intent donation in TimerService
- [ ] Create TimerIntentSnippetView.swift
- [ ] Register shortcuts in GrowthApp.swift
- [ ] Test with Siri ("Hey Siri, pause my Growth timer")
- [ ] Test with Shortcuts app
- [ ] Test with Action button (iPhone 15 Pro)
- [ ] Test with Spotlight search

### Expected Benefits

1. **Siri Integration**: Users can control timer with voice commands
2. **Shortcuts App**: Timer controls available in automation workflows
3. **Action Button**: Quick access on iPhone 15 Pro/Pro Max
4. **Spotlight**: Timer actions appear in search
5. **Predictive Suggestions**: iOS learns usage patterns and suggests actions

### Testing Commands

```bash
# Test Siri commands
"Hey Siri, pause my Growth timer"
"Hey Siri, resume my Growth timer"
"Hey Siri, stop my Growth timer"

# These should work after donation
"Hey Siri, pause workout"
"Hey Siri, continue timer"
```

## Notes

- App Shortcuts are available immediately after app installation
- Intent donation improves over time as users interact with the app
- Visual snippet views appear in Siri responses
- Dialog responses are spoken by Siri
- All enhancements are iOS 17.0+ only