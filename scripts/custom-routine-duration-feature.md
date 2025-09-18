# Custom Routine Duration Feature

## Overview
Added the ability for users to customize the duration prescribed for each method when creating custom routines.

## Changes Made

### 1. Updated EditDayScheduleView
- Replaced simple method ID selection with full `MethodSchedule` objects that include duration
- Added ability to add/remove methods for each day
- Added reordering support for methods within a day
- Integrated with the new data model that supports duration per method

### 2. New MethodScheduleRow Component
- Displays each method with its title and stage
- Shows current duration with a tappable button to change it
- Includes a dropdown menu to change the selected method
- Has a delete button to remove the method from the day

### 3. New DurationPickerView
- Presents preset duration options: 5, 10, 15, 20, 25, 30, 45, 60 minutes
- Allows custom duration input (1-180 minutes)
- Shows as a sheet with medium presentation detent
- Validates custom input to ensure reasonable values

### 4. Updated DayScheduleCard
- Now shows total duration for all methods in a day
- Displays both method count and total minutes
- Better visual hierarchy with icons

## Data Model
The feature leverages the existing `MethodSchedule` struct:
```swift
public struct MethodSchedule: Codable, Hashable {
    public var methodId: String
    public var duration: Int // Minutes
    public var order: Int // Order in the day
}
```

## User Experience

1. **Creating a Routine**: Users can now:
   - Add multiple methods to each day
   - Set custom duration for each method (5-180 minutes)
   - Reorder methods within a day
   - See total time commitment for each day

2. **Visual Feedback**:
   - Duration shown as a tappable button with clock icon
   - Total duration displayed on day cards
   - Clear visual separation between methods

3. **Flexibility**:
   - Preset durations for quick selection
   - Custom duration for specific needs
   - Easy method swapping without losing duration settings

## Benefits
- Users can adapt routines to their available time
- More personalized training schedules
- Better time management and planning
- Flexibility for different fitness levels and goals

## Technical Notes
- Uses SwiftUI's Form and sheet presentation
- Maintains order of methods for sequential execution
- Validates all inputs to prevent unreasonable values
- Integrates seamlessly with existing routine creation flow