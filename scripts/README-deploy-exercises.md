# PE Exercise Library Deployment

## Overview

This directory contains the deployment script for populating the Growth Training app's PE exercise library. The script deploys comprehensive training protocols to Firestore with complete safety information, categorization, and timer configurations.

## Script: deploy-pe-exercises.js

### Purpose

Deploys 16+ PE training exercises to the `growth_exercises` Firestore collection, including:
- **Manual Methods** (5 exercises): Basic stretching, jelqing, pressure holds
- **Device-Based Methods** (7 exercises): Pumping, extending, hanging, clamping
- **Advanced Techniques** (3 exercises): Combination protocols for experienced users
- **Conditioning & EQ** (1 exercise): Heat therapy and circulation work

### Prerequisites

1. **Node.js 20+** installed
2. **Firebase Admin SDK** installed in functions directory:
   ```bash
   cd functions && npm install
   ```
3. **Application Default Credentials** configured:
   ```bash
   gcloud auth application-default login
   ```
4. **Firestore Access**: Write access to `growth_exercises` collection

### Usage

```bash
# From project root directory
GCLOUD_PROJECT=growth-training-app node scripts/deploy-pe-exercises.js
```

### What the Script Does

1. **Validates** all exercise data for required fields and proper formatting
2. **Creates batch write** with all exercises
3. **Deploys** to Firestore `growth_exercises` collection
4. **Reports** deployment status and exercise breakdown

### Exercise Data Structure

Each exercise includes:

```javascript
{
  // Required fields
  id: "stage1_exercise_name",           // Unique document ID
  stage: 1,                               // Must be >= 1 for actionable protocols
  classification: "Beginner|Intermediate|Advanced",
  title: "Exercise Name",
  description: "Brief description",
  instructionsText: "Detailed step-by-step instructions",

  // Categorization
  categories: ["length", "girth", "conditioning", "eq"],
  equipmentNeeded: ["pump", "lube", "clamp", etc.],

  // Safety & metadata
  safetyNotes: "Complete safety information with disclaimers",
  estimatedDurationMinutes: 30,
  isFeatured: true|false,
  benefits: ["Benefit 1", "Benefit 2"],
  relatedMethods: ["related_exercise_id"],

  // Optional: Timer configuration
  timerConfig: {
    recommended_duration_seconds: 300,
    is_countdown: true,
    has_intervals: true,
    intervals: [
      { name: "Work", duration_seconds: 30 },
      { name: "Rest", duration_seconds: 30 }
    ]
  },

  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Safety Notes Requirements

Every exercise MUST include comprehensive safety information:

- **Medical Disclaimer**: Standard warning about consulting healthcare provider
- **Stop Signals**: List of symptoms requiring immediate cessation
- **Contraindications**: Conditions that preclude doing the exercise
- **Safety Guidelines**: Exercise-specific safety rules
- **Age Restriction**: 18+ only disclaimer

### Validation

The script validates:
- ✅ All required fields are present
- ✅ Stage is >= 1 (no Level 0 educational content)
- ✅ Classification is valid (Beginner/Intermediate/Advanced)
- ✅ Categories are valid (length/girth/conditioning/eq)
- ✅ Equipment tags are properly formatted

### Verification

After deployment, verify in:

1. **Firebase Console**:
   - https://console.firebase.google.com/project/growth-training-app/firestore
   - Navigate to `growth_exercises` collection
   - Confirm all exercises uploaded

2. **Growth Training App**:
   - Open Methods Guide view
   - Verify exercises appear in list
   - Test category and classification filtering
   - Test search functionality
   - Open exercise detail views to verify safety notes

3. **Timer Integration** (for timed exercises):
   - Select timed exercise (e.g., RIP, Vanilla Interval Pumping)
   - Verify timer configuration loads correctly
   - Test interval timers work as expected

## Exercise Categories

### length
Exercises focused on increasing length through stretching, extending, or hanging.

### girth
Exercises focused on expanding girth through pumping, clamping, or compression techniques.

### conditioning
Exercises that improve tissue health, flexibility, and resilience without primary focus on size.

### eq
Erection quality exercises focused on vascular health and circulation.

## Classification Levels

### Beginner
- Manual methods without devices
- Low risk when done correctly
- < 30 minutes duration
- No prior PE experience required

### Intermediate
- Device-based methods
- Moderate risk requiring proper technique
- 30-60 minutes duration
- Some PE experience recommended

### Advanced
- High-intensity techniques
- Significant risk if done incorrectly
- Combination protocols
- Extensive PE experience required

## Equipment Tags

- `pump`: Vacuum pumping devices
- `clamp`: Clamping devices (cable clamps, etc.)
- `hanger`: Weight hanging systems
- `extender`: Vacuum or strap extenders
- `ads`: All-day stretcher devices
- `lube`: Water-based lubricant required
- `heat`: Heat application (rice sock, heating pad)
- Empty array `[]`: Manual methods requiring no equipment

## Troubleshooting

### "Permission denied" error
- Verify Application Default Credentials: `gcloud auth application-default login`
- Ensure you have Firestore write access
- Check GCLOUD_PROJECT environment variable is set correctly

### "Validation failed" error
- Review error messages for specific missing fields
- Ensure all classifications are spelled correctly
- Verify all categories use lowercase tags
- Check that stage values are >= 1

### Exercises not appearing in app
- Verify deployment completed successfully (check console output)
- Restart app to clear cache (TrainingProtocolService has 30-min cache)
- Check Firestore Console to confirm documents exist
- Verify stage values are > 0 (stage 0 protocols are filtered out)

### Timer configurations not working
- Verify timerConfig structure matches expected format
- Check duration values are in seconds (not minutes)
- Ensure intervals array is properly formatted
- Test with simple countdown timer first

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Project development guidelines
- [Epic 8](../docs/prd/epic-8-growth-methods-expansion.md) - Exercise library expansion plan
- [Story 8.2](../docs/stories/8.2.populate-pe-exercise-library.story.md) - This implementation story
- [TrainingProtocol Model](../Growth/Core/Models/TrainingProtocol.swift) - Swift data model

## Maintenance

### Adding New Exercises

1. Add exercise data to appropriate array in `deploy-pe-exercises.js`:
   - `MANUAL_METHODS` for manual exercises
   - `DEVICE_METHODS` for device-based
   - `ADVANCED_METHODS` for combination techniques
   - `CONDITIONING_METHODS` for conditioning/EQ work

2. Follow existing exercise structure exactly

3. Ensure all required fields are populated

4. Run deployment script to add new exercises

5. Verify in Firestore Console and app

### Updating Existing Exercises

**WARNING**: The deployment script uses `batch.set()` which overwrites existing documents.

To update exercises:
1. Modify exercise data in script
2. Run deployment (overwrites existing docs with same IDs)
3. Verify changes in Firestore

**Alternative**: Use Firestore Console for single-field updates to avoid full document replacement.

### Deleting Exercises

Use Firebase Console to manually delete documents. The deployment script does not handle deletions.

## Change Log

| Date       | Version | Description                      | Author |
| ---------- | ------- | -------------------------------- | ------ |
| 2025-10-07 | 1.0     | Initial deployment documentation | James (Dev Agent) |
