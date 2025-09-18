# Angion Methods Multi-Step Deployment Instructions

## Quick Deployment Steps

Since direct Firebase deployment requires service account credentials, here are the manual deployment steps:

### Option 1: Firebase Console (Recommended)

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/project/growth-70a85/firestore/data/~2FgrowthMethods

2. **Update Each Method**
   - Click on each method document ID
   - Click "Edit document"
   - Copy the entire JSON content from the corresponding file
   - Paste into the document editor
   - **PRESERVE these existing fields:**
     - `createdAt`
     - `viewCount`
     - `averageRating`
     - `totalRatings`
   - Click "Update"

3. **Method Files to Copy**
   ```
   angion_method_1_0 → scripts/angion-method-1-0-multistep.json
   angio_pumping → scripts/angion-methods-multistep/angio-pumping.json
   angion_method_2_0 → scripts/angion-methods-multistep/angion-method-2-0.json
   jelq_2_0 → scripts/angion-methods-multistep/jelq-2-0.json
   vascion → scripts/angion-methods-multistep/vascion.json
   ```

### Option 2: Firebase Admin SDK (Requires Service Account)

1. **Get Service Account Key**
   - Go to: https://console.firebase.google.com/project/growth-70a85/settings/serviceaccounts/adminsdk
   - Click "Generate new private key"
   - Save as `scripts/service-account-key.json`

2. **Run Deployment Script**
   ```bash
   cd scripts
   node replace-all-angion-methods.js
   ```

### Option 3: Using Firebase CLI (Alternative)

If you have Firebase CLI access with proper permissions:

```bash
# Set the project
firebase use growth-70a85

# Deploy using Functions (if you have deployment access)
cd functions
node deploy-angion-methods.js
```

## What Gets Updated

Each method now includes:
- ✅ 7-9 detailed steps with instructions
- ✅ Timer configurations for each phase
- ✅ Safety warnings and tips per step
- ✅ Equipment lists
- ✅ Progression criteria
- ✅ Intensity levels (low/medium/high)
- ✅ Related methods references

## Post-Deployment Verification

1. Check that methods display correctly in the app
2. Test timer functionality with new intervals
3. Verify step navigation works properly
4. Ensure user progress tracking continues

## JSON Preview Helper

To view any method JSON formatted:
```bash
# View Angion Method 1.0
cat scripts/angion-method-1-0-multistep.json | jq .

# View other methods
cat scripts/angion-methods-multistep/angio-pumping.json | jq .
cat scripts/angion-methods-multistep/angion-method-2-0.json | jq .
cat scripts/angion-methods-multistep/jelq-2-0.json | jq .
cat scripts/angion-methods-multistep/vascion.json | jq .
```