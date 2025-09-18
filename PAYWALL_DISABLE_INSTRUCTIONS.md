# Paywall Disable Instructions for App Store Approval

## Overview
To address the App Store rejection regarding unavailable subscriptions (Guideline 2.1), we have temporarily disabled all paywall presentations while keeping the code intact for easy re-enabling once subscriptions are approved.

## What Was Changed

### 1. Created Feature Flag System
- **File**: `Growth/Core/Configuration/FeatureFlags.swift`
- **Purpose**: Centralized control for enabling/disabling paywalls
- **Master Flag**: `paywallsEnabled = false`

### 2. Modified Onboarding Flow
- **File**: `Growth/Features/Onboarding/ViewModels/OnboardingViewModel.swift`
- **Change**: `advance()` function now skips the paywall step when feature flag is disabled
- **Effect**: Users go directly from Initial Assessment to Routine Goal Selection

### 3. Hidden Subscription Section in Settings
- **File**: `Growth/Features/Settings/SettingsView.swift`
- **Changes**: 
  - Wrapped subscription section with `if FeatureFlags.showSubscriptionInSettings`
  - Modified sheet presentation to respect feature flag

### 4. Disabled Paywall Coordinator
- **File**: `Growth/Core/Services/PaywallCoordinator.swift`
- **Change**: `presentPaywall()` returns early when feature flag is disabled
- **Effect**: All paywall presentation attempts are silently ignored

### 5. Disabled Feature Gate Upgrade Prompts
- **File**: `Growth/Core/Views/Components/FeatureGateView.swift`
- **Change**: Sheet presentation respects feature flag
- **Effect**: Upgrade prompts won't show even when features are gated

## How to Re-Enable Paywalls

Once your subscriptions are approved by Apple:

1. Open `Growth/Core/Configuration/FeatureFlags.swift`
2. Change `paywallsEnabled` from `false` to `true`:
   ```swift
   static let paywallsEnabled = true  // Changed from false
   ```
3. Rebuild and submit the app

## All Affected Areas

When `paywallsEnabled = false`:
- ✅ Onboarding flow skips paywall step
- ✅ Settings menu hides subscription section
- ✅ Feature gates don't show upgrade prompts
- ✅ PaywallCoordinator ignores all presentation requests
- ✅ No paywall sheets will be presented anywhere

## Testing

To verify paywalls are properly disabled:
1. Go through onboarding - should skip from assessment to routine selection
2. Open Settings - subscription section should be hidden
3. Try accessing premium features - no upgrade prompts should appear

## Important Notes

- All paywall code remains intact and unchanged
- This is a temporary measure for App Store approval
- The app will function normally without subscription features
- Users can access basic features without seeing any paywall prompts

## App Store Resubmission

When resubmitting:
1. Keep `paywallsEnabled = false`
2. In App Store Connect review notes, mention:
   - "Subscriptions are being reviewed separately"
   - "Paywall functionality has been temporarily disabled"
   - "App provides full basic functionality without subscriptions"
3. Once app is approved, submit an update with paywalls enabled after subscriptions are approved

## Contact

If you have questions about this implementation, the changes are minimal and easily reversible by changing a single boolean value.