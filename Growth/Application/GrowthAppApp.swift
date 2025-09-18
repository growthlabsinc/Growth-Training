//
//  GrowthTrainingApp.swift
//  GrowthTraining
//
//  Created by Developer on 5/8/25.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth

// Darwin notification handling has been moved to TimerService to prevent duplicate handlers

@main
struct GrowthTrainingApp: App {
    // Use the UIApplicationDelegateAdaptor property wrapper to register the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Add PersistenceController from GrowthApp.swift
    // let persistenceController = PersistenceController.shared
    
    // Create AuthViewModel at app level to ensure it's available throughout the app
    @StateObject private var authViewModel = AuthViewModel()
    
    // Add ThemeManager
    @StateObject private var themeManager = ThemeManager.shared
    
    // Add BiometricService
    @StateObject private var biometricService = BiometricAuthService.shared
    
    // Simplified StoreKit 2 managers following demo pattern
    @StateObject private var entitlementManager = SimplifiedEntitlementManager()
    @StateObject private var purchaseManager: SimplifiedPurchaseManager
    
    // Track if app is locked
    @State private var isAppLocked = false

    // Set up UITabBar appearance for selected/unselected item colors
    init() {
        // Initialize StoreKit managers
        let entitlementManager = SimplifiedEntitlementManager()
        let purchaseManager = SimplifiedPurchaseManager(entitlementManager: entitlementManager)
        
        self._entitlementManager = StateObject(wrappedValue: entitlementManager)
        self._purchaseManager = StateObject(wrappedValue: purchaseManager)
        
        // Disable verbose Firebase logging
        configureFirebaseLogging()
        
        // Configure Firebase early to prevent timing warnings
        let environment = EnvironmentDetector.detectEnvironment()
        _ = FirebaseClient.shared.configure(for: environment)
        
        setupTabBarAppearance()
        
        // Darwin notification observers are now handled in TimerService to prevent duplicates
    }
    
    private func configureFirebaseLogging() {
        // Disable verbose Firebase logging in console
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        
        // Also set UserDefaults flags for Firebase components
        UserDefaults.standard.set(false, forKey: "firebase_crashlytics_collection_enabled")
        UserDefaults.standard.set(false, forKey: "firebase_analytics_collection_deactivated")
    }
    
    private func setupTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        // Use dynamic colors that will update with theme changes
        let selectedColor = UIColor { _ in
            // This will be overridden by SwiftUI's .tint modifier
            return UIColor.systemGreen
        }
        let normalColor = UIColor.systemGray
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
                    .environmentObject(entitlementManager)
                    .environmentObject(purchaseManager)
                    // .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .applyTheme() // Apply theme settings
                    .opacity(isAppLocked ? 0 : 1)
                
                // Show biometric lock view if app is locked
                if isAppLocked {
                    BiometricLockView {
                        withAnimation(.easeIn(duration: 0.3)) {
                            isAppLocked = false
                            biometricService.isUnlocked = true
                        }
                    }
                    .transition(.opacity)
                }
            }
            .task {
                // Check if app requires biometric authentication
                if biometricService.requireBiometricOnLaunch && biometricService.canUseBiometrics() {
                    isAppLocked = true
                    biometricService.isUnlocked = false
                }
            }
            .task {
                // Initialize simplified StoreKit 2 managers
                do {
                    try await purchaseManager.loadProducts()
                    await purchaseManager.updatePurchasedProducts()
                    print("✅ StoreKit initialized: \(purchaseManager.products.count) products loaded")
                } catch {
                    print("❌ StoreKit initialization failed: \(error)")
                }
            }
            .task {
                    // Ensure Firebase is initialized before checking auth
                    guard FirebaseApp.app() != nil else {
                        print("Firebase not yet initialized, skipping auth check")
                        return
                    }
                    
                    #if DEBUG
                    // Validate App Check configuration in debug builds
                    // TODO: Implement AppCheckDebugHelper if App Check validation is needed
                    // AppCheckDebugHelper.shared.validateConfiguration()
                    #endif
                    
                    // Check authentication state on app launch
                    if let currentUser = Auth.auth().currentUser {
                        print("User already authenticated: \(currentUser.uid)")
                        print("Is anonymous: \(currentUser.isAnonymous)")
                        
                        // Refresh the user's auth token to ensure it's valid
                        do {
                            _ = try await currentUser.getIDToken(forcingRefresh: true)
                            print("Successfully refreshed auth token")
                            
                        } catch {
                            print("Failed to refresh auth token: \(error.localizedDescription)")
                            
                            // Check if it's an SSL/network error
                            if let nsError = error as NSError?,
                               nsError.domain == NSURLErrorDomain,
                               nsError.code == NSURLErrorSecureConnectionFailed {
                                print("⚠️ SSL connection error - this may be a temporary network issue")
                                print("⚠️ Try: 1) Check network connection, 2) Restart simulator, 3) Test on real device")
                            }
                            
                            // Non-critical error - app can continue without token refresh
                            // Firebase will refresh the token automatically when needed
                        }
                    } else {
                        print("No user authenticated on app launch")
                        // Don't automatically sign in anonymously - let user sign in/up normally
                        // Anonymous auth was causing issues with AI Coach
                    }
                }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Additional state check when app becomes active
                // This catches cases where SceneDelegate might not be called
                TimerService.shared.checkStateOnAppBecomeActive()
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "growth" else { return }
        
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 2 else { return }
        
        switch pathComponents[1] {
        case "timer":
            // Use the new Live Activity action handler for push-based updates
            if #available(iOS 16.2, *) {
                LiveActivityActionHandler.shared.handleAction(from: url)
            } else {
                // Fallback for older iOS versions
                if pathComponents.count >= 3 {
                    // For URL-based actions, we're handling the main timer
                    let userInfo = [Notification.Name.TimerUserInfoKey.timerType: Notification.Name.TimerType.main.rawValue]
                    
                    switch pathComponents[2] {
                    case "pause":
                        NotificationCenter.default.post(name: .timerPauseRequested, object: nil, userInfo: userInfo)
                    case "stop":
                        NotificationCenter.default.post(name: .timerStopRequested, object: nil, userInfo: userInfo)
                    default:
                        break
                    }
                }
            }
        default:
            break
        }
    }
} 