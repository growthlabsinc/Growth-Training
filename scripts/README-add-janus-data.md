# Adding Janus Protocol Data to Firestore

This guide explains how to add the Janus Protocol growth methods and 12-week routine to your Firestore database.

## Option 1: Using Firebase Console (Recommended for First Time)

Since the Firestore security rules prevent direct writes to the `growthMethods` and `routines` collections, you have several options:

### 1a. Temporarily Modify Security Rules

1. Go to Firebase Console → Firestore → Rules
2. Temporarily add write permissions for your admin user:

```javascript
// Temporary admin rule - REMOVE AFTER ADDING DATA
match /growthMethods/{methodId} {
  allow read: if true;
  allow write: if request.auth != null && request.auth.uid == "YOUR_ADMIN_UID";
}

match /routines/{routineId} {
  allow read: if true;
  allow write: if request.auth != null && request.auth.uid == "YOUR_ADMIN_UID";
}
```

3. Run the script
4. **IMPORTANT**: Remove the write permissions after adding data

### 1b. Use Firebase Admin SDK with Service Account

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save the JSON file as `service-account.json` in the scripts directory
4. Run: `node add-janus-protocol-admin.mjs`

## Option 2: Direct Firebase Console Import

You can manually add the data through the Firebase Console:

1. Go to Firebase Console → Firestore
2. Create the following growth methods in the `growthMethods` collection:

### Growth Methods to Add:

**angion_method_1_0** (Stage 2 - Foundation)
- Title: Angion Method 1.0
- Description: Venous-focused technique to improve blood flow. Foundational vascular training.

**angion_method_2_5** (Stage 4 - Intermediate)
- Title: Angion Method 2.5 (Jelq 2.0)
- Description: Bridge technique between Angion Method 2.0 and 3.0

**angion_method_3_0** (Stage 5 - Expert)
- Title: Angion Method 3.0 (Vascion)
- Description: The pinnacle hand technique for maximum vascular development

**bfr_cyclic_bending** (Stage 3 - Intermediate)
- Title: BFR Cyclic Bending
- Description: Blood Flow Restriction technique using cyclic pressure

**bfr_glans_pulsing** (Stage 3 - Intermediate)
- Title: BFR Glans Pulsing
- Description: Gentle pulsing technique for venous stimulation

**sabre_type_a** through **sabre_type_d** (Stages 2-5)
- Progressive SABRE strike techniques

**s2s_advanced** (Stage 2 - Foundation)
- Title: S2S Advanced Stretches
- Description: Side-to-side stretching for flexibility

### Routine to Add:

In the `routines` collection, create document with ID: `janus_protocol_12week`
- Name: Janus Protocol - 12 Week Advanced
- Difficulty: Advanced
- 84 days total (12 weeks)
- Structured progression through all techniques

## Option 3: Using the App Code Itself

Since the app already has sample data loading capability, you can:

1. Update `SampleGrowthMethods.swift` with all the methods
2. Create a one-time data migration function in the app
3. Run it once to populate Firestore

## Data Files

The complete data structure is available in:
- `add-janus-protocol-web.mjs` - Contains all method and routine data
- `add-janus-protocol-complete.mjs` - Admin SDK version

## Important Notes

- These are ADVANCED techniques requiring mastery of foundational methods
- The 12-week routine includes built-in deload weeks for recovery
- Users should meet all progression criteria before advancing
- Safety warnings are critical - never train through pain

## Verification

After adding data, verify in the app:
1. Methods appear in the Methods tab
2. "Janus Protocol - 12 Week Advanced" appears in Routines
3. All method IDs in the routine schedule resolve correctly