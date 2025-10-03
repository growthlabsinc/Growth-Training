//
//  AppCheckProviderFactory.swift
//  Growth
//
//  Created by Developer on 7/16/25.
//

import Foundation
import FirebaseAppCheck
import Firebase

/// Factory class for creating App Check providers with App Attest (iOS 14+) or Device Check fallback
class AppAttestAppCheckFactory: NSObject, AppCheckProviderFactory {
    /// Create an App Check provider based on iOS version
    /// - Parameter app: Firebase app instance
    /// - Returns: App Attest provider for iOS 14+ or Device Check provider for earlier versions
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            // Use App Attest for iOS 14+
            return AppAttestProvider(app: app)
        } else {
            // Fall back to Device Check for earlier versions
            return DeviceCheckProvider(app: app)
        }
    }
}

/// Factory class for creating App Check providers with Device Check
class DeviceCheckAppCheckFactory: NSObject, AppCheckProviderFactory {
    /// Create a device check provider for App Check
    /// - Parameter app: Firebase app instance
    /// - Returns: Device check provider
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return DeviceCheckProvider(app: app)
    }
}

/// Debug provider factory for Firebase App Check in development
class DebugAppCheckFactory: NSObject, AppCheckProviderFactory {
    /// Create a debug provider for App Check
    /// - Parameter app: Firebase app instance
    /// - Returns: Debug provider
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppCheckDebugProvider(app: app)
    }
} 