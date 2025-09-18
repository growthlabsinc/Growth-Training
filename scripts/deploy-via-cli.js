#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Deploying Angion Methods via Firebase CLI...\n');

// Read the multi-step data
const angionMethod1 = JSON.parse(fs.readFileSync(path.join(__dirname, 'angion-method-1-0-multistep.json'), 'utf8'));

// Create update commands
const commands = [
  // Angion Method 1.0
  `firebase firestore:set growthMethods/angion_method_1_0 '${JSON.stringify(angionMethod1).replace(/'/g, "'\"'\"'")}'`,
  
  // Angio Pumping - just add the steps field
  `firebase firestore:update growthMethods/angio_pumping --data '{
    "steps": [
      {
        "stepNumber": 1,
        "title": "Safety Check and Equipment Setup",
        "description": "As a safety precaution, males that have experienced prolonged and non-compliant severe erectile dysfunction would be wise to have either an ultrasound or Doppler done on the arteries feeding their sexual organs to check for calcification or blockage.",
        "duration": 60,
        "tips": ["Ensure you have a penis pump with quick release valve", "Must have pressure gauge", "Need elastic ACE bandage wrap", "California Exotics pump recommended for button release mechanism"],
        "warnings": ["Never exceed 4hg pressure", "Ideally stay at or below 3hg"]
      },
      {
        "stepNumber": 2,
        "title": "Prepare Pump and Bandage",
        "description": "Remove the rubber sleeve at the bottom of the pump and place it over your member. Once in place, wrap your member snugly in the ACE elastic bandage wrap.",
        "duration": 120,
        "tips": ["Bandage helps stave off edema", "Increases fluid exchange between arterial and venous networks", "Wrap snugly but not too tight"]
      },
      {
        "stepNumber": 3,
        "title": "Position Equipment",
        "description": "With the bandage wraps in place, slide the penile pump back into its rubber sleeve. Ensure everything is in position and sealed.",
        "duration": 60,
        "tips": ["Check for proper seal", "Ensure comfortable positioning", "Lie down - never perform seated"]
      },
      {
        "stepNumber": 4,
        "title": "Initial Pump Test",
        "description": "Pump until the dial hits 3hg. Your member will likely begin to expand. Now, slowly release the pressure. You should feel blood rushing from your member through your Deep Dorsal Vein and Superficial Vein.",
        "duration": 60,
        "intensity": "low",
        "tips": ["This mechanically forces Bulbo-Dorsal Circuit activation", "Pay attention to the sensation of blood flow", "Go slowly on first attempt"]
      },
      {
        "stepNumber": 5,
        "title": "Rapid Pumping Phase - Beginner",
        "description": "Begin rapidly pumping until the dial reaches 3hg and then releasing the pressure to mechanically force your penile tissues to breathe and exchange fluid between arterial and venous networks.",
        "duration": 300,
        "intensity": "medium",
        "tips": ["Beginners keep sessions short", "Focus on rhythm", "As rate of flow increases, so does shear based stimulation"],
        "warnings": ["Maximum 10 minutes for beginners"]
      },
      {
        "stepNumber": 6,
        "title": "Rapid Pumping Phase - Intermediate",
        "description": "Continue rapid pump and release cycles, maintaining rhythm and watching pressure gauge carefully.",
        "duration": 600,
        "intensity": "medium",
        "tips": ["Only progress to this after several sessions", "May take weeks to reach this duration", "Monitor for any discomfort"]
      },
      {
        "stepNumber": 7,
        "title": "Rapid Pumping Phase - Advanced",
        "description": "For advanced users only. Continue pump and release cycles for extended duration.",
        "duration": 900,
        "intensity": "medium",
        "tips": ["Aim for full 30 minute workout eventually", "Do not rush progression", "Overtraining is counterproductive"]
      },
      {
        "stepNumber": 8,
        "title": "Cool Down and Recovery",
        "description": "Slowly decrease pumping frequency and carefully remove equipment. Remove bandage wrap last.",
        "duration": 120,
        "intensity": "low",
        "tips": ["Release all pressure before removing", "Remove bandage gently", "Allow natural recovery"]
      }
    ]
  }'`
];

console.log('📝 Current Firebase project:');
execSync('firebase use', { stdio: 'inherit' });

console.log('\n🔧 Manual Steps:');
console.log('1. Copy the JSON data from scripts/firebase-deploy-data/');
console.log('2. Go to Firebase Console > Firestore');
console.log('3. Update the growthMethods collection documents manually');
console.log('   - angion_method_1_0: Add the "steps" array field');
console.log('   - angio_pumping: Add the "steps" array field');

console.log('\n✅ Deployment preparation complete!');
console.log('📁 JSON files are in: scripts/firebase-deploy-data/');