# Password Autofill Setup Guide

## Overview
This guide explains how password autofill has been configured for the Growth app to enable seamless login experiences for iOS users.

## Implementation Details

### 1. Entitlements Configuration
The app's entitlements file (`Growth.entitlements`) has been updated to include associated domains:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>webcredentials:growthtraining.com</string>
    <string>webcredentials:www.growthtraining.com</string>
</array>
```

### 2. Text Field Configuration
Both login and create account views have been configured with proper content types:

- **Email/Username Field**: `.textContentType(.username)`
- **Password Field**: `.textContentType(.password)`
- **New Password Field**: `.textContentType(.newPassword)`

### 3. Server Requirements
To complete the password autofill setup, you need to:

1. **Host the apple-app-site-association file** on your server at:
   - `https://growthtraining.com/.well-known/apple-app-site-association`
   - `https://www.growthtraining.com/.well-known/apple-app-site-association`

2. **Update the Team ID** in the apple-app-site-association.json file:
   ```json
   {
       "webcredentials": {
           "apps": ["YOUR_TEAM_ID.com.growthtraining.Growth"]
       }
   }
   ```
   Replace `YOUR_TEAM_ID` with your actual Apple Developer Team ID.

3. **Serve the file** with:
   - Content-Type: `application/json`
   - No redirects (must be served directly)
   - HTTPS only

### 4. Testing Password Autofill
1. Save a password for your domain in Safari or Settings > Passwords
2. Open the app and navigate to the login screen
3. Tap on the email or password field
4. The QuickType bar should show saved credentials
5. Tap the credential to autofill both fields

### 5. Troubleshooting
If password autofill isn't working:

1. **Verify Associated Domains**:
   - Check that the entitlements file is properly configured
   - Ensure the app ID in Apple Developer Portal has Associated Domains capability enabled

2. **Check Server Configuration**:
   - Verify the apple-app-site-association file is accessible
   - Check HTTPS certificate is valid
   - Ensure no redirects are happening

3. **Test in Safari First**:
   - Save credentials for your domain in Safari
   - Verify autofill works in Safari before testing in the app

4. **Debug with Console**:
   - Check Xcode console for associated domains errors
   - Look for "swcd" process logs in Console.app

### 6. Additional Features Implemented
- Biometric authentication integration (Face ID/Touch ID)
- "Remember me" functionality
- Proper keyboard navigation between fields