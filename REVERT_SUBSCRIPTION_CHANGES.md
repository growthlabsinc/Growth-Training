# Reverting Subscription-Based Routine Management Changes

This document lists all changes made to implement premium-only custom routine sharing, so they can be reverted if needed.

## Files Modified/Created

### 1. iOS App Files

#### **Growth/Core/Models/RoutineModel.swift**

**Added Field (Line ~89):**
```swift
public var isEnabled: Bool = true // Whether routine is accessible (disabled when subscription expires)
```

**Added to Decoder (Line ~166):**
```swift
self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
```

**Added to Encoder (Line ~197):**
```swift
try container.encode(isEnabled, forKey: .isEnabled)
```

**Added to CodingKeys enum (Line ~229):**
```swift
case isEnabled
```

**To Revert:** Remove the `isEnabled` property and all references to it in the decoder, encoder, and CodingKeys enum.

---

#### **Growth/Core/Services/RoutineService.swift**

**Modified `fetchCommunityRoutines()` method (Lines ~81-128):**
- Added `.whereField("isEnabled", isEqualTo: true)` to query (Line ~97)
- Added double-check for `isEnabled` in filtering (Lines ~111-114)

**Modified `fetchAllCommunityRoutines()` method (Lines ~130-151):**
- Added `.whereField("isEnabled", isEqualTo: true)` to query (Line ~134)
- Added filtering for enabled routines (Line ~147)

**Modified `shareRoutineWithCommunity()` method (Lines ~407-432):**
- Changed signature to include `entitlementProvider: EntitlementProvider` parameter
- Added premium subscription check (Lines ~414-423)
- Added `sharedRoutine.isEnabled = true` (Line ~432)

**Added to routine data dictionary (Line ~453):**
```swift
"isEnabled": true
```

**Added new error case to `RoutineServiceError` enum (Line ~670):**
```swift
case premiumRequiredForSharing
```

**Added error description (Lines ~679-680):**
```swift
case .premiumRequiredForSharing:
    return "Sharing routines with the community requires a Premium subscription. Upgrade to share your custom routines with others."
```

**Updated `shouldShowUpgradePrompt` (Line ~693):**
```swift
case .premiumRequired, .premiumRequiredForSharing, .trialExpired, .customRoutineLimitReached:
```

**Added new extension (Lines ~701-749):**
```swift
// MARK: - Subscription Management Methods
extension RoutineService {
    /// Disable all shared routines for a user when their subscription expires
    func disableUserSharedRoutines(userId: String) async throws { ... }

    /// Re-enable all shared routines for a user when their subscription is renewed
    func enableUserSharedRoutines(userId: String) async throws { ... }

    /// Check if a user has an active premium subscription for sharing
    func canUserShareRoutines(userId: String, entitlementProvider: EntitlementProvider) -> Bool { ... }
}
```

**To Revert:**
1. Remove the `isEnabled` filtering from all queries
2. Remove the `entitlementProvider` parameter from `shareRoutineWithCommunity()`
3. Remove the premium subscription check
4. Remove the `premiumRequiredForSharing` error case
5. Remove the entire `Subscription Management Methods` extension

---

### 2. UI Text Changes

#### **Growth/Features/Routines/Views/MethodsGuideView.swift**
**Line 58:** Changed `"Search methods..."` to `"Search exercises..."`

#### **Growth/Features/Routines/Views/CreateCustomRoutineView.swift**
**Line 1033:** Changed `"Search methods..."` to `"Search exercises..."`

#### **Growth/Features/Routines/Views/PremiumCreateCustomRoutineView.swift**
**Line 1250:** Changed `"Search methods"` to `"Search exercises"`
**Line 1264:** Changed `"methods selected"` to `"exercises selected"`
**Line 1308:** Changed `"more methods available"` to `"more exercises available"`

**To Revert:** Change all instances of "exercises" back to "methods"

---

### 3. Firebase Files

#### **firestore.indexes.json**
**Added indexes for:**
```json
{
  "collectionGroup": "routines",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "isCustom", "order": "ASCENDING"},
    {"fieldPath": "shareWithCommunity", "order": "ASCENDING"},
    {"fieldPath": "isEnabled", "order": "ASCENDING"}
  ]
}
```

**To Revert:** Remove the indexes containing `isEnabled` field. You may want to keep other indexes.

---

### 4. Firebase Functions (Created but not deployed)

#### **functions/subscriptionLifecycleHandler.js** (Created)
- Complete file can be deleted

#### **functions/subscriptionLifecycle.js** (Created)
- Complete file can be deleted

#### **functions/index.js**
**Added lines 29-34 (currently commented out):**
```javascript
// Subscription Lifecycle Management Functions
// NOTE: Commented out due to deployment timeout issues with v2 functions
// The functionality is available via manual script: scripts/manage-subscription-routines.js
// const subscriptionLifecycle = require('./subscriptionLifecycle');
// exports.handleSubscriptionStatusChange = subscriptionLifecycle.handleSubscriptionStatusChange;
// exports.dailyRoutineStatusCheck = subscriptionLifecycle.dailyRoutineStatusCheck;
```

**To Revert:** Remove these commented lines

---

### 5. Scripts (All can be deleted)

#### **scripts/manage-subscription-routines.js** (Created)
- Complete file can be deleted

#### **scripts/setup-subscription-cron.sh** (Created)
- Complete file can be deleted

#### **scripts/README-subscription-routines.md** (Created)
- Complete file can be deleted

---

### 6. Documentation (All can be deleted)

#### **SUBSCRIPTION_ROUTINE_MANAGEMENT.md** (Created)
- Complete file can be deleted

#### **REVERT_SUBSCRIPTION_CHANGES.md** (This file)
- Can be deleted after reverting

---

## Quick Revert Commands

### 1. Git Revert (if committed)
```bash
# Find the commit hash
git log --oneline | grep -i subscription

# Revert the commit
git revert <commit-hash>
```

### 2. Manual File Cleanup
```bash
# Delete created files
rm -f functions/subscriptionLifecycleHandler.js
rm -f functions/subscriptionLifecycle.js
rm -f scripts/manage-subscription-routines.js
rm -f scripts/setup-subscription-cron.sh
rm -f scripts/README-subscription-routines.md
rm -f SUBSCRIPTION_ROUTINE_MANAGEMENT.md
rm -f REVERT_SUBSCRIPTION_CHANGES.md

# Remove cron job if set up
crontab -e
# Delete line containing: manage-subscription-routines.js
```

### 3. Firestore Cleanup (Optional)
If any routines were disabled, you may want to re-enable them:
```javascript
// In Firebase Console or using Admin SDK
db.collection('routines')
  .where('isEnabled', '==', false)
  .get()
  .then(snapshot => {
    const batch = db.batch();
    snapshot.forEach(doc => {
      batch.update(doc.ref, {
        isEnabled: true,
        disabledReason: FieldValue.delete(),
        disabledAt: FieldValue.delete()
      });
    });
    return batch.commit();
  });
```

---

## Summary of Core Changes

The main changes that need reverting are:

1. **RoutineModel.swift** - Remove `isEnabled` property
2. **RoutineService.swift** - Remove subscription checks and filtering
3. **UI Text** - Change "exercises" back to "methods" (optional)
4. **Delete all created scripts and documentation files**

The most critical files to revert are:
- `Growth/Core/Models/RoutineModel.swift`
- `Growth/Core/Services/RoutineService.swift`

These contain the actual logic that restricts routine sharing to premium subscribers.

---

## Testing After Revert

After reverting:
1. Build the iOS app to ensure no compilation errors
2. Test that non-premium users can share routines again
3. Verify all routines are visible in community view
4. Check that no references to `isEnabled` remain in the codebase