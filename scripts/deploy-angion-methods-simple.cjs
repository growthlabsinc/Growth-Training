#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');

// Firebase configuration
const PROJECT_ID = 'growth-70a85';
const API_KEY = 'AIzaSyC-iNr6VkDx38j2g-rPoH1CRYV8XlQTVpY';

// Method data
const angionMethod1Data = JSON.parse(fs.readFileSync(path.join(__dirname, 'firebase-deploy-data/angion_method_1_0.json'), 'utf8'));

// Angio Pumping data
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
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  viewCount: 0,
  averageRating: 0,
  totalRatings: 0
};

// Function to update Firestore using REST API
async function updateFirestoreDocument(collection, documentId, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      fields: convertToFirestoreFormat(data)
    });

    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${documentId}?key=${API_KEY}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': postData.length
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

// Convert JS object to Firestore format
function convertToFirestoreFormat(obj) {
  const result = {};
  
  for (const [key, value] of Object.entries(obj)) {
    if (value === null || value === undefined) continue;
    
    if (typeof value === 'string') {
      result[key] = { stringValue: value };
    } else if (typeof value === 'number') {
      result[key] = { integerValue: Math.floor(value) };
    } else if (typeof value === 'boolean') {
      result[key] = { booleanValue: value };
    } else if (Array.isArray(value)) {
      result[key] = { 
        arrayValue: { 
          values: value.map(v => {
            if (typeof v === 'string') return { stringValue: v };
            if (typeof v === 'object') return { mapValue: { fields: convertToFirestoreFormat(v) } };
            return { stringValue: String(v) };
          })
        }
      };
    } else if (typeof value === 'object') {
      result[key] = { mapValue: { fields: convertToFirestoreFormat(value) } };
    }
  }
  
  return result;
}

// Main deployment function
async function deploy() {
  console.log('🚀 Starting Angion Methods deployment...\n');
  
  try {
    // Deploy Angion Method 1.0
    console.log('📋 Deploying Angion Method 1.0...');
    await updateFirestoreDocument('growthMethods', 'angion_method_1_0', angionMethod1Data);
    console.log('✅ Angion Method 1.0 deployed successfully!');
    
    // Deploy Angio Pumping
    console.log('\n📋 Deploying Angio Pumping...');
    await updateFirestoreDocument('growthMethods', 'angio_pumping', angioPumpingData);
    console.log('✅ Angio Pumping deployed successfully!');
    
    console.log('\n🎉 All methods deployed successfully!');
    console.log('📝 The methods now have full multi-step instructions in Firebase.');
    
  } catch (error) {
    console.error('❌ Deployment error:', error.message);
    if (error.message.includes('403')) {
      console.error('\n⚠️  Permission denied. Please check:');
      console.error('   1. Firebase project permissions');
      console.error('   2. API key is correct');
      console.error('   3. Firestore security rules allow writes');
    }
  }
}

// Run deployment
deploy();