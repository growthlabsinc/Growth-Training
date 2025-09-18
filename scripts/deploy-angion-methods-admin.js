#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Configuration
const PROJECT_ID = 'growth-70a85';
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  path.join(__dirname, '..', 'service-account-key.json');

// Check if service account file exists
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error(`❌ Service account key not found at: ${SERVICE_ACCOUNT_PATH}`);
  console.error('Please ensure you have a service account key file.');
  console.error('You can download it from Firebase Console > Project Settings > Service Accounts');
  process.exit(1);
}

// Initialize Firebase Admin
try {
  const serviceAccount = require(SERVICE_ACCOUNT_PATH);
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: PROJECT_ID
  });
  
  console.log(`✅ Firebase Admin initialized for project: ${PROJECT_ID}`);
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin:', error.message);
  process.exit(1);
}

const db = admin.firestore();

// Angion methods with multi-step data
const angionMethods = [
  {
    id: 'angion-method-1-0',
    name: 'Angion Method 1.0',
    description: 'The foundational Angion Method focuses on improving blood flow through rhythmic compression.',
    category: 'angion',
    difficulty: 'beginner',
    duration: 1800, // 30 minutes
    isMultiStep: true,
    multiStepData: {
      totalDuration: 1800,
      steps: [
        {
          id: 'step-1',
          name: 'Warm Up',
          description: 'Gentle massage to prepare for the exercise',
          duration: 300, // 5 minutes
          order: 0,
          instructions: [
            'Apply gentle pressure with your thumb and index finger',
            'Start at the base and work your way up',
            'Use slow, controlled movements',
            'Focus on relaxation and blood flow'
          ]
        },
        {
          id: 'step-2',
          name: 'Main Exercise - Compressions',
          description: 'Rhythmic compressions to stimulate blood flow',
          duration: 1200, // 20 minutes
          order: 1,
          instructions: [
            'Form an "OK" grip with moderate pressure',
            'Compress at the base for 2-3 seconds',
            'Release and move up slightly',
            'Repeat in a rhythmic pattern',
            'Maintain consistent pressure throughout'
          ]
        },
        {
          id: 'step-3',
          name: 'Cool Down',
          description: 'Gentle massage to finish the session',
          duration: 300, // 5 minutes
          order: 2,
          instructions: [
            'Reduce pressure to very light',
            'Perform gentle strokes from base to tip',
            'Focus on relaxation',
            'Allow blood flow to normalize'
          ]
        }
      ]
    },
    instructions: 'Angion Method 1.0 uses rhythmic compressions to enhance blood flow.',
    benefits: [
      'Improved blood circulation',
      'Enhanced vascular health',
      'Better endurance',
      'Increased sensitivity'
    ],
    precautions: [
      'Start with light pressure and gradually increase',
      'Stop immediately if you experience pain',
      'Maintain proper form throughout',
      'Stay hydrated before and after'
    ],
    equipment: ['Lubrication (water-based recommended)'],
    imageUrl: '',
    videoUrl: '',
    order: 0,
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: 'angion-method-2-0',
    name: 'Angion Method 2.0',
    description: 'An advanced technique that builds upon AM 1.0 with more intense stimulation.',
    category: 'angion',
    difficulty: 'intermediate',
    duration: 2400, // 40 minutes
    isMultiStep: true,
    multiStepData: {
      totalDuration: 2400,
      steps: [
        {
          id: 'step-1',
          name: 'Initial Warm Up',
          description: 'Prepare with AM 1.0 technique',
          duration: 600, // 10 minutes
          order: 0,
          instructions: [
            'Start with AM 1.0 compressions',
            'Use moderate pressure',
            'Focus on achieving good blood flow',
            'Ensure you\'re fully warmed up'
          ]
        },
        {
          id: 'step-2',
          name: 'Advanced Compressions',
          description: 'More intense rhythmic compressions',
          duration: 1500, // 25 minutes
          order: 1,
          instructions: [
            'Increase compression intensity from AM 1.0',
            'Use a faster rhythm (1-2 compressions per second)',
            'Focus on the corpus cavernosum',
            'Maintain consistent pressure and rhythm',
            'Take brief breaks if needed'
          ]
        },
        {
          id: 'step-3',
          name: 'Recovery Phase',
          description: 'Gentle massage and stretching',
          duration: 300, // 5 minutes
          order: 2,
          instructions: [
            'Reduce to very light pressure',
            'Perform gentle stretches',
            'Focus on relaxation and recovery',
            'Allow blood flow to stabilize'
          ]
        }
      ]
    },
    instructions: 'Angion Method 2.0 intensifies the compressions from AM 1.0 for advanced practitioners.',
    benefits: [
      'Significantly improved blood flow',
      'Enhanced vascular capacity',
      'Increased stamina',
      'Better overall vascular health'
    ],
    precautions: [
      'Must master AM 1.0 first',
      'Monitor for any discomfort',
      'Do not exceed recommended duration',
      'Take rest days between sessions'
    ],
    equipment: ['Quality lubrication', 'Timer', 'Comfortable environment'],
    imageUrl: '',
    videoUrl: '',
    order: 1,
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: 'angion-method-3-0',
    name: 'Angion Method 3.0',
    description: 'The most advanced Angion Method, incorporating specialized techniques.',
    category: 'angion',
    difficulty: 'advanced',
    duration: 3600, // 60 minutes
    isMultiStep: true,
    multiStepData: {
      totalDuration: 3600,
      steps: [
        {
          id: 'step-1',
          name: 'Progressive Warm Up',
          description: 'Gradual preparation through AM 1.0 and 2.0',
          duration: 900, // 15 minutes
          order: 0,
          instructions: [
            'Begin with 5 minutes of AM 1.0',
            'Progress to AM 2.0 technique',
            'Gradually increase intensity',
            'Ensure optimal blood flow before proceeding'
          ]
        },
        {
          id: 'step-2',
          name: 'Advanced Vascular Training',
          description: 'Specialized techniques for maximum effect',
          duration: 2100, // 35 minutes
          order: 1,
          instructions: [
            'Implement advanced compression patterns',
            'Vary pressure and rhythm strategically',
            'Focus on different vascular regions',
            'Include brief isometric holds',
            'Monitor your body\'s response closely'
          ]
        },
        {
          id: 'step-3',
          name: 'Extended Cool Down',
          description: 'Comprehensive recovery protocol',
          duration: 600, // 10 minutes
          order: 2,
          instructions: [
            'Gradually reduce intensity over 5 minutes',
            'Perform gentle stretching exercises',
            'Use very light massage techniques',
            'Focus on complete relaxation',
            'Hydrate and rest afterward'
          ]
        }
      ]
    },
    instructions: 'Angion Method 3.0 is for experienced practitioners only, combining all previous techniques.',
    benefits: [
      'Maximum vascular enhancement',
      'Peak blood flow capacity',
      'Superior endurance',
      'Optimal vascular health'
    ],
    precautions: [
      'Requires mastery of AM 1.0 and 2.0',
      'Not for beginners',
      'Monitor closely for overtraining',
      'Ensure adequate recovery time',
      'Stay well hydrated'
    ],
    equipment: ['Premium lubrication', 'Timer', 'Heart rate monitor (optional)', 'Recovery supplements'],
    imageUrl: '',
    videoUrl: '',
    order: 2,
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

async function deployMethods() {
  console.log('\n🚀 Starting Angion Methods deployment...\n');
  
  const batch = db.batch();
  const methodsRef = db.collection('methods');
  
  try {
    // Deploy each method
    for (const method of angionMethods) {
      const docRef = methodsRef.doc(method.id);
      batch.set(docRef, method, { merge: true });
      
      console.log(`📝 Preparing ${method.name} for deployment...`);
      
      // Log multi-step details
      if (method.isMultiStep && method.multiStepData) {
        console.log(`   - Multi-step method with ${method.multiStepData.steps.length} steps`);
        method.multiStepData.steps.forEach(step => {
          console.log(`     • ${step.name} (${step.duration}s)`);
        });
      }
    }
    
    // Commit the batch
    console.log('\n⏳ Committing to Firestore...');
    await batch.commit();
    
    console.log('\n✅ All Angion Methods deployed successfully!');
    
    // Verify deployment
    console.log('\n🔍 Verifying deployment...');
    for (const method of angionMethods) {
      const doc = await methodsRef.doc(method.id).get();
      if (doc.exists) {
        const data = doc.data();
        console.log(`✓ ${data.name} - Multi-step: ${data.isMultiStep ? 'Yes' : 'No'}`);
        
        if (data.isMultiStep && data.multiStepData) {
          console.log(`  Steps: ${data.multiStepData.steps.map(s => s.name).join(', ')}`);
        }
      } else {
        console.log(`❌ ${method.name} - Not found!`);
      }
    }
    
    console.log('\n🎉 Deployment complete!');
    
  } catch (error) {
    console.error('\n❌ Deployment failed:', error);
    throw error;
  }
}

// Run deployment
deployMethods()
  .then(() => {
    console.log('\n👋 Exiting...');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Fatal error:', error);
    process.exit(1);
  });