import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Growth Methods Data with proper naming
const methods = [
  {
    id: "angion_method_1_0",
    stage: 2,
    classification: "Foundation",
    title: "Angion Method 1.0",
    description: "Venous-focused technique to improve blood flow. Foundational vascular training.",
    instructionsText: "Obtain an erection and apply water or silicone-based lubricant along the dorsal side. Place thumbs on dorsal veins, stroke downward from glans to base alternating thumbs. Start slowly, aim to increase pace. Maintain for 20-30 minutes.",
    equipmentNeeded: ["Water or silicone-based lubricant"],
    estimatedDurationMinutes: 30,
    categories: ["Angion", "Foundation"],
    isFeatured: true,
    safetyNotes: "Never perform while seated. Stop if pain occurs. Loss of erection is normal initially.",
    benefits: ["Improved venous circulation", "Better resting fullness", "Foundation for advanced methods"]
  },
  {
    id: "angion_method_2_5",
    stage: 4,
    classification: "Intermediate",
    title: "Angion Method 2.5 (Jelq 2.0)",
    description: "Bridge technique between Angion Method 2.0 and 3.0, focusing on Corpora Spongiosum development.",
    instructionsText: "Obtain erection, apply lubricant. Using first two fingers, depress corpora spongiosum with thumb facing down. Pull upward with partial grip focusing force on CS. Start slow, increase speed as session progresses.",
    equipmentNeeded: ["Water or silicone-based lubricant"],
    estimatedDurationMinutes: 30,
    categories: ["Angion", "Intermediate"],
    isFeatured: false,
    safetyNotes: "Focus on corpora spongiosum, not full encircling grip. Stop if pain occurs.",
    benefits: ["CS development", "Bridge to Angion Method 3.0", "Improved glans fullness"]
  },
  {
    id: "angion_method_3_0",
    stage: 5,
    classification: "Expert",
    title: "Angion Method 3.0 (Vascion)",
    description: "The pinnacle hand technique focusing on Corpora Spongiosum stimulation for maximum vascular development.",
    instructionsText: "Lay on back, apply liberal lubricant to CS. Using middle fingers, depress CS while stroking upward in alternating fashion. Maintain rapid alternating strokes for full session.",
    equipmentNeeded: ["Silicone-based lubricant (ideal)"],
    estimatedDurationMinutes: 30,
    categories: ["Angion", "Expert"],
    isFeatured: true,
    safetyNotes: "CS flattening is normal initially. Short-lived priapisms may occur post-session. This is normal.",
    benefits: ["Maximum vascular development", "Supra-physiological engorgement", "Peak hand technique mastery"]
  },
  {
    id: "bfr_cyclic_bending",
    stage: 3,
    classification: "Intermediate",
    title: "BFR Cyclic Bending",
    description: "Blood Flow Restriction technique using cyclic pressure to encourage venous arterialization.",
    instructionsText: "While heavily engorged, clamp base with one hand. With other hand, take overhand grip on upper shaft. Kegel blood in, then gently bend member left/right cyclically. Release clamp every 30 seconds.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 20,
    categories: ["BFR", "Pressure"],
    isFeatured: false,
    safetyNotes: "CRITICAL: Be very gentle. Too much pressure causes blood spots/vessel damage. Release every 30 seconds.",
    benefits: ["Venous network strengthening", "Improved pressure tolerance", "Arterialization effects"]
  },
  {
    id: "bfr_glans_pulsing",
    stage: 3,
    classification: "Intermediate",
    title: "BFR Glans Pulsing",
    description: "Gentle pulsing technique to stimulate venous networks through pressure fluctuations.",
    instructionsText: "Achieve full erection. Grip base to restrict outflow. With other hand, gently pulse/squeeze glans rhythmically. Release base grip every 30 seconds.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 20,
    categories: ["BFR", "Pressure"],
    isFeatured: false,
    safetyNotes: "GENTLE squeezes only. No red spots should appear. Dull ache is ok, pain means stop.",
    benefits: ["PDGF release", "Venous network stimulation", "Controlled pressure training"]
  },
  {
    id: "sabre_type_a",
    stage: 2,
    classification: "Foundation",
    title: "SABRE Type A - Low Speed/Low Intensity",
    description: "Foundation SABRE strikes for EQ improvement and vascular development.",
    instructionsText: "Using hand strikes at 1-3 per second with light force. Focus 10 minutes each on left corporal body, right corporal body, and glans.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 30,
    categories: ["SABRE", "Foundation"],
    isFeatured: false,
    safetyNotes: "Light force only. Never strike with pain-inducing force.",
    benefits: ["EQ improvement", "Vascular network development", "Foundation for advanced SABRE"]
  },
  {
    id: "sabre_type_b",
    stage: 3,
    classification: "Intermediate",
    title: "SABRE Type B - High Speed/Low Intensity",
    description: "Increased speed SABRE for enhanced shear stress and Bayliss Effect activation.",
    instructionsText: "Hand strikes at 2-5 per second with light force. Work with heavily engorged flaccid to partially erect state. 10 minutes per corporal body and glans.",
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
    instructionsText: "Using metal rod (8-10 inch smooth bolt), perform 1 strike per second with moderate force. Do 60 strikes per corporal body per set, 3 sets each.",
    equipmentNeeded: ["Smooth metal rod (8-10 inch bolt, 0.5 inch diameter)"],
    estimatedDurationMinutes: 20,
    categories: ["SABRE", "Advanced"],
    isFeatured: false,
    safetyNotes: "Start very gentle to acclimate. Never strike with painful force. Control is critical.",
    benefits: ["Tissue stretch stimulation", "Controlled pressure application", "Advanced conditioning"]
  },
  {
    id: "sabre_type_d",
    stage: 5,
    classification: "Expert",
    title: "SABRE Type D - High Speed/High Intensity",
    description: "Maximum intensity SABRE for advanced practitioners.",
    instructionsText: "Using metal rod, 2-5 strikes per second with moderate force. Partially to fully erect state. 2 sets of 60 strikes per corporal body.",
    equipmentNeeded: ["Smooth metal rod", "Warm towel for aftercare"],
    estimatedDurationMinutes: 15,
    categories: ["SABRE", "Expert"],
    isFeatured: false,
    safetyNotes: "Only after mastering Type C. Extreme caution required. Stop immediately if pain occurs.",
    benefits: ["Maximum stimulation", "Peak conditioning", "Advanced tissue adaptation"]
  },
  {
    id: "s2s_advanced",
    stage: 2,
    classification: "Foundation",
    title: "S2S Advanced Stretches",
    description: "Side-to-side stretching routine for flexibility and warm-up.",
    instructionsText: "While flaccid, grasp behind glans. Pull gently side to side, holding 30-60 seconds each direction. Can also do rotational stretches.",
    equipmentNeeded: [],
    estimatedDurationMinutes: 10,
    categories: ["Stretching", "Recovery"],
    isFeatured: false,
    benefits: ["Improved flexibility", "Gentle conditioning", "Active recovery"]
  }
];

// Export as JSON files
const methodsJson = JSON.stringify(methods, null, 2);
writeFileSync(join(__dirname, 'janus-methods.json'), methodsJson);

// Create a simple routine structure (first 2 weeks as example)
const routineSchedule = [
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
  { id: "w2d7", dayNumber: 14, dayName: "Week 2 Day 7: Rest", description: "Complete rest day", methodIds: null, isRestDay: true }
];

const routine = {
  id: "janus_protocol_12week",
  name: "Janus Protocol - 12 Week Advanced",
  description: "The complete 12-week advanced routine based on the Janus Protocol. Incorporates Angion Methods, SABRE techniques, and BFR training in a carefully structured progression.",
  difficultyLevel: "Advanced",
  schedule: routineSchedule
};

const routineJson = JSON.stringify(routine, null, 2);
writeFileSync(join(__dirname, 'janus-routine-sample.json'), routineJson);

console.log('✅ Data exported to:');
console.log('   - janus-methods.json (all 10 growth methods)');
console.log('   - janus-routine-sample.json (first 2 weeks of routine)');
console.log('\nYou can now import these JSON files into Firebase Console.');