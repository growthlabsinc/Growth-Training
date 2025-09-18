#!/bin/bash

echo "🚀 Deploying Angion Methods to Firestore..."
echo "================================"

# Check Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first."
    exit 1
fi

# Check current project
echo "📋 Current Firebase project:"
firebase use

echo -e "\n📝 Deployment approach:"
echo "Since Firebase CLI doesn't support direct document updates,"
echo "we'll use the Firebase Admin SDK via a Node.js script."

# Create deployment script
cat > /tmp/deploy-angion-methods.js << 'EOF'
const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85'
});

const db = admin.firestore();

async function deployMethods() {
  console.log('Starting deployment...');
  
  // Angion Method 1.0 steps
  const angion1Steps = [
    {
      stepNumber: 1,
      title: "Preparation and Lubrication",
      description: "Obtain an erection and apply either a non-paraben (or non methyl paraben) water-based lubricant or silicone-based lubricant (ideal) along the dorsal side of your member (the portion you see when looking down) right along the middle line.",
      duration: 60,
      tips: [
        "Silicone-based lubricant is ideal for longer sessions",
        "Apply lubricant generously along the center line",
        "Ensure the dorsal side is well-lubricated"
      ],
      warnings: ["Avoid parabens and methyl parabens in lubricants"]
    },
    {
      stepNumber: 2,
      title: "Locate the Dorsal Veins",
      description: "So long as a male's member does not present with extreme curvature, the Deep Dorsal and Superficial Dorsal Veins should exist along the center line of the shaft. In the event of extreme curvature, gently squeeze your member with your hand and kegel blood into the erectile chambers, then visually inspect your shaft.",
      duration: 30,
      tips: [
        "The Deep Dorsal Vein should be visible to the naked eye",
        "Look for the vein along the center line of the shaft",
        "In case of curvature, note the vein's actual position"
      ],
      warnings: ["If you have severe arterial insufficiency/underdevelopment, consult a healthcare provider"]
    },
    {
      stepNumber: 3,
      title: "Hand Positioning",
      description: "Once the area over and around your Deep Dorsal Vein is sufficiently lubricated, hold your member between your hands in such a way that you are able to place both of your thumbs along the dorsal side of your member.",
      duration: 30,
      tips: [
        "Position hands comfortably with thumbs on top",
        "Ensure you can easily alternate between thumbs",
        "Maintain a relaxed grip"
      ]
    },
    {
      stepNumber: 4,
      title: "Initial Stroke Technique",
      description: "Place one of your thumbs just below the glans on your shaft. Depress the vein cluster (Deep Dorsal and Superficial Dorsal Vein) along the middle line or where noted in the case of curvature, and then drag your thumb downwardly towards the base of your member.",
      duration: 60,
      tips: [
        "Apply moderate pressure - not too light, not too heavy",
        "Follow the vein line from glans to base",
        "This is manipulating the venous portion of your Bulbo-Dorsal Circuit"
      ],
      warnings: ["Stop if you experience pain"]
    },
    {
      stepNumber: 5,
      title: "Begin the Workout - Slow Pace",
      description: "Place your thumb just below your glans along the center line and begin stroking downwardly. As your first thumb is finishing its downward stroke, begin another downward stroke with your other thumb. Start slowly.",
      duration: 300,
      tips: [
        "Alternate thumbs continuously",
        "Maintain consistent pressure",
        "Focus on rhythm and technique"
      ],
      intensity: "low"
    },
    {
      stepNumber: 6,
      title: "Increase Pace - Medium Intensity",
      description: "Continue the alternating thumb strokes while gradually increasing your pace. Maintain proper form while building speed.",
      duration: 600,
      tips: [
        "Increase speed gradually",
        "Maintain consistent pressure",
        "Re-apply lubricant if needed"
      ],
      intensity: "medium"
    },
    {
      stepNumber: 7,
      title: "Peak Workout - Higher Intensity",
      description: "Aim to pick up your pace as the workout progresses. Maintain the alternating thumb strokes at a faster pace while keeping proper form.",
      duration: 900,
      tips: [
        "Find a sustainable fast pace",
        "Loss of erection is normal initially",
        "Focus on the vein stimulation, not maintaining erection"
      ],
      intensity: "high",
      warnings: ["Never perform while seated", "Stop if pain occurs"]
    },
    {
      stepNumber: 8,
      title: "Cool Down",
      description: "Gradually reduce the pace of your strokes back to a slow rhythm before stopping completely. This helps normalize blood flow.",
      duration: 180,
      tips: [
        "Slow down gradually",
        "End with gentle strokes",
        "Allow natural detumescence"
      ],
      intensity: "low"
    }
  ];
  
  // Angio Pumping steps
  const angioPumpingSteps = [
    {
      stepNumber: 1,
      title: "Safety Check and Equipment Setup",
      description: "As a safety precaution, males that have experienced prolonged and non-compliant severe erectile dysfunction would be wise to have either an ultrasound or Doppler done on the arteries feeding their sexual organs to check for calcification or blockage.",
      duration: 60,
      tips: [
        "Ensure you have a penis pump with quick release valve",
        "Must have pressure gauge",
        "Need elastic ACE bandage wrap",
        "California Exotics pump recommended for button release mechanism"
      ],
      warnings: ["Never exceed 4hg pressure", "Ideally stay at or below 3hg"]
    },
    {
      stepNumber: 2,
      title: "Prepare Pump and Bandage",
      description: "Remove the rubber sleeve at the bottom of the pump and place it over your member. Once in place, wrap your member snugly in the ACE elastic bandage wrap.",
      duration: 120,
      tips: [
        "Bandage helps stave off edema",
        "Increases fluid exchange between arterial and venous networks",
        "Wrap snugly but not too tight"
      ]
    },
    {
      stepNumber: 3,
      title: "Position Equipment",
      description: "With the bandage wraps in place, slide the penile pump back into its rubber sleeve. Ensure everything is in position and sealed.",
      duration: 60,
      tips: [
        "Check for proper seal",
        "Ensure comfortable positioning",
        "Lie down - never perform seated"
      ]
    },
    {
      stepNumber: 4,
      title: "Initial Pump Test",
      description: "Pump until the dial hits 3hg. Your member will likely begin to expand. Now, slowly release the pressure. You should feel blood rushing from your member through your Deep Dorsal Vein and Superficial Vein.",
      duration: 60,
      intensity: "low",
      tips: [
        "This mechanically forces Bulbo-Dorsal Circuit activation",
        "Pay attention to the sensation of blood flow",
        "Go slowly on first attempt"
      ]
    },
    {
      stepNumber: 5,
      title: "Rapid Pumping Phase - Beginner",
      description: "Begin rapidly pumping until the dial reaches 3hg and then releasing the pressure to mechanically force your penile tissues to breathe and exchange fluid between arterial and venous networks.",
      duration: 300,
      intensity: "medium",
      tips: [
        "Beginners keep sessions short",
        "Focus on rhythm",
        "As rate of flow increases, so does shear based stimulation"
      ],
      warnings: ["Maximum 10 minutes for beginners"]
    },
    {
      stepNumber: 6,
      title: "Rapid Pumping Phase - Intermediate",
      description: "Continue rapid pump and release cycles, maintaining rhythm and watching pressure gauge carefully.",
      duration: 600,
      intensity: "medium",
      tips: [
        "Only progress to this after several sessions",
        "May take weeks to reach this duration",
        "Monitor for any discomfort"
      ]
    },
    {
      stepNumber: 7,
      title: "Rapid Pumping Phase - Advanced",
      description: "For advanced users only. Continue pump and release cycles for extended duration.",
      duration: 900,
      intensity: "medium",
      tips: [
        "Aim for full 30 minute workout eventually",
        "Don't rush progression",
        "Overtraining is counterproductive"
      ]
    },
    {
      stepNumber: 8,
      title: "Cool Down and Recovery",
      description: "Slowly decrease pumping frequency and carefully remove equipment. Remove bandage wrap last.",
      duration: 120,
      intensity: "low",
      tips: [
        "Release all pressure before removing",
        "Remove bandage gently",
        "Allow natural recovery"
      ]
    }
  ];
  
  try {
    // Update Angion Method 1.0
    await db.collection('growthMethods').doc('angion_method_1_0').update({
      steps: angion1Steps,
      hasMultipleSteps: true
    });
    console.log('✅ Angion Method 1.0 updated with 8 steps');
    
    // Update Angio Pumping
    await db.collection('growthMethods').doc('angio_pumping').update({
      steps: angioPumpingSteps,
      hasMultipleSteps: true
    });
    console.log('✅ Angio Pumping updated with 8 steps');
    
    console.log('\n🎉 Deployment complete!');
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  process.exit(0);
}

deployMethods();
EOF

echo -e "\n📋 Manual Deployment Instructions:"
echo "1. Go to Firebase Console: https://console.firebase.google.com"
echo "2. Select project: growth-70a85"
echo "3. Navigate to Firestore Database"
echo "4. Find the 'growthMethods' collection"
echo "5. Update these documents:"
echo "   - angion_method_1_0: Add the 'steps' array field"
echo "   - angio_pumping: Add the 'steps' array field"
echo ""
echo "📁 The full step data is in:"
echo "   - scripts/firebase-deploy-data/angion_method_1_0.json"
echo "   - scripts/firebase-deploy-data/angio_pumping.json"
echo ""
echo "✅ You can copy and paste the steps array from these files!"