# Firebase Functions Deployment Status

## Currently Deployed Functions (14)
✅ addMissingRoutines
✅ banUser
✅ checkUserBanned
✅ checkUsernameAvailability
✅ cleanupOldReports
✅ collectAPNsDiagnostics
✅ fixTimerDates
✅ generateAIResponse
✅ handleAppStoreNotification
✅ manageLiveActivityUpdates
✅ moderateContent
✅ moderateNewRoutine
✅ onTimerStateChange
✅ processReport

## Functions Defined But Not Deployed (14)
❌ updateLiveActivityTimer
❌ updateLiveActivity
❌ testAPNsConnection
❌ registerLiveActivityPushToken
❌ registerPushToStartToken
❌ updateEducationalResourceImages
❌ updateEducationalResourceImagesCallable
❌ validateSubscriptionReceipt
❌ updateLiveActivitySimplified
❌ notifyLiveActivityStateChange
❌ testDeployment
❌ trackRoutineDownload
❌ updateRoutineStats

## Critical Functions for Live Activities
The following functions are essential for Live Activity functionality:
- updateLiveActivityTimer
- updateLiveActivity
- registerLiveActivityPushToken
- registerPushToStartToken
- updateLiveActivitySimplified
- notifyLiveActivityStateChange

## Deployment Command
To deploy all functions:
```bash
cd /Users/tradeflowj/Desktop/Dev/growth-training/functions
firebase deploy --only functions
```

To deploy specific missing functions:
```bash
firebase deploy --only functions:updateLiveActivityTimer,functions:updateLiveActivity,functions:testAPNsConnection,functions:registerLiveActivityPushToken,functions:registerPushToStartToken
```