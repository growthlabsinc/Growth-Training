# Update Firebase with New Production APNs Key

## Steps to Update Firebase Secrets

### 1. Update APNS_AUTH_KEY Secret

```bash
# Read the new key file
cat /Users/tradeflowj/Downloads/AuthKey_S5JA56D56T.p8

# Copy the ENTIRE content (including BEGIN/END lines)
# Then run:
firebase functions:secrets:set APNS_AUTH_KEY
# Paste the key content when prompted
```

### 2. Update APNS_KEY_ID Secret

```bash
firebase functions:secrets:set APNS_KEY_ID
# When prompted, enter: S5JA56D56T
```

### 3. Verify APNS_TEAM_ID is Still Correct

```bash
firebase functions:secrets:access APNS_TEAM_ID
# Should show: 62T6J77P6R
```

### 4. Deploy Functions to Use New Secrets

```bash
firebase deploy --only functions:updateLiveActivity,functions:manageLiveActivityUpdates,functions:updateLiveActivityTimer,functions:collectAPNsDiagnostics
```

## Alternative: Quick Update Script

Run this script to update both secrets:

```bash
#!/bin/bash

echo "Updating APNS_AUTH_KEY..."
firebase functions:secrets:set APNS_AUTH_KEY < /Users/tradeflowj/Downloads/AuthKey_S5JA56D56T.p8

echo "Updating APNS_KEY_ID..."
echo "S5JA56D56T" | firebase functions:secrets:set APNS_KEY_ID

echo "Done! Now deploy the functions:"
echo "firebase deploy --only functions"
```

## Important Notes

1. **Production Key**: This new key (S5JA56D56T) is configured for Production, not Sandbox
2. **Both Environments**: If you need both dev and prod support, you'll need environment-specific keys
3. **Team ID**: Remains the same (62T6J77P6R) - no need to update

After updating, your Live Activities should work with production push tokens!