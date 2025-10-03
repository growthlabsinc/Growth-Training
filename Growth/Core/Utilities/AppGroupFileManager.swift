import Foundation

/// Manages file-based communication through app group container
struct AppGroupFileManager {
    static let shared = AppGroupFileManager()
    
    private let fileName = "timer_action.json"
    
    private var containerURL: URL? {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.identifier)
        // Logger.debug("🏠 AppGroupFileManager: Container URL request for '\(AppGroupConstants.identifier)' returned: \(url?.path ?? "nil")")
        return url
    }
    
    private var actionFileURL: URL? {
        containerURL?.appendingPathComponent(fileName)
    }
    
    struct TimerAction: Codable {
        let action: String
        let timestamp: Date
        let activityId: String
        let timerType: String // "main" or "quick"
    }
    
    /// Write timer action to shared file
    func writeTimerAction(_ action: String, activityId: String, timerType: String = "main") -> Bool {
        guard let url = actionFileURL else {
            // Logger.debug("❌ AppGroupFileManager: No container URL available")
            return false
        }
        
        let timerAction = TimerAction(
            action: action,
            timestamp: Date(),
            activityId: activityId,
            timerType: timerType
        )
        
        do {
            let data = try JSONEncoder().encode(timerAction)
            try data.write(to: url, options: .atomic)
            // Logger.debug("✅ AppGroupFileManager: Wrote action '\(action)' to file")
            return true
        } catch {
            Logger.error("❌ AppGroupFileManager: Failed to write action: \(error)")
            return false
        }
    }
    
    /// Read timer action from shared file
    func readTimerAction() -> TimerAction? {
        guard let containerURL = containerURL else {
            // Logger.debug("❌ AppGroupFileManager: Container URL is nil")
            return nil
        }
        
        // Logger.debug("📁 AppGroupFileManager: Looking for files in: \(containerURL.path)")
        
        guard let url = actionFileURL else {
            // Logger.debug("❌ AppGroupFileManager: Action file URL is nil")
            return nil
        }
        
        // Logger.debug("📄 AppGroupFileManager: Checking file at: \(url.path)")
        
        // List all files in container directory for debugging
        do {
            let _ = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
            // Logger.debug("📂 AppGroupFileManager: Files in container: \(files.map { $0.lastPathComponent })")
        } catch {
            Logger.error("❌ AppGroupFileManager: Failed to list directory contents: \(error)")
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            // Logger.debug("ℹ️ AppGroupFileManager: No action file exists at \(url.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            // Logger.debug("📊 AppGroupFileManager: Read data size: \(data.count) bytes")
            
            let action = try JSONDecoder().decode(TimerAction.self, from: data)
            // Logger.debug("✅ AppGroupFileManager: Read action '\(action.action)' from file")
            return action
        } catch {
            Logger.error("❌ AppGroupFileManager: Failed to read action: \(error)")
            Logger.error("❌ AppGroupFileManager: Error type: \(type(of: error))")
            Logger.error("❌ AppGroupFileManager: Error localized: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear the timer action file
    func clearTimerAction() {
        guard let url = actionFileURL else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
            Logger.debug("✅ AppGroupFileManager: Cleared action file")
        } catch {
            Logger.error("ℹ️ AppGroupFileManager: No file to clear: \(error)")
        }
    }
}