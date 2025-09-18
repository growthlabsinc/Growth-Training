const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
  const serviceAccount = require(path.join(__dirname, '../Growth/Resources/Plist/dev.GoogleService-Info.json'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

// 12-Week Advanced Routine based on Janus Protocol
const advancedRoutine = {
  id: "janus_protocol_12week",
  name: "Janus Protocol - 12 Week Advanced",
  description: "The complete 12-week advanced routine based on the Janus Protocol. Incorporates Angion Methods, SABRE techniques, and BFR training in a carefully structured progression. Requires mastery of intermediate techniques.",
  difficultyLevel: "Advanced",
  schedule: [
    // Week 1
    { id: "w1d1", dayNumber: 1, dayName: "Week 1 Day 1: Heavy Day", description: "Angion Methods + SABRE + BFR", methodIds: ["vascion", "sabre_type_b", "bfr_cyclic_bending"], isRestDay: false },
    { id: "w1d2", dayNumber: 2, dayName: "Week 1 Day 2: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w1d3", dayNumber: 3, dayName: "Week 1 Day 3: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w1d4", dayNumber: 4, dayName: "Week 1 Day 4: SABRE/BFR", description: "SABRE and BFR combination", methodIds: ["sabre_type_b", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w1d5", dayNumber: 5, dayName: "Week 1 Day 5: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w1d6", dayNumber: 6, dayName: "Week 1 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w1d7", dayNumber: 7, dayName: "Week 1 Day 7: Heavy Day", description: "Full workout - all techniques", methodIds: ["vascion", "sabre_type_b", "bfr_cyclic_bending"], isRestDay: false },
    
    // Week 2
    { id: "w2d1", dayNumber: 8, dayName: "Week 2 Day 1: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w2d2", dayNumber: 9, dayName: "Week 2 Day 2: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w2d3", dayNumber: 10, dayName: "Week 2 Day 3: SABRE/BFR", description: "SABRE and BFR combination", methodIds: ["sabre_type_b", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w2d4", dayNumber: 11, dayName: "Week 2 Day 4: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w2d5", dayNumber: 12, dayName: "Week 2 Day 5: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w2d6", dayNumber: 13, dayName: "Week 2 Day 6: Heavy Day", description: "Full workout - all techniques", methodIds: ["vascion", "sabre_type_b", "bfr_cyclic_bending"], isRestDay: false },
    { id: "w2d7", dayNumber: 14, dayName: "Week 2 Day 7: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    
    // Week 3
    { id: "w3d1", dayNumber: 15, dayName: "Week 3 Day 1: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w3d2", dayNumber: 16, dayName: "Week 3 Day 2: SABRE/BFR", description: "SABRE and BFR combination", methodIds: ["sabre_type_b", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w3d3", dayNumber: 17, dayName: "Week 3 Day 3: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w3d4", dayNumber: 18, dayName: "Week 3 Day 4: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w3d5", dayNumber: 19, dayName: "Week 3 Day 5: Heavy Day", description: "Full workout - all techniques", methodIds: ["vascion", "sabre_type_b", "bfr_cyclic_bending"], isRestDay: false },
    { id: "w3d6", dayNumber: 20, dayName: "Week 3 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w3d7", dayNumber: 21, dayName: "Week 3 Day 7: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    
    // Week 4 - Deload Week
    { id: "w4d1", dayNumber: 22, dayName: "Week 4 Day 1: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
    { id: "w4d2", dayNumber: 23, dayName: "Week 4 Day 2: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false, additionalNotes: "Keep it very light - recovery focus" },
    { id: "w4d3", dayNumber: 24, dayName: "Week 4 Day 3: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
    { id: "w4d4", dayNumber: 25, dayName: "Week 4 Day 4: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false, additionalNotes: "Keep it very light - recovery focus" },
    { id: "w4d5", dayNumber: 26, dayName: "Week 4 Day 5: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
    { id: "w4d6", dayNumber: 27, dayName: "Week 4 Day 6: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false, additionalNotes: "Keep it very light - recovery focus" },
    { id: "w4d7", dayNumber: 28, dayName: "Week 4 Day 7: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
    
    // Week 5 - Intensity Increase
    { id: "w5d1", dayNumber: 29, dayName: "Week 5 Day 1: Heavy Plus", description: "Increased intensity", methodIds: ["vascion", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false, additionalNotes: "Moving to Type C SABRE" },
    { id: "w5d2", dayNumber: 30, dayName: "Week 5 Day 2: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w5d3", dayNumber: 31, dayName: "Week 5 Day 3: Angion Focus", description: "Extended Angion session", methodIds: ["vascion"], isRestDay: false, additionalNotes: "Try for 35-40 minutes if possible" },
    { id: "w5d4", dayNumber: 32, dayName: "Week 5 Day 4: SABRE/BFR", description: "Higher intensity SABRE", methodIds: ["sabre_type_c", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w5d5", dayNumber: 33, dayName: "Week 5 Day 5: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w5d6", dayNumber: 34, dayName: "Week 5 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w5d7", dayNumber: 35, dayName: "Week 5 Day 7: Heavy Plus", description: "Full workout with Type C SABRE", methodIds: ["vascion", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false },
    
    // Week 6
    { id: "w6d1", dayNumber: 36, dayName: "Week 6 Day 1: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w6d2", dayNumber: 37, dayName: "Week 6 Day 2: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w6d3", dayNumber: 38, dayName: "Week 6 Day 3: SABRE/BFR", description: "Type C SABRE focus", methodIds: ["sabre_type_c", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w6d4", dayNumber: 39, dayName: "Week 6 Day 4: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w6d5", dayNumber: 40, dayName: "Week 6 Day 5: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w6d6", dayNumber: 41, dayName: "Week 6 Day 6: Heavy Plus", description: "Full workout intensity", methodIds: ["vascion", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false },
    { id: "w6d7", dayNumber: 42, dayName: "Week 6 Day 7: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    
    // Week 7
    { id: "w7d1", dayNumber: 43, dayName: "Week 7 Day 1: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w7d2", dayNumber: 44, dayName: "Week 7 Day 2: SABRE/BFR", description: "Maintain Type C intensity", methodIds: ["sabre_type_c", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w7d3", dayNumber: 45, dayName: "Week 7 Day 3: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w7d4", dayNumber: 46, dayName: "Week 7 Day 4: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w7d5", dayNumber: 47, dayName: "Week 7 Day 5: Heavy Plus", description: "Full workout intensity", methodIds: ["vascion", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false },
    { id: "w7d6", dayNumber: 48, dayName: "Week 7 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w7d7", dayNumber: 49, dayName: "Week 7 Day 7: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    
    // Week 8 - Deload
    { id: "w8d1", dayNumber: 50, dayName: "Week 8 Day 1: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
    { id: "w8d2", dayNumber: 51, dayName: "Week 8 Day 2: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false },
    { id: "w8d3", dayNumber: 52, dayName: "Week 8 Day 3: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
    { id: "w8d4", dayNumber: 53, dayName: "Week 8 Day 4: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false },
    { id: "w8d5", dayNumber: 54, dayName: "Week 8 Day 5: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
    { id: "w8d6", dayNumber: 55, dayName: "Week 8 Day 6: Light S2S", description: "Light stretching only", methodIds: ["s2s_advanced"], isRestDay: false },
    { id: "w8d7", dayNumber: 56, dayName: "Week 8 Day 7: Rest", description: "Deload week - complete rest", methodIds: null, isRestDay: true },
    
    // Week 9 - Peak Intensity Introduction
    { id: "w9d1", dayNumber: 57, dayName: "Week 9 Day 1: Peak Heavy", description: "Introducing Type D SABRE", methodIds: ["vascion", "sabre_type_d", "bfr_cyclic_bending"], isRestDay: false, additionalNotes: "First Type D session - be very careful" },
    { id: "w9d2", dayNumber: 58, dayName: "Week 9 Day 2: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w9d3", dayNumber: 59, dayName: "Week 9 Day 3: Angion Focus", description: "Recovery focus", methodIds: ["vascion"], isRestDay: false },
    { id: "w9d4", dayNumber: 60, dayName: "Week 9 Day 4: Moderate SABRE", description: "Back to Type C for recovery", methodIds: ["sabre_type_c", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w9d5", dayNumber: 61, dayName: "Week 9 Day 5: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w9d6", dayNumber: 62, dayName: "Week 9 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w9d7", dayNumber: 63, dayName: "Week 9 Day 7: Heavy Plus", description: "Type C intensity", methodIds: ["vascion", "sabre_type_c", "bfr_cyclic_bending"], isRestDay: false },
    
    // Week 10
    { id: "w10d1", dayNumber: 64, dayName: "Week 10 Day 1: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w10d2", dayNumber: 65, dayName: "Week 10 Day 2: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w10d3", dayNumber: 66, dayName: "Week 10 Day 3: Peak SABRE", description: "Type D SABRE session", methodIds: ["sabre_type_d", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w10d4", dayNumber: 67, dayName: "Week 10 Day 4: Angion Focus", description: "Recovery focus", methodIds: ["vascion"], isRestDay: false },
    { id: "w10d5", dayNumber: 68, dayName: "Week 10 Day 5: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w10d6", dayNumber: 69, dayName: "Week 10 Day 6: Peak Heavy", description: "Full Type D workout", methodIds: ["vascion", "sabre_type_d", "bfr_cyclic_bending"], isRestDay: false },
    { id: "w10d7", dayNumber: 70, dayName: "Week 10 Day 7: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    
    // Week 11
    { id: "w11d1", dayNumber: 71, dayName: "Week 11 Day 1: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w11d2", dayNumber: 72, dayName: "Week 11 Day 2: Peak SABRE", description: "Maintaining peak intensity", methodIds: ["sabre_type_d", "bfr_glans_pulsing"], isRestDay: false },
    { id: "w11d3", dayNumber: 73, dayName: "Week 11 Day 3: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    { id: "w11d4", dayNumber: 74, dayName: "Week 11 Day 4: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w11d5", dayNumber: 75, dayName: "Week 11 Day 5: Peak Heavy", description: "Full Type D workout", methodIds: ["vascion", "sabre_type_d", "bfr_cyclic_bending"], isRestDay: false },
    { id: "w11d6", dayNumber: 76, dayName: "Week 11 Day 6: Rest", description: "Complete rest day", methodIds: null, isRestDay: true },
    { id: "w11d7", dayNumber: 77, dayName: "Week 11 Day 7: Angion Focus", description: "Angion Methods only", methodIds: ["vascion"], isRestDay: false },
    
    // Week 12 - Final Deload
    { id: "w12d1", dayNumber: 78, dayName: "Week 12 Day 1: Rest", description: "Final deload - complete rest", methodIds: null, isRestDay: true },
    { id: "w12d2", dayNumber: 79, dayName: "Week 12 Day 2: Light S2S", description: "Light recovery work", methodIds: ["s2s_advanced"], isRestDay: false },
    { id: "w12d3", dayNumber: 80, dayName: "Week 12 Day 3: Rest", description: "Final deload - complete rest", methodIds: null, isRestDay: true },
    { id: "w12d4", dayNumber: 81, dayName: "Week 12 Day 4: Light Angion", description: "Light Angion work", methodIds: ["am2_0"], isRestDay: false, additionalNotes: "Use AM2.0 for lighter intensity" },
    { id: "w12d5", dayNumber: 82, dayName: "Week 12 Day 5: Rest", description: "Final deload - complete rest", methodIds: null, isRestDay: true },
    { id: "w12d6", dayNumber: 83, dayName: "Week 12 Day 6: Assessment", description: "Light session to assess progress", methodIds: ["vascion"], isRestDay: false, additionalNotes: "20 minutes max - assess improvements" },
    { id: "w12d7", dayNumber: 84, dayName: "Week 12 Day 7: Complete", description: "Program complete - rest and plan next cycle", methodIds: null, isRestDay: true, additionalNotes: "Congratulations! Take measurements and plan next training cycle" }
  ],
  createdAt: new Date(),
  updatedAt: new Date()
};

async function addAdvancedRoutine() {
  console.log('Adding Janus Protocol 12-Week Advanced Routine to Firestore...');
  
  try {
    const routineRef = db.collection('routines').doc(advancedRoutine.id);
    await routineRef.set({
      ...advancedRoutine,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Successfully added the Janus Protocol 12-Week Advanced Routine!');
    console.log(`Total days: ${advancedRoutine.schedule.length}`);
    console.log(`Training days: ${advancedRoutine.schedule.filter(d => !d.isRestDay).length}`);
    console.log(`Rest days: ${advancedRoutine.schedule.filter(d => d.isRestDay).length}`);
  } catch (error) {
    console.error('Error adding routine:', error);
  }
}

// Run the function
addAdvancedRoutine().then(() => {
  console.log('Script completed');
  process.exit(0);
}).catch(error => {
  console.error('Script failed:', error);
  process.exit(1);
});