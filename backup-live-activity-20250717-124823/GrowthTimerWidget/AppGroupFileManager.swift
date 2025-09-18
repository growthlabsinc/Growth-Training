import Foundation

/// Manages file-based communication through app group container
struct AppGroupFileManager {
    static let shared = AppGroupFileManager()
    
    private let fileName = "timer_action.json"
    
    private var containerURL: URL? {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.identifier)
        print("🏠 AppGroupFileManager: Container URL request for '\(AppGroupConstants.identifier)' returned: \(url?.path ?? "nil")")
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
        print("📝 AppGroupFileManager: Attempting to write action '\(action)'")
        
        guard let containerURL = containerURL else {
            print("❌ AppGroupFileManager: Container URL is nil")
            return false
        }
        
        print("📁 AppGroupFileManager: Container URL: \(containerURL.path)")
        
        guard let url = actionFileURL else {
            print("❌ AppGroupFileManager: Action file URL is nil")
            return false
        }
        
        print("📄 AppGroupFileManager: File URL: \(url.path)")
        
        // Ensure directory exists
        do {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
            print("✅ AppGroupFileManager: Directory exists or created")
        } catch {
            print("❌ AppGroupFileManager: Failed to create directory: \(error)")
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
            print("📊 AppGroupFileManager: Encoded data size: \(data.count) bytes")
            
            try data.write(to: url, options: .atomic)
            print("✅ AppGroupFileManager: Wrote action '\(action)' to file at \(url.path)")
            
            // Verify the file was written
            if FileManager.default.fileExists(atPath: url.path) {
                print("✅ AppGroupFileManager: File verified to exist")
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                print("📏 AppGroupFileManager: File size: \(attributes?[.size] ?? "unknown")")
            } else {
                print("❌ AppGroupFileManager: File does not exist after write!")
            }
            
            return true
        } catch {
            print("❌ AppGroupFileManager: Failed to write action: \(error)")
            print("❌ AppGroupFileManager: Error type: \(type(of: error))")
            print("❌ AppGroupFileManager: Error localized: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Read timer action from shared file
    func readTimerAction() -> TimerAction? {
        guard let url = actionFileURL else {
            print("❌ AppGroupFileManager: No container URL available")
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("ℹ️ AppGroupFileManager: No action file exists")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let action = try JSONDecoder().decode(TimerAction.self, from: data)
            print("✅ AppGroupFileManager: Read action '\(action.action)' from file")
            return action
        } catch {
            print("❌ AppGroupFileManager: Failed to read action: \(error)")
            return nil
        }
    }
    
    /// Clear the timer action file
    func clearTimerAction() {
        guard let url = actionFileURL else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("✅ AppGroupFileManager: Cleared action file")
        } catch {
            print("ℹ️ AppGroupFileManager: No file to clear: \(error)")
        }
    }
}