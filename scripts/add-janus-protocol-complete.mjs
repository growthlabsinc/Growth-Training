import admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Check if running in production mode
const isProduction = process.argv.includes('--production');

// Initialize Firebase Admin SDK
let serviceAccountPath;
if (isProduction) {
  serviceAccountPath = path.join(__dirname, '../Growth/Resources/Plist/GoogleService-Info.plist');
} else {
  serviceAccountPath = path.join(__dirname, '../Growth/Resources/Plist/dev.GoogleService-Info.json');
}

// Check if service account file exists
if (!fs.existsSync(serviceAccountPath)) {
  console.error(`Service account file not found at: ${serviceAccountPath}`);
  console.error('Please ensure the Firebase service account JSON file exists.');
  process.exit(1);
}

// Read the service account file
const serviceAccountContent = fs.readFileSync(serviceAccountPath, 'utf8');
const serviceAccount = JSON.parse(serviceAccountContent);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addAllData() {
  console.log(`Running in ${isProduction ? 'PRODUCTION' : 'DEVELOPMENT'} mode\n`);
  
  // Add Growth Methods
  console.log('=== Adding Growth Methods ===');
  const methodsBatch = db.batch();
  const methodsRef = db.collection('growthMethods');
  
  const methods = [
    // Angion Methods
    {
      id: "angion_method_1_0",
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
      id: "angion_method_2_5",
      stage: 4,
      classification: "Intermediate",
      title: "Angion Method 2.5 (Jelq 2.0)",
      description: "Bridge technique between Angion Method 2.0 and 3.0, focusing on Corpora Spongiosum development.",
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
      benefits: ["CS development", "Bridge to Angion Method 3.0", "Improved glans fullness"]
    },
    {
      id: "angion_method_3_0",
      stage: 5,
      classification: "Expert",
      title: "Angion Method 3.0 (Vascion)",
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
  
  for (const method of methods) {
    const docRef = methodsRef.doc(method.id);
    methodsBatch.set(docRef, {
      ...method,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`✓ Prepared method: ${method.title}`);
  }
  
  try {
    await methodsBatch.commit();
    console.log('\n✅ Successfully added all growth methods!\n');
  } catch (error) {
    console.error('❌ Error adding growth methods:', error);
    return;
  }
  
  // Add the 12-Week Routine
  console.log('=== Adding 12-Week Advanced Routine ===');
  
  const routine = {
    id: "janus_protocol_12week",
    name: "Janus Protocol - 12 Week Advanced",
    description: "The complete 12-week advanced routine based on the Janus Protocol. Incorporates Angion Methods, SABRE techniques, and BFR training in a carefully structured progression. Requires mastery of intermediate techniques.",
    difficultyLevel: "Advanced",
    schedule: [
      // Week 1
      { id: "w1d1", dayNumber: 1, dayName: "Week 1 Day 1: Heavy Day", description: "Angion Methods + SABRE + BFR", methodIds: ["angion_method_3_0", "sabre_type_b", "bfr_cyclic_bending"], isRestDay: false },
      { id: "w1d2", dayNumber: 2, dayName: "Week 1 Day 2: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w1d3", dayNumber: 3, dayName: "Week 1 Day 3: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w1d4", dayNumber: 4, dayName: "Week 1 Day 4: SABRE/BFR", description: "SABRE and BFR combination", methodIds: ["sabre_type_b", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w1d5", dayNumber: 5, dayName: "Week 1 Day 5: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w1d6", dayNumber: 6, dayName: "Week 1 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w1d7", dayNumber: 7, dayName: "Week 1 Day 7: Heavy Day", description: "Full workout - all techniques", methodIds: ["angion_method_3_0", "sabre_type_b", "bfr_cyclic_bending"], isRestDay: false },
      
      // Week 2
      { id: "w2d1", dayNumber: 8, dayName: "Week 2 Day 1: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w2d2", dayNumber: 9, dayName: "Week 2 Day 2: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w2d3", dayNumber: 10, dayName: "Week 2 Day 3: SABRE/BFR", description: "SABRE and BFR combination", methodIds: ["sabre_type_b", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w2d4", dayNumber: 11, dayName: "Week 2 Day 4: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w2d5", dayNumber: 12, dayName: "Week 2 Day 5: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w2d6", dayNumber: 13, dayName: "Week 2 Day 6: Heavy Day", description: "Full workout - all techniques", methodIds: ["angion_method_3_0", "sabre_type_b", "bfr_cyclic_bending"], isRestDay: false },
      { id: "w2d7", dayNumber: 14, dayName: "Week 2 Day 7: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      
      // Week 3
      { id: "w3d1", dayNumber: 15, dayName: "Week 3 Day 1: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w3d2", dayNumber: 16, dayName: "Week 3 Day 2: SABRE/BFR", description: "SABRE and BFR combination", methodIds: ["sabre_type_b", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w3d3", dayNumber: 17, dayName: "Week 3 Day 3: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w3d4", dayNumber: 18, dayName: "Week 3 Day 4: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w3d5", dayNumber: 19, dayName: "Week 3 Day 5: Heavy Day", description: "Full workout - all techniques", methodIds: ["angion_method_3_0", "sabre_type_b", "bfr_cyclic_bending"], isRestDay: false },
      { id: "w3d6", dayNumber: 20, dayName: "Week 3 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w3d7", dayNumber: 21, dayName: "Week 3 Day 7: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      
      // Week 4 - Deload Week
      { id: "w4d1", dayNumber: 22, dayName: "Week 4 Day 1: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
      { id: "w4d2", dayNumber: 23, dayName: "Week 4 Day 2: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false, additionalNotes: "Keep it very light - recovery focus" },
      { id: "w4d3", dayNumber: 24, dayName: "Week 4 Day 3: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
      { id: "w4d4", dayNumber: 25, dayName: "Week 4 Day 4: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false, additionalNotes: "Keep it very light - recovery focus" },
      { id: "w4d5", dayNumber: 26, dayName: "Week 4 Day 5: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
      { id: "w4d6", dayNumber: 27, dayName: "Week 4 Day 6: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false, additionalNotes: "Keep it very light - recovery focus" },
      { id: "w4d7", dayNumber: 28, dayName: "Week 4 Day 7: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
      
      // Week 5 - Intensity Increase
      { id: "w5d1", dayNumber: 29, dayName: "Week 5 Day 1: Heavy Plus", description: "Increased intensity", methodIds: ["angion_method_3_0", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false, additionalNotes: "Moving to Type C SABRE" },
      { id: "w5d2", dayNumber: 30, dayName: "Week 5 Day 2: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w5d3", dayNumber: 31, dayName: "Week 5 Day 3: Angion Focus", description: "Extended Angion session", methodIds: ["angion_method_3_0"], isRestDay: false, additionalNotes: "Try for 35-40 minutes if possible" },
      { id: "w5d4", dayNumber: 32, dayName: "Week 5 Day 4: SABRE/BFR", description: "Higher intensity SABRE", methodIds: ["sabre_type_c", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w5d5", dayNumber: 33, dayName: "Week 5 Day 5: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w5d6", dayNumber: 34, dayName: "Week 5 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w5d7", dayNumber: 35, dayName: "Week 5 Day 7: Heavy Plus", description: "Full workout with Type C SABRE", methodIds: ["angion_method_3_0", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false },
      
      // Week 6
      { id: "w6d1", dayNumber: 36, dayName: "Week 6 Day 1: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w6d2", dayNumber: 37, dayName: "Week 6 Day 2: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w6d3", dayNumber: 38, dayName: "Week 6 Day 3: SABRE/BFR", description: "Type C SABRE focus", methodIds: ["sabre_type_c", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w6d4", dayNumber: 39, dayName: "Week 6 Day 4: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w6d5", dayNumber: 40, dayName: "Week 6 Day 5: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w6d6", dayNumber: 41, dayName: "Week 6 Day 6: Heavy Plus", description: "Full workout intensity", methodIds: ["angion_method_3_0", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false },
      { id: "w6d7", dayNumber: 42, dayName: "Week 6 Day 7: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      
      // Week 7
      { id: "w7d1", dayNumber: 43, dayName: "Week 7 Day 1: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w7d2", dayNumber: 44, dayName: "Week 7 Day 2: SABRE/BFR", description: "Maintain Type C intensity", methodIds: ["sabre_type_c", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w7d3", dayNumber: 45, dayName: "Week 7 Day 3: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w7d4", dayNumber: 46, dayName: "Week 7 Day 4: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w7d5", dayNumber: 47, dayName: "Week 7 Day 5: Heavy Plus", description: "Full workout intensity", methodIds: ["angion_method_3_0", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false },
      { id: "w7d6", dayNumber: 48, dayName: "Week 7 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w7d7", dayNumber: 49, dayName: "Week 7 Day 7: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      
      // Week 8 - Deload
      { id: "w8d1", dayNumber: 50, dayName: "Week 8 Day 1: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
      { id: "w8d2", dayNumber: 51, dayName: "Week 8 Day 2: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false },
      { id: "w8d3", dayNumber: 52, dayName: "Week 8 Day 3: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
      { id: "w8d4", dayNumber: 53, dayName: "Week 8 Day 4: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false },
      { id: "w8d5", dayNumber: 54, dayName: "Week 8 Day 5: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
      { id: "w8d6", dayNumber: 55, dayName: "Week 8 Day 6: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false },
      { id: "w8d7", dayNumber: 56, dayName: "Week 8 Day 7: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
      
      // Week 9 - Peak Intensity Introduction
      { id: "w9d1", dayNumber: 57, dayName: "Week 9 Day 1: Peak Heavy", description: "Introducing Type D SABRE", methodIds: ["angion_method_3_0", "sabre_type_d", "bfr_cyclic_bending"], isRestDay: false, additionalNotes: "First Type D session - be very careful" },
      { id: "w9d2", dayNumber: 58, dayName: "Week 9 Day 2: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w9d3", dayNumber: 59, dayName: "Week 9 Day 3: Angion Focus", description: "Recovery focus", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w9d4", dayNumber: 60, dayName: "Week 9 Day 4: Moderate SABRE", description: "Back to Type C for recovery", methodIds: ["sabre_type_c", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w9d5", dayNumber: 61, dayName: "Week 9 Day 5: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w9d6", dayNumber: 62, dayName: "Week 9 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w9d7", dayNumber: 63, dayName: "Week 9 Day 7: Heavy Plus", description: "Type C intensity", methodIds: ["angion_method_3_0", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false },
      
      // Week 10
      { id: "w10d1", dayNumber: 64, dayName: "Week 10 Day 1: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w10d2", dayNumber: 65, dayName: "Week 10 Day 2: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w10d3", dayNumber: 66, dayName: "Week 10 Day 3: Peak SABRE", description: "Type D SABRE session", methodIds: ["sabre_type_d", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w10d4", dayNumber: 67, dayName: "Week 10 Day 4: Angion Focus", description: "Recovery focus", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w10d5", dayNumber: 68, dayName: "Week 10 Day 5: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w10d6", dayNumber: 69, dayName: "Week 10 Day 6: Peak Heavy", description: "Full Type D workout", methodIds: ["angion_method_3_0", "sabre_type_d", "bfr_cyclic_bending"], isRestDay: false },
      { id: "w10d7", dayNumber: 70, dayName: "Week 10 Day 7: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      
      // Week 11
      { id: "w11d1", dayNumber: 71, dayName: "Week 11 Day 1: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w11d2", dayNumber: 72, dayName: "Week 11 Day 2: Peak SABRE", description: "Maintaining peak intensity", methodIds: ["sabre_type_d", "bfr_glans_pulsing"], isRestDay: false },
      { id: "w11d3", dayNumber: 73, dayName: "Week 11 Day 3: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      { id: "w11d4", dayNumber: 74, dayName: "Week 11 Day 4: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w11d5", dayNumber: 75, dayName: "Week 11 Day 5: Peak Heavy", description: "Full Type D workout", methodIds: ["angion_method_3_0", "sabre_type_d", "bfr_cyclic_bending"], isRestDay: false },
      { id: "w11d6", dayNumber: 76, dayName: "Week 11 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
      { id: "w11d7", dayNumber: 77, dayName: "Week 11 Day 7: Angion Focus", description: "Angion Methods only", methodIds: ["angion_method_3_0"], isRestDay: false },
      
      // Week 12 - Final Deload
      { id: "w12d1", dayNumber: 78, dayName: "Week 12 Day 1: Rest", description: "Final deload - complete rest", methodIds: null, isRestDay: true },
      { id: "w12d2", dayNumber: 79, dayName: "Week 12 Day 2: Light S2S", description: "Light recovery work", methodIds: ["s2s_advanced"], isRestDay: false },
      { id: "w12d3", dayNumber: 80, dayName: "Week 12 Day 3: Rest", description: "Final deload - complete rest", methodIds: null, isRestDay: true },
      { id: "w12d4", dayNumber: 81, dayName: "Week 12 Day 4: Light Angion", description: "Light Angion work", methodIds: ["am2_0"], isRestDay: false, additionalNotes: "Use Angion Method 2.0 for lighter intensity" },
      { id: "w12d5", dayNumber: 82, dayName: "Week 12 Day 5: Rest", description: "Final deload - complete rest", methodIds: null, isRestDay: true },
      { id: "w12d6", dayNumber: 83, dayName: "Week 12 Day 6: Assessment", description: "Light session to assess progress", methodIds: ["angion_method_3_0"], isRestDay: false, additionalNotes: "20 minutes max - assess improvements" },
      { id: "w12d7", dayNumber: 84, dayName: "Week 12 Day 7: Complete", description: "Program complete - rest and plan next cycle", methodIds: null, isRestDay: true, additionalNotes: "Congratulations! Take measurements and plan next training cycle" }
    ],
    createdAt: new Date(),
    updatedAt: new Date()
  };
  
  try {
    const routineRef = db.collection('routines').doc(routine.id);
    await routineRef.set({
      ...routine,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Successfully added the Janus Protocol 12-Week Advanced Routine!');
    console.log(`   Total days: ${routine.schedule.length}`);
    console.log(`   Training days: ${routine.schedule.filter(d => !d.isRestDay).length}`);
    console.log(`   Rest days: ${routine.schedule.filter(d => d.isRestDay).length}`);
  } catch (error) {
    console.error('❌ Error adding routine:', error);
  }
}

// Run the script
addAllData().then(() => {
  console.log('\n🎉 Script completed successfully!');
  process.exit(0);
}).catch(error => {
  console.error('\n💥 Script failed:', error);
  process.exit(1);
});