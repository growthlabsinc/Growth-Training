# Run APNs Diagnostic NOW

Since you started a timer, here's how to run the diagnostic:

## Option 1: From Xcode Console

1. Look at your Xcode console for the timer you just started
2. Find a log line that shows the push token, it will look like:
   ```
   [LiveActivityManager] Push token for activity: <LONG_HEX_STRING>
   ```
3. Copy that push token

## Option 2: Use Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/growth-70a85/functions)
2. Click on `collectAPNsDiagnostics` function
3. Go to the "Testing" tab
4. Enter this JSON (replace YOUR_PUSH_TOKEN with the actual token):
   ```json
   {
     "data": {
       "pushToken": "YOUR_PUSH_TOKEN",
       "activityId": "55D2E17F-D280-474F-8DFB-C55611A10120"
     }
   }
   ```
5. Click "Test the function"

## Option 3: From Terminal (if you have the token)

```bash
# Replace YOUR_PUSH_TOKEN with the actual token from Xcode console
PUSH_TOKEN="YOUR_PUSH_TOKEN"

# Run this command
curl -X POST https://collectapnsdiagnostics-i7nqvdntua-uc.a.run.app \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "pushToken": "'$PUSH_TOKEN'",
      "activityId": "55D2E17F-D280-474F-8DFB-C55611A10120"
    }
  }'
```

## View Results

After running the diagnostic:

```bash
firebase functions:log --only collectAPNsDiagnostics --lines 200
```

Look for the section between:
```
=== APNs DIAGNOSTIC DATA ===
... diagnostic information ...
=== END DIAGNOSTIC DATA ===
```

Copy this entire section and save it for Apple Developer Support.

## What the Diagnostic Will Show

- Exact timestamp and timezone
- Bundle ID: com.growthlabs.growthmethod
- Team ID and Key ID being used
- JWT token validation
- Full HTTP/2 request/response
- APNs server response and status code
- Error interpretation if it fails

This will give Apple Support everything they need to diagnose why the InvalidProviderToken error is occurring.