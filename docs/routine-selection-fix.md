# Routine Selection During Onboarding - Issue Analysis & Fix

## Problem Summary
Users who select "Start a Guided Routine" during onboarding but don't actually select a routine end up with:
- `preferredPracticeMode: "routine"` saved in Firestore
- No `selectedRoutineId` saved
- Dashboard shows "No Routine Selected" despite user choosing routine mode
- First-time prompt shows "View My Routine" but there's no routine to view

## Root Causes
1. The routine selection happens in a dismissible modal
2. Onboarding continues even if no routine is selected
3. No validation that routine mode users have actually selected a routine

## Recommended Fixes

### Option 1: Make Routine Selection Required (Recommended)
Modify `RoutineGoalSelectionView` to ensure users who select routine mode must choose a routine:

```swift
// In RoutineGoalSelectionView.swift
.fullScreenCover(isPresented: $showRoutineBrowser) {
    NavigationStack {
        if let userId = Auth.auth().currentUser?.uid {
            RoutinesListView(viewModel: RoutinesViewModel(userId: userId))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            // Only allow dismissal if a routine was selected
                            if routinesViewModel.selectedRoutineId != nil {
                                showRoutineBrowser = false
                                viewModel.advance()
                            } else {
                                // Show alert that they must select a routine
                                showMustSelectRoutineAlert = true
                            }
                        }
                    }
                }
                .interactiveDismissDisabled(routinesViewModel.selectedRoutineId == nil)
        }
    }
}
```

### Option 2: Default Routine Assignment
When user selects routine mode but doesn't pick a routine, automatically assign a beginner routine:

```swift
private func handleGuidedRoutineSelection() {
    savePracticePreference(mode: "routine") { success in
        if success {
            // Check if they already have a selected routine
            UserService.shared.fetchSelectedRoutineId(userId: userId) { existingRoutineId in
                if existingRoutineId == nil {
                    // Auto-select beginner routine
                    selectDefaultBeginnerRoutine()
                }
                showRoutineBrowser = true
            }
        }
    }
}

private func selectDefaultBeginnerRoutine() {
    // Auto-select "Beginner's Journey" or similar
    RoutineService().fetchAllRoutines { result in
        if case .success(let routines) = result,
           let beginnerRoutine = routines.first(where: { $0.difficultyLevel == "Beginner" }) {
            UserService.shared.updateSelectedRoutine(userId: userId, routineId: beginnerRoutine.id)
        }
    }
}
```

### Option 3: Update Dashboard Logic
Enhance the dashboard to better handle the "routine mode but no routine selected" state:

```swift
// In TodayViewViewModel
private func loadTodayFocusState() {
    // Check user's practice preference
    UserService.shared.fetchUser(userId: userId) { result in
        if case .success(let user) = result,
           user.preferredPracticeMode == "routine",
           routinesViewModel.selectedRoutineId == nil {
            // Special state for routine users without a routine
            self.todayFocusState = .needsRoutineSelection
        }
    }
}

// Add new state
enum TodayFocusState {
    // ... existing cases
    case needsRoutineSelection
}
```

### Option 4: Validate at Onboarding Completion
Add validation before completing onboarding:

```swift
// In OnboardingViewModel
func validateOnboardingCompletion() -> Bool {
    if user.preferredPracticeMode == "routine" && user.selectedRoutineId == nil {
        // Don't complete onboarding - show routine selection again
        currentStep = .routineGoalSelection
        return false
    }
    return true
}
```

## Recommended Implementation
I recommend **Option 1** (Make Routine Selection Required) because:
- It ensures users who want structured routines actually have one selected
- Prevents confusion on the dashboard
- Maintains consistency between user intent and app state
- Provides clear feedback if they try to skip selection

Combined with updating the FirstTimeUserPrompt to handle edge cases:

```swift
// In FirstTimeUserPrompt
private var promptTitle: String {
    if user.preferredPracticeMode == "routine" && routinesViewModel.selectedRoutineId == nil {
        return "Select Your First Routine"
    } else if user.preferredPracticeMode == "routine" {
        return "Ready to Start Your Routine?"
    } else {
        return "Ready for Your First Session?"
    }
}
```