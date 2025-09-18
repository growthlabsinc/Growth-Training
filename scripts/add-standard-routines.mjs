import { initializeApp } from 'firebase/app';
import { getFirestore, collection, doc, setDoc, serverTimestamp } from 'firebase/firestore';

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

// Standard routines data
const standardRoutines = [
  {
    id: "standard_growth_routine",
    name: "Standard Growth Routine",
    description: "A proven 7-day routine designed for consistent gains through progressive tissue expansion.",
    difficultyLevel: "Beginner",
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
    ]
  },
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
  }
];

async function addRoutines() {
  console.log('Starting to add standard routines to Firebase...\n');
  
  try {
    for (const routine of standardRoutines) {
      const routineData = {
        ...routine,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      };
      
      await setDoc(doc(db, 'routines', routine.id), routineData);
      console.log(`✓ Added: ${routine.name} (${routine.id})`);
    }
    
    console.log('\n✅ All standard routines have been successfully added to Firebase!');
  } catch (error) {
    console.error('\n❌ Error adding routines:', error);
  }
  
  process.exit();
}

// Run the function
addRoutines();