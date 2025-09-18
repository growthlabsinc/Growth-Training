import AppIntents
import WidgetKit

@available(iOS 16.2, *)
struct PauseTimerIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description: IntentDescription = "Pauses the current timer"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        // Post notification that will be received by the app
        NotificationCenter.default.post(
            name: Notification.Name("PauseTimerFromWidget"),
            object: nil,
            userInfo: ["source": "widget"]
        )
        
        return .result()
    }
}