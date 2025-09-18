# Janus Protocol - Advanced Growth Methods & 12-Week Routine

This directory contains scripts to add the complete Janus Protocol to the Growth app, including:
- New growth methods (Angion Methods, BFR techniques, SABRE strikes)
- A comprehensive 12-week advanced routine

## Prerequisites

1. Ensure you have Node.js installed
2. Navigate to the scripts directory: `cd scripts`
3. Install dependencies: `npm install`
4. Ensure you have the appropriate Firebase service account file:
   - For development: `Growth/Resources/Plist/dev.GoogleService-Info.json`
   - For production: `Growth/Resources/Plist/GoogleService-Info.plist`

## Running the Scripts

### Option 1: Run Everything at Once (Recommended)

```bash
# For development environment
node add-janus-protocol-complete.js

# For production environment (be careful!)
node add-janus-protocol-complete.js --production
```

### Option 2: Run Individual Scripts

```bash
# Add growth methods only
node add-advanced-growth-methods.js

# Add the 12-week routine only
node add-advanced-routine.js
```

## What Gets Added

### Growth Methods (10 new methods)
1. **Angion Method 1.0** - Foundation venous-focused technique
2. **Angion Method 2.5 (Jelq 2.0)** - Bridge to Vascion
3. **Vascion (AM 3.0)** - Expert-level CS stimulation
4. **BFR Cyclic Bending** - Pressure-based venous arterialization
5. **BFR Glans Pulsing** - Gentle pressure fluctuations
6. **SABRE Type A** - Low speed/low intensity strikes
7. **SABRE Type B** - High speed/low intensity strikes
8. **SABRE Type C** - Low speed/high intensity strikes
9. **SABRE Type D** - High speed/high intensity strikes
10. **S2S Advanced** - Side-to-side stretching

### 12-Week Advanced Routine
- **ID**: `janus_protocol_12week`
- **Duration**: 84 days (12 weeks)
- **Structure**: 
  - Weeks 1-3: Foundation building
  - Week 4: Deload
  - Weeks 5-7: Intensity increase (Type C SABRE)
  - Week 8: Deload
  - Weeks 9-11: Peak intensity (Type D SABRE)
  - Week 12: Final deload and assessment
- **Training Days**: 54
- **Rest Days**: 30

## Important Safety Notes

⚠️ **WARNING**: These are advanced techniques that require:
- Mastery of foundational methods
- Excellent body awareness
- Strict adherence to safety guidelines
- Never training through pain
- Proper warm-up and recovery

## Verification

After running the scripts, verify in the Growth app:
1. Check Methods tab for new growth methods
2. Check Routines tab for "Janus Protocol - 12 Week Advanced"
3. Test starting the routine and ensure all methods load correctly

## Troubleshooting

If you encounter errors:
1. Check Firebase service account file exists
2. Ensure proper Firebase permissions
3. Check console output for specific error messages
4. Verify network connectivity to Firebase

## Notes

- The routine follows the exact structure from the Janus Protocol
- Rest days are crucial - do not skip them
- Deload weeks (4, 8, 12) are essential for recovery
- Progress gradually through intensity levels
- Stop immediately if pain or injury occurs