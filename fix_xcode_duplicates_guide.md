# Fix Xcode Duplicate Files Guide

## Issue Summary
The build is failing due to:
1. Duplicate Swift files in different locations
2. Multiple references to the same Info.plist file

## Files Already Fixed (Duplicates Removed)
✅ Removed duplicates, keeping only these versions:
- `/Growth/Features/Settings/NotificationPreferencesView.swift`
- `/Growth/Core/Models/PendingConsents.swift`
- `/Growth/Core/Models/ConsentRecord.swift`
- `/Growth/Core/Models/RoutineProgress.swift`
- `/Growth/Core/Services/InsightGenerationService.swift`

## Steps to Complete the Fix

### 1. Clean Xcode's Cache
```bash
# Already done, but if needed again:
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
```

### 2. Fix in Xcode

#### Remove Dead References
1. Open `Growth.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), look for files with red names (missing files)
3. Select each red file and press Delete key
4. Choose "Remove Reference" (not "Move to Trash")

#### Fix Info.plist Duplicate
1. Select the Growth project in navigator
2. Select the Growth target
3. Go to **Build Settings** tab
4. Search for "Info.plist"
5. Ensure **Info.plist File** is set to: `Growth/Resources/Plist/App/Info.plist`

6. Go to **Build Phases** tab
7. Expand **Copy Bundle Resources**
8. Look for any Info.plist entries
9. Remove any Info.plist files from this list (they shouldn't be copied as resources)

### 3. Clean and Rebuild
1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. **Product → Build** (Cmd+B)

## Prevention Tips
- When adding files to Xcode, ensure you're not adding them multiple times
- Use proper group organization to avoid confusion
- Don't add Info.plist to Copy Bundle Resources phase
- When moving files, remove old references before adding new ones

## If Issues Persist
1. Close Xcode
2. Delete DerivedData again
3. Reset Xcode's cache:
   ```bash
   rm -rf ~/Library/Caches/com.apple.dt.Xcode
   ```
4. Reopen project and try again

## File Organization Best Practice
Keep files organized by feature/layer:
```
Growth/
├── Core/
│   ├── Models/        (shared models)
│   └── Services/      (shared services)
└── Features/
    ├── Settings/      (settings-related views)
    ├── Progress/      (progress-specific components)
    └── Onboarding/    (onboarding-specific components)
```