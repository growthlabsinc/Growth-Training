import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Get current directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load service account
const serviceAccount = JSON.parse(
  readFileSync(join(__dirname, '../growth-70a85-firebase-adminsdk-zpnea-e7bc8b5c93.json'), 'utf8')
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://growth-70a85.firebaseio.com"
});

const db = admin.firestore();

// Standard routines data
const standardRoutines = [
  {
    id: "standard_growth_routine",
    name: "Standard Growth Routine",
    description: "A proven 7-day routine designed for consistent gains through progressive tissue expansion.",
    difficultyLevel: "Beginner",
    weeklySchedule: {
      monday: {
        methods: ["angio_pumping", "am1_0"],
        estimatedDuration: 30
      },
      tuesday: {
        methods: ["s2s_stretches"],
        estimatedDuration: 15
      },
      wednesday: {
        methods: ["angio_pumping", "am2_0"],
        estimatedDuration: 35
      },
      thursday: {
        methods: ["s2s_stretches"],
        estimatedDuration: 15
      },
      friday: {
        methods: ["angio_pumping", "am1_0"],
        estimatedDuration: 30
      },
      saturday: {
        methods: ["s2s_stretches"],
        estimatedDuration: 15
      },
      sunday: {
        methods: [],
        estimatedDuration: 0
      }
    },
    totalDuration: 21,
    schedule: [
      {
        dayNumber: 1,
        dayName: "Day 1: Foundation",
        description: "Begin with pumping to enhance blood flow, then progress to AM 1.0",
        methodIds: ["angio_pumping", "am1_0"],
        isRestDay: false
      },
      {
        dayNumber: 2,
        dayName: "Day 2: Recovery Stretching",
        description: "Light stretching to maintain elasticity",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 3,
        dayName: "Day 3: Progressive Load",
        description: "Pumping followed by moderate intensity AM 2.0",
        methodIds: ["angio_pumping", "am2_0"],
        isRestDay: false
      },
      {
        dayNumber: 4,
        dayName: "Day 4: Active Recovery",
        description: "Gentle stretching to promote healing",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 5,
        dayName: "Day 5: Reinforcement",
        description: "Return to foundation work",
        methodIds: ["angio_pumping", "am1_0"],
        isRestDay: false
      },
      {
        dayNumber: 6,
        dayName: "Day 6: Flexibility",
        description: "Maintain tissue elasticity",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 7,
        dayName: "Day 7: Complete Rest",
        description: "Allow full recovery and adaptation",
        methodIds: [],
        isRestDay: true
      }
    ],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "beginner_express",
    name: "Beginner Express",
    description: "A gentle 5-day introduction routine perfect for those new to enhancement training.",
    difficultyLevel: "Beginner",
    weeklySchedule: {
      monday: {
        methods: ["am1_0"],
        estimatedDuration: 20
      },
      tuesday: {
        methods: ["s2s_stretches"],
        estimatedDuration: 10
      },
      wednesday: {
        methods: [],
        estimatedDuration: 0
      },
      thursday: {
        methods: ["am1_0"],
        estimatedDuration: 20
      },
      friday: {
        methods: ["s2s_stretches"],
        estimatedDuration: 10
      },
      saturday: {
        methods: [],
        estimatedDuration: 0
      },
      sunday: {
        methods: [],
        estimatedDuration: 0
      }
    },
    totalDuration: 7,
    schedule: [
      {
        dayNumber: 1,
        dayName: "Day 1: Introduction",
        description: "Start with basic AM 1.0",
        methodIds: ["am1_0"],
        isRestDay: false
      },
      {
        dayNumber: 2,
        dayName: "Day 2: Flexibility",
        description: "Gentle stretching",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 3,
        dayName: "Day 3: Rest",
        description: "Recovery day",
        methodIds: [],
        isRestDay: true
      },
      {
        dayNumber: 4,
        dayName: "Day 4: Practice",
        description: "Reinforce AM 1.0 technique",
        methodIds: ["am1_0"],
        isRestDay: false
      },
      {
        dayNumber: 5,
        dayName: "Day 5: Stretch",
        description: "Maintain flexibility",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      }
    ],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "intermediate_progressive",
    name: "Intermediate Progressive",
    description: "A balanced 7-day routine that introduces AM 2.5 for continued progression.",
    difficultyLevel: "Intermediate",
    weeklySchedule: {
      monday: {
        methods: ["angio_pumping", "am2_0"],
        estimatedDuration: 35
      },
      tuesday: {
        methods: ["s2s_stretches", "am2_5"],
        estimatedDuration: 40
      },
      wednesday: {
        methods: ["angio_pumping"],
        estimatedDuration: 20
      },
      thursday: {
        methods: [],
        estimatedDuration: 0
      },
      friday: {
        methods: ["am2_5", "angio_pumping"],
        estimatedDuration: 45
      },
      saturday: {
        methods: ["s2s_stretches"],
        estimatedDuration: 15
      },
      sunday: {
        methods: [],
        estimatedDuration: 0
      }
    },
    totalDuration: 28,
    schedule: [
      {
        dayNumber: 1,
        dayName: "Day 1: Volume Work",
        description: "Pumping and moderate intensity",
        methodIds: ["angio_pumping", "am2_0"],
        isRestDay: false
      },
      {
        dayNumber: 2,
        dayName: "Day 2: Intensity Focus",
        description: "Stretching followed by higher intensity",
        methodIds: ["s2s_stretches", "am2_5"],
        isRestDay: false
      },
      {
        dayNumber: 3,
        dayName: "Day 3: Active Recovery",
        description: "Light pumping only",
        methodIds: ["angio_pumping"],
        isRestDay: false
      },
      {
        dayNumber: 4,
        dayName: "Day 4: Rest",
        description: "Complete recovery",
        methodIds: [],
        isRestDay: true
      },
      {
        dayNumber: 5,
        dayName: "Day 5: Peak Session",
        description: "High intensity followed by pumping",
        methodIds: ["am2_5", "angio_pumping"],
        isRestDay: false
      },
      {
        dayNumber: 6,
        dayName: "Day 6: Flexibility",
        description: "Stretching for recovery",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 7,
        dayName: "Day 7: Rest",
        description: "Prepare for next week",
        methodIds: [],
        isRestDay: true
      }
    ],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "advanced_intensive",
    name: "Advanced Intensive",
    description: "A challenging 7-day routine for experienced practitioners ready for maximum intensity.",
    difficultyLevel: "Advanced",
    weeklySchedule: {
      monday: {
        methods: ["angio_pumping", "am3_0"],
        estimatedDuration: 50
      },
      tuesday: {
        methods: ["s2s_stretches", "am2_5"],
        estimatedDuration: 45
      },
      wednesday: {
        methods: ["angio_pumping", "am3_0"],
        estimatedDuration: 50
      },
      thursday: {
        methods: ["s2s_stretches"],
        estimatedDuration: 15
      },
      friday: {
        methods: ["am3_0", "angio_pumping"],
        estimatedDuration: 55
      },
      saturday: {
        methods: ["am2_5"],
        estimatedDuration: 30
      },
      sunday: {
        methods: [],
        estimatedDuration: 0
      }
    },
    totalDuration: 42,
    schedule: [
      {
        dayNumber: 1,
        dayName: "Day 1: High Intensity",
        description: "Full intensity training",
        methodIds: ["angio_pumping", "am3_0"],
        isRestDay: false
      },
      {
        dayNumber: 2,
        dayName: "Day 2: Mixed Intensity",
        description: "Stretch and moderate work",
        methodIds: ["s2s_stretches", "am2_5"],
        isRestDay: false
      },
      {
        dayNumber: 3,
        dayName: "Day 3: Peak Load",
        description: "Maximum intensity session",
        methodIds: ["angio_pumping", "am3_0"],
        isRestDay: false
      },
      {
        dayNumber: 4,
        dayName: "Day 4: Recovery",
        description: "Light stretching only",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 5,
        dayName: "Day 5: Final Push",
        description: "High intensity with pump finish",
        methodIds: ["am3_0", "angio_pumping"],
        isRestDay: false
      },
      {
        dayNumber: 6,
        dayName: "Day 6: Deload",
        description: "Moderate intensity recovery",
        methodIds: ["am2_5"],
        isRestDay: false
      },
      {
        dayNumber: 7,
        dayName: "Day 7: Rest",
        description: "Complete recovery",
        methodIds: [],
        isRestDay: true
      }
    ],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "two_week_transformation",
    name: "Two Week Transformation",
    description: "An intensive 14-day program designed for rapid progression with careful load management.",
    difficultyLevel: "Intermediate",
    totalDuration: 14,
    schedule: [
      // Week 1
      {
        dayNumber: 1,
        dayName: "Day 1: Foundation",
        description: "Start with basics",
        methodIds: ["angio_pumping", "am1_0"],
        isRestDay: false
      },
      {
        dayNumber: 2,
        dayName: "Day 2: Stretch",
        description: "Flexibility work",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 3,
        dayName: "Day 3: Progress",
        description: "Increase intensity",
        methodIds: ["angio_pumping", "am2_0"],
        isRestDay: false
      },
      {
        dayNumber: 4,
        dayName: "Day 4: Rest",
        description: "Recovery day",
        methodIds: [],
        isRestDay: true
      },
      {
        dayNumber: 5,
        dayName: "Day 5: Volume",
        description: "Extended session",
        methodIds: ["am2_0", "s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 6,
        dayName: "Day 6: Intensity",
        description: "Higher load",
        methodIds: ["angio_pumping", "am2_5"],
        isRestDay: false
      },
      {
        dayNumber: 7,
        dayName: "Day 7: Active Recovery",
        description: "Light work",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      // Week 2
      {
        dayNumber: 8,
        dayName: "Day 8: Rest",
        description: "Mid-program recovery",
        methodIds: [],
        isRestDay: true
      },
      {
        dayNumber: 9,
        dayName: "Day 9: Peak Intensity",
        description: "Maximum effort",
        methodIds: ["angio_pumping", "am2_5"],
        isRestDay: false
      },
      {
        dayNumber: 10,
        dayName: "Day 10: Maintenance",
        description: "Moderate work",
        methodIds: ["am2_0", "s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 11,
        dayName: "Day 11: Push",
        description: "High intensity",
        methodIds: ["am2_5", "angio_pumping"],
        isRestDay: false
      },
      {
        dayNumber: 12,
        dayName: "Day 12: Recovery",
        description: "Light stretching",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        dayNumber: 13,
        dayName: "Day 13: Final Session",
        description: "Complete program",
        methodIds: ["angio_pumping", "am2_0"],
        isRestDay: false
      },
      {
        dayNumber: 14,
        dayName: "Day 14: Rest & Assess",
        description: "Recovery and evaluation",
        methodIds: [],
        isRestDay: true
      }
    ],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

async function addRoutines() {
  console.log('Starting to add standard routines to Firebase...\n');
  
  const batch = db.batch();
  
  for (const routine of standardRoutines) {
    const routineRef = db.collection('routines').doc(routine.id);
    batch.set(routineRef, routine);
    console.log(`✓ Added: ${routine.name} (${routine.id})`);
  }
  
  try {
    await batch.commit();
    console.log('\n✅ All standard routines have been successfully added to Firebase!');
  } catch (error) {
    console.error('\n❌ Error adding routines:', error);
  }
  
  process.exit();
}

// Run the function
addRoutines();