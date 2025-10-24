# Subscription-Based Routine Management Implementation

## Status: ✅ Implemented (Manual Management)

Due to Firebase Functions v2 deployment timeout issues, the automatic subscription lifecycle management has been implemented as a manual/scheduled script solution.

## What's Been Implemented

### 1. **Database Model Updates** ✅
- Added `isEnabled` field to Routine model
- Tracks whether routines are accessible based on subscription status

### 2. **iOS App Updates** ✅
- Premium-only sharing enforced in `RoutineService.swift`
- Community queries filter out disabled routines (`isEnabled: false`)
- Error handling with upgrade prompts for non-premium users

### 3. **Firestore Indexes** ✅
- Deployed indexes for efficient querying of enabled routines
- Composite indexes for:
  - `isCustom + shareWithCommunity + isEnabled`
  - `createdBy + shareWithCommunity`

### 4. **Manual Management Script** ✅
Located at: `scripts/manage-subscription-routines.js`

## How to Use the Manual Management System

### Check Service Account Key
```bash
cd scripts
ls service-account-key.json
# If missing, download from Firebase Console > Project Settings > Service Accounts
```

### Manual Commands

#### 1. Check All Users (Recommended Daily)
```bash
node manage-subscription-routines.js check
```
This will:
- Check all users' subscription status
- Disable routines for expired subscriptions
- Enable routines for renewed subscriptions

#### 2. Disable Specific User's Routines
```bash
node manage-subscription-routines.js disable USER_ID
```

#### 3. Enable Specific User's Routines
```bash
node manage-subscription-routines.js enable USER_ID
```

### Set Up Automated Daily Check (Optional)

#### Option A: Using Cron (Mac/Linux)
```bash
cd scripts
./setup-subscription-cron.sh
```
This sets up a daily check at 2 AM.

#### Option B: Manual Daily Run
Run the check command daily or when subscription changes occur:
```bash
cd scripts
node manage-subscription-routines.js check
```

## How It Works

### For Users

#### Premium Subscribers
- Can create unlimited custom routines
- Can share routines with the community
- Shared routines remain accessible to others

#### When Subscription Expires
- User's shared routines are marked as `isEnabled: false`
- Routines become inaccessible to other users
- User can still see their own routines
- Cannot share new routines

#### When Subscription Renewed
- All previously disabled routines are re-enabled
- Routines become accessible to community again
- Can share new routines again

### Technical Implementation

#### Database Fields
```javascript
{
  isEnabled: true/false,           // Whether routine is accessible
  disabledReason: 'subscription_expired',  // Why it was disabled
  disabledAt: Timestamp,           // When disabled
  enabledAt: Timestamp             // When re-enabled
}
```

#### Query Filtering
All community routine queries include:
```swift
.whereField("isEnabled", isEqualTo: true)
```

## Monitoring

### Check Logs
```bash
# If using cron job
ls -la scripts/logs/

# View latest log
tail -f scripts/logs/subscription-check-*.log
```

### Audit Trail
All enable/disable actions are logged to Firestore `audit_logs` collection with:
- Action type (routines_enabled/routines_disabled)
- User ID
- Number of routines affected
- Timestamp

## Troubleshooting

### Issue: Functions won't deploy
**Solution**: Use the manual script instead of Firebase Functions

### Issue: Routines not being disabled
**Check**:
1. User document has `isPremium: false` or `entitlements.premium: false`
2. Run `node manage-subscription-routines.js check`
3. Check audit_logs collection for errors

### Issue: Routines not being re-enabled
**Check**:
1. User document has `isPremium: true` or `entitlements.premium: true`
2. Routines have `disabledReason: 'subscription_expired'`
3. Run `node manage-subscription-routines.js enable USER_ID`

## Future Improvements

When Firebase Functions v2 deployment issues are resolved:
1. Uncomment subscription functions in `functions/index.js`
2. Deploy functions: `firebase deploy --only functions`
3. Remove cron job if set up
4. Functions will handle automatically on subscription changes

## Files Modified

- `Growth/Core/Models/RoutineModel.swift` - Added isEnabled field
- `Growth/Core/Services/RoutineService.swift` - Added subscription checks
- `firestore.indexes.json` - Added indexes for queries
- `scripts/manage-subscription-routines.js` - Manual management script
- `scripts/setup-subscription-cron.sh` - Cron job setup (optional)
- `functions/subscriptionLifecycle.js` - Firebase Functions (ready but not deployed)