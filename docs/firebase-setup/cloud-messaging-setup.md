# Firebase Cloud Messaging Setup for Growth Training

## Step 1: Select Message Type
✅ **Select "Firebase Notification messages"** (as shown in your screen)
- This allows sending push notifications to users even when they're outside the app
- Required for Live Activity updates and general notifications

## Step 2: Platform Configuration

### For iOS Setup:
1. Click "Create" after selecting Notification messages
2. You'll be taken to the Cloud Messaging dashboard
3. Navigate to Project Settings → Cloud Messaging tab

## Step 3: Apple Push Notification Service (APNs) Configuration

### Required Certificates/Keys:
You'll need ONE of the following approaches:

#### Option A: APNs Authentication Key (Recommended)
1. **Generate in Apple Developer Portal**:
   - Go to https://developer.apple.com/account
   - Navigate to Certificates, Identifiers & Profiles
   - Keys → Create a new key
   - Check "Apple Push Notifications service (APNs)"
   - Download the .p8 file (save it securely!)
   - Note the Key ID

2. **Upload to Firebase**:
   - In Firebase Console → Project Settings → Cloud Messaging
   - Under "Apple app configuration", find your iOS app
   - Click "Upload" under "APNs Authentication Key"
   - Upload the .p8 file
   - Enter Key ID and Team ID

#### Option B: APNs Certificates (Legacy)
1. Generate certificates for Development and Production
2. Upload both .p12 files to Firebase

## Step 4: iOS App Configuration

### Update iOS App Capabilities:
1. In Xcode, select your project
2. Go to "Signing & Capabilities"
3. Add the following capabilities:
   - ✅ Push Notifications
   - ✅ Background Modes
     - Enable "Remote notifications"
     - Enable "Background fetch"

### Info.plist Configuration:
Add these keys if not already present:
```xml
<key>FirebaseMessagingAutoInitEnabled</key>
<true/>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Step 5: Update Firebase Functions Secrets

Since we created dummy APNS secrets earlier, you'll need to update them with real values:

```bash
# Update with real APNS Key (from the .p8 file)
firebase functions:secrets:set APNS_AUTH_KEY --data-file=/path/to/AuthKey_XXXXXX.p8

# Update with real Key ID
echo "YOUR_KEY_ID" | firebase functions:secrets:set APNS_KEY_ID

# Update with real Team ID
echo "YOUR_TEAM_ID" | firebase functions:secrets:set APNS_TEAM_ID

# Bundle ID should already be correct
echo "com.growthlabs.growthtraining" | firebase functions:secrets:set APNS_TOPIC
```

## Step 6: Test Push Notifications

### Using Firebase Console:
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter test message details
4. Target your test device
5. Send and verify receipt

### Using Firebase Functions:
The deployed functions can now send push notifications:
```javascript
// In your Firebase Functions
const message = {
  notification: {
    title: 'Growth Training',
    body: 'Your timer has completed!'
  },
  token: userFCMToken,
  apns: {
    payload: {
      aps: {
        'content-available': 1
      }
    }
  }
};

await admin.messaging().send(message);
```

## Step 7: iOS Code Integration

### AppDelegate Setup:
```swift
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Register for push notifications
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )

        application.registerForRemoteNotifications()

        // Set messaging delegate
        Messaging.messaging().delegate = self

        return true
    }

    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Save FCM token to Firestore for this user
        print("FCM Token: \(fcmToken ?? "")")
    }
}
```

## Important Notes:

1. **Live Activities**: Require additional setup with Activity Push Token
2. **Testing**: Must use physical device (push notifications don't work in simulator)
3. **Production**: Ensure production APNs certificate/key is configured
4. **Entitlements**: Verify aps-environment is set correctly

## Troubleshooting:

### If notifications aren't received:
1. Check device has notifications enabled for app
2. Verify APNs key/certificate is uploaded correctly
3. Check FCM token is being generated
4. Review Firebase Functions logs for sending errors
5. Ensure app capabilities are configured correctly

## Next Steps:
1. Upload real APNs authentication key
2. Update Firebase secrets with real values
3. Test on physical iOS device
4. Implement FCM token management in app
5. Configure Live Activity push tokens