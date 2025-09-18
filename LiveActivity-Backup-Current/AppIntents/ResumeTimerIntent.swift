import AppIntents
import WidgetKit

@available(iOS 16.2, *)
struct ResumeTimerIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description: IntentDescription = "Resumes the paused timer"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        // Post notification that will be received by the app
        NotificationCenter.default.post(
            name: Notification.Name("ResumeTimerFromWidget"),
            object: nil,
            userInfo: ["source": "widget"]
        )
        
        return .result()
    }
}