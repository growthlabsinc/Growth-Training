# Epic 9: Subscription Offer Codes - Brownfield Enhancement

## Epic Goal

Enable influencer and partner marketing by implementing App Store offer code redemption, allowing distribution of promotional codes for discounted or free annual subscriptions to drive user acquisition and retention.

## Epic Description

### Existing System Context

- **Current subscription system:** SimplifiedEntitlementManagerWithTrial manages premium entitlements using StoreKit 2
- **Technology stack:** Swift/SwiftUI, StoreKit 2, Firebase Functions, App Group shared storage
- **Integration points:**
  - `SimplifiedEntitlementManagerWithTrial.swift` - entitlement state management
  - Subscription paywall UI (existing purchase flow)
  - Transaction observer for App Store purchases
  - Firebase backend for user subscription status sync

### Enhancement Details

**What's being added/changed:**

This enhancement adds support for App Store subscription offer codes, enabling the distribution of promotional codes to influencers, partners, and marketing campaigns. The feature will:

1. **In-App Redemption UI** - Add a discrete "Redeem Offer Code" entry point in the subscription paywall
2. **System Redemption Sheet** - Implement Apple's native offer code redemption sheet using `offerCodeRedemption(isPresented:onCompletion:)` (iOS 16+)
3. **Transaction Handling** - Extend existing transaction observer to detect and process offer code redemptions
4. **Receipt Validation** - Add offer code detection logic to identify `offer_code_ref_name` field in receipts
5. **Backend Integration** - Update Firebase Functions to track offer code redemptions and tie them to user accounts
6. **App Store Connect Setup** - Configure offer codes in App Store Connect for distribution

**How it integrates:**

- Extends existing `SimplifiedEntitlementManagerWithTrial` to handle offer code transactions
- Adds new UI element to subscription paywall without disrupting existing purchase flows
- Leverages existing StoreKit 2 transaction observer and receipt validation infrastructure
- Uses existing App Group storage for offer code redemption state
- Integrates with existing Firebase Functions for analytics and tracking

**Success criteria:**

- Users can redeem valid offer codes within the app successfully
- Offer code redemptions grant appropriate subscription access (discount or free trial extension)
- Invalid/expired codes show proper error messaging via Apple's system sheet
- Backend correctly identifies and tracks offer code redemptions
- Existing purchase flows remain unaffected
- Analytics track offer code redemption rates and attribution

## Apple Documentation Reference

Implementation follows Apple's official guidance:
- **Primary API:** `offerCodeRedemption(isPresented:onCompletion:)` for SwiftUI (iOS 16+)
- **Fallback API:** `presentCodeRedemptionSheet()` for iOS 14-15 compatibility
- **Receipt Field:** `offer_code_ref_name` identifies redeemed offer in transaction receipts
- **App Store Connect:** Up to 10 active offers per subscription, max 1M redemptions per app per quarter
- **Offer Types:** One-time use codes and custom codes both supported

## Stories

### Story 9.1: App Store Connect Offer Code Setup
**Goal:** Configure subscription offer codes in App Store Connect for influencer distribution

**Key tasks:**
- Create offer code configuration for annual subscription
- Generate custom codes for influencer distribution
- Document offer code management process
- Set up tracking spreadsheet for code distribution

**Acceptance criteria:**
- At least one active offer configured (e.g., "INFLUENCER_ANNUAL_FREE")
- Custom codes generated and ready for distribution
- Documentation created for creating/managing future offer codes

### Story 9.2: In-App Offer Code Redemption UI & Flow
**Goal:** Implement in-app offer code redemption using Apple's native sheet

**Key tasks:**
- Add "Redeem Offer Code" button to subscription paywall
- Implement `offerCodeRedemption(isPresented:onCompletion:)` for iOS 16+
- Add fallback `presentCodeRedemptionSheet()` for iOS 14-15
- Handle redemption completion callbacks
- Add analytics tracking for redemption attempts

**Acceptance criteria:**
- "Redeem Offer Code" button visible on paywall
- Tapping button presents Apple's native redemption sheet
- Valid codes successfully redeem and grant subscription access
- Invalid/expired codes show Apple's error messaging
- Redemption events tracked in Firebase Analytics

### Story 9.3: Offer Code Transaction Processing & Backend Integration
**Goal:** Extend transaction observer and backend to detect and process offer code redemptions

**Key tasks:**
- Extend transaction observer to detect `offer_code_ref_name` in receipts
- Update `SimplifiedEntitlementManagerWithTrial` to handle offer code transactions
- Modify Firebase Function to log offer code redemptions with metadata
- Add App Group storage for offer code redemption state
- Update receipt validation to identify offer code transactions

**Acceptance criteria:**
- Transaction observer correctly identifies offer code redemptions
- Entitlement manager grants appropriate access for offer code subscriptions
- Firebase backend logs offer code redemptions with user ID and offer reference
- Receipt validation distinguishes offer code purchases from regular purchases
- Existing subscription flows remain unaffected

## Compatibility Requirements

- [x] Existing purchase APIs remain unchanged
- [x] Current subscription paywall UI only receives additive changes (new button)
- [x] Transaction observer extends existing logic without breaking current flows
- [x] Receipt validation adds offer code detection without affecting existing validation
- [x] Performance impact is minimal (native Apple sheet handles redemption)
- [x] No database schema changes required

## Risk Mitigation

**Primary Risk:** Offer code redemption conflicts with existing trial or subscription logic

**Mitigation:**
- Apple's redemption sheet handles validation and prevents downgrades
- Existing transaction observer pattern already handles various purchase types
- Offer code transactions follow same receipt validation flow as regular purchases
- Firebase backend tracks redemption source for debugging

**Rollback Plan:**
- Remove "Redeem Offer Code" button from paywall UI
- Comment out offer code detection logic in transaction observer
- Deactivate offer codes in App Store Connect
- Existing subscription flows continue working normally

## Definition of Done

- [x] All stories completed with acceptance criteria met
- [x] Existing subscription purchase flows verified through testing
- [x] Offer code redemption tested with valid and invalid codes
- [x] Firebase analytics tracking offer code redemptions correctly
- [x] Documentation updated with offer code management process
- [x] No regression in existing subscription or trial functionality
- [x] App Store Connect offer codes configured and ready for distribution

## Validation Checklist

### Scope Validation
- [x] Epic can be completed in 3 stories maximum
- [x] No architectural documentation required (follows existing StoreKit 2 patterns)
- [x] Enhancement follows existing subscription management patterns
- [x] Integration complexity is manageable (additive changes only)

### Risk Assessment
- [x] Risk to existing system is low (Apple's API handles validation)
- [x] Rollback plan is feasible (remove UI entry point)
- [x] Testing approach covers existing subscription functionality
- [x] Team has sufficient knowledge of StoreKit 2 integration points

### Completeness Check
- [x] Epic goal is clear and achievable
- [x] Stories are properly scoped and sequenced
- [x] Success criteria are measurable
- [x] Dependencies identified (StoreKit 2, Firebase Functions)

## Technical Implementation Notes

### Key Files to Modify

1. **SimplifiedEntitlementManagerWithTrial.swift**
   - Add offer code redemption state tracking
   - Extend transaction observer to detect `offer_code_ref_name`
   - Add method to present redemption sheet

2. **Subscription Paywall View**
   - Add "Redeem Offer Code" button
   - Implement redemption sheet presentation
   - Handle redemption completion

3. **Firebase Functions**
   - Extend subscription webhook to log offer code metadata
   - Add analytics event for offer code redemptions

### Apple APIs to Use

```swift
// iOS 16+ (preferred)
.offerCodeRedemption(isPresented: $showingRedemption) { result in
    // Handle redemption result
}

// iOS 14-15 (fallback)
SKPaymentQueue.default().presentCodeRedemptionSheet()
```

### Receipt Detection

```swift
// In receipt validation
if let offerCodeRef = transaction["offer_code_ref_name"] as? String {
    // This is an offer code redemption
    // Log to Firebase with offerCodeRef for attribution
}
```

## Marketing Use Cases

**Primary use case:** Influencer partnerships
- Provide custom codes to PE community influencers (e.g., u/karlwikman, other community leaders)
- Track which influencers drive subscriptions
- Build credibility through trusted community voices

**Secondary use cases:**
- Partner marketing campaigns (PE equipment vendors, health/fitness platforms)
- Customer win-back campaigns (free month for churned users)
- Launch promotions (limited-time free annual access)

## Analytics & Tracking

Track the following events:
- `offer_code_redemption_attempted` (user tapped redeem button)
- `offer_code_redemption_completed` (successful redemption)
- `offer_code_redemption_failed` (invalid/expired code)
- `offer_code_attributed_subscription` (first session after redemption)

Metadata to capture:
- `offer_code_ref_name` (which offer was redeemed)
- `user_id` (Firebase Auth UID)
- `redemption_source` (in-app vs App Store vs URL)
- `timestamp` (when redemption occurred)

---

## Story Manager Handoff

**Story Manager Handoff:**

"Please develop detailed user stories for this brownfield epic. Key considerations:

- This is an enhancement to the existing StoreKit 2 subscription system in SimplifiedEntitlementManagerWithTrial.swift
- Integration points:
  - SimplifiedEntitlementManagerWithTrial (transaction observer, entitlement state)
  - Subscription paywall UI (add redemption entry point)
  - Firebase Functions (track offer code redemptions)
  - App Store Connect (configure offers outside of code)
- Existing patterns to follow:
  - StoreKit 2 transaction observation pattern
  - Receipt validation using existing infrastructure
  - Firebase analytics event tracking
  - App Group shared storage for state
- Critical compatibility requirements:
  - Existing subscription purchase flows must remain unchanged
  - Offer code redemption must not interfere with trial logic
  - Apple's native redemption sheet handles all validation
- Each story must include verification that existing subscription functionality remains intact

The epic should maintain subscription system integrity while enabling influencer marketing through App Store offer codes."

---

## References

- [Apple Documentation: Implementing offer codes in your app](https://developer.apple.com/documentation/storekit/in-app_purchase/subscriptions_and_offers/implementing_offer_codes_in_your_app)
- [App Store Connect: Set up offer codes](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-offer-codes)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- Growth Training: `SimplifiedEntitlementManagerWithTrial.swift`
- Growth Training: `CLAUDE.md` (subscription architecture)
