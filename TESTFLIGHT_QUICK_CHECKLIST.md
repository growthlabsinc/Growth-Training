# TestFlight Upload Quick Checklist

## Pre-Flight Checks
- [ ] Bundle ID: `com.growthlabs.growthmethod`
- [ ] Team ID: `62T6J77P6R`
- [ ] Increment build number if re-uploading
- [ ] All app icons present in Assets.xcassets
- [ ] Release notes prepared

## Xcode Steps
1. [ ] Open `Growth.xcodeproj`
2. [ ] Clean Build Folder (⇧⌘K)
3. [ ] Select "Any iOS Device (arm64)" as destination
4. [ ] Verify scheme is set to Release configuration
5. [ ] Product → Archive
6. [ ] Validate App in Organizer
7. [ ] Distribute App → App Store Connect → Upload

## App Store Connect Steps
1. [ ] Wait for "Processing" to complete (10-30 min)
2. [ ] Add "What to Test" information
3. [ ] Answer Export Compliance
4. [ ] Add internal testers
5. [ ] Send invites

## Important Reminders
- TestFlight will use **production** APNs environment
- Push tokens will be different from development
- Build expires after 90 days
- Each upload needs unique build number

## Current Status
- Version: 1.0
- Build: 1
- Next Build: 2

## If APNs Still Fails in TestFlight
The app will still work with:
- Timer progress bars (ProgressView with timerInterval)
- Manual refresh when app opens
- Basic functionality intact

Contact Apple Developer Support with:
- Error: InvalidProviderToken (403)
- Key ID: DQ46FN4PQU
- Environment: Production via TestFlight