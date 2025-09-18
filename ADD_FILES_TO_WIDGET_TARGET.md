# Add Files to Widget Target in Xcode

## The Problem
The widget can't find `TimerActivityAttributes` because the file isn't included in the widget target.

## Files That Need to Be Added to Widget Target

In Xcode, add these files to the **GrowthTimerWidgetExtension** target:

1. **`Growth/Features/Timer/Models/TimerActivityAttributes.swift`**
   - This defines the ActivityAttributes structure
   - Required by the widget to understand the Live Activity data

2. **`Growth/Core/Utilities/AppGroupConstants.swift`**
   - Defines the App Group identifier
   - Used by both app and widget

3. **`Growth/Core/Utilities/AppGroupFileManager.swift`** (if referenced)
   - Handles file-based communication
   - May be needed by TimerControlIntent

## How to Add Files to Widget Target

1. **Select the file** in Xcode navigator
2. **Open File Inspector** (right panel)
3. **Under "Target Membership":**
   - ✅ Check "GrowthTimerWidgetExtension"
   - ✅ Keep "Growth" checked (both targets need it)

## Alternative: Create a Shared Framework

If you have many shared files, consider:
1. Create a new Framework target
2. Move shared code there
3. Import the framework in both app and widget

## After Adding Files

1. Clean Build Folder (Cmd+Shift+K)
2. Build again (Cmd+B)

The "Cannot find type 'TimerActivityAttributes' in scope" errors should be resolved!