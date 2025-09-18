# APNs Development Server Update

## Summary
Updated all Firebase functions to use the development APNs server (`api.development.push.apple.com`) instead of the production server (`api.push.apple.com`) since the APNs key `55LZB28UY2` is a development/sandbox key.

## Files Updated

### 1. `/functions/liveActivityUpdates.js`
- Changed `config.APNS_HOST_PROD` from `'api.push.apple.com'` to `'api.development.push.apple.com'`
- Changed `config.APNS_HOST_DEV` from `'api.push.apple.com'` to `'api.development.push.apple.com'`

### 2. `/functions/collectAPNsDiagnostics.js`
- Updated `http2.connect()` URL from `'https://api.push.apple.com:443'` to `'https://api.development.push.apple.com:443'`

### 3. `/functions/manageLiveActivityUpdates.js`
- Changed `APNS_HOST` default value from `'api.push.apple.com'` to `'api.development.push.apple.com'`

### 4. `/functions/apnsHelper.js`
- Updated `getAPNsHost()` function to always return `'api.development.push.apple.com'`

### 5. `/functions/test-apns-direct.js`
- Changed `apnsHost` from `'api.push.apple.com'` to `'api.development.push.apple.com'`

### 6. `/functions/liveActivityUpdates.backup.js`
- Changed `APNS_HOST` from `'api.push.apple.com'` to `'api.development.push.apple.com'`

## Why This Change Was Necessary

Apple requires that:
- Development/sandbox APNs keys must connect to `api.development.push.apple.com`
- Production APNs keys must connect to `api.push.apple.com`

Since the key `55LZB28UY2` is a development/sandbox key, all connections must use the development server. Using the wrong server results in authentication errors (403 Forbidden).

## Next Steps

1. Deploy the updated functions to Firebase:
   ```bash
   cd functions
   firebase deploy --only functions
   ```

2. Test Live Activity updates with the development server

3. When ready for production:
   - Create a production APNs key in Apple Developer Console
   - Update the Firebase secrets with the production key
   - Revert these changes to use `api.push.apple.com`

## Important Notes

- This configuration is correct for development and testing
- For App Store distribution, you'll need a production APNs key
- The development server works with apps built with development provisioning profiles
- Push tokens from TestFlight or App Store apps won't work with the development server