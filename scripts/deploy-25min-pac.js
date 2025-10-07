#!/usr/bin/env node

/**
 * Deploy the 25min PAC exercise (the one to keep)
 *
 * This replaces the 20min version with the detailed 25min version
 * that has 7 structured steps with timers.
 */

const admin = require('firebase-admin');

admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

const MEDICAL_DISCLAIMER_BASE = `⚠️ MEDICAL DISCLAIMER
This exercise carries physical risks. Consult a healthcare provider before beginning any PE program.

STOP IMMEDIATELY if you experience:
- Pain or sharp discomfort
- Numbness or tingling
- Dark discoloration (purple/black spots)
- Loss of erection quality
- Reduced sensitivity
- Blistering or skin damage`;

const AGE_RESTRICTION = "This content is for adults 18+ only. Individual results vary.";

function createSafetyNotes(contraindications, guidelines) {
  return `${MEDICAL_DISCLAIMER_BASE}

CONTRAINDICATIONS:
${contraindications.map(c => `- ${c}`).join('\n')}

SAFETY GUIDELINES:
${guidelines.map(g => `- ${g}`).join('\n')}

${AGE_RESTRICTION}`;
}

const PAC_25MIN = {
  id: "pump_assisted_clamping_pac",
  stage: 3,
  classification: "Advanced",
  title: "Pump Assisted Clamping (PAC)",
  description: "Advanced girth technique combining vacuum pumping with clamping for maximum expansion. PAC alternates between pump-induced expansion and clamp-restricted blood flow to promote significant girth gains through progressive tissue expansion.",
  instructionsText: `This advanced technique combines the benefits of pumping and clamping for maximum girth expansion. Follow each phase carefully and monitor for any warning signs.

TOTAL DURATION: 25 minutes

PHASE 1 - Warm-up (5 min)
PHASE 2 - Initial Pump (5 min)
PHASE 3 - Clamp Application (1 min)
PHASE 4 - Clamped Hold (5-7 min)
PHASE 5 - Release and Massage (2 min)
PHASE 6 - Second Pump Session (5 min)
PHASE 7 - Cool-down (5 min)`,
  categories: ["girth"],
  equipmentNeeded: ["pump", "clamp", "lube", "heat"],
  estimatedDurationMinutes: 25,
  safetyNotes: createSafetyNotes(
    [
      "All contraindications for pumping AND clamping",
      "Cardiovascular disease or heart problems",
      "High or low blood pressure issues",
      "Blood clotting disorders",
      "Taking any blood thinners or anticoagulants",
      "History of priapism or blood vessel issues",
      "Diabetes or severe circulatory problems",
      "Beginners - DO NOT attempt without extensive pumping AND clamping experience"
    ],
    [
      "This is EXPERT-LEVEL technique - requires significant experience with BOTH pumping and clamping separately",
      "NEVER exceed 10 minutes total clamped time per session",
      "Start with lower pressure (3-5 inHg) than your normal pumping routine",
      "Use adequate padding under clamp to prevent tissue damage",
      "Monitor glans color every 2 minutes while clamped",
      "Release clamp IMMEDIATELY if numbness, pain, or dark discoloration occurs",
      "Limit to 1-2 sessions per WEEK maximum due to high intensity",
      "Have at least 3 months of pumping AND clamping experience before attempting",
      "Never rush - follow timing precisely for each phase"
    ]
  ),
  isFeatured: false,
  benefits: [
    "Combines synergistic effects of pumping and clamping",
    "Enhanced girth gains through dual expansion methods",
    "Improved vascularity and blood flow capacity",
    "Progressive tissue expansion for permanent gains",
    "Better tissue conditioning than single method",
    "Potential for faster girth development"
  ],
  relatedMethods: ["stage2_static_pumping", "stage3_soft_clamping"],

  // Structured steps with precise timing
  steps: [
    {
      step_number: 1,
      title: "Warm-up Phase",
      description: "Warm up with 5-10 minutes of hot wrap or warm shower to prepare tissues",
      duration: 300,
      tips: [
        "Use as warm as comfortable",
        "Can also use heating pad"
      ],
      warnings: [],
      intensity: "Low"
    },
    {
      step_number: 2,
      title: "Initial Pump Session",
      description: "Start with pump at low pressure (3-5 Hg) for 5 minutes. Achieve 80-90% erection level.",
      duration: 300,
      tips: [
        "Start with lower pressure if new to pumping",
        "Use water-based lube for better seal"
      ],
      warnings: [
        "Monitor for red spots or discoloration"
      ],
      intensity: "Moderate"
    },
    {
      step_number: 3,
      title: "Clamp Application",
      description: "Release pump and immediately apply cable clamp at base with padding. Tighten to restrict outflow but maintain some inflow.",
      duration: 60,
      tips: [
        "Use mousepad or cloth for padding",
        "Should feel tight but not painful"
      ],
      warnings: [
        "Never clamp without padding"
      ],
      intensity: "Moderate"
    },
    {
      step_number: 4,
      title: "Clamped Hold",
      description: "Hold clamp for 5-7 minutes maximum for beginners. Perform light jelqs or squeezes while clamped (optional).",
      duration: 420,
      tips: [
        "Check glans color every 2 minutes",
        "Light movements only"
      ],
      warnings: [
        "Release immediately if numbness occurs",
        "Never exceed 10 minutes"
      ],
      intensity: "High"
    },
    {
      step_number: 5,
      title: "Release and Massage",
      description: "Release clamp and massage thoroughly to restore circulation",
      duration: 120,
      tips: [
        "Focus on base and shaft",
        "Use circular motions"
      ],
      warnings: [],
      intensity: "Low"
    },
    {
      step_number: 6,
      title: "Second Pump Session",
      description: "Return to pump for another 5 minute session at low pressure",
      duration: 300,
      tips: [
        "May use slightly higher pressure if comfortable",
        "Monitor expansion"
      ],
      warnings: [
        "Stop if pain occurs"
      ],
      intensity: "Moderate"
    },
    {
      step_number: 7,
      title: "Cool-down",
      description: "Cool down with light massage and warm wrap",
      duration: 300,
      tips: [
        "Gentle stretches can help",
        "Apply moisturizer"
      ],
      warnings: [],
      intensity: "Low"
    }
  ],

  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp()
};

async function deploy25MinPAC() {
  console.log('🚀 Deploying 25min PAC Exercise\n');

  // First, delete the 20min version if it exists
  console.log('🗑️  Removing 20min version (stage3_pump_assisted_clamping)...');
  await db.collection('growth_exercises').doc('stage3_pump_assisted_clamping').delete();
  console.log('✅ Removed\n');

  // Deploy the 25min version
  console.log('📤 Deploying 25min PAC exercise...');
  await db.collection('growth_exercises').doc(PAC_25MIN.id).set(PAC_25MIN);
  console.log('✅ Deployed!\n');

  // Verify
  const doc = await db.collection('growth_exercises').doc(PAC_25MIN.id).get();
  if (doc.exists) {
    const data = doc.data();
    console.log('📋 Exercise Details:');
    console.log(`   ID: ${doc.id}`);
    console.log(`   Title: ${data.title}`);
    console.log(`   Description: ${data.description}`);
    console.log(`   Stage: ${data.stage}`);
    console.log(`   Classification: ${data.classification}`);
    console.log(`   Duration: ${data.estimatedDurationMinutes} min`);
    console.log(`   Equipment: ${data.equipmentNeeded.join(', ')}`);
    console.log(`   Steps: ${data.steps?.length || 0} structured steps`);
    console.log(`   Benefits: ${data.benefits?.length || 0} listed`);
    console.log('\n✅ SUCCESS! 25min PAC exercise is now deployed.');
  } else {
    console.log('❌ ERROR: Failed to verify deployment');
  }
}

deploy25MinPAC().catch(err => {
  console.error('❌ Deployment failed:', err);
  process.exit(1);
});
