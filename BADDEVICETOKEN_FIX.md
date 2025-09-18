# BadDeviceToken Error Fix

## Issue
The Live Activity push updates are failing with `BadDeviceToken` error because:
1. The app is built with development provisioning profile (aps-environment = development)
2. The Firebase function tries production APNs server first
3. Development tokens cannot be used with production APNs server

## Evidence
From entitlements:
```xml
<key>aps-environment</key>
<string>development</string>
```

From Firebase logs:
```
❌ APNs error: 400 - {"reason":"BadDeviceToken"}
```

## Solution

### Option 1: Quick Fix - Try Development Server First
Modify the Firebase function to try development server first when in development:

```javascript
// In updateLiveActivity function, change line 246:
try {
  // Try development first if environment suggests it
  const isDevelopment = tokenData?.environment === 'development' || 
                       tokenData?.bundleId?.includes('.dev');
  
  await sendLiveActivityUpdate(
    finalPushToken, 
    activityId, 
    contentState, 
    null, 
    topicOverride, 
    isDevelopment // Start with dev if in development
  );
} catch (error) {
  if (error.message?.includes('BadDeviceToken')) {
    console.log('🔄 Retrying with opposite APNs endpoint...');
    await sendLiveActivityUpdate(
      finalPushToken, 
      activityId, 
      contentState, 
      null, 
      topicOverride, 
      !isDevelopment // Try opposite endpoint
    );
  } else {
    throw error;
  }
}
```

### Option 2: Store APNs Environment with Token
Better solution - store the APNs environment when saving the push token:

In LiveActivityManager.swift:
```swift
let data: [String: Any] = [
    // ... existing fields ...
    "apnsEnvironment": Bundle.main.apsEnvironment // Add this
]
```

Then use it in Firebase function to select correct server.

### Option 3: Build for Production
Build the app with production provisioning profile to match production APNs server.

## Immediate Fix
Since the app is in development, I'll implement a quick fix to prefer development APNs server.