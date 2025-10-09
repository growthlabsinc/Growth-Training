# Subscription-Based Routine Management

## Overview

This system ensures that **only premium subscribers can share custom routines** with the community. When a premium subscription expires, all shared routines from that user are automatically disabled and become inaccessible to other users. When the subscription is renewed, the routines are automatically re-enabled.

## Implementation Status

### ✅ Completed
1. **Model Updates** - Added `isEnabled` field to Routine model
2. **Service Layer** - Added subscription checks and filtering for disabled routines
3. **Firestore Indexes** - Deployed indexes for efficient querying
4. **Manual Management Script** - Created script for manual routine management

### ⚠️ Pending
- **Automatic Firebase Functions** - Functions have module loading issues, need debugging

## Manual Management

Until the automatic functions are deployed, use the management script:

```bash
cd scripts

# Check service account key exists
ls service-account-key.json

# Disable routines when subscription expires
node manage-subscription-routines.js disable USER_ID

# Enable routines when subscription renewed
node manage-subscription-routines.js enable USER_ID

# Check all users and update statuses
node manage-subscription-routines.js check
```

## How It Works

### For Premium Users
- Can create and share unlimited custom routines
- Routines remain accessible to community while subscription active
- All sharing features available

### When Subscription Expires
- User's shared routines are marked as `isEnabled: false`
- Routines become inaccessible to other users
- Routines remain in database but are filtered out from community views
- User can still see their own routines

### When Subscription Renewed
- All previously disabled routines are re-enabled
- Routines become accessible to community again
- No data loss - everything restored to previous state

## Technical Details

### Database Fields
- `isEnabled` - Boolean flag on each routine
- `disabledReason` - Tracks why routine was disabled
- `disabledAt` - Timestamp when disabled
- `enabledAt` - Timestamp when re-enabled

### Queries Updated
All community routine queries now filter by `isEnabled: true`:
```swift
.whereField("isCustom", isEqualTo: true)
.whereField("shareWithCommunity", isEqualTo: true)
.whereField("isEnabled", isEqualTo: true)
```

### Error Messages
- "Sharing routines with the community requires a Premium subscription"
- Shows upgrade prompt to non-premium users

## Future Improvements

1. **Fix Firebase Functions** - Debug module loading timeout issue
2. **Add Grace Period** - Allow 3-7 days before disabling routines
3. **Email Notifications** - Notify users when routines are disabled/enabled
4. **Dashboard Stats** - Show creators how many routines are affected

## Testing

1. Create test user with premium subscription
2. Have them create and share a custom routine
3. Remove premium status from user document
4. Run `node manage-subscription-routines.js check`
5. Verify routine is disabled
6. Restore premium status
7. Run check again
8. Verify routine is re-enabled