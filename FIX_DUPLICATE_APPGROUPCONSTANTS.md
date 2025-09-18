# Fix Duplicate AppGroupConstants.stringsdata Error

## Problem
The error "Multiple commands produce AppGroupConstants.stringsdata" occurs because `AppGroupConstants.swift` is being compiled by both:
- The main Growth app target
- The GrowthTimerWidget target

## Solution in Xcode

### Option 1: Use Target Membership (Recommended)
1. **Select `AppGroupConstants.swift` in Xcode**
2. **Open File Inspector** (right panel)
3. **Under "Target Membership":**
   - ✅ Check "Growth" (main app)
   - ❌ Uncheck "GrowthTimerWidget"
   - ❌ Uncheck "GrowthTimerWidgetExtension" (if exists)

### Option 2: Create a Shared Framework
1. **File > New > Target > Framework**
2. Name it "GrowthShared"
3. Move shared files to this framework
4. Import the framework in both targets

### Option 3: Use Folder References
1. **Create a "Shared" group** in Xcode
2. **For each shared file:**
   - Remove from all targets
   - Add to main target only
   - In widget target's Build Phases > Compile Sources
   - Add reference using "Add Other..." > "Add Files..."
   - Don't copy, just reference

## Quick Fix for AppGroupConstants

Since `AppGroupConstants` is a simple constants file, the quickest fix is:

1. **In Xcode, select `AppGroupConstants.swift`**
2. **In File Inspector, under Target Membership:**
   - ✅ Growth (main app) - CHECKED
   - ❌ GrowthTimerWidget - UNCHECKED
   - ❌ GrowthTimerWidgetExtension - UNCHECKED

3. **For the Widget to access it:**
   - The widget already imports the file at compile time
   - Since it's just constants, they'll be available

## Other Files That May Have Same Issue

Check target membership for these shared files:
- `AppGroupFileManager.swift`
- `TimerActivityAttributes.swift`
- `TimerState.swift`

These should typically be:
- ✅ Included in main app target
- ❌ NOT included in widget target (unless needed for compilation)

## Verification

After fixing:
1. Clean Build Folder (Cmd+Shift+K)
2. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
   ```
3. Build again

## Alternative: Preprocessor Approach

If you need the file in both targets, use preprocessor directives:

```swift
#if TARGET_IS_WIDGET
// Widget-specific code
#else
// Main app code
#endif
```

But for simple constants, Option 1 is the best approach.