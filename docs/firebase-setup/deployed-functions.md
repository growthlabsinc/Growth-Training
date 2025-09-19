# Deployed Firebase Functions

## Successfully Deployed Functions

### 1. generateAIResponse ✅
- **Status**: Deployed Successfully
- **Type**: Callable function (v2)
- **Region**: us-central1
- **Memory**: 256 MB
- **Purpose**: AI Coach functionality using Vertex AI
- **How to use in iOS app**:
  ```swift
  // In your iOS app
  let functions = Functions.functions()
  functions.httpsCallable("generateAIResponse").call(["prompt": userMessage]) { result, error in
      // Handle response
  }
  ```

## Function URLs

Since these are callable functions (not HTTP endpoints), they don't have direct URLs. They are accessed through the Firebase SDK.

### iOS Integration

In your iOS app, the functions are called like this:

```swift
import FirebaseFunctions

// Get a reference to the functions service
lazy var functions = Functions.functions()

// Call the generateAIResponse function
func callAICoach(prompt: String) {
    functions.httpsCallable("generateAIResponse").call(["prompt": prompt]) { result, error in
        if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                let message = error.localizedDescription
                let details = error.userInfo[FunctionsErrorDetailsKey]
                // Handle error
            }
        }
        if let result = result {
            // Process the AI response
            if let data = result.data as? [String: Any],
               let response = data["response"] as? String {
                // Use the AI response
            }
        }
    }
}
```

## Other Functions Status

The following functions exist but couldn't be updated due to trigger type conflicts:
- onTimerStateChange (needs to be deleted and recreated)
- Various Live Activity functions (need APNS keys to be functional)

## Next Steps

1. **Update iOS App Configuration**
   - Ensure the app is using the correct project ID: `growth-training-app`
   - The GoogleService-Info.plist should already be configured

2. **Test the AI Coach**
   - The generateAIResponse function is ready to use
   - It will use Vertex AI for generating responses

3. **Configure Real APNS Keys** (when available)
   - Replace dummy secrets with real Apple Push Notification Service keys
   - This will enable Live Activity updates

4. **Delete and Recreate Conflicting Functions** (if needed)
   ```bash
   # Delete function with wrong trigger type
   firebase functions:delete onTimerStateChange --project growth-training-app

   # Then redeploy
   firebase deploy --only functions:onTimerStateChange --project growth-training-app
   ```

## Monitoring

View function logs and metrics:
- Firebase Console: https://console.firebase.google.com/project/growth-training-app/functions
- Logs: `firebase functions:log --project growth-training-app`

## Important Notes

1. **Secrets**: All secrets are currently dummy values. Replace with real values when available.
2. **Vertex AI**: Requires the Vertex AI API to be enabled (already done in Story 1.3)
3. **Billing**: Functions will incur costs based on invocations and compute time
4. **Cold Starts**: First invocation after idle time may be slower