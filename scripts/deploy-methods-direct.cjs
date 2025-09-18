#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Read the multi-step data
const angionMethod1Data = JSON.parse(fs.readFileSync(path.join(__dirname, 'angion-method-1-0-multistep.json'), 'utf8'));

// Angio Pumping data with full 8 steps
const angioPumpingData = {
  id: "angio_pumping",
  stage: 3,
  classification: "Specialized",
  title: "Angio Pumping",
  description: "For males with non-compliant severe ED who need mechanical intervention to activate vascular networks.",
  instructionsText: "A specialized pumping technique that mechanically forces Bulbo-Dorsal Circuit activation.",
  steps: [
    {
      stepNumber: 1,
      title: "Safety Check and Equipment Setup",
      description: "As a safety precaution, males that have experienced prolonged and non-compliant severe erectile dysfunction would be wise to have either an ultrasound or Doppler done on the arteries feeding their sexual organs to check for calcification or blockage.",
      duration: 60,
      tips: [
        "Ensure you have a penis pump with quick release valve",
        "Must have pressure gauge",
        "Need elastic ACE bandage wrap",
        "California Exotics pump recommended for button release mechanism"
      ],
      warnings: ["Never exceed 4hg pressure", "Ideally stay at or below 3hg"]
    },
    {
      stepNumber: 2,
      title: "Prepare Pump and Bandage",
      description: "Remove the rubber sleeve at the bottom of the pump and place it over your member. Once in place, wrap your member snugly in the ACE elastic bandage wrap.",
      duration: 120,
      tips: [
        "Bandage helps stave off edema",
        "Increases fluid exchange between arterial and venous networks",
        "Wrap snugly but not too tight"
      ]
    },
    {
      stepNumber: 3,
      title: "Position Equipment",
      description: "With the bandage wraps in place, slide the penile pump back into its rubber sleeve. Ensure everything is in position and sealed.",
      duration: 60,
      tips: [
        "Check for proper seal",
        "Ensure comfortable positioning",
        "Lie down - never perform seated"
      ]
    },
    {
      stepNumber: 4,
      title: "Initial Pump Test",
      description: "Pump until the dial hits 3hg. Your member will likely begin to expand. Now, slowly release the pressure. You should feel blood rushing from your member through your Deep Dorsal Vein and Superficial Vein.",
      duration: 60,
      intensity: "low",
      tips: [
        "This mechanically forces Bulbo-Dorsal Circuit activation",
        "Pay attention to the sensation of blood flow",
        "Go slowly on first attempt"
      ]
    },
    {
      stepNumber: 5,
      title: "Rapid Pumping Phase - Beginner",
      description: "Begin rapidly pumping until the dial reaches 3hg and then releasing the pressure to mechanically force your penile tissues to breathe and exchange fluid between arterial and venous networks.",
      duration: 300,
      intensity: "medium",
      tips: [
        "Beginners keep sessions short",
        "Focus on rhythm",
        "As rate of flow increases, so does shear based stimulation"
      ],
      warnings: ["Maximum 10 minutes for beginners"]
    },
    {
      stepNumber: 6,
      title: "Rapid Pumping Phase - Intermediate",
      description: "Continue rapid pump and release cycles, maintaining rhythm and watching pressure gauge carefully.",
      duration: 600,
      intensity: "medium",
      tips: [
        "Only progress to this after several sessions",
        "May take weeks to reach this duration",
        "Monitor for any discomfort"
      ]
    },
    {
      stepNumber: 7,
      title: "Rapid Pumping Phase - Advanced",
      description: "For advanced users only. Continue pump and release cycles for extended duration.",
      duration: 900,
      intensity: "medium",
      tips: [
        "Aim for full 30 minute workout eventually",
        "Don't rush progression",
        "Overtraining is counterproductive"
      ]
    },
    {
      stepNumber: 8,
      title: "Cool Down and Recovery",
      description: "Slowly decrease pumping frequency and carefully remove equipment. Remove bandage wrap last.",
      duration: 120,
      intensity: "low",
      tips: [
        "Release all pressure before removing",
        "Remove bandage gently",
        "Allow natural recovery"
      ]
    }
  ],
  estimatedDurationMinutes: 36,
  equipmentNeeded: ["Penis pump with pressure gauge", "Quick release valve", "ACE elastic bandage wrap"],
  safetyNotes: "Never exceed 4hg pressure. Ideally maintain 3hg or below. Never perform while seated - always lie down. Stop immediately if pain occurs.",
  categories: ["Recovery", "Specialized"],
  benefits: [
    "Mechanically activates Bulbo-Dorsal Circuit",
    "Forces vascular network expansion",
    "Helps with severe ED cases"
  ],
  hasMultipleSteps: true,
  isActive: true,
  isFeatured: false
};

console.log('🚀 Firebase Method Deployment Script');
console.log('=====================================\n');

console.log('📝 Methods to deploy:');
console.log('1. Angion Method 1.0 - ' + angionMethod1Data.steps.length + ' steps');
console.log('2. Angio Pumping - ' + angioPumpingData.steps.length + ' steps\n');

console.log('⚠️  This script requires Firebase authentication to be set up.\n');

console.log('📋 Next Steps:');
console.log('1. Ensure you are logged into Firebase CLI: firebase login');
console.log('2. Use Firebase Console to manually update the methods');
console.log('3. Or use the Firebase Admin SDK with proper service account\n');

console.log('🔧 Manual Update Instructions:');
console.log('1. Go to Firebase Console > Firestore Database');
console.log('2. Navigate to the "growthMethods" collection');
console.log('3. Find document: angion_method_1_0');
console.log('4. Add/Update the "steps" field with the multi-step data');
console.log('5. Repeat for angio_pumping document\n');

// Write the data to files for easy copying
const outputDir = path.join(__dirname, 'firebase-deploy-data');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir);
}

fs.writeFileSync(
  path.join(outputDir, 'angion_method_1_0.json'),
  JSON.stringify(angionMethod1Data, null, 2)
);

fs.writeFileSync(
  path.join(outputDir, 'angio_pumping.json'),
  JSON.stringify(angioPumpingData, null, 2)
);

console.log('✅ Data files created in: ' + outputDir);
console.log('   - angion_method_1_0.json');
console.log('   - angio_pumping.json\n');

console.log('📌 You can copy these JSON files to update Firebase manually.');
console.log('📌 Or use Firebase Functions to deploy programmatically.\n');

// Create a Firebase Function deployment script
const functionDeployScript = `
// Deploy this as a Firebase Function to update the methods

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

exports.deployAngionMethods = functions.https.onCall(async (data, context) => {
  try {
    // Angion Method 1.0 data
    const angionMethod1 = ${JSON.stringify(angionMethod1Data, null, 2)};
    
    // Angio Pumping data
    const angioPumping = ${JSON.stringify(angioPumpingData, null, 2)};
    
    // Update Firestore
    const batch = db.batch();
    
    batch.set(db.collection('growthMethods').doc('angion_method_1_0'), angionMethod1, { merge: true });
    batch.set(db.collection('growthMethods').doc('angio_pumping'), angioPumping, { merge: true });
    
    await batch.commit();
    
    return { 
      success: true, 
      message: 'Methods deployed successfully',
      methods: ['angion_method_1_0', 'angio_pumping']
    };
  } catch (error) {
    console.error('Deployment error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
`;

fs.writeFileSync(
  path.join(outputDir, 'deploy-function.js'),
  functionDeployScript
);

console.log('🔥 Firebase Function created: deploy-function.js');
console.log('   Deploy it with: firebase deploy --only functions:deployAngionMethods\n');

console.log('✅ Deployment preparation complete!');