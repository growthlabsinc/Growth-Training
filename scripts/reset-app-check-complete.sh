#!/bin/bash

echo "🔐 Complete App Check Reset and Setup"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Stop everything
echo "1️⃣  Stopping all Growth processes..."
pkill -f Growth || true
pkill -f "Xcode.*Growth" || true
echo -e "${GREEN}✓ Processes stopped${NC}"

# Step 2: Clear all caches
echo ""
echo "2️⃣  Clearing all Firebase and App Check caches..."

# Clear DerivedData
echo "   Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Clear module cache
echo "   Clearing module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Clear Swift Package Manager cache
echo "   Clearing SPM cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/.swiftpm

# Clear App Group
APP_GROUP="group.com.growthlabs.growthlabsmethod.shared"
APP_GROUP_PATH=~/Library/Group\ Containers/$APP_GROUP

if [ -d "$APP_GROUP_PATH" ]; then
    echo "   Clearing App Group data..."
    rm -rf "$APP_GROUP_PATH"/Firebase* 2>/dev/null
    rm -rf "$APP_GROUP_PATH"/*app_check* 2>/dev/null
    rm -rf "$APP_GROUP_PATH"/*token* 2>/dev/null
fi

echo -e "${GREEN}✓ Caches cleared${NC}"

# Step 3: Remove from Keychain
echo ""
echo "3️⃣  Removing App Check tokens from Keychain..."
echo -e "${YELLOW}   Note: You may be prompted for keychain access${NC}"

# List of possible keychain items
KEYCHAIN_ITEMS=(
    "com.firebase.appcheck"
    "com.google.firebase.appcheck"
    "FIRAppCheckToken"
    "FIRAppCheckDebugToken"
    "firebase_app_check_token"
)

for item in "${KEYCHAIN_ITEMS[@]}"; do
    security delete-generic-password -s "$item" 2>/dev/null && echo "   Removed: $item" || true
done

echo -e "${GREEN}✓ Keychain cleaned${NC}"

# Step 4: Update Firebase configuration
echo ""
echo "4️⃣  Checking Firebase configuration..."

# Check if GoogleService-Info.plist exists
PLIST_PATH="Growth/Resources/Plist/GoogleService-Info.plist"
if [ -f "$PLIST_PATH" ]; then
    echo -e "${GREEN}✓ GoogleService-Info.plist found${NC}"
    
    # Extract some key info
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$PLIST_PATH" 2>/dev/null || echo "Unknown")
    echo "   Bundle ID: $BUNDLE_ID"
else
    echo -e "${RED}✗ GoogleService-Info.plist not found!${NC}"
fi

# Step 5: Create App Check initialization enhancer
echo ""
echo "5️⃣  Creating App Check initialization enhancer..."

cat > Growth/Core/Networking/AppCheckTokenManager.swift << 'EOF'
//
//  AppCheckTokenManager.swift
//  Growth
//
//  Manages App Check token lifecycle and debugging
//

import Foundation
import FirebaseAppCheck

class AppCheckTokenManager {
    static let shared = AppCheckTokenManager()
    
    private init() {}
    
    /// Force refresh App Check token
    func forceRefreshToken() async {
        print("🔄 [AppCheck] Forcing token refresh...")
        
        // Clear any cached tokens
        clearCachedTokens()
        
        // Request new token
        do {
            let appCheck = AppCheck.appCheck()
            let token = try await appCheck.token(forcingRefresh: true)
            print("✅ [AppCheck] New token obtained")
            print("   Token: \(token.token.prefix(20))...")
            print("   Expires: \(token.expirationDate)")
            
            // Store in App Group for debugging
            if let appGroup = UserDefaults(suiteName: AppGroupConstants.identifier) {
                appGroup.set(token.token, forKey: "debug_app_check_token")
                appGroup.set(token.expirationDate, forKey: "debug_app_check_expiry")
            }
        } catch {
            print("❌ [AppCheck] Failed to refresh token: \(error)")
        }
    }
    
    /// Clear all cached App Check tokens
    func clearCachedTokens() {
        // Clear from App Group
        if let appGroup = UserDefaults(suiteName: AppGroupConstants.identifier) {
            let keysToRemove = [
                "firebase_app_check_token",
                "app_check_token_expiry",
                "app_check_debug_token",
                "debug_app_check_token",
                "debug_app_check_expiry"
            ]
            
            for key in keysToRemove {
                appGroup.removeObject(forKey: key)
            }
            appGroup.synchronize()
        }
        
        print("🧹 [AppCheck] Cached tokens cleared")
    }
    
    /// Get debug token for Firebase Console
    func getDebugToken() -> String? {
        #if DEBUG
        if let debugProvider = AppCheck.appCheck().currentProvider as? AppCheckDebugProvider {
            let token = debugProvider.currentDebugToken()
            print("🔐 [AppCheck] Debug token: \(token ?? "nil")")
            return token
        }
        #endif
        return nil
    }
}
EOF

echo -e "${GREEN}✓ AppCheckTokenManager created${NC}"

# Step 6: Show next steps
echo ""
echo "===================================="
echo -e "${GREEN}✅ App Check reset complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Open Xcode and clean build folder (Cmd+Shift+K)"
echo ""
echo "2. Reset package caches:"
echo "   File → Packages → Reset Package Caches"
echo ""
echo "3. Build and run the app"
echo ""
echo "4. In the app, you can force a new token by calling:"
echo -e "${YELLOW}   await AppCheckTokenManager.shared.forceRefreshToken()${NC}"
echo ""
echo "5. Look for the new debug token in console:"
echo "   🔐 [AppCheck] Debug token: [YOUR-NEW-TOKEN]"
echo ""
echo "6. Add the new token to Firebase Console:"
echo "   • Go to Firebase Console → App Check → Apps"
echo "   • Click on your iOS app → Manage debug tokens"
echo "   • Add the new token"
echo ""
echo -e "${YELLOW}⚠️  Important: The debug token is only for development!${NC}"
echo "   Production apps use attestation providers automatically."

# Make executable
chmod +x "$0"