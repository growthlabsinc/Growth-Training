# 🚀 Quick Deployment Instructions

The multi-step method data is ready to deploy to Firebase\!

## Files Ready for Deployment

✅ **Angion Method 1.0** (8 steps)
📁 Location: `scripts/firebase-deploy-data/angion_method_1_0.json`

✅ **Angio Pumping** (8 steps)
📁 Location: `scripts/firebase-deploy-data/angio_pumping.json`

## Deploy via Firebase Console (5 minutes)

1. Open https://console.firebase.google.com
2. Select project: **growth-70a85**
3. Go to **Firestore Database**
4. Find **growthMethods** collection

### For angion_method_1_0 document:
- Add field `hasMultipleSteps` = true
- Add field `steps` = [copy array from angion_method_1_0.json]

### For angio_pumping document:
- Add field `hasMultipleSteps` = true
- Add field `steps` = [copy array from angio_pumping.json]

## That's it\! 🎉

Once deployed, the Routines view will show all 8 detailed steps for each method instead of the simplified version.
EOF < /dev/null