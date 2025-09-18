/**
 * Script to restore all standard routines to Firebase
 * This will add the 5 missing standard routines
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85',
});

const db = admin.firestore();

// Standard routines data
const standardRoutines = [
  {
    id: "beginner_express",
    name: "Beginner Express",
    description: "A shorter 5-day introduction routine for those new to the practice. Perfect for building consistency and learning proper form.",
    difficulty: "beginner",
    difficultyLevel: "Beginner",
    duration: 5,
    isCustom: false,
    shareWithCommunity: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdDate: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    stages: [1],
    focusAreas: ["Beginner", "Foundation", "5-Day"],
    schedule: [
      {
        id: "be_day1",
        day: 1,
        dayNumber: 1,
        dayName: "Day 1: Introduction",
        description: "Start with basic Angion Method 1.0 to learn the fundamentals.",
        isRestDay: false,
        methodIds: ["angion_method_1_0"],
        methods: [
          {
            methodId: "angion_method_1_0",
            duration: 20,
            order: 0
          }
        ],
        notes: "Focus on technique, not intensity. 15-20 minutes max.",
        additionalNotes: "Focus on technique, not intensity. 15-20 minutes max."
      },
      {
        id: "be_day2",
        day: 2,
        dayNumber: 2,
        dayName: "Day 2: Rest",
        description: "Rest and recover.",
        isRestDay: true,
        methodIds: null,
        notes: "Stay hydrated and get good sleep.",
        additionalNotes: "Stay hydrated and get good sleep."
      },
      {
        id: "be_day3",
        day: 3,
        dayNumber: 3,
        dayName: "Day 3: Stretching Focus",
        description: "Introduction to S2S stretches with light AM1.0.",
        isRestDay: false,
        methodIds: ["s2s_stretch", "angion_method_1_0"],
        methods: [
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 0
          },
          {
            methodId: "angion_method_1_0",
            duration: 15,
            order: 1
          }
        ],
        notes: "Gentle stretching, no forcing.",
        additionalNotes: "Gentle stretching, no forcing."
      },
      {
        id: "be_day4",
        day: 4,
        dayNumber: 4,
        dayName: "Day 4: Rest",
        description: "Rest and recover.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "be_day5",
        day: 5,
        dayNumber: 5,
        dayName: "Day 5: Assessment",
        description: "Light session to assess progress and comfort level.",
        isRestDay: false,
        methodIds: ["angion_method_1_0"],
        methods: [
          {
            methodId: "angion_method_1_0",
            duration: 20,
            order: 0
          }
        ],
        notes: "Note any improvements in technique or comfort.",
        additionalNotes: "Note any improvements in technique or comfort."
      }
    ]
  },
  {
    id: "intermediate_progressive",
    name: "Intermediate Progressive",
    description: "A progressive routine for those ready to advance beyond basics. Introduces AM2.5 and more structured training.",
    difficulty: "intermediate",
    difficultyLevel: "Intermediate",
    duration: 7,
    isCustom: false,
    shareWithCommunity: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdDate: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    stages: [2, 3],
    focusAreas: ["Intermediate", "Progressive", "AM2.5"],
    schedule: [
      {
        id: "ip_day1",
        day: 1,
        dayNumber: 1,
        dayName: "Day 1: Power Day",
        description: "Advanced Angion Methods with focus on intensity.",
        isRestDay: false,
        methodIds: ["am2_0", "angion_method_2_5", "angio_pumping"],
        methods: [
          {
            methodId: "am2_0",
            duration: 15,
            order: 0
          },
          {
            methodId: "angion_method_2_5",
            duration: 15,
            order: 1
          },
          {
            methodId: "angio_pumping",
            duration: 10,
            order: 2
          }
        ],
        notes: "30-40 minute session. Monitor fatigue.",
        additionalNotes: "30-40 minute session. Monitor fatigue."
      },
      {
        id: "ip_day2",
        day: 2,
        dayNumber: 2,
        dayName: "Day 2: Active Recovery",
        description: "Light stretching and mobility work.",
        isRestDay: false,
        methodIds: ["s2s_stretch"],
        methods: [
          {
            methodId: "s2s_stretch",
            duration: 20,
            order: 0
          }
        ],
        notes: "Keep it light, focus on recovery.",
        additionalNotes: "Keep it light, focus on recovery."
      },
      {
        id: "ip_day3",
        day: 3,
        dayNumber: 3,
        dayName: "Day 3: Rest",
        description: "Complete rest day.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "ip_day4",
        day: 4,
        dayNumber: 4,
        dayName: "Day 4: Technique Day",
        description: "Focus on perfecting AM2.5 technique.",
        isRestDay: false,
        methodIds: ["angion_method_2_5", "am2_0"],
        methods: [
          {
            methodId: "angion_method_2_5",
            duration: 20,
            order: 0
          },
          {
            methodId: "am2_0",
            duration: 15,
            order: 1
          }
        ],
        notes: "Quality over quantity. Perfect form.",
        additionalNotes: "Quality over quantity. Perfect form."
      },
      {
        id: "ip_day5",
        day: 5,
        dayNumber: 5,
        dayName: "Day 5: Rest",
        description: "Rest and recover.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "ip_day6",
        day: 6,
        dayNumber: 6,
        dayName: "Day 6: Endurance",
        description: "Longer session focusing on endurance.",
        isRestDay: false,
        methodIds: ["am2_0", "s2s_stretch", "angio_pumping"],
        methods: [
          {
            methodId: "am2_0",
            duration: 20,
            order: 0
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 1
          },
          {
            methodId: "angio_pumping",
            duration: 15,
            order: 2
          }
        ],
        notes: "40-45 minutes. Pace yourself.",
        additionalNotes: "40-45 minutes. Pace yourself."
      },
      {
        id: "ip_day7",
        day: 7,
        dayNumber: 7,
        dayName: "Day 7: Rest",
        description: "Complete rest to prepare for next week.",
        isRestDay: true,
        methodIds: null,
        notes: "Assess weekly progress.",
        additionalNotes: "Assess weekly progress."
      }
    ]
  },
  {
    id: "advanced_intensive",
    name: "Advanced Intensive",
    description: "High-intensity routine for experienced practitioners. Requires excellent technique and recovery capacity.",
    difficulty: "advanced",
    difficultyLevel: "Advanced",
    duration: 7,
    isCustom: false,
    shareWithCommunity: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdDate: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    stages: [3, 4, 5],
    focusAreas: ["Advanced", "High Intensity", "AM3.0"],
    schedule: [
      {
        id: "ai_day1",
        day: 1,
        dayNumber: 1,
        dayName: "Day 1: Maximum Intensity",
        description: "Full spectrum training with all advanced methods.",
        isRestDay: false,
        methodIds: ["angion_method_2_5", "angion_method_3_0", "angio_pumping", "s2s_stretch"],
        methods: [
          {
            methodId: "angion_method_2_5",
            duration: 15,
            order: 0
          },
          {
            methodId: "angion_method_3_0",
            duration: 20,
            order: 1
          },
          {
            methodId: "angio_pumping",
            duration: 15,
            order: 2
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 3
          }
        ],
        notes: "45-60 minutes. Full intensity.",
        additionalNotes: "45-60 minutes. Full intensity."
      },
      {
        id: "ai_day2",
        day: 2,
        dayNumber: 2,
        dayName: "Day 2: Recovery Methods",
        description: "Active recovery with light methods.",
        isRestDay: false,
        methodIds: ["angion_method_1_0", "s2s_stretch"],
        methods: [
          {
            methodId: "angion_method_1_0",
            duration: 15,
            order: 0
          },
          {
            methodId: "s2s_stretch",
            duration: 15,
            order: 1
          }
        ],
        notes: "20-30 minutes. Focus on blood flow.",
        additionalNotes: "20-30 minutes. Focus on blood flow."
      },
      {
        id: "ai_day3",
        day: 3,
        dayNumber: 3,
        dayName: "Day 3: Power Focus",
        description: "High-intensity Angion Method 3.0 focus.",
        isRestDay: false,
        methodIds: ["angion_method_3_0", "angion_method_2_5"],
        methods: [
          {
            methodId: "angion_method_3_0",
            duration: 25,
            order: 0
          },
          {
            methodId: "angion_method_2_5",
            duration: 20,
            order: 1
          }
        ],
        notes: "35-45 minutes. Maximum effort.",
        additionalNotes: "35-45 minutes. Maximum effort."
      },
      {
        id: "ai_day4",
        day: 4,
        dayNumber: 4,
        dayName: "Day 4: Rest",
        description: "Complete rest for recovery.",
        isRestDay: true,
        methodIds: null,
        notes: "Critical recovery day.",
        additionalNotes: "Critical recovery day."
      },
      {
        id: "ai_day5",
        day: 5,
        dayNumber: 5,
        dayName: "Day 5: Endurance Challenge",
        description: "Extended session for endurance building.",
        isRestDay: false,
        methodIds: ["angion_method_2_5", "am2_0", "angio_pumping", "s2s_stretch"],
        methods: [
          {
            methodId: "angion_method_2_5",
            duration: 20,
            order: 0
          },
          {
            methodId: "am2_0",
            duration: 20,
            order: 1
          },
          {
            methodId: "angio_pumping",
            duration: 15,
            order: 2
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 3
          }
        ],
        notes: "60+ minutes. Pace strategically.",
        additionalNotes: "60+ minutes. Pace strategically."
      },
      {
        id: "ai_day6",
        day: 6,
        dayNumber: 6,
        dayName: "Day 6: Rest",
        description: "Rest and assess weekly progress.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "ai_day7",
        day: 7,
        dayNumber: 7,
        dayName: "Day 7: Optional Session",
        description: "Optional light session or complete rest.",
        isRestDay: false,
        methodIds: ["s2s_stretch"],
        methods: [
          {
            methodId: "s2s_stretch",
            duration: 20,
            order: 0
          }
        ],
        notes: "Listen to your body.",
        additionalNotes: "Listen to your body."
      }
    ]
  },
  {
    id: "two_week_transformation",
    name: "Two Week Transformation",
    description: "An intensive 14-day program designed to kickstart your journey with progressive overload and strategic recovery.",
    difficulty: "intermediate",
    difficultyLevel: "Intermediate",
    duration: 14,
    isCustom: false,
    shareWithCommunity: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdDate: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    stages: [2, 3],
    focusAreas: ["Transformation", "14-Day", "Progressive"],
    schedule: [
      // Week 1
      {
        id: "tw_day1",
        day: 1,
        dayNumber: 1,
        dayName: "Week 1, Day 1: Foundation",
        description: "Establish baseline with core methods.",
        isRestDay: false,
        methodIds: ["angion_method_1_0", "s2s_stretch"],
        methods: [
          {
            methodId: "angion_method_1_0",
            duration: 15,
            order: 0
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 1
          }
        ],
        notes: "Start conservative, focus on form.",
        additionalNotes: "Start conservative, focus on form."
      },
      {
        id: "tw_day2",
        day: 2,
        dayNumber: 2,
        dayName: "Week 1, Day 2: Rest",
        description: "Rest and recover.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "tw_day3",
        day: 3,
        dayNumber: 3,
        dayName: "Week 1, Day 3: Progress",
        description: "Introduce AM2.0 with stretching.",
        isRestDay: false,
        methodIds: ["am2_0", "s2s_stretch"],
        methods: [
          {
            methodId: "am2_0",
            duration: 20,
            order: 0
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 1
          }
        ],
        notes: "Note differences from Day 1.",
        additionalNotes: "Note differences from Day 1."
      },
      {
        id: "tw_day4",
        day: 4,
        dayNumber: 4,
        dayName: "Week 1, Day 4: Rest",
        description: "Rest and recover.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "tw_day5",
        day: 5,
        dayNumber: 5,
        dayName: "Week 1, Day 5: Integration",
        description: "Combine methods learned so far.",
        isRestDay: false,
        methodIds: ["angion_method_1_0", "am2_0", "angio_pumping"],
        methods: [
          {
            methodId: "angion_method_1_0",
            duration: 10,
            order: 0
          },
          {
            methodId: "am2_0",
            duration: 15,
            order: 1
          },
          {
            methodId: "angio_pumping",
            duration: 5,
            order: 2
          }
        ],
        notes: "30 minute session max.",
        additionalNotes: "30 minute session max."
      },
      {
        id: "tw_day6",
        day: 6,
        dayNumber: 6,
        dayName: "Week 1, Day 6: Active Recovery",
        description: "Light stretching only.",
        isRestDay: false,
        methodIds: ["s2s_stretch"],
        methods: [
          {
            methodId: "s2s_stretch",
            duration: 15,
            order: 0
          }
        ],
        notes: "Keep it very light.",
        additionalNotes: "Keep it very light."
      },
      {
        id: "tw_day7",
        day: 7,
        dayNumber: 7,
        dayName: "Week 1, Day 7: Rest",
        description: "Complete rest before Week 2.",
        isRestDay: true,
        methodIds: null,
        notes: "Prepare for next week.",
        additionalNotes: "Prepare for next week."
      },
      // Week 2
      {
        id: "tw_day8",
        day: 8,
        dayNumber: 8,
        dayName: "Week 2, Day 1: Advancement",
        description: "Introduce AM2.5 if ready.",
        isRestDay: false,
        methodIds: ["am2_0", "angion_method_2_5", "angio_pumping"],
        methods: [
          {
            methodId: "am2_0",
            duration: 15,
            order: 0
          },
          {
            methodId: "angion_method_2_5",
            duration: 15,
            order: 1
          },
          {
            methodId: "angio_pumping",
            duration: 10,
            order: 2
          }
        ],
        notes: "Only add AM2.5 if comfortable.",
        additionalNotes: "Only add AM2.5 if comfortable."
      },
      {
        id: "tw_day9",
        day: 9,
        dayNumber: 9,
        dayName: "Week 2, Day 2: Rest",
        description: "Rest and recover.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "tw_day10",
        day: 10,
        dayNumber: 10,
        dayName: "Week 2, Day 3: Intensity",
        description: "Higher intensity session.",
        isRestDay: false,
        methodIds: ["angion_method_2_5", "am2_0", "s2s_stretch"],
        methods: [
          {
            methodId: "angion_method_2_5",
            duration: 20,
            order: 0
          },
          {
            methodId: "am2_0",
            duration: 15,
            order: 1
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 2
          }
        ],
        notes: "Push harder but maintain form.",
        additionalNotes: "Push harder but maintain form."
      },
      {
        id: "tw_day11",
        day: 11,
        dayNumber: 11,
        dayName: "Week 2, Day 4: Recovery",
        description: "Active recovery day.",
        isRestDay: false,
        methodIds: ["angion_method_1_0", "s2s_stretch"],
        methods: [
          {
            methodId: "angion_method_1_0",
            duration: 15,
            order: 0
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 1
          }
        ],
        notes: "Light session only.",
        additionalNotes: "Light session only."
      },
      {
        id: "tw_day12",
        day: 12,
        dayNumber: 12,
        dayName: "Week 2, Day 5: Peak",
        description: "Peak performance day.",
        isRestDay: false,
        methodIds: ["angion_method_2_5", "angio_pumping", "s2s_stretch"],
        methods: [
          {
            methodId: "angion_method_2_5",
            duration: 25,
            order: 0
          },
          {
            methodId: "angio_pumping",
            duration: 15,
            order: 1
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 2
          }
        ],
        notes: "Best effort of the program.",
        additionalNotes: "Best effort of the program."
      },
      {
        id: "tw_day13",
        day: 13,
        dayNumber: 13,
        dayName: "Week 2, Day 6: Rest",
        description: "Rest before final assessment.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "tw_day14",
        day: 14,
        dayNumber: 14,
        dayName: "Week 2, Day 7: Assessment",
        description: "Final session to assess progress.",
        isRestDay: false,
        methodIds: ["am2_0", "s2s_stretch"],
        methods: [
          {
            methodId: "am2_0",
            duration: 20,
            order: 0
          },
          {
            methodId: "s2s_stretch",
            duration: 10,
            order: 1
          }
        ],
        notes: "Compare to Week 1 performance.",
        additionalNotes: "Compare to Week 1 performance."
      }
    ]
  },
  {
    id: "recovery_focus",
    name: "Recovery Focus",
    description: "A gentle routine emphasizing recovery and tissue health. Perfect for deload weeks or when recovering from intense training.",
    difficulty: "beginner",
    difficultyLevel: "Beginner",
    duration: 7,
    isCustom: false,
    shareWithCommunity: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdDate: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    stages: [1],
    focusAreas: ["Recovery", "Gentle", "Deload"],
    schedule: [
      {
        id: "rf_day1",
        day: 1,
        dayNumber: 1,
        dayName: "Day 1: Gentle Start",
        description: "Light stretching and basic blood flow work.",
        isRestDay: false,
        methodIds: ["s2s_stretch", "angion_method_1_0"],
        methods: [
          {
            methodId: "s2s_stretch",
            duration: 15,
            order: 0
          },
          {
            methodId: "angion_method_1_0",
            duration: 10,
            order: 1
          }
        ],
        notes: "Keep intensity very low.",
        additionalNotes: "Keep intensity very low."
      },
      {
        id: "rf_day2",
        day: 2,
        dayNumber: 2,
        dayName: "Day 2: Rest",
        description: "Complete rest day.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "rf_day3",
        day: 3,
        dayNumber: 3,
        dayName: "Day 3: Mobility",
        description: "Focus on flexibility and mobility.",
        isRestDay: false,
        methodIds: ["s2s_stretch"],
        methods: [
          {
            methodId: "s2s_stretch",
            duration: 20,
            order: 0
          }
        ],
        notes: "Gentle stretching throughout.",
        additionalNotes: "Gentle stretching throughout."
      },
      {
        id: "rf_day4",
        day: 4,
        dayNumber: 4,
        dayName: "Day 4: Rest",
        description: "Complete rest day.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      },
      {
        id: "rf_day5",
        day: 5,
        dayNumber: 5,
        dayName: "Day 5: Light Work",
        description: "Very light Angion work for blood flow.",
        isRestDay: false,
        methodIds: ["angion_method_1_0"],
        methods: [
          {
            methodId: "angion_method_1_0",
            duration: 15,
            order: 0
          }
        ],
        notes: "50% intensity maximum.",
        additionalNotes: "50% intensity maximum."
      },
      {
        id: "rf_day6",
        day: 6,
        dayNumber: 6,
        dayName: "Day 6: Stretch",
        description: "Final stretching session.",
        isRestDay: false,
        methodIds: ["s2s_stretch"],
        methods: [
          {
            methodId: "s2s_stretch",
            duration: 15,
            order: 0
          }
        ],
        notes: "Prepare for next week's training.",
        additionalNotes: "Prepare for next week's training."
      },
      {
        id: "rf_day7",
        day: 7,
        dayNumber: 7,
        dayName: "Day 7: Rest",
        description: "Complete rest before returning to regular training.",
        isRestDay: true,
        methodIds: null,
        notes: "",
        additionalNotes: ""
      }
    ]
  }
];

async function restoreStandardRoutines() {
  console.log('🚀 Starting to restore standard routines...\n');
  
  const batch = db.batch();
  let addedCount = 0;
  let skippedCount = 0;
  
  for (const routine of standardRoutines) {
    try {
      // Check if routine already exists
      const existingDoc = await db.collection('routines').doc(routine.id).get();
      
      if (existingDoc.exists) {
        console.log(`⏭️  Skipping ${routine.name} - already exists`);
        skippedCount++;
        continue;
      }
      
      // Add to batch
      const docRef = db.collection('routines').doc(routine.id);
      batch.set(docRef, routine);
      
      console.log(`✅ Adding ${routine.name} (${routine.difficulty})`);
      addedCount++;
      
    } catch (error) {
      console.error(`❌ Error processing ${routine.name}:`, error);
    }
  }
  
  if (addedCount > 0) {
    try {
      await batch.commit();
      console.log(`\n✅ Successfully added ${addedCount} routines to Firebase`);
    } catch (error) {
      console.error('❌ Error committing batch:', error);
    }
  }
  
  console.log(`\n📊 Summary:`);
  console.log(`   - Added: ${addedCount} routines`);
  console.log(`   - Skipped: ${skippedCount} routines`);
  console.log(`   - Total standard routines: ${standardRoutines.length}`);
  
  // Verify all routines are now present
  console.log('\n🔍 Verifying all routines...');
  const allRoutines = await db.collection('routines').get();
  console.log(`\n✅ Total routines in Firebase: ${allRoutines.size}`);
  
  const routineNames = [];
  allRoutines.forEach(doc => {
    const data = doc.data();
    routineNames.push(`   - ${data.name} (${data.difficulty || data.difficultyLevel})`);
  });
  
  console.log('\nRoutines in Firebase:');
  routineNames.sort().forEach(name => console.log(name));
}

// Run the restoration
restoreStandardRoutines()
  .then(() => {
    console.log('\n✅ Restoration complete!');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });