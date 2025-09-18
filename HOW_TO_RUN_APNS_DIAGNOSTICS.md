# How to Run APNs Diagnostics

The `collectAPNsDiagnostics` function has been deployed to help gather all the information Apple Developer Support needs to diagnose the InvalidProviderToken issue.

## Prerequisites

You need a recent push token from a Live Activity. To get one:

1. Build and run the app on a physical device (not simulator)
2. Start a timer to create a new Live Activity
3. Check the Xcode console logs for the push token

## Method 1: Using Firebase Functions Shell

```bash
# Start the Firebase functions shell
firebase functions:shell

# In the shell, call the function with a push token
collectAPNsDiagnostics({
  pushToken: "YOUR_PUSH_TOKEN_HERE",
  activityId: "test-diagnostic"
})

# Exit the shell
.exit
```

## Method 2: Using Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/growth-70a85/functions)
2. Find `collectAPNsDiagnostics` in the functions list
3. Click on it and go to the "Testing" tab
4. Enter this JSON:
   ```json
   {
     "data": {
       "pushToken": "YOUR_PUSH_TOKEN_HERE",
       "activityId": "test-diagnostic"
     }
   }
   ```
5. Click "Test the function"

## Method 3: From the iOS App

Add this temporary code to test:

```swift
// In your timer start function, after getting the push token
Functions.functions().httpsCallable("collectAPNsDiagnostics").call([
    "pushToken": tokenString,
    "activityId": activityId
]) { result, error in
    if let error = error {
        print("Diagnostic error: \(error)")
    } else if let data = result?.data as? [String: Any] {
        print("Diagnostic complete: \(data)")
    }
}
```

## Viewing the Results

After running the diagnostic:

1. Check the function logs:
   ```bash
   firebase functions:log --only collectAPNsDiagnostics --lines 100
   ```

2. Look for the section between:
   ```
   === APNs DIAGNOSTIC DATA ===
   ... diagnostic information ...
   === END DIAGNOSTIC DATA ===
   ```

3. Copy this entire section for Apple Support

## What the Diagnostic Collects

- Exact timestamp and timezone
- Bundle ID and Team ID
- JWT token validation
- Full HTTP/2 request and response headers
- Payload details
- Server IP addresses
- Error interpretation
- Request duration

## Next Steps

1. Run the diagnostic within the next 48 hours
2. Copy the diagnostic output from the logs
3. Format it according to `APPLE_DEVELOPER_RESPONSE_JON_WEBB.md`
4. Submit to Apple Developer Support with your case

## Troubleshooting

If you get an error running the diagnostic:

- **"Push token is required"**: Make sure you're passing a valid push token
- **"APNS_AUTH_KEY not found"**: The Firebase secrets might not be accessible
- **JWT generation errors**: The APNs key might be malformed

The diagnostic function includes error handling and will provide detailed error messages to help identify any issues.