import AppIntents
import WidgetKit

@available(iOS 16.2, *)
struct StopTimerIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Timer"
    static var description: IntentDescription = "Stops the timer and ends the session"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        // Post notification that will be received by the app
        NotificationCenter.default.post(
            name: Notification.Name("StopTimerFromWidget"),
            object: nil,
            userInfo: ["source": "widget", "action": "stop"]
        )
        
        return .result()
    }
}