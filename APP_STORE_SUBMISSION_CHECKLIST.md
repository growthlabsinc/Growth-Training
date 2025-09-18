# App Store Submission Checklist - Binary + Subscriptions

## Critical Understanding
**Apple's Message:** Your subscriptions weren't rejected for content - they were returned because you need to submit them WITH an app binary. First-time subscription submissions MUST include the app.

## Pre-Submission Checklist

### ✅ Code Preparation
- [x] Enable paywalls: `FeatureFlags.paywallsEnabled = true` (COMPLETED)
- [ ] Test subscription purchase flow in sandbox
- [ ] Verify restore purchases functionality
- [ ] Test subscription management UI
- [ ] Ensure receipt validation works (both production and sandbox)
- [ ] Check Live Activities work with subscriptions
- [ ] Verify all 3 product IDs load correctly

### ✅ Build & Archive
```bash
# 1. Clean build folder
./XCODE_DEEP_CLEAN.sh

# 2. In Xcode:
- Select "Any iOS Device (arm64)" as build target
- Product → Archive
- Wait for archive completion
- Window → Organizer will open
```

### ✅ App Store Connect Submission

#### Step 1: Create New Version
1. Go to App Store Connect → Your App
2. Click (+) next to "iOS App"
3. Enter version number (e.g., 1.1.0)

#### Step 2: Configure Version Details
1. **What's New in This Version:**
   ```
   • New subscription options for premium features
   • AI-powered coaching system
   • Enhanced timer with Live Activities
   • Performance improvements and bug fixes
   ```

2. **Promotional Text (Optional):**
   ```
   Try Growth Premium FREE for 7 days! Unlock AI coaching, custom routines, and advanced analytics.
   ```

#### Step 3: Add In-App Purchases
1. Scroll to "In-App Purchases" section
2. Click "+" to add
3. Select all 3 subscriptions:
   - Growth Premium - Weekly
   - Growth Premium - 3 Months  
   - Growth Premium - Annual
4. Click "Done"

#### Step 4: Upload Build
1. In Xcode Organizer, click "Distribute App"
2. Select "App Store Connect"
3. Choose "Upload"
4. Follow prompts (usually accept defaults)
5. Wait for processing (~15-30 minutes)
6. Once processed, select build in App Store Connect

#### Step 5: App Review Information
```
Sign-in Required: Yes

Test Account:
Username: appreview@test.com
Password: TestPass123!

Notes:
This submission includes our subscription implementation with 3 tiers:
- Weekly ($4.99)
- 3-Month ($29.99, saves 40%)
- Annual ($49.99, saves 75%, includes 7-day trial)

To test subscriptions:
1. Launch app and complete onboarding
2. Paywall appears after initial assessment
3. Select any subscription tier
4. Use sandbox account for purchase
5. Verify access to premium features

All subscriptions auto-renew and can be managed in Settings.
Receipt validation uses production-first with sandbox fallback per Apple guidelines.
```

#### Step 6: Submit for Review
1. Review all information
2. Click "Add for Review"
3. Answer export compliance (usually "No")
4. Click "Submit for Review"

## Post-Submission

### Monitor Status
- Check email for updates
- Review typically takes 24-48 hours
- Subscriptions are reviewed WITH the app

### If Rejected
Common reasons and fixes:
1. **Missing metadata**: Add more details to subscription descriptions
2. **Unclear value**: Better explain what premium features include
3. **Technical issues**: Ensure sandbox testing works properly
4. **Guideline 3.1.2**: Ensure subscriptions work across all user's devices

### After Approval
1. Monitor subscription analytics
2. Watch for user feedback
3. Consider A/B testing pricing
4. Plan promotional campaigns

## Important URLs
- App Store Connect: https://appstoreconnect.apple.com
- Subscription Analytics: [Your App] → Analytics → Subscriptions
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/#subscriptions

## Support Contacts
If you need help:
- Apple Developer Support: https://developer.apple.com/support/
- Phone: 1-800-633-2152 (US)
- Response time: Usually within 2 business days

## Binary + Subscription Requirement
**Remember:** Apple's policy states that first-time subscription submissions MUST include:
1. A new app binary (even if just version bump)
2. All subscription products attached to that version
3. Complete review notes explaining subscription implementation

This is standard procedure - your subscriptions weren't rejected, they just need to be submitted properly with the app binary.