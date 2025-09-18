# Testing Custom Routine Duration Feature

## How to Test

1. **Navigate to Routines Tab**
   - Open the app
   - Go to the Routines tab
   - Look for "Browse Routines" or similar option

2. **Create Custom Routine**
   - Look for "Create Custom" button (usually at the bottom of the routines grid)
   - Tap on it to open the custom routine creation view

3. **Fill Basic Information**
   - Enter a routine name
   - Enter a description
   - Select difficulty level
   - Choose duration (7, 14, 21, or 28 days)

4. **Edit Day Schedule**
   - In the "Weekly Schedule" section, tap on any day card
   - This opens the EditDayScheduleView where you can:

5. **Add Methods with Custom Duration**
   - Tap "Add methods to this day" button
   - A method will be added with default 20 minutes duration
   - You'll see:
     - Method name with dropdown to change it
     - Duration button showing "20 minutes" with clock icon
     - Delete button (red minus circle)

6. **Customize Duration**
   - Tap the duration button (e.g., "20 minutes")
   - A sheet appears with:
     - Preset options: 5, 10, 15, 20, 25, 30, 45, 60 minutes
     - Custom duration input field (1-180 minutes)
   - Select a preset or enter custom duration
   - The duration updates immediately

7. **Add Multiple Methods**
   - Tap "Add another method" to add more
   - Each method can have its own duration
   - Methods can be reordered by dragging (Edit mode)
   - Total duration is shown on the day card

8. **Save and Create**
   - Save the day schedule
   - Back in main view, you'll see updated method count and total duration
   - Complete all required fields and tap "Create Routine"

## What to Look For

- **Duration Display**: Each method shows its duration clearly
- **Total Time**: Day cards show total duration for all methods
- **Flexibility**: Can set any duration from 1-180 minutes
- **Visual Feedback**: Clock icons and clear labeling
- **Smooth Interaction**: Duration picker appears as a sheet

## Troubleshooting

If you don't see the new features:
1. Make sure you're in the custom routine creation flow
2. Clean build folder and rebuild
3. Check that you're editing a non-rest day
4. Ensure methods have been added to your routine first (via "Manage Methods")