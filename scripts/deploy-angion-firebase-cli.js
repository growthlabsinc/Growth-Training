#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

// Methods to deploy
const methodsToReplace = [
  {
    fileName: 'angion-method-1-0-multistep.json',
    methodId: 'angion_method_1_0',
    name: 'Angion Method 1.0'
  }
];

// First, let's create the proper JSON files for empty ones
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
  isFeatured: false,
  timerConfig: {
    intervals: [
      { name: "Equipment Setup", duration: 180, type: "preparation" },
      { name: "Initial Test", duration: 60, type: "work" },
      { name: "Pumping Phase", duration: 1800, type: "work" },
      { name: "Cool Down", duration: 120, type: "rest" }
    ],
    totalDuration: 2160,
    hasRest: 1,
    restBetweenSets: 0
  }
};

// Write the angio pumping file
fs.writeFileSync(
  path.join(__dirname, 'angion-methods-multistep/angio-pumping.json'),
  JSON.stringify(angioPumpingData, null, 2)
);

console.log('✅ Created angio-pumping.json');

// Now let's deploy using Firebase CLI
async function deployWithFirebaseCLI() {
  console.log('🚀 Starting Angion Methods deployment using Firebase CLI...\n');
  
  try {
    // First, let's verify we're in the right project
    const { stdout: projectInfo } = await execPromise('firebase use');
    console.log('📋 Current Firebase project:', projectInfo.trim());
    
    // Deploy the Angion Method 1.0
    console.log('\n📋 Deploying Angion Method 1.0...');
    const method1Data = fs.readFileSync(path.join(__dirname, 'angion-method-1-0-multistep.json'), 'utf8');
    const method1 = JSON.parse(method1Data);
    
    // Write to a temp file for Firebase CLI
    const tempFile = path.join(__dirname, 'temp-deploy.json');
    fs.writeFileSync(tempFile, JSON.stringify({
      growthMethods: {
        angion_method_1_0: method1
      }
    }));
    
    // Deploy using Firebase CLI
    const deployCmd = `firebase firestore:delete growthMethods/angion_method_1_0 --force && echo '${JSON.stringify(method1)}' | firebase firestore:set growthMethods/angion_method_1_0`;
    
    console.log('Deploying to Firestore...');
    await execPromise(deployCmd);
    
    console.log('✅ Angion Method 1.0 deployed successfully!');
    
    // Clean up
    if (fs.existsSync(tempFile)) {
      fs.unlinkSync(tempFile);
    }
    
  } catch (error) {
    console.error('❌ Deployment error:', error.message);
  }
}

// Run the deployment
deployWithFirebaseCLI().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});