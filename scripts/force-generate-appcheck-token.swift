#!/usr/bin/env swift

import Foundation

// Script to generate or retrieve App Check debug token
// This bypasses the Firebase API and works directly with UserDefaults

let bundleId = "com.growthlabs.growthmethod"
let tokenKey = "FIRAAppCheckDebugToken"

print("🔍 App Check Debug Token Helper")
print("================================")

// Create UserDefaults for the app
guard let appDefaults = UserDefaults(suiteName: bundleId) else {
    // Fall back to standard defaults
    let standardDefaults = UserDefaults.standard
    
    // Check if token exists
    if let existingToken = standardDefaults.string(forKey: tokenKey) {
        print("✅ Found existing debug token:")
        print(existingToken)
    } else {
        // Generate new token
        let newToken = UUID().uuidString
        standardDefaults.set(newToken, forKey: tokenKey)
        standardDefaults.synchronize()
        print("✅ Generated new debug token:")
        print(newToken)
    }
    
    print("\n📋 Next steps:")
    print("1. Copy the token above")
    print("2. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps")
    print("3. Click on your iOS app → Manage debug tokens")
    print("4. Add this token with a descriptive name")
    print("5. Restart the app")
    
    exit(0)
}

// Check if token exists
if let existingToken = appDefaults.string(forKey: tokenKey) {
    print("✅ Found existing debug token:")
    print(existingToken)
    print("\n💡 To copy: echo '\(existingToken)' | pbcopy")
} else {
    print("❌ No debug token found in app UserDefaults")
    print("\nGenerating a new token...")
    
    // Generate new token
    let newToken = UUID().uuidString
    
    // Try to save it
    appDefaults.set(newToken, forKey: tokenKey)
    appDefaults.synchronize()
    
    print("✅ Generated new debug token:")
    print(newToken)
    print("\n⚠️  Note: You'll need to restart the app for this token to take effect")
}

print("\n📋 Next steps:")
print("1. Copy the token above")
print("2. Go to: https://console.firebase.google.com/project/growth-70a85/appcheck/apps")
print("3. Click on your iOS app → Manage debug tokens")
print("4. Add this token with a descriptive name")
print("5. Restart the app if you generated a new token")