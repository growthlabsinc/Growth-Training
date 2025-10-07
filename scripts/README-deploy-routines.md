# PE Routine Deployment Guide

This guide explains how to deploy PE routine templates to the Firestore `routines` collection using the `deploy-pe-routines.js` script.

## Overview

The `deploy-pe-routines.js` script deploys 6 structured PE routine templates based on Reddit community best practices:

### Beginner Routines (2)
1. **Length-Focused Beginner** - Daily manual stretches or device wear for length gains
2. **Balanced Beginner** - Alternating length/girth days for balanced development

### Intermediate Routines (2)
3. **Intermediate Shock Loading** - 5-10 min girth work before length for accelerated gains
4. **Intermediate Pumping** - Static and interval pumping on 1on/1off schedule

### Advanced Routines (2)
5. **Advanced RIP Protocol** - Rapid Interval Pumping (30s pump / 30s rest) for maximum girth
6. **Advanced PAC Protocol** - Pump-Assisted Clamping for extreme girth expansion

## Prerequisites

Before running the deployment script, ensure you have:

1. **Node.js 20+** installed
2. **Firebase Admin SDK** installed:
   ```bash
   npm install firebase-admin
   ```
3. **Application Default Credentials** configured:
   ```bash
   gcloud auth application-default login
   ```
4. **Story 8.2 Exercises Deployed** - The routines reference exercises from the `growth_exercises` collection

## Usage

### Basic Deployment

Run the deployment script with the appropriate Firebase project:

```bash
GCLOUD_PROJECT=growth-training-app node scripts/deploy-pe-routines.js
```

### Expected Output

```
🏋️ PE Routine Deployment Script
================================

🔍 Validating routine data...
✅ Validation passed - all routines are valid

📦 Preparing to deploy 6 routines to Firestore...
   ✓ Queued: routine_beginner_length_focused (beginner)
   ✓ Queued: routine_beginner_balanced (beginner)
   ✓ Queued: routine_intermediate_shock_loading (intermediate)
   ✓ Queued: routine_intermediate_pumping (intermediate)
   ✓ Queued: routine_advanced_rip (advanced)
   ✓ Queued: routine_advanced_pac (advanced)

🚀 Committing batch write to Firestore...
✅ Batch write successful!

📊 Deployment Summary:
  Total Routines: 6
  - Beginner: 2
  - Intermediate: 2
  - Advanced: 2
```

## Routine Structure

Each routine follows this structure:

### Required Fields
- `id` (string) - Unique document ID (e.g., `routine_beginner_length_focused`)
- `name` (string) - Display name
- `description` (string) - Routine description
- `difficulty` (string enum) - `"beginner"`, `"intermediate"`, or `"advanced"`
- `duration` (number) - Total days in routine cycle
- `focusAreas` (array) - Focus categories: `["length"]`, `["girth"]`, or `["length", "girth"]`
- `stages` (array) - Exercise stages included: `[1]`, `[1, 2]`, or `[1, 2, 3]`
- `schedule` (array) - Array of `DaySchedule` objects
- `isCustom` (boolean) - MUST be `false` for standard routines
- `createdDate` (timestamp) - Creation date
- `lastUpdated` (timestamp) - Last update date

### Optional Fields
- `createdBy` (string) - Set to `null` for standard routines
- `shareWithCommunity` (boolean) - Set to `false` for standard routines
- `schedulingType` (string) - `"sequential"` or `"weekday"` (defaults to `"sequential"`)
- `tags` (array) - Tags for categorization
- `version` (number) - Version number (default: 1)

### DaySchedule Structure

```javascript
{
  "id": "day_1_1234567890",
  "day": 1,                              // Day number
  "description": "Manual Stretch Day",   // Day description
  "isRestDay": false,                    // true for rest days
  "methods": [MethodSchedule],           // Array of methods for this day
  "notes": "Keep session under 40 min"   // Additional notes
}
```

### MethodSchedule Structure

```javascript
{
  "id": "method_1234567890_abc123",
  "methodId": "stage1_basic_manual_stretch",  // Exercise document ID from growth_exercises
  "duration": 25,                              // Duration in minutes
  "order": 0                                   // Order in the day (0, 1, 2, ...)
}
```

## Routine Design Patterns

### 1on/1off Pattern
- Train one day, rest one day, repeat
- Used in: Intermediate Pumping, Advanced RIP
- Example: Train → Rest → Train → Rest

### 2on/1off Pattern
- Train two days, rest one day, repeat
- Used in: Advanced PAC
- Example: Train → Train → Rest → Train → Train → Rest

### Daily with Active Recovery
- Train most days with light recovery sessions
- Used in: Shock Loading, Length-Focused Beginner
- Example: Heavy → Light → Heavy → Light → Combined → Rest

### Alternating Focus
- Alternate between length and girth days
- Used in: Balanced Beginner
- Example: Length → Rest → Girth → Rest → Combined → Rest

## Exercise References

Routines reference exercises from the `growth_exercises` collection using these document IDs:

### Manual Methods (Stage 1)
- `stage1_basic_manual_stretch` - 25 min, length-focused
- `stage1_modified_jelq` - 20 min, girth/conditioning
- `stage2_timed_pressure_hold` - 20 min, intermediate length (TPH)
- `stage1_timed_squash` - 10 min, conditioning/EQ
- `stage1_milking_eq` - 10 min, EQ/conditioning

### Device Methods (Stage 1-2)
- `stage2_static_pumping` - 30 min, intermediate girth
- `stage3_rapid_interval_pumping` - 30 min, advanced girth (RIP)
- `stage2_vanilla_interval_pumping` - 30 min, intermediate girth
- `stage3_soft_clamping` - 15 min, advanced girth
- `stage2_shopping_bag_hanger` - 30 min, intermediate length
- `stage2_vacuum_extending` - 120 min, intermediate length
- `stage1_all_day_stretcher` - 360 min, beginner length (ADS)

### Advanced Methods (Stage 2-3)
- `stage2_shock_loading` - 30 min, intermediate girth/length combo
- `stage3_pump_assisted_clamping` - 25 min, advanced girth (PAC)
- `stage3_bundles_with_pumping` - 30 min, advanced girth/length

### Conditioning (Stage 1)
- `stage1_heat_application` - 10 min, conditioning/EQ

## Validation

The script validates all routine data before deployment:

- ✅ All required fields present
- ✅ Difficulty values are valid enums
- ✅ `isCustom` is `false` for all standard routines
- ✅ Schedule arrays are not empty
- ✅ Focus areas and stages are defined
- ✅ Training days have methods arrays
- ✅ Day numbers are valid

If validation fails, the script exits with error messages listing all issues.

## Verification

After deployment, verify the routines:

### 1. Firebase Console
Visit: https://console.firebase.google.com/project/growth-training-app/firestore/data/routines

Check that:
- All 6 routines are present
- Required fields are populated
- `isCustom` is `false` for all
- Schedule arrays have proper structure

### 2. App Integration
Open the Growth Training app and:
- Navigate to Routines view
- Verify all 6 routines appear
- Test filtering by difficulty (beginner/intermediate/advanced)
- Test filtering by focus area (length/girth)
- Select a routine and verify schedule displays
- Verify exercise references resolve correctly

### 3. Service Layer
The `RoutineService.fetchStandardRoutines()` method automatically returns all routines where `isCustom: false`, so no code changes are required.

## Troubleshooting

### Error: "Missing Application Default Credentials"
**Solution**: Run `gcloud auth application-default login`

### Error: "Permission denied on Firestore"
**Solution**: Verify your Google Cloud account has Firestore write access for the project

### Error: "firebase-admin not found"
**Solution**: Run `npm install firebase-admin` in the project root

### Error: "Exercise reference not found"
**Solution**: Ensure Story 8.2 exercises are deployed first using:
```bash
GCLOUD_PROJECT=growth-training-app node scripts/deploy-pe-exercises.js
```

### Validation Errors
Review the error messages and fix the routine definitions in `deploy-pe-routines.js` before re-running.

## Updating Routines

To update existing routines:

1. Edit the routine definitions in `deploy-pe-routines.js`
2. Update the `version` number
3. Update the `lastUpdated` timestamp (automatically set to server timestamp)
4. Re-run the deployment script

**Note**: The script uses `batch.set()` which will overwrite existing routines with matching document IDs.

## Adding New Routines

To add new routines:

1. Define a new routine object following the structure pattern
2. Add it to the `ALL_ROUTINES` array
3. Ensure proper difficulty categorization
4. Verify all exercise references exist in `growth_exercises`
5. Run validation and deployment

## Best Practices

### Routine Design
- **Recovery is essential**: Include adequate rest days
- **Progressive overload**: Start light, increase gradually
- **Safety first**: Include comprehensive safety notes
- **Pattern consistency**: Stick to established patterns (1on/1off, etc.)

### Exercise Selection
- **Stage-appropriate**: Match exercise difficulty to routine difficulty
- **Focus-aligned**: Ensure exercises match routine focus areas
- **Time-realistic**: Keep total session times reasonable (20-60 min typical)
- **Equipment-aware**: Consider equipment requirements for target audience

### Documentation
- **Clear descriptions**: Explain routine purpose and approach
- **Helpful notes**: Provide guidance for each day
- **Progression criteria**: Help users know when to advance
- **Safety warnings**: Emphasize safety for advanced techniques

## Related Documentation

- [Story 8.3](../docs/stories/8.3.create-structured-routine-templates.story.md) - Full story specification
- [Story 8.2](../docs/stories/8.2.populate-pe-exercise-library.story.md) - Exercise library deployment
- [Epic 8](../docs/prd/epic-8-routine-population.md) - Routine population epic
- [CLAUDE.md](../CLAUDE.md) - Project development guide
- [Routine Model](../Growth/Core/Models/RoutineModel.swift) - Swift model definition

## Support

For issues or questions:
1. Check Firebase Console logs
2. Review validation error messages
3. Verify exercise IDs exist in `growth_exercises` collection
4. Ensure Application Default Credentials are configured
5. Check Node.js version compatibility (20+)
