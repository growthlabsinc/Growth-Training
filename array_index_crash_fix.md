# Array Index Out of Bounds Crash Fix

## Issue
The app was crashing with an array index out of bounds error when using the DurationPickerView. The crash occurred when:
1. Opening the duration picker for a method
2. Deleting the method while the picker was still open
3. The picker trying to access the binding to a now-deleted array element

## Stack Trace Analysis
```
Swift.Array._checkSubscript(_: Swift.Int, wasNativeTypeChecked: Swift.Bool)
...
DurationPickerView.duration.getter at CreateCustomRoutineView.swift:988
```

## Root Cause
The `DurationPickerView` was directly bound to `$methodSchedule.duration` where `methodSchedule` was an element in an array. When the element was deleted, the binding became invalid, causing the crash.

## Fixes Applied

### 1. Added Local State for Duration
```swift
// In MethodScheduleRow
@State private var currentDuration: Int = 20

// Update local state before showing picker
Button {
    currentDuration = methodSchedule.duration
    showingDurationPicker = true
}

// Use local state in sheet
.sheet(isPresented: $showingDurationPicker) {
    DurationPickerView(duration: $currentDuration)
        .onDisappear {
            methodSchedule.duration = currentDuration
        }
}
```

### 2. Fixed ForEach with Indices
Changed from using indices directly to using the actual objects:
```swift
// Before - unsafe
ForEach(selectedMethods.indices, id: \.self) { index in

// After - safe
ForEach(selectedMethods, id: \.self) { method in
    if let index = selectedMethods.firstIndex(of: method) {
```

### 3. Added Safety Checks
Added checks before accessing array elements:
```swift
onDelete: {
    if let deleteIndex = selectedMethods.firstIndex(of: method) {
        selectedMethods.remove(at: deleteIndex)
    }
}
```

## Benefits
1. **No more crashes**: The duration picker now uses local state instead of direct array bindings
2. **Safer array operations**: Using object identity instead of indices prevents out-of-bounds access
3. **Better user experience**: Users can safely delete methods even with sheets open

## Testing
1. Add multiple methods to a day
2. Open duration picker for a method
3. While picker is open, delete the method
4. Verify no crash occurs
5. Test reordering methods with drag and drop