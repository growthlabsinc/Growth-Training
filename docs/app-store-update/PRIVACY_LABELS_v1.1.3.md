# App Store Privacy Labels Configuration - v1.1.3

## ⚠️ IMPORTANT: AppsFlyer Integration Changes

With AppsFlyer SDK added in v1.1.3, privacy labels **MUST** be updated to reflect tracking.

---

## Quick Summary

**Key Changes from Previous Version:**
- ✅ **Device ID** now marked as "Used to Track You" (AppsFlyer attribution)
- ✅ **User ID** moved to "Data Linked to You" (AppsFlyer analytics)
- ✅ All other data remains "Not Linked to You"

---

## Privacy Policy & Tracking Settings

### 1. Privacy Policy URL
```
https://www.growthlabs.coach/privacy-policy
```

### 2. User Privacy Choices URL
```
Leave blank (not required)
```

---

## Data Collection Labels - CORRECT CONFIGURATION

### ✅ DATA USED TO TRACK YOU

Apple requires this section when you have `NSUserTrackingUsageDescription` in your Info.plist.

**Device ID**
- ✅ Check "Data Used to Track You"
- Purpose: **Advertising or Marketing**
- Linked to User: **NO**

**Why:** AppsFlyer uses Device ID (IDFA/IDFV) for attribution tracking to measure ad campaign effectiveness.

---

### ✅ DATA LINKED TO YOU

Data that is connected to the user's identity (by User ID).

#### 1. **User ID**
- Used for: **Analytics**, **App Functionality**, **Product Personalization**
- Examples: Anonymous user ID for session tracking

#### 2. **Email Address** (Optional - only if collected)
- Used for: **App Functionality**, **Product Personalization**
- Examples: Account email for login

#### 3. **Name** (Optional - only if collected)
- Used for: **App Functionality**, **Product Personalization**
- Examples: Display name in app

---

### ✅ DATA NOT LINKED TO YOU

Data that is not connected to user identity.

#### 1. **Health & Fitness**
- Fitness
- Used for: **App Functionality**, **Analytics**
- Examples: Workout session data, measurements (anonymized)

#### 2. **Usage Data**
- Product Interaction
- Used for: **Analytics**, **App Functionality**
- Examples: Feature usage, button taps, navigation patterns

#### 3. **Diagnostics**
- Crash Data
- Used for: **App Functionality**
- Examples: Stack traces, crash logs

- Performance Data
- Used for: **App Functionality**
- Examples: App launch time, memory usage

---

## Step-by-Step: Update Privacy Labels in App Store Connect

### Step 1: Navigate to Privacy Section
1. Go to App Store Connect
2. Select your app
3. Click on "App Privacy" in left sidebar

### Step 2: Update "Data Used to Track You"
1. Click "Edit" next to "Data Used to Track You"
2. Add **Device ID**
3. Purpose: **Advertising or Marketing**
4. Click "Save"

**Apple's Definition of Tracking:**
> Linking data collected from your app with data collected from other companies' apps or websites for advertising or advertising measurement purposes, OR sharing data with data brokers.

### Step 3: Update "Data Linked to You"
1. Click "Edit" next to "Data Linked to You"
2. Add these data types:
   - ✅ User ID
   - ✅ Email Address (if you collect it)
   - ✅ Name (if you collect it)
3. For each, select purposes:
   - Analytics
   - App Functionality
   - Product Personalization
4. Click "Save"

### Step 4: Update "Data Not Linked to You"
1. Click "Edit" next to "Data Not Linked to You"
2. Keep these data types:
   - ✅ Fitness (Health & Fitness category)
   - ✅ Product Interaction (Usage Data category)
   - ✅ Crash Data (Diagnostics category)
   - ✅ Performance Data (Diagnostics category)
3. **REMOVE** Device ID (moved to "Data Used to Track You")
4. **REMOVE** User ID (moved to "Data Linked to You")
5. Click "Save"

### Step 5: Review and Submit
1. Review all sections
2. Click "Save" at top right
3. Privacy nutrition label will update on App Store

---

## Complete Privacy Labels Checklist

### ✅ Data Used to Track You
- [x] Device ID - Advertising or Marketing

### ✅ Data Linked to You
- [x] User ID - Analytics, App Functionality, Product Personalization
- [x] Email Address - App Functionality, Product Personalization (optional)
- [x] Name - App Functionality, Product Personalization (optional)

### ✅ Data Not Linked to You
- [x] Fitness - App Functionality, Analytics
- [x] Product Interaction - Analytics, App Functionality
- [x] Crash Data - App Functionality
- [x] Performance Data - App Functionality

---

## What Changed vs Previous Version

| Data Type | v1.1.2 (Before) | v1.1.3 (After) |
|-----------|-----------------|----------------|
| Device ID | Not Linked to You | **Used to Track You** |
| User ID | Not Linked to You | **Linked to You** |
| Email Address | Not Linked to You | **Linked to You** |
| Name | Not Linked to You | **Linked to You** |
| Fitness | Not Linked to You | Not Linked to You |
| Product Interaction | Not Linked to You | Not Linked to You |
| Crash Data | Not Linked to You | Not Linked to You |
| Performance Data | Not Linked to You | Not Linked to You |

---

## Why These Changes?

### Device ID → "Used to Track You"
**Reason:** AppsFlyer uses IDFA (when user consents via ATT prompt) or IDFV (fallback) for attribution tracking. This links app installs to ad campaigns across apps/websites, which Apple defines as "tracking."

**What We Track:**
- Which ad campaign brought the user (Google, Facebook, organic)
- Install attribution
- Re-engagement attribution

**User Control:**
- Users see ATT prompt: "Allow Growth Training to track your activity across other companies' apps and websites?"
- If user taps "Ask App Not to Track" → AppsFlyer doesn't use IDFA
- App functions normally either way

### User ID → "Linked to You"
**Reason:** AppsFlyer logs events with user ID to track retention and feature usage per user.

**What We Track:**
- Session completions per user
- Subscription status per user
- Feature adoption per user

**Note:** This is anonymized in AppsFlyer (no names/emails), but it's linked to the same user across sessions.

### Email/Name → "Linked to You"
**Reason:** Used for account authentication and personalization.

**What We Collect:**
- Email: For Firebase Auth login
- Name: For display in app (optional)

---

## User-Facing Privacy Nutrition Label

After you save these changes, users will see this on the App Store:

```
App Privacy
See Details

Data Used to Track You
The following data is used to track you across apps and websites owned by other companies:
• Identifiers

Data Linked to You
The following data is collected and linked to your identity:
• Email Address
• Name
• Identifiers

Data Not Linked to You
The following data may be collected but is not linked to your identity:
• Health & Fitness
• Identifiers
• Usage Data
• Diagnostics
```

---

## App Tracking Transparency (ATT) Prompt

**Required Prompt Text:**
(Already in your Info.plist as `NSUserTrackingUsageDescription`)

```
We use your data to measure the effectiveness of our marketing and improve your experience. You can opt out anytime in Settings.
```

**When It Shows:**
- First time app is launched after install
- Before any tracking occurs
- User can choose "Allow" or "Ask App Not to Track"

**If User Opts Out:**
- AppsFlyer respects opt-out immediately
- No IDFA collected
- Attribution uses IDFV (device-level, not cross-app)
- App functionality unchanged

---

## Privacy Policy Requirements

Your privacy policy must include:

✅ **What We Collect:**
- Device identifiers (IDFA/IDFV) for attribution
- Anonymous user ID for analytics
- Email and name for account
- Session and measurement data

✅ **Why We Collect:**
- Attribution: Measure ad campaign effectiveness
- Analytics: Improve features users care about
- Functionality: Provide app services

✅ **Who We Share With:**
- AppsFlyer (analytics service provider)
- Firebase (cloud hosting, auth, database)

✅ **User Rights:**
- Opt-out of tracking via iOS Settings
- Export all data
- Delete account and all data

✅ **Data Retention:**
- AppsFlyer: 24 months (configurable)
- Firebase: Until user deletes account

---

## Compliance Notes

### GDPR (EU Users)
- ✅ Explicit consent via ATT prompt
- ✅ Right to access (data export)
- ✅ Right to deletion (account deletion)
- ✅ Data processor agreement with AppsFlyer

### CCPA (California Users)
- ✅ Opt-out mechanism (ATT prompt)
- ✅ Disclosure of data sharing (privacy policy)
- ✅ No sale of personal data

### HIPAA (Not Applicable)
- ⚠️ Measurements (length, girth) are NOT protected health information (PHI) under HIPAA
- ✅ We don't collect diagnosis, treatment, or payment info
- ✅ Not a covered entity or business associate

---

## Testing Privacy Labels

### Before Submitting to Review:
1. ✅ Update labels in App Store Connect
2. ✅ Save changes
3. ✅ Check Product Page Preview
4. ✅ Verify "Data Used to Track You" shows Device ID
5. ✅ Verify warning message disappears

### After Approval:
1. ✅ Check App Store listing shows correct privacy nutrition label
2. ✅ Test ATT prompt shows on first launch
3. ✅ Verify opt-out works (check AppsFlyer dashboard shows no IDFA)
4. ✅ Monitor for any user privacy concerns

---

## Common Questions

**Q: Why didn't we need this before?**
A: Version 1.1.2 didn't have AppsFlyer, so no cross-app tracking. Now we use AppsFlyer for attribution, which Apple defines as "tracking."

**Q: Will this hurt App Store conversion?**
A: Privacy labels are transparent and expected. Most apps have similar labels. Users who care about privacy appreciate honesty.

**Q: What if user opts out of tracking?**
A: App works normally. AppsFlyer uses IDFV instead of IDFA. We still get basic analytics, just not cross-app attribution.

**Q: Do we need to update privacy policy?**
A: Yes, privacy policy should mention AppsFlyer. Check with legal team.

**Q: Can we remove the ATT prompt?**
A: Only if you remove AppsFlyer SDK entirely. Otherwise, Apple requires the prompt.

---

## Support Article Template

For users who ask about privacy:

```
Privacy & Data Collection in Growth Training

We take your privacy seriously. Here's what we collect and why:

TRACKING (With Your Permission):
• Device ID - To measure which ads bring users to our app
• You control this via "Allow Tracking" prompt
• Opt-out anytime: Settings → Privacy → Tracking

ACCOUNT DATA (To Make the App Work):
• Email - For login and account recovery
• Display name - To personalize your experience
• Anonymous user ID - To save your progress

USAGE DATA (To Improve Features):
• Which features you use most
• Session completions and streaks
• Crash reports and performance metrics

NEVER COLLECTED:
• Your measurements are private (not shared with third parties)
• Your personal notes stay local or in your Firebase account
• We don't sell your data to anyone

Learn more: Settings → Privacy & Legal
```

---

## Next Steps

1. **Update Privacy Labels in App Store Connect** (follow steps above)
2. **Verify warning disappears** after saving
3. **Update Privacy Policy** to mention AppsFlyer (coordinate with legal)
4. **Submit v1.1.3 for review**
5. **Monitor feedback** after release for privacy concerns

---

## File History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-07 | 1.0 | Initial privacy labels guide for AppsFlyer integration | Claude Code |
