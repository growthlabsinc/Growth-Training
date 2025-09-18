# APNs Setup Guide for Live Activity Push Notifications

## Prerequisites

1. Apple Developer Account with push notification capability
2. APNs Authentication Key (.p8 file) from Apple Developer Portal
3. Firebase CLI installed and logged in
4. Access to Firebase project

## Step 1: Create APNs Authentication Key

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Go to **Keys** section
4. Click **+** to create a new key
5. Enter a key name (e.g., "Growth Live Activity Push")
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue** and then **Register**
8. Download the `.p8` file (you can only download it once!)
9. Note down:
   - **Key ID** (10 characters)
   - **Team ID** (10 characters, found in your account settings)

## Step 2: Configure Firebase Functions

### Option A: Using the Setup Script (Recommended)

1. Navigate to the functions directory:
   ```bash
   cd /Users/tradeflowj/Desktop/Growth/functions
   ```

2. Run the setup script:
   ```bash
   ./setup-apns-v2.sh
   ```

3. Enter the requested information:
   - Apple Developer Team ID
   - APNs Key ID
   - Path to your .p8 file
   - Widget Bundle ID (e.g., `com.growthlabs.growthmethod.GrowthTimerWidget`)

### Option B: Manual Configuration

1. Create a `.env` file in the functions directory:
   ```bash
   cd /Users/tradeflowj/Desktop/Growth/functions
   cp .env.example .env
   ```

2. Edit `.env` and add your values:
   ```env
   APNS_TEAM_ID=YOUR_TEAM_ID
   APNS_KEY_ID=YOUR_KEY_ID
   APNS_TOPIC=com.growthlabs.growthmethod.GrowthTimerWidget.push-type.liveactivity
   APNS_AUTH_KEY="-----BEGIN PRIVATE KEY-----
   YOUR_KEY_CONTENT_HERE
   -----END PRIVATE KEY-----"
   ```

3. Set the secret in Firebase:
   ```bash
   firebase functions:secrets:set APNS_AUTH_KEY < path/to/your.p8
   ```

## Step 3: Deploy Firebase Functions

Deploy the updated functions with environment variables:

```bash
cd /Users/tradeflowj/Desktop/Growth
firebase deploy --only functions
```

## Step 4: Verify Configuration

1. Check Firebase Functions logs:
   ```bash
   firebase functions:log --only updateLiveActivityTimer,onTimerStateChange
   ```

2. Look for successful configuration messages:
   - "Successfully loaded APNs configuration"
   - Should show Key ID, Team ID, and Topic

## Step 5: Test Live Activity Push Updates

1. Start a timer in the app
2. Background the app
3. Check that:
   - Dynamic Island continues updating
   - Lock screen Live Activity continues updating
   - Firebase logs show successful push notifications

## Troubleshooting

### "APNs authentication key not configured"
- Ensure `.env` file exists with `APNS_AUTH_KEY`
- Check that the key includes BEGIN/END lines
- Verify the secret was deployed: `firebase functions:secrets:access APNS_AUTH_KEY`

### "APNs configuration incomplete"
- Check `APNS_TEAM_ID` and `APNS_KEY_ID` are set
- Ensure they are exactly 10 characters each
- Redeploy functions after setting environment variables

### Push notifications not received
1. Verify widget has push entitlement in `GrowthTimerWidget.entitlements`
2. Check that `APNS_TOPIC` matches: `{widget-bundle-id}.push-type.liveactivity`
3. Ensure device has network connectivity
4. Check Firebase logs for specific APNs error codes

### Common APNs Error Codes
- **400**: Invalid request (check payload format)
- **403**: Authentication failed (check Team ID, Key ID, and key)
- **404**: Invalid device token
- **410**: Device token no longer valid
- **429**: Too many requests (rate limiting)

## Security Notes

- Never commit `.env` files to version control
- Keep your `.p8` file secure and backed up
- Rotate APNs keys periodically
- Use Firebase secrets for production deployments