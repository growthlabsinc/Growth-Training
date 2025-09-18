#!/bin/bash

echo "🔍 Getting New App Check Debug Token"
echo "==================================="
echo ""
echo "Instructions:"
echo "1. First, clean and rebuild your app in Xcode"
echo "2. Run the app on simulator or device"
echo "3. Look for one of these in the console:"
echo ""
echo "   Option A - Debug token in logs:"
echo "   [AppCheck] Debug token: YOUR-TOKEN-HERE"
echo ""
echo "   Option B - Token configuration message:"
echo "   'Configure this debug token for your project: YOUR-TOKEN-HERE'"
echo ""
echo "4. Once you have the token, add it to Firebase Console:"
echo "   • Go to: https://console.firebase.google.com"
echo "   • Select your project"
echo "   • Go to App Check → Apps → Your iOS App"
echo "   • Click 'Manage debug tokens'"
echo "   • Add the new token"
echo ""
echo "🔧 To force token generation in your app, add this code:"
echo ""
cat << 'CODE'
// In your app initialization (e.g., AppDelegate or main app file)
#if DEBUG
Task {
    if let debugProvider = AppCheck.appCheck().currentProvider as? AppCheckDebugProvider {
        let token = debugProvider.currentDebugToken()
        print("🔐 App Check Debug Token: \(token ?? "not available")")
        print("Add this token to Firebase Console → App Check → Manage debug tokens")
    }
    
    // Force refresh
    do {
        let token = try await AppCheck.appCheck().token(forcingRefresh: true)
        print("✅ App Check token refreshed successfully")
    } catch {
        print("❌ Failed to refresh App Check token: \(error)")
    }
}
#endif
CODE

echo ""
echo "📱 For production builds:"
echo "   App Check will use the attestation provider automatically"
echo "   No debug tokens needed for TestFlight/App Store builds"

chmod +x "$0"