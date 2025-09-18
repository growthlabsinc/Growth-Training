const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require(path.join(__dirname, '../Growth/Resources/Plist/dev.GoogleService-Info.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// New Growth Methods based on Janus Protocol
const newMethods = [
  // Angion Methods (already have AM2.0, adding the rest)
  {
    id: "am1_0",
    stage: 2,
    classification: "Foundation",
    title: "Angion Method 1.0",
    description: "Venous-focused technique to improve blood flow. Foundational vascular training.",
    instructionsText: "Obtain an erection and apply water or silicone-based lubricant along the dorsal side. Place thumbs on dorsal veins, stroke downward from glans to base alternating thumbs. Start slowly, aim to increase pace. Maintain for 20-30 minutes.",
    visualPlaceholderUrl: null,
    equipmentNeeded: ["Water or silicone-based lubricant"],
    estimatedDurationMinutes: 30,
    categories: ["Angion", "Foundation"],
    isFeatured: true,
    progressionCriteria: {
      minSessionsAtThisStage: 15,
      minConsecutiveDaysPractice: 7,
      timeSpentAtStageMinutes: 450,
      additionalCriteria: {
        "canMaintainErection": "Full 30 minute session",
        "canPalpateDoralPulse": "Yes"
      }
    },
    safetyNotes: "Never perform while seated. Stop if pain occurs. Loss of erection is normal initially.",
    benefits: ["Improved venous circulation", "Better resting fullness", "Foundation for advanced methods"],
    timerConfig: {
      recommendedDurationSeconds: 1800,
      isCountdown: false,
      hasIntervals: false
    }
  },
  {
    id: "am2_5",
    stage: 4,
    classification: "Intermediate",
    title: "Angion Method 2.5 (Jelq 2.0)",
    description: "Bridge technique between AM 2.0 and 3.0, focusing on Corpora Spongiosum development.",
    instructionsText: "Obtain erection, apply lubricant. Using first two fingers, depress corpora spongiosum with thumb facing down. Pull upward with partial grip focusing force on CS. Start slow, increase speed as session progresses. Should feel glans swell and blood rush through dorsal veins.",
    visualPlaceholderUrl: null,
    equipmentNeeded: ["Water or silicone-based lubricant"],
    estimatedDurationMinutes: 30,
    categories: ["Angion", "Intermediate"],
    isFeatured: false,
    progressionCriteria: {
      minSessionsAtThisStage: 10,
      timeSpentAtStageMinutes: 300,
      additionalCriteria: {
        "canPerformVascion": "5 minutes minimum"
      }
    },
    safetyNotes: "Focus on corpora spongiosum, not full encircling grip. Stop if pain occurs.",
    benefits: ["CS development", "Bridge to Vascion", "Improved glans fullness"]
  },
  {
    id: "vascion",
    stage: 5,
    classification: "Expert",
    title: "Vascion (Angion Method 3.0)",
    description: "The pinnacle hand technique focusing on Corpora Spongiosum stimulation for maximum vascular development.",
    instructionsText: "Lay on back, apply liberal lubricant to CS. Using middle fingers, depress CS while stroking upward in alternating fashion. Glans should swell, blood rushes through dorsal veins. Maintain rapid alternating strokes for full session. Supra-physiological engorgement is common.",
    visualPlaceholderUrl: null,
    equipmentNeeded: ["Silicone-based lubricant (ideal)"],
    estimatedDurationMinutes: 30,
    categories: ["Angion", "Expert"],
    isFeatured: true,
    progressionCriteria: {
      minSessionsAtThisStage: 30,
      timeSpentAtStageMinutes: 900,
      additionalCriteria: {
        "canMaintainFullSession": "30 minutes without CS flattening"
      }
    },
    safetyNotes: "CS flattening is normal initially. Short-lived priapisms may occur post-session. This is normal.",
    benefits: ["Maximum vascular development", "Supra-physiological engorgement", "Peak hand technique mastery"],
    timerConfig: {
      recommendedDurationSeconds: 1800,
      maxRecommendedDurationSeconds: 1800,
      isCountdown: false,
      hasIntervals: false
    }
  },
  // BFR Techniques
  {
    id: "bfr_cyclic_bending",
    stage: 3,
    classification: "Intermediate",
    title: "BFR Cyclic Bending",
    description: "Blood Flow Restriction technique using cyclic pressure to encourage venous arterialization.",
    instructionsText: "While heavily engorged, clamp base with one hand. With other hand, take overhand grip on upper shaft. Kegel blood in, then gently bend member left/right cyclically. Blood pressure will build causing vascular expansion. Release clamp every 30 seconds to let tissues breathe. Total 15-20 minutes.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 20,
    categories: ["BFR", "Pressure"],
    isFeatured: false,
    progressionCriteria: {
      minSessionsAtThisStage: 10,
      additionalCriteria: {
        "noBloodSpots": "Yes",
        "comfortableWithTechnique": "Yes"
      }
    },
    safetyNotes: "CRITICAL: Be very gentle. Too much pressure causes blood spots/vessel damage. Release every 30 seconds. Never train to pain.",
    benefits: ["Venous network strengthening", "Improved pressure tolerance", "Arterialization effects"],
    timerConfig: {
      recommendedDurationSeconds: 1200,
      hasIntervals: true,
      intervals: [
        { name: "Pressure Phase", durationSeconds: 30 },
        { name: "Release Phase", durationSeconds: 10 }
      ]
    }
  },
  {
    id: "bfr_glans_pulsing",
    stage: 3,
    classification: "Intermediate", 
    title: "BFR Glans Pulsing",
    description: "Gentle pulsing technique to stimulate venous networks through pressure fluctuations.",
    instructionsText: "Achieve full erection. Grip base to restrict outflow. With other hand, gently pulse/squeeze glans rhythmically. Should feel slight dull ache, never pain. Release base grip every 30 seconds. Continue for 15-20 minutes total.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 20,
    categories: ["BFR", "Pressure"],
    isFeatured: false,
    safetyNotes: "GENTLE squeezes only. No red spots should appear. Dull ache is ok, pain means stop.",
    benefits: ["PDGF release", "Venous network stimulation", "Controlled pressure training"]
  },
  // SABRE Techniques
  {
    id: "sabre_type_a",
    stage: 2,
    classification: "Foundation",
    title: "SABRE Type A - Low Speed/Low Intensity",
    description: "Foundation SABRE strikes for EQ improvement and vascular development.",
    instructionsText: "Using hand strikes at 1-3 per second with light force. Focus 10 minutes each on left corporal body, right corporal body, and glans. Work with flaccid to partially erect state. This is a timed session focused on shear stress.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 30,
    categories: ["SABRE", "Foundation"],
    isFeatured: false,
    progressionCriteria: {
      minSessionsAtThisStage: 10,
      timeSpentAtStageMinutes: 300
    },
    safetyNotes: "Light force only. Never strike with pain-inducing force.",
    benefits: ["EQ improvement", "Vascular network development", "Foundation for advanced SABRE"]
  },
  {
    id: "sabre_type_b", 
    stage: 3,
    classification: "Intermediate",
    title: "SABRE Type B - High Speed/Low Intensity",
    description: "Increased speed SABRE for enhanced shear stress and Bayliss Effect activation.",
    instructionsText: "Hand strikes at 2-5 per second with light force. Work primarily with heavily engorged flaccid to partially erect state. 10 minutes per corporal body and glans. Focus on consistent rhythm.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 30,
    categories: ["SABRE", "Intermediate"],
    isFeatured: false,
    safetyNotes: "Maintain light force despite increased speed. Stop if discomfort occurs.",
    benefits: ["Bayliss Effect activation", "Enhanced shear stress", "Smooth muscle stimulation"]
  },
  {
    id: "sabre_type_c",
    stage: 4,
    classification: "Intermediate",
    title: "SABRE Type C - Low Speed/High Intensity", 
    description: "Stretch-focused SABRE strikes for tissue expansion.",
    instructionsText: "Using metal rod (8-10 inch smooth bolt), perform 1 strike per second with moderate force. Work with partially erect state. Do 60 strikes per corporal body per set, 3 sets each. Palm strikes for glans.",
    equipmentNeeded: ["Smooth metal rod (8-10 inch bolt, 0.5 inch diameter)"],
    estimatedDurationMinutes: 20,
    categories: ["SABRE", "Advanced"],
    isFeatured: false,
    progressionCriteria: {
      minSessionsAtThisStage: 15,
      additionalCriteria: {
        "comfortableWithRod": "Yes",
        "noDiscomfort": "Yes"
      }
    },
    safetyNotes: "Start very gentle to acclimate. Never strike with painful force. Control is critical.",
    benefits: ["Tissue stretch stimulation", "Controlled pressure application", "Advanced conditioning"]
  },
  {
    id: "sabre_type_d",
    stage: 5,
    classification: "Expert",
    title: "SABRE Type D - High Speed/High Intensity",
    description: "Maximum intensity SABRE for advanced practitioners.",
    instructionsText: "Using metal rod, 2-5 strikes per second with moderate force. Partially to fully erect state. 2 sets of 60 strikes per corporal body. Requires excellent control and conditioning.",
    equipmentNeeded: ["Smooth metal rod", "Warm towel for aftercare"],
    estimatedDurationMinutes: 15,
    categories: ["SABRE", "Expert"],
    isFeatured: false,
    safetyNotes: "Only after mastering Type C. Extreme caution required. Stop immediately if pain occurs.",
    benefits: ["Maximum stimulation", "Peak conditioning", "Advanced tissue adaptation"]
  },
  // S2S included in original but adding proper entry
  {
    id: "s2s_advanced",
    stage: 2,
    classification: "Foundation",
    title: "S2S Advanced Stretches",
    description: "Side-to-side stretching routine for flexibility and warm-up.",
    instructionsText: "While flaccid, grasp behind glans. Pull gently side to side, holding 30-60 seconds each direction. Can also do rotational stretches. Multiple sets throughout the day. Excellent for rest days or warm-up.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 10,
    categories: ["Stretching", "Recovery"],
    isFeatured: false,
    benefits: ["Improved flexibility", "Gentle conditioning", "Active recovery"],
    timerConfig: {
      hasIntervals: true,
      intervals: [
        { name: "Left Stretch", durationSeconds: 30 },
        { name: "Rest", durationSeconds: 5 },
        { name: "Right Stretch", durationSeconds: 30 },
        { name: "Rest", durationSeconds: 5 }
      ]
    }
  }
];

async function addGrowthMethods() {
  console.log('Adding new growth methods to Firestore...');
  
  const batch = db.batch();
  const methodsRef = db.collection('growthMethods');
  
  for (const method of newMethods) {
    const docRef = methodsRef.doc(method.id);
    batch.set(docRef, {
      ...method,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`Prepared method: ${method.title}`);
  }
  
  try {
    await batch.commit();
    console.log('Successfully added all growth methods!');
  } catch (error) {
    console.error('Error adding growth methods:', error);
  }
}

// Run the function
addGrowthMethods().then(() => {
  console.log('Script completed');
  process.exit(0);
}).catch(error => {
  console.error('Script failed:', error);
  process.exit(1);
});