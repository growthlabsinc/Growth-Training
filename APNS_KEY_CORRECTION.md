# APNs Key Correction

## Issue Found
The Firebase functions were using a non-existent APNs key ID: `FM3P8KLCJQ`

## Your Actual Keys (from Apple Developer Portal)
1. **`5SLZB28UY2`** - "Growth Method Dev Token" (Sandbox environment)
2. **`DQ46FN4PQU`** - "Growth Method Token" (Production environment)

## Fix Applied
Updated the fallback key ID in Firebase functions from `FM3P8KLCJQ` to `DQ46FN4PQU`:

### Files Updated:
- `/functions/updateLiveActivitySimplified.js`
- `/functions/manageLiveActivityUpdates.js`

### Change:
```javascript
// Before
const KEY_ID = process.env.APNS_KEY_ID?.trim() || 'FM3P8KLCJQ';

// After
const KEY_ID = process.env.APNS_KEY_ID?.trim() || 'DQ46FN4PQU';
```

## Why The Timer Still Works
The timer works perfectly because:
1. **Native Timer APIs**: Using `ProgressView(timerInterval:)` and `Text(timerInterval:)` which update automatically
2. **Local Control**: Darwin notifications handle pause/resume without needing push
3. **Push Optional**: Push notifications are only for remote updates, not core functionality

## Next Steps
1. Deploy the updated functions:
   ```bash
   cd functions
   firebase deploy --only functions:updateLiveActivitySimplified,manageLiveActivityUpdates
   ```

2. Verify the correct key is set in Firebase secrets:
   ```bash
   firebase functions:secrets:access APNS_KEY_ID
   ```
   Should show: `DQ46FN4PQU`

3. Make sure you have the corresponding key file uploaded:
   ```bash
   firebase functions:secrets:access APNS_AUTH_KEY
   ```
   Should contain the contents of `AuthKey_DQ46FN4PQU.p8`

## Environment Consideration
Since `DQ46FN4PQU` is marked as "Production" in your Apple Developer account, you may want to:
- Use `5SLZB28UY2` for development/sandbox
- Use `DQ46FN4PQU` for production

This can be managed through environment variables or separate Firebase projects.