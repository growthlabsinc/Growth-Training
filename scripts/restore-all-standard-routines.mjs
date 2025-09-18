import { initializeApp } from 'firebase/app';
import { getFirestore, collection, doc, setDoc, serverTimestamp, getDoc } from 'firebase/firestore';

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBEb5yyfz0SQA_Uo7rvP_cJmB71bPdAv3Y",
  authDomain: "growth-70a85.firebaseapp.com",
  projectId: "growth-70a85",
  storageBucket: "growth-70a85.firebasestorage.app",
  messagingSenderId: "373738088450",
  appId: "1:373738088450:ios:f63af80bed2ffd3e42e16f"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// All standard routines data based on SampleRoutines.swift
const standardRoutines = [
  {
    id: "beginner_express",
    name: "Beginner Express",
    description: "A gentle 5-day introduction routine perfect for those new to enhancement training.",
    difficultyLevel: "Beginner",
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
    ]
  },
  {
    id: "intermediate_progressive",
    name: "Intermediate Progressive",
    description: "A balanced 7-day routine that introduces AM 2.5 for continued progression.",
    difficultyLevel: "Intermediate",
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
    ]
  },
  {
    id: "advanced_intensive",
    name: "Advanced Intensive",
    description: "A challenging 7-day routine for experienced practitioners ready for maximum intensity.",
    difficultyLevel: "Advanced",
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
    ]
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
    ]
  }
];

async function checkAndAddRoutines() {
  console.log('Checking existing routines and adding missing ones...\n');
  
  try {
    for (const routine of standardRoutines) {
      // Check if routine already exists
      const docRef = doc(db, 'routines', routine.id);
      const docSnap = await getDoc(docRef);
      
      if (docSnap.exists()) {
        console.log(`✓ Already exists: ${routine.name} (${routine.id})`);
      } else {
        // Add routine with timestamps
        const routineData = {
          ...routine,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        };
        
        await setDoc(docRef, routineData);
        console.log(`✅ Added: ${routine.name} (${routine.id})`);
      }
    }
    
    console.log('\n✅ All standard routines have been checked and missing ones added!');
    console.log('\nExisting routines in Firebase:');
    console.log('- standard_growth_routine (Beginner)');
    console.log('- janus_protocol_12week (Advanced)');
    console.log('\nTotal routines now: 6');
  } catch (error) {
    console.error('\n❌ Error adding routines:', error);
  }
  
  process.exit();
}

// Run the function
checkAndAddRoutines();