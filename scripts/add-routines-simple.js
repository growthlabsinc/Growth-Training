// Simple script to add missing routines using Firebase Admin SDK
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin with default credentials from environment
if (!getApps().length) {
  initializeApp({
    projectId: 'growth-70a85',
  });
}

const db = getFirestore();

// Missing routines data
const missingRoutines = [
  {
    id: "beginner_express",
    name: "Beginner Express",
    description: "A gentle 5-day introduction routine perfect for those new to enhancement training.",
    difficultyLevel: "Beginner",
    totalDuration: 5,
    schedule: [
      {
        id: "be_day1",
        dayNumber: 1,
        dayName: "Day 1: Introduction",
        description: "Start with basic AM 1.0",
        methodIds: ["am1_0"],
        isRestDay: false
      },
      {
        id: "be_day2",
        dayNumber: 2,
        dayName: "Day 2: Flexibility",
        description: "Gentle stretching",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        id: "be_day3",
        dayNumber: 3,
        dayName: "Day 3: Rest",
        description: "Recovery day",
        methodIds: [],
        isRestDay: true
      },
      {
        id: "be_day4",
        dayNumber: 4,
        dayName: "Day 4: Practice",
        description: "Reinforce AM 1.0 technique",
        methodIds: ["am1_0"],
        isRestDay: false
      },
      {
        id: "be_day5",
        dayNumber: 5,
        dayName: "Day 5: Stretch",
        description: "Maintain flexibility",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      }
    ],
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    id: "intermediate_progressive",
    name: "Intermediate Progressive",
    description: "A balanced 7-day routine that introduces AM 2.5 for continued progression.",
    difficultyLevel: "Intermediate",
    totalDuration: 7,
    schedule: [
      {
        id: "ip_day1",
        dayNumber: 1,
        dayName: "Day 1: Volume Work",
        description: "Pumping and moderate intensity",
        methodIds: ["angio_pumping", "am2_0"],
        isRestDay: false
      },
      {
        id: "ip_day2",
        dayNumber: 2,
        dayName: "Day 2: Intensity Focus",
        description: "Stretching followed by higher intensity",
        methodIds: ["s2s_stretches", "am2_5"],
        isRestDay: false
      },
      {
        id: "ip_day3",
        dayNumber: 3,
        dayName: "Day 3: Active Recovery",
        description: "Light pumping only",
        methodIds: ["angio_pumping"],
        isRestDay: false
      },
      {
        id: "ip_day4",
        dayNumber: 4,
        dayName: "Day 4: Rest",
        description: "Complete recovery",
        methodIds: [],
        isRestDay: true
      },
      {
        id: "ip_day5",
        dayNumber: 5,
        dayName: "Day 5: Peak Session",
        description: "High intensity followed by pumping",
        methodIds: ["am2_5", "angio_pumping"],
        isRestDay: false
      },
      {
        id: "ip_day6",
        dayNumber: 6,
        dayName: "Day 6: Flexibility",
        description: "Stretching for recovery",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        id: "ip_day7",
        dayNumber: 7,
        dayName: "Day 7: Rest",
        description: "Prepare for next week",
        methodIds: [],
        isRestDay: true
      }
    ],
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    id: "advanced_intensive",
    name: "Advanced Intensive",
    description: "A challenging 7-day routine for experienced practitioners ready for maximum intensity.",
    difficultyLevel: "Advanced",
    totalDuration: 7,
    schedule: [
      {
        id: "ai_day1",
        dayNumber: 1,
        dayName: "Day 1: High Intensity",
        description: "Full intensity training",
        methodIds: ["angio_pumping", "am3_0"],
        isRestDay: false
      },
      {
        id: "ai_day2",
        dayNumber: 2,
        dayName: "Day 2: Mixed Intensity",
        description: "Stretch and moderate work",
        methodIds: ["s2s_stretches", "am2_5"],
        isRestDay: false
      },
      {
        id: "ai_day3",
        dayNumber: 3,
        dayName: "Day 3: Peak Load",
        description: "Maximum intensity session",
        methodIds: ["angio_pumping", "am3_0"],
        isRestDay: false
      },
      {
        id: "ai_day4",
        dayNumber: 4,
        dayName: "Day 4: Recovery",
        description: "Light stretching only",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        id: "ai_day5",
        dayNumber: 5,
        dayName: "Day 5: Final Push",
        description: "High intensity with pump finish",
        methodIds: ["am3_0", "angio_pumping"],
        isRestDay: false
      },
      {
        id: "ai_day6",
        dayNumber: 6,
        dayName: "Day 6: Deload",
        description: "Moderate intensity recovery",
        methodIds: ["am2_5"],
        isRestDay: false
      },
      {
        id: "ai_day7",
        dayNumber: 7,
        dayName: "Day 7: Rest",
        description: "Complete recovery",
        methodIds: [],
        isRestDay: true
      }
    ],
    createdAt: new Date(),
    updatedAt: new Date()
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
        id: "tw_day1",
        dayNumber: 1,
        dayName: "Day 1: Foundation",
        description: "Start with basics",
        methodIds: ["angio_pumping", "am1_0"],
        isRestDay: false
      },
      {
        id: "tw_day2",
        dayNumber: 2,
        dayName: "Day 2: Stretch",
        description: "Flexibility work",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        id: "tw_day3",
        dayNumber: 3,
        dayName: "Day 3: Progress",
        description: "Increase intensity",
        methodIds: ["angio_pumping", "am2_0"],
        isRestDay: false
      },
      {
        id: "tw_day4",
        dayNumber: 4,
        dayName: "Day 4: Rest",
        description: "Recovery day",
        methodIds: [],
        isRestDay: true
      },
      {
        id: "tw_day5",
        dayNumber: 5,
        dayName: "Day 5: Volume",
        description: "Extended session",
        methodIds: ["am2_0", "s2s_stretches"],
        isRestDay: false
      },
      {
        id: "tw_day6",
        dayNumber: 6,
        dayName: "Day 6: Intensity",
        description: "Higher load",
        methodIds: ["angio_pumping", "am2_5"],
        isRestDay: false
      },
      {
        id: "tw_day7",
        dayNumber: 7,
        dayName: "Day 7: Active Recovery",
        description: "Light work",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      // Week 2
      {
        id: "tw_day8",
        dayNumber: 8,
        dayName: "Day 8: Rest",
        description: "Mid-program recovery",
        methodIds: [],
        isRestDay: true
      },
      {
        id: "tw_day9",
        dayNumber: 9,
        dayName: "Day 9: Peak Intensity",
        description: "Maximum effort",
        methodIds: ["angio_pumping", "am2_5"],
        isRestDay: false
      },
      {
        id: "tw_day10",
        dayNumber: 10,
        dayName: "Day 10: Maintenance",
        description: "Moderate work",
        methodIds: ["am2_0", "s2s_stretches"],
        isRestDay: false
      },
      {
        id: "tw_day11",
        dayNumber: 11,
        dayName: "Day 11: Push",
        description: "High intensity",
        methodIds: ["am2_5", "angio_pumping"],
        isRestDay: false
      },
      {
        id: "tw_day12",
        dayNumber: 12,
        dayName: "Day 12: Recovery",
        description: "Light stretching",
        methodIds: ["s2s_stretches"],
        isRestDay: false
      },
      {
        id: "tw_day13",
        dayNumber: 13,
        dayName: "Day 13: Final Session",
        description: "Complete program",
        methodIds: ["angio_pumping", "am2_0"],
        isRestDay: false
      },
      {
        id: "tw_day14",
        dayNumber: 14,
        dayName: "Day 14: Rest & Assess",
        description: "Recovery and evaluation",
        methodIds: [],
        isRestDay: true
      }
    ],
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

async function addRoutines() {
  console.log('Starting to add missing routines to Firebase...\n');
  
  try {
    // Check existing routines first
    const routinesSnapshot = await db.collection('routines').get();
    const existingIds = new Set(routinesSnapshot.docs.map(doc => doc.id));
    console.log(`Found ${existingIds.size} existing routines\n`);
    
    // Add only missing routines
    let addedCount = 0;
    for (const routine of missingRoutines) {
      if (!existingIds.has(routine.id)) {
        await db.collection('routines').doc(routine.id).set(routine);
        console.log(`✓ Added: ${routine.name} (${routine.id})`);
        addedCount++;
      } else {
        console.log(`⏭️  Skipped: ${routine.name} (already exists)`);
      }
    }
    
    console.log(`\n✅ Successfully added ${addedCount} missing routines!`);
    console.log(`Total routines in database: ${existingIds.size + addedCount}`);
    
  } catch (error) {
    console.error('\n❌ Error adding routines:', error);
    throw error;
  }
}

// Run the function
addRoutines()
  .then(() => {
    console.log('\nProcess completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\nProcess failed:', error);
    process.exit(1);
  });