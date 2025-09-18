#!/usr/bin/env swift

// Test script to verify routine loading
// Run with: swift test-routine-loading.swift

print("""
===========================================
Routine Loading Test Guide
===========================================

To test if the Firebase routines are loading correctly:

1. BUILD THE APP:
   xcodebuild -project Growth.xcodeproj -scheme Growth -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

2. RUN THE APP and check console logs for:

   🔍 RoutineService: Starting fetchAllRoutines...
   📄 RoutineService: Found 2 documents in Firestore
   ✅ RoutineService: Successfully decoded routine: janus_protocol_12week - Janus Protocol - 12 Week Advanced
      - Schedule days: 84
      - Difficulty: Advanced
      - isCustom: false
   ✅ RoutineService: Successfully decoded routine: standard_growth_routine - Standard Growth Routine
      - Schedule days: 7
      - Difficulty: Beginner
      - isCustom: false

3. IN THE APP:
   - Go to the Routines tab
   - Tap "Browse Routines" 
   - You should see both routines listed
   - Check console for BrowseRoutinesView logs

4. EXPECTED ROUTINES:
   - "Standard Growth Routine" (7 days, Beginner)
   - "Janus Protocol - 12 Week Advanced" (84 days, Advanced)

5. TRY FILTERING:
   - Tap "Beginner" category -> Should show Standard Growth Routine
   - Tap "Advanced" category -> Should show Janus Protocol
   - Tap "Featured" category -> Should show both routines

TROUBLESHOOTING:
- If routines don't appear, check Xcode console for error logs
- Look for ❌ symbols indicating errors
- Ensure you're connected to internet for Firebase access
- The app will fall back to sample routines if Firebase fails

===========================================
""")