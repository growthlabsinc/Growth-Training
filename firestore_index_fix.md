# Firestore Index Required for Session Logs Query

## Issue
The Reset Today's Routine feature requires a composite index in Firestore for the session logs query.

## Error Message
```
The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/growth-70a85/firestore/indexes?create_composite=...
```

## Solution

### Option 1: Create the Index (Recommended)
1. Click the link in the error message, or
2. Go to Firebase Console → Firestore → Indexes
3. Create a new composite index:
   - Collection: `sessionLogs`
   - Fields:
     - `userId` (Ascending)
     - `endTime` (Ascending)
   - Query scope: Collection

### Option 2: The Code Now Handles This
The reset function will now work even without the index:
- It will log the index error but continue
- It will still reset the routine progress
- Session logs won't be deleted until the index is created

## Current Behavior
1. When index is missing:
   - Shows error in console
   - Still resets routine progress
   - Success message appears
   - Routine can be redone

2. When index exists:
   - Deletes session logs
   - Resets routine progress
   - Success message appears
   - Routine can be redone

## Testing
The reset feature now works with or without the index. Creating the index will enable full functionality (deleting session logs).