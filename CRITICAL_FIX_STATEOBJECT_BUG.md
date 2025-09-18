# CRITICAL BUG FOUND: @StateObject Misuse with Shared Singletons

## The Problem

**Critical Bug:** Throughout the codebase, `@StateObject` is being used with shared singleton instances. This is incorrect and causes the AI Coach lock issue!

### Why This Is Wrong

```swift
// ❌ WRONG - Creates new instance, ignores shared singleton
@StateObject private var featureGate = FeatureGateService.shared

// ✅ CORRECT - Observes the shared singleton
@ObservedObject private var featureGate = FeatureGateService.shared
```

**@StateObject** creates and owns a new instance of the object. When you write `@StateObject var x = Something.shared`, SwiftUI:
1. Calls `Something.shared` to get the initial value
2. **Creates its own retained copy** 
3. Never updates even when the shared instance changes

**@ObservedObject** observes an existing instance. It doesn't create or own the object, just observes changes.

## Impact on AI Coach Issue

This bug directly causes the AI Coach lock problem:

1. User purchases subscription
2. `FeatureGateService.shared` updates with new access
3. BUT the `FeatureGateModifier` has its own copy via `@StateObject`
4. The view never sees the update
5. AI Coach remains locked

## Files With This Bug

### Critical (Subscription Related) - FIXED
- ✅ `Growth/Core/Views/FeatureGate.swift` - **FIXED**

### Critical (Subscription Related) - NEEDS FIXING
- `Growth/Core/Views/Components/FeatureGateView.swift` (2 instances)
- `Growth/Core/Views/Components/UpgradePromptView.swift` (2 instances)
- `Growth/Core/Annotations/FeatureGateAnnotations.swift` (1 instance)
- `Growth/Features/Analytics/Views/MetricsDashboardView.swift` (1 instance)

### App Level (Probably OK)
These are in the main App file and only created once, so they might be acceptable:
- `Growth/Application/GrowthAppApp.swift`
- `Growth/MainView.swift`

### Other Services (Lower Priority)
Various other services using the same pattern that should be reviewed.

## Immediate Fix Applied

```swift
// File: Growth/Core/Views/FeatureGate.swift
// Changed from:
@StateObject private var featureGate = FeatureGateService.shared
// To:
@ObservedObject private var featureGate = FeatureGateService.shared
```

## Next Steps

1. **Test Immediately**: This fix alone might solve the AI Coach issue
2. **Fix Other Critical Files**: Update all feature gate related files
3. **Review Pattern**: Establish clear guidelines for when to use @StateObject vs @ObservedObject

## Testing Instructions

1. Clean build folder (⌘+Shift+K)
2. Run app in debug mode
3. Purchase subscription
4. Check AI Coach - should unlock immediately

## Prevention

Add a linting rule or code review checklist:
- **Never use @StateObject with .shared singletons**
- **@StateObject** = Creating and owning an instance
- **@ObservedObject** = Observing an existing instance

## Why This Wasn't Caught Earlier

The symptoms were subtle:
- Works fine on app launch (initial state is correct)
- Fails only on state changes (purchases)
- Multiple layers of services masked the root cause
- @StateObject with shared singleton is a common mistake

This is THE root cause of the subscription state not updating in UI!