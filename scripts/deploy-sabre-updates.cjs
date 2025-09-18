const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase configuration
const projectId = 'growth-70a85';

// Load step data
const sabreTypeA = JSON.parse(fs.readFileSync(path.join(__dirname, 'sabre-updates/sabre_type_a_steps.json'), 'utf8'));
const sabreTypeB = JSON.parse(fs.readFileSync(path.join(__dirname, 'sabre-updates/sabre_type_b_steps.json'), 'utf8'));
const sabreTypeC = JSON.parse(fs.readFileSync(path.join(__dirname, 'sabre-updates/sabre_type_c_steps.json'), 'utf8'));
const sabreTypeD = JSON.parse(fs.readFileSync(path.join(__dirname, 'sabre-updates/sabre_type_d_steps.json'), 'utf8'));

// Updated SABRE method descriptions based on Janus's video
const sabreUpdates = {
  sabre_type_a: {
    title: "SABRE Type A - Low Speed/Low Intensity",
    description: "Foundation SABRE strikes (1-3 per second, light force) for EQ improvement and vascular development. Phase One of the Path of Eleven.",
    instructionsText: "Shockwave/Strike Activated Bayliss Response Exercise. Using hand strikes at 1-3 per second with light force on heavily engorged but non-erect member. Timed session approach: 10 minutes each on left corporal, right corporal, and glans. Total 20-30 minutes.",
    safetyNotes: "Must be performed lying down. Never use painful force. Stop when fullness peaks and begins dropping. Maximum 30 minutes per session due to diminishing returns. Schedule: 1 day on, 2 days off.",
    benefits: [
      "Foundation for future gains",
      "EQ improvements",
      "Vascular network development",
      "Shear stress stimulation",
      "Prepares for advanced SABRE types"
    ],
    creator: "Janus Bifrons",
    ...sabreTypeA
  },
  sabre_type_b: {
    title: "SABRE Type B - High Speed/Low Intensity",
    description: "Increased speed SABRE (2-5 per second, light force) for enhanced shear stress and Bayliss Effect activation via calcium cycling. Phase Two progression.",
    instructionsText: "Higher speed strikes elicit Bayliss Effect driven smooth muscle activation. Work with heavily engorged flaccid to partially erect state. Same 10-minute divisions between structures. Increased speed causes calcium cycling between smooth muscles and endothelial cells.",
    safetyNotes: "Speed increases but force remains low. Calcium cycling creates powerful vasodilation. Stop at peak fullness. 1 on 2 off schedule mandatory for recovery.",
    benefits: [
      "Bayliss Effect activation",
      "Enhanced calcium cycling",
      "Smooth muscle stimulation",
      "Marked vasodilation",
      "Superior engorgement"
    ],
    creator: "Janus Bifrons",
    ...sabreTypeB
  },
  sabre_type_c: {
    title: "SABRE Type C - Low Speed/High Intensity",
    description: "Introduction of metal rod implements. Low speed (1 per second) with moderate force for stretch-based stimulation. Phase Three/Four advancement.",
    instructionsText: "Transition from hand to smooth metal rod (8-10 inch bolt, 0.5 inch diameter). After Type B warm-up and Vascion preparation, perform 3 sets of 60 strikes per corporal body. Focus on elastic deformation without bruising.",
    safetyNotes: "First implement use requires extreme caution. Start very gentle to acclimate. Never use painful force. Control is critical. Extended recovery needed.",
    benefits: [
      "Stretch-based tissue stimulation",
      "Enhanced morning erections",
      "Tissue conditioning",
      "Preparation for Type D",
      "Advanced vascular development"
    ],
    equipmentNeeded: [
      "Smooth metal rod (8-10 inch bolt, 0.5 inch diameter)",
      "Long shank with minimal threads preferred",
      "Silicone-based lubricant",
      "Timer for sets"
    ],
    creator: "Janus Bifrons",
    ...sabreTypeC
  },
  sabre_type_d: {
    title: "SABRE Type D - High Speed/High Intensity",
    description: "Maximum intensity SABRE using rod at 2-5 strikes per second with moderate force. Peak of Phase Four training. The ultimate expression of SABRE techniques.",
    instructionsText: "After comprehensive warm-up including Type B and Type C preparation, execute 2 sets of 60 strikes per corporal body at 2-5 per second with moderate force. Unprecedented tissue stimulation combining speed and force.",
    safetyNotes: "Only after mastering Type C. Requires exceptional control and conditioning. Extended cool down mandatory. Never on consecutive days. Stop immediately if pain occurs.",
    benefits: [
      "Maximum tissue stimulation",
      "Peak vascular development",
      "Extreme morning erections",
      "Ultimate conditioning",
      "Renders traditional PE obsolete"
    ],
    equipmentNeeded: [
      "Smooth metal rod (expert implement)",
      "Premium silicone lubricant",
      "Warm towels for aftercare",
      "Precise timer"
    ],
    creator: "Janus Bifrons",
    sabrePhilosophy: "The culmination of 16 years of vascular research. SABRE techniques render all other forms of PE obsolete.",
    ...sabreTypeD
  }
};

console.log('🚀 SABRE Methods Update Script');
console.log('================================');
console.log('Updating SABRE techniques with detailed multi-step instructions from Janus video\n');

// Manual update instructions
console.log('📋 Manual Update Instructions:');
console.log('1. Go to Firebase Console: https://console.firebase.google.com');
console.log('2. Select project: growth-70a85');
console.log('3. Navigate to Firestore Database > growthMethods collection\n');

console.log('📝 Update these documents:');
Object.entries(sabreUpdates).forEach(([id, data]) => {
  console.log(`\n${id}:`);
  console.log(`- Update title: "${data.title}"`);
  console.log(`- Update description: "${data.description}"`);
  console.log(`- Update instructionsText with detailed info`);
  console.log(`- Add/Update steps array (${data.steps.length} steps)`);
  console.log(`- Add/Update hasMultipleSteps: true`);
  console.log(`- Add/Update timerConfig object`);
  console.log(`- Add creator: "Janus Bifrons"`);
});

console.log('\n💡 Key Points from Janus:');
console.log('- All SABRE types use same actions, different speeds/intensities');
console.log('- Sessions are timed (20-30 minutes), not rep-based');
console.log('- Stop when fullness peaks and drops');
console.log('- Switch between structures every 5 minutes');
console.log('- 1 on, 2 off schedule is mandatory');
console.log('- Never exceed 30 minutes (diminishing returns)');
console.log('- Must be performed lying down');

console.log('\n📁 Step data files location:');
console.log('scripts/sabre-updates/sabre_type_a_steps.json');
console.log('scripts/sabre-updates/sabre_type_b_steps.json');
console.log('scripts/sabre-updates/sabre_type_c_steps.json');
console.log('scripts/sabre-updates/sabre_type_d_steps.json');

// Write combined update file
const combinedUpdates = {
  updateInstructions: "Update these fields in each SABRE document",
  lastUpdated: new Date().toISOString(),
  source: "Janus Bifrons SABRE video transcript and Path of Eleven post",
  methods: sabreUpdates
};

fs.writeFileSync(
  path.join(__dirname, 'sabre-updates/all-sabre-updates.json'),
  JSON.stringify(combinedUpdates, null, 2)
);

console.log('\n✅ Update data prepared successfully!');
console.log('📄 Combined file: scripts/sabre-updates/all-sabre-updates.json');