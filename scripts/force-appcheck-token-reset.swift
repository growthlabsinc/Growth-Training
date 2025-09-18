#!/usr/bin/swift

import Foundation

// Script to force App Check token regeneration
// Run with: swift force-appcheck-token-reset.swift

print("🔄 Forcing App Check Token Reset")
print("================================")

// App Group identifier
let appGroupIdentifier = "group.com.growthlabs.growthlabsmethod.shared"

// Get App Group container
guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
    print("❌ Failed to access App Group container")
    exit(1)
}

print("📁 App Group Path: \(appGroupURL.path)")

// Clear App Check related files
let filesToDelete = [
    "app_check_token.json",
    "firebase_app_check_token",
    "app_check_debug_token",
    "firebase_tokens.plist",
    "com.firebase.appcheck.token"
]

var deletedCount = 0
for fileName in filesToDelete {
    let fileURL = appGroupURL.appendingPathComponent(fileName)
    if FileManager.default.fileExists(atPath: fileURL.path) {
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ Deleted: \(fileName)")
            deletedCount += 1
        } catch {
            print("⚠️  Failed to delete \(fileName): \(error)")
        }
    }
}

// Clear UserDefaults in App Group
if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
    let keysToRemove = [
        "firebase_app_check_token",
        "app_check_token_expiry",
        "app_check_debug_token",
        "last_app_check_fetch",
        "app_check_token_data"
    ]
    
    for key in keysToRemove {
        if sharedDefaults.object(forKey: key) != nil {
            sharedDefaults.removeObject(forKey: key)
            print("✅ Cleared UserDefaults key: \(key)")
            deletedCount += 1
        }
    }
    
    sharedDefaults.synchronize()
}

// Create reset flag
let resetFlagURL = appGroupURL.appendingPathComponent("force_app_check_reset.flag")
do {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    try timestamp.write(to: resetFlagURL, atomically: true, encoding: .utf8)
    print("✅ Created reset flag with timestamp: \(timestamp)")
} catch {
    print("⚠️  Failed to create reset flag: \(error)")
}

print("\n================================")
print("📊 Summary: Cleared \(deletedCount) cached items")
print("\n🎯 The app will generate a new App Check token on next launch")
print("\n💡 Remember to update the debug token in Firebase Console if using debug mode")