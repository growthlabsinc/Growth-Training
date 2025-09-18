const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

const routine = {
  id: 'standard_growth_routine',
  name: 'Standard Growth Routine',
  description: 'A balanced weekly routine based on the 1on1off principle, focusing on Angion Methods for optimal vascular development and recovery.',
  difficultyLevel: 'Beginner',
  schedule: [
    {
      id: 'day1',
      dayNumber: 1,
      dayName: 'Day 1: Heavy Day',
      description: 'Perform Angio Pumping (if required) or Angion Method 1.0/2.0, plus optional pumping and S2S stretches.',
      methodIds: ['angio_pumping', 'am1_0', 'am2_0'],
      isRestDay: false,
      additionalNotes: 'Keep session under 30 minutes. Use ACE bandage and pump if doing Angio Pumping.'
    },
    {
      id: 'day2',
      dayNumber: 2,
      dayName: 'Day 2: Rest or Light',
      description: 'Rest day or light Angion Method 1.0. Focus on recovery, light massage, and heat.',
      methodIds: ['am1_0'],
      isRestDay: false,
      additionalNotes: 'If feeling fatigued, take a full rest day.'
    },
    {
      id: 'day3',
      dayNumber: 3,
      dayName: 'Day 3: Moderate Day',
      description: 'Angion Method 2.0 and S2S stretches. Optional light pumping.',
      methodIds: ['am2_0', 's2s_stretch'],
      isRestDay: false,
      additionalNotes: 'Monitor for any signs of overtraining.'
    },
    {
      id: 'day4',
      dayNumber: 4,
      dayName: 'Day 4: Rest',
      description: 'Full rest day. No exercises. Focus on recovery.',
      methodIds: [],
      isRestDay: true,
      additionalNotes: 'Use heat and light massage if desired.'
    },
    {
      id: 'day5',
      dayNumber: 5,
      dayName: 'Day 5: Heavy Day',
      description: 'Repeat Day 1: Angio Pumping (if required) or Angion Method 1.0/2.0, plus optional pumping and S2S stretches.',
      methodIds: ['angio_pumping', 'am1_0', 'am2_0'],
      isRestDay: false,
      additionalNotes: 'Keep session under 30 minutes. Use ACE bandage and pump if doing Angio Pumping.'
    },
    {
      id: 'day6',
      dayNumber: 6,
      dayName: 'Day 6: Rest or Light',
      description: 'Rest day or light Angion Method 1.0. Focus on recovery, light massage, and heat.',
      methodIds: ['am1_0'],
      isRestDay: false,
      additionalNotes: 'If feeling fatigued, take a full rest day.'
    },
    {
      id: 'day7',
      dayNumber: 7,
      dayName: 'Day 7: Rest',
      description: 'Full rest day. No exercises. Focus on recovery.',
      methodIds: [],
      isRestDay: true,
      additionalNotes: 'Use heat and light massage if desired.'
    }
  ],
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp()
};

db.collection('routines').doc(routine.id).set(routine)
  .then(() => {
    console.log('Routine uploaded!');
    process.exit(0);
  })
  .catch(err => {
    console.error('Error uploading routine:', err);
    process.exit(1);
  }); 