#!/usr/bin/env node

/**
 * Deploy PE Exercise Library to Firestore
 *
 * This script deploys comprehensive PE training protocols to the growth_exercises
 * collection in Firestore. All exercises include:
 * - Complete safety notes with medical disclaimers
 * - Equipment requirements and contraindications
 * - Proper categorization (length, girth, conditioning, eq)
 * - Classification levels (Beginner, Intermediate, Advanced)
 * - Timer configurations for timed exercises
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/deploy-pe-exercises.js
 *
 * Prerequisites:
 *   - Firebase Admin SDK installed
 *   - Application Default Credentials configured
 *   - Access to Firestore growth_exercises collection
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (uses Application Default Credentials)
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

// Standard medical disclaimer template for all PE exercises
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

/**
 * Creates comprehensive safety notes for an exercise
 * @param {Array<string>} contraindications - List of contraindications
 * @param {Array<string>} guidelines - List of safety guidelines
 * @returns {string} - Formatted safety notes
 */
function createSafetyNotes(contraindications, guidelines) {
  return `${MEDICAL_DISCLAIMER_BASE}

CONTRAINDICATIONS:
${contraindications.map(c => `- ${c}`).join('\n')}

SAFETY GUIDELINES:
${guidelines.map(g => `- ${g}`).join('\n')}

${AGE_RESTRICTION}`;
}

// ========================================
// MANUAL METHODS (No Equipment) - Stage 1
// ========================================

const MANUAL_METHODS = [
  {
    id: "stage1_basic_manual_stretch",
    stage: 1,
    classification: "Beginner",
    title: "Basic Manual Stretch",
    description: "Foundational length exercise using manual stretching technique to promote tissue extension and flexibility",
    instructionsText: `1. Grip behind the glans with an OK-grip (thumb and index finger forming a circle)
2. Pull gently forward, holding for 30-60 seconds
3. Release and rest for 30 seconds
4. Repeat in different directions: straight out, up, down, left, right
5. Perform 10-15 stretches per session
6. Focus on consistent tension rather than maximum force

IMPORTANT: Never grip directly on the glans. Always use an OK-grip behind the corona.`,
    categories: ["length"],
    equipmentNeeded: [],
    estimatedDurationMinutes: 25,
    safetyNotes: createSafetyNotes(
      [
        "Recent injury or surgery to the area",
        "Active infection or inflammation",
        "Peyronie's disease (consult physician first)",
        "Severe erectile dysfunction requiring treatment"
      ],
      [
        "Start with gentle tension - this is not a maximum force exercise",
        "Never grip the glans directly - use OK-grip behind the head",
        "Maintain consistent pressure throughout the hold",
        "Stop if skin becomes irritated or red",
        "Warm up with heat application before stretching"
      ]
    ),
    isFeatured: true,
    benefits: [
      "Increases length over time through controlled tissue extension",
      "Improves tissue flexibility and elasticity",
      "Low equipment requirements - can be done anywhere",
      "Good foundation for more advanced techniques"
    ],
    relatedMethods: ["stage1_timed_pressure_hold", "stage1_vacuum_extending"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage1_modified_jelq",
    stage: 1,
    classification: "Beginner",
    title: "Modified Jelq",
    description: "Girth-focused exercise using rhythmic compression to promote tissue expansion and blood flow",
    instructionsText: `1. Achieve 60-80% erection level (NOT fully erect)
2. Apply generous water-based lubricant
3. Form OK-grip at base with one hand
4. Slowly slide grip from base to glans over 2-3 seconds
5. Just before reaching glans, start new stroke with other hand
6. Alternate hands, maintaining consistent rhythm
7. Perform 200-300 strokes per session
8. Increase count gradually over weeks

CRITICAL: Never perform on 100% erection - this can cause injury.`,
    categories: ["girth", "conditioning"],
    equipmentNeeded: ["lube"],
    estimatedDurationMinutes: 20,
    safetyNotes: createSafetyNotes(
      [
        "Blood clotting disorders or taking blood thinners",
        "Cardiovascular disease or high blood pressure",
        "Skin conditions or allergies to lubricants",
        "Active infection or inflammation"
      ],
      [
        "NEVER perform on 100% erection - stay at 60-80% maximum",
        "Use generous water-based lubricant to prevent friction",
        "Start with 100-150 strokes and increase gradually",
        "Maintain moderate grip pressure - not too tight",
        "Take rest days between sessions for tissue recovery",
        "Stop if you see dark spots or bruising"
      ]
    ),
    isFeatured: true,
    benefits: [
      "Promotes girth expansion through controlled blood flow",
      "Improves tissue conditioning and resilience",
      "Enhances vascular health and circulation",
      "Can improve erection quality when done correctly"
    ],
    relatedMethods: ["stage1_milking_eq", "stage2_static_pumping"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage2_timed_pressure_hold",
    stage: 2,
    classification: "Intermediate",
    title: "Timed Pressure Hold (TPH)",
    description: "Advanced manual stretching technique using sustained pressure holds to maximize tissue extension",
    instructionsText: `1. Warm up with 5 minutes of heat application
2. Achieve semi-erect state (40-50%)
3. Grip behind glans with OK-grip
4. Apply moderate tension and hold for 3-5 minutes
5. Focus on consistent pressure, not maximum force
6. Change direction every hold (straight, up, down, sides)
7. Perform 4-6 holds per session with 2-minute rest between holds
8. Total session: 20-30 minutes including rest periods

KEY: The extended hold time creates sustained tension that promotes tissue adaptation.`,
    categories: ["length"],
    equipmentNeeded: [],
    estimatedDurationMinutes: 20,
    timerConfig: {
      recommended_duration_seconds: 300,
      is_countdown: true,
      has_intervals: true,
      intervals: [
        { name: "Hold", duration_seconds: 300 },
        { name: "Rest", duration_seconds: 120 }
      ],
      max_recommended_duration_seconds: 300
    },
    safetyNotes: createSafetyNotes(
      [
        "Recent injury or surgery",
        "Peyronie's disease (consult physician)",
        "Severe erectile dysfunction",
        "Nerve sensitivity issues"
      ],
      [
        "Build up to longer holds gradually - start with 2 minutes",
        "Never use maximum force - moderate consistent tension is key",
        "Take breaks if grip becomes too fatigued",
        "Stop if you experience numbness or loss of sensation",
        "This is an intermediate technique - master basic stretches first"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Extended hold time promotes greater tissue adaptation",
      "More efficient than multiple short stretches",
      "Develops mental discipline and body awareness",
      "Can produce faster length gains than basic stretching"
    ],
    relatedMethods: ["stage1_basic_manual_stretch", "stage2_vacuum_extending"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage1_timed_squash",
    stage: 1,
    classification: "Beginner",
    title: "Timed Squash",
    description: "Conditioning exercise using rhythmic compression to improve tissue flexibility and circulation",
    instructionsText: `1. Achieve flaccid or semi-erect state
2. Grip shaft with both hands close together
3. Squeeze gently while simultaneously compressing length (like an accordion)
4. Hold compression for 10-20 seconds
5. Release and allow blood flow to return
6. Repeat 20-30 times per session
7. Vary hand positions along the shaft

TECHNIQUE: This creates lateral tissue expansion while minimizing length, promoting flexibility.`,
    categories: ["conditioning", "eq"],
    equipmentNeeded: [],
    estimatedDurationMinutes: 10,
    safetyNotes: createSafetyNotes(
      [
        "Cardiovascular issues",
        "Blood pressure problems",
        "Active skin conditions"
      ],
      [
        "Use gentle to moderate pressure only",
        "Never compress so hard it causes pain",
        "Allow full blood flow return between compressions",
        "Start with fewer repetitions and build up",
        "This is a conditioning exercise, not a force exercise"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Improves tissue flexibility and conditioning",
      "Enhances circulation throughout the shaft",
      "Low risk when performed correctly",
      "Good warm-up or cooldown exercise"
    ],
    relatedMethods: ["stage1_milking_eq", "stage1_heat_application"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage1_milking_eq",
    stage: 1,
    classification: "Beginner",
    title: "Milking (EQ Focus)",
    description: "Gentle rhythmic strokes focused on improving erection quality and vascular health",
    instructionsText: `1. Achieve 40-60% erection
2. Apply light lubrication
3. Form loose OK-grip at base
4. Gently "milk" from base to glans with very light pressure
5. Focus on smooth, gentle strokes - NOT force
6. Perform 50-100 gentle strokes
7. Alternate hands for continuous motion
8. Session duration: 5-10 minutes

PURPOSE: This is about circulation and blood flow, not tissue expansion. Keep pressure LIGHT.`,
    categories: ["eq", "conditioning"],
    equipmentNeeded: [],
    estimatedDurationMinutes: 8,
    safetyNotes: createSafetyNotes(
      [
        "Cardiovascular disease",
        "Recent heart issues or stroke",
        "Severe high blood pressure"
      ],
      [
        "Keep pressure VERY light - this is not a jelq",
        "Focus on smooth rhythm, not force",
        "Stop if erection becomes uncomfortably hard",
        "This is a recovery/conditioning exercise",
        "Can be done daily as it's very low intensity"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Improves circulation and vascular health",
      "Enhances erection quality over time",
      "Very low risk when done with light pressure",
      "Good for rest days or as warm-up/cooldown",
      "Promotes tissue health without stress"
    ],
    relatedMethods: ["stage1_heat_application", "stage1_modified_jelq"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

// ========================================
// DEVICE-BASED METHODS - Stage 2 & 3
// ========================================

const DEVICE_METHODS = [
  {
    id: "stage2_static_pumping",
    stage: 2,
    classification: "Intermediate",
    title: "Static Pumping",
    description: "Girth exercise using sustained vacuum pressure to promote tissue expansion and blood flow",
    instructionsText: `1. Trim pubic hair to ensure good seal
2. Apply water-based lubricant to base of penis and cylinder entrance
3. Insert into cylinder and create seal
4. Pump slowly to create gentle vacuum (start at 3-5 inHg)
5. Hold pressure for 5 minutes
6. Release pressure completely, massage, rest 2 minutes
7. Repeat for 3-5 sets
8. Total session: 20-40 minutes
9. NEVER exceed 10 inHg pressure

CRITICAL: Start with LOW pressure and increase gradually over weeks, not within a single session.`,
    categories: ["girth"],
    equipmentNeeded: ["pump", "lube"],
    estimatedDurationMinutes: 30,
    timerConfig: {
      recommended_duration_seconds: 300,
      is_countdown: true,
      has_intervals: true,
      intervals: [
        { name: "Pump", duration_seconds: 300 },
        { name: "Rest", duration_seconds: 120 }
      ],
      max_recommended_duration_seconds: 2400
    },
    safetyNotes: createSafetyNotes(
      [
        "Blood clotting disorders",
        "Taking blood thinners or anticoagulants",
        "History of priapism",
        "Severe cardiovascular disease",
        "Recent surgery in the area"
      ],
      [
        "NEVER exceed 10 inHg pressure - serious injury can occur",
        "Start at 3-5 inHg and increase slowly over WEEKS",
        "Use a gauge pump to monitor pressure accurately",
        "Stop if you see dark purple/black spots (burst capillaries)",
        "Limit sessions to 40 minutes maximum",
        "Take at least one rest day between sessions",
        "Apply heat before pumping for better results"
      ]
    ),
    isFeatured: true,
    benefits: [
      "Promotes significant girth expansion over time",
      "Improves vascular capacity and blood flow",
      "Can enhance erection quality when done correctly",
      "Predictable and measurable results"
    ],
    relatedMethods: ["stage2_vanilla_interval_pumping", "stage3_rapid_interval_pumping"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage3_rapid_interval_pumping",
    stage: 3,
    classification: "Advanced",
    title: "Rapid Interval Pumping (RIP)",
    description: "Advanced pumping protocol using rapid pressure cycling to maximize vascular expansion",
    instructionsText: `1. Warm up with 5 minutes of heat
2. Apply generous lubricant and insert into cylinder
3. Pump to working pressure (5-7 inHg for beginners)
4. Hold for 30 seconds
5. Release pressure COMPLETELY
6. Rest for 30 seconds (massage during rest)
7. Repeat cycle for 20-30 intervals
8. Total session: 20-30 minutes
9. Finish with 5-minute static hold at low pressure

ADVANCED TECHNIQUE: This protocol is for experienced pumpers only. The rapid cycling creates significant vascular stress.`,
    categories: ["girth"],
    equipmentNeeded: ["pump", "lube"],
    estimatedDurationMinutes: 30,
    timerConfig: {
      recommended_duration_seconds: 1800,
      is_countdown: true,
      has_intervals: true,
      intervals: [
        { name: "Pump", duration_seconds: 30 },
        { name: "Rest", duration_seconds: 30 }
      ],
      max_recommended_duration_seconds: 1800
    },
    safetyNotes: createSafetyNotes(
      [
        "Blood clotting disorders",
        "Taking blood thinners",
        "History of priapism or blood vessel issues",
        "Cardiovascular disease",
        "Beginners - use static pumping first"
      ],
      [
        "This is an ADVANCED technique - requires pumping experience",
        "Start with lower pressure than your static pumping routine",
        "Release pressure COMPLETELY during rest intervals",
        "Watch for dark spots - stop immediately if they appear",
        "Limit to 2-3 sessions per week maximum",
        "Never rush the intervals - maintain precise timing",
        "Have several weeks of static pumping experience first"
      ]
    ),
    isFeatured: false,
    benefits: [
      "More aggressive vascular expansion than static pumping",
      "Can produce faster girth gains for experienced users",
      "Improves vascular adaptation and capacity",
      "Efficient use of time for advanced practitioners"
    ],
    relatedMethods: ["stage2_static_pumping", "stage2_vanilla_interval_pumping"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage2_vanilla_interval_pumping",
    stage: 2,
    classification: "Intermediate",
    title: "Vanilla Interval Pumping",
    description: "Moderate interval pumping protocol balancing expansion with recovery time",
    instructionsText: `1. Warm up with heat application
2. Apply lubricant and create seal in cylinder
3. Pump to working pressure (5-7 inHg)
4. Hold for 5 minutes
5. Release pressure completely
6. Rest and massage for 1 minute
7. Repeat for 5-6 cycles
8. Total session: 30-36 minutes

TECHNIQUE: The longer intervals provide more expansion time while rest periods prevent fluid buildup.`,
    categories: ["girth"],
    equipmentNeeded: ["pump", "lube"],
    estimatedDurationMinutes: 30,
    timerConfig: {
      recommended_duration_seconds: 1800,
      is_countdown: true,
      has_intervals: true,
      intervals: [
        { name: "Pump", duration_seconds: 300 },
        { name: "Rest", duration_seconds: 60 }
      ],
      max_recommended_duration_seconds: 2160
    },
    safetyNotes: createSafetyNotes(
      [
        "Blood clotting disorders",
        "Taking blood thinners",
        "History of priapism",
        "Cardiovascular issues"
      ],
      [
        "Start at 5 inHg and increase gradually over weeks",
        "Never exceed 10 inHg pressure",
        "Massage during rest periods to maintain circulation",
        "Watch for excessive fluid buildup (donut effect)",
        "Take full rest days between sessions",
        "Stop if you see dark discoloration"
      ]
    ),
    isFeatured: true,
    benefits: [
      "Good balance between expansion and safety",
      "Less aggressive than RIP but more active than static",
      "Reduces fluid buildup compared to continuous pumping",
      "Suitable for intermediate users moving beyond static pumping"
    ],
    relatedMethods: ["stage2_static_pumping", "stage3_rapid_interval_pumping"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage3_soft_clamping",
    stage: 3,
    classification: "Advanced",
    title: "Soft Clamping",
    description: "Advanced girth exercise using controlled blood restriction to promote expansion",
    instructionsText: `1. Achieve 80-90% erection
2. Apply cable clamp at BASE only - never mid-shaft
3. Tighten just enough to maintain erection (start very loose)
4. Hold for 5 minutes maximum
5. Remove clamp completely
6. Rest for 5 minutes with massage
7. Repeat for 2-3 sets maximum
8. Total session: 10-20 minutes

CRITICAL: This is called "soft" clamping because the clamp is LOOSE, not tight. Never overtighten.`,
    categories: ["girth"],
    equipmentNeeded: ["clamp"],
    estimatedDurationMinutes: 15,
    timerConfig: {
      recommended_duration_seconds: 300,
      is_countdown: true,
      has_intervals: true,
      intervals: [
        { name: "Clamp", duration_seconds: 300 },
        { name: "Rest", duration_seconds: 300 }
      ],
      max_recommended_duration_seconds: 300
    },
    safetyNotes: createSafetyNotes(
      [
        "Cardiovascular disease or heart problems",
        "High or low blood pressure issues",
        "Blood clotting disorders",
        "Taking blood thinners or anticoagulants",
        "Diabetes or circulatory problems",
        "History of priapism"
      ],
      [
        "This is an ADVANCED technique with significant risk",
        "NEVER exceed 5 minutes clamped",
        "Start with VERY loose clamping - barely restricting",
        "Remove clamp immediately if erection becomes painful",
        "Never clamp mid-shaft - base only",
        "Stop if you see purple/black discoloration",
        "Limit to 2 sessions per week maximum",
        "Have significant PE experience before attempting"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Can produce rapid girth gains",
      "Increases vascular capacity",
      "Time-efficient for advanced users",
      "Enhances hardness and expansion potential"
    ],
    relatedMethods: ["stage3_pump_assisted_clamping"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage2_shopping_bag_hanger",
    stage: 2,
    classification: "Intermediate",
    title: "Shopping Bag Hanger",
    description: "Length exercise using progressive weight hanging with safe attachment method",
    instructionsText: `1. Ensure completely flaccid state
2. Attach hanger device securely behind glans (never on glans)
3. Start with minimal weight (1-2 lbs maximum for beginners)
4. Sit or stand with weight hanging freely
5. Maintain for 10-20 minutes
6. Remove weight and massage thoroughly
7. Can repeat for 2-3 sets with rest between
8. GRADUALLY increase weight over months, not days

TECHNIQUE: The "shopping bag" refers to progressive weight addition method used by experienced practitioners.`,
    categories: ["length"],
    equipmentNeeded: ["hanger"],
    estimatedDurationMinutes: 30,
    timerConfig: {
      recommended_duration_seconds: 1200,
      is_countdown: true,
      has_intervals: false,
      max_recommended_duration_seconds: 1200
    },
    safetyNotes: createSafetyNotes(
      [
        "Nerve damage or sensitivity issues",
        "Recent injury or surgery",
        "Peyronie's disease",
        "Severe erectile dysfunction"
      ],
      [
        "NEVER exceed 20 minutes per set",
        "Start with 1-2 lbs only - this is NOT a maximum weight exercise",
        "Never hang on an erect penis - fully flaccid only",
        "Remove immediately if you feel numbness or coldness",
        "Increase weight VERY gradually over months",
        "Never attach directly to glans - behind corona only",
        "Stop if you experience any nerve symptoms",
        "Take full rest days between sessions"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Consistent tension promotes length gains",
      "Measurable and progressive weight addition",
      "Can be done while working or doing other activities",
      "Well-documented results in community"
    ],
    relatedMethods: ["stage1_basic_manual_stretch", "stage1_vacuum_extending"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage2_vacuum_extending",
    stage: 2,
    classification: "Intermediate",
    title: "Vacuum Extending",
    description: "Length exercise using vacuum attachment extender for prolonged gentle tension",
    instructionsText: `1. Ensure clean, dry skin
2. Apply vacuum extender cap/sleeve
3. Create gentle vacuum seal
4. Attach to extension rods or strap system
5. Apply light tension - should feel comfortable
6. Wear for 1-2 hours per session
7. Take 10-minute breaks every hour
8. Gradually increase wearing time over weeks

ADVANTAGE: Vacuum attachment is more comfortable than traditional strap extenders for long-duration wear.`,
    categories: ["length"],
    equipmentNeeded: ["extender"],
    estimatedDurationMinutes: 120,
    timerConfig: {
      recommended_duration_seconds: 3600,
      is_countdown: true,
      has_intervals: true,
      intervals: [
        { name: "Extend", duration_seconds: 3000 },
        { name: "Rest", duration_seconds: 600 }
      ],
      max_recommended_duration_seconds: 7200
    },
    safetyNotes: createSafetyNotes(
      [
        "Nerve sensitivity issues",
        "Circulatory problems",
        "Recent injury or surgery",
        "Severe erectile dysfunction"
      ],
      [
        "Start with 30-60 minute sessions and build up gradually",
        "Never use maximum tension - light consistent tension is key",
        "Take 10-minute breaks every hour",
        "Remove immediately if you feel numbness or coldness",
        "Ensure proper vacuum seal to prevent slippage",
        "Can be worn under clothing but ensure privacy",
        "Stop if skin becomes irritated or chafed"
      ]
    ),
    isFeatured: true,
    benefits: [
      "Extended wearing time promotes consistent tension",
      "More comfortable than strap-based extenders",
      "Can be worn during daily activities",
      "Well-documented length gains with consistent use",
      "Lower risk than hanging when done correctly"
    ],
    relatedMethods: ["stage1_all_day_stretcher", "stage2_shopping_bag_hanger"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage1_all_day_stretcher",
    stage: 1,
    classification: "Beginner",
    title: "All-Day Stretcher (ADS)",
    description: "Passive length exercise using lightweight device for extended daily wear",
    instructionsText: `1. Select comfortable ADS device (sleeve, strap, or vacuum)
2. Ensure flaccid state
3. Apply device with minimal tension
4. Wear for 4-8 hours per day
5. Take breaks every 2 hours for circulation
6. Can be worn under normal clothing
7. Remove for bathroom, exercise, sleep
8. Clean device daily

CONCEPT: Consistent low-tension over many hours per day prevents retraction and promotes length retention.`,
    categories: ["length"],
    equipmentNeeded: ["ads"],
    estimatedDurationMinutes: 360,
    safetyNotes: createSafetyNotes(
      [
        "Circulatory problems",
        "Nerve sensitivity",
        "Skin allergies to device materials"
      ],
      [
        "Use MINIMAL tension - this is passive stretching",
        "Take regular breaks for circulation",
        "Never wear during sleep",
        "Remove if you feel any numbness or discomfort",
        "Ensure device is clean to prevent infection",
        "Start with shorter wearing periods (2-4 hours)",
        "This is a complementary exercise, not primary length work"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Prevents retraction between active PE sessions",
      "Maintains length gains",
      "Very low intensity and risk",
      "Can be worn during normal daily activities",
      "Good for beginners or rest day activity"
    ],
    relatedMethods: ["stage1_vacuum_extending", "stage1_basic_manual_stretch"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

// ========================================
// ADVANCED TECHNIQUES - Stage 2 & 3
// ========================================

const ADVANCED_METHODS = [
  {
    id: "stage2_shock_loading",
    stage: 2,
    classification: "Intermediate",
    title: "Shock Loading",
    description: "Pre-fatigue technique using brief girth work before length exercises to enhance results",
    instructionsText: `1. Warm up with 5 minutes of heat
2. PHASE 1 - Girth Pre-Fatigue (5 minutes):
   - Perform 50-100 light jelqs OR
   - 5 minutes of light pumping (3-5 inHg)
3. Rest for 2-3 minutes with massage
4. PHASE 2 - Length Work (20-25 minutes):
   - Perform manual stretches OR
   - Use extender/hanger OR
   - Vacuum extending
5. Finish with cooldown

THEORY: Brief girth work creates temporary expansion that may enhance length exercise effectiveness.`,
    categories: ["girth", "length"],
    equipmentNeeded: ["pump", "lube"],
    estimatedDurationMinutes: 30,
    safetyNotes: createSafetyNotes(
      [
        "Any contraindications for both girth and length work",
        "Cardiovascular issues",
        "Blood pressure problems"
      ],
      [
        "Keep girth pre-fatigue LIGHT - this is not maximum effort",
        "Rest adequately between phases",
        "This combines techniques so carry higher fatigue",
        "Monitor for any excessive stress signals",
        "Not recommended for complete beginners",
        "Reduce overall session frequency if doing shock loading"
      ]
    ),
    isFeatured: false,
    benefits: [
      "May enhance length exercise effectiveness",
      "Time-efficient combination approach",
      "Addresses multiple goals in one session",
      "Used successfully by intermediate/advanced practitioners"
    ],
    relatedMethods: ["stage1_modified_jelq", "stage2_static_pumping"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage3_pump_assisted_clamping",
    stage: 3,
    classification: "Advanced",
    title: "Pump-Assisted Clamping (PAC)",
    description: "Advanced combination technique using pumping before clamping for maximum girth expansion",
    instructionsText: `1. Apply generous lubricant
2. PHASE 1 - Pumping (10 minutes):
   - Pump to 5-7 inHg
   - Hold for 5 minutes
   - Release, massage, repeat
3. Remove from pump with maintained engorgement
4. PHASE 2 - Clamping (10 minutes maximum):
   - Immediately apply clamp at base
   - Maintain for 5 minutes maximum
   - Remove clamp, massage thoroughly
   - Can repeat for ONE additional set maximum
5. Total session: 20 minutes maximum

CRITICAL: This is an ADVANCED technique combining two high-intensity methods.`,
    categories: ["girth"],
    equipmentNeeded: ["pump", "clamp", "lube"],
    estimatedDurationMinutes: 20,
    timerConfig: {
      recommended_duration_seconds: 600,
      is_countdown: true,
      has_intervals: true,
      intervals: [
        { name: "Pump Phase", duration_seconds: 300 },
        { name: "Clamp Phase", duration_seconds: 300 }
      ],
      max_recommended_duration_seconds: 1200
    },
    safetyNotes: createSafetyNotes(
      [
        "All contraindications for pumping AND clamping",
        "Cardiovascular disease",
        "Blood pressure issues",
        "Blood clotting disorders",
        "Taking any blood thinners",
        "History of priapism",
        "Diabetes"
      ],
      [
        "This is EXPERT-LEVEL technique - significant experience required",
        "NEVER exceed 5 minutes clamped",
        "Watch for dark purple/black discoloration",
        "Remove clamp immediately if painful",
        "Limit to 1-2 sessions per WEEK maximum",
        "Have extensive pumping AND clamping experience separately first",
        "This carries highest injury risk - proceed with extreme caution",
        "Many practitioners do NOT recommend this technique"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Maximum girth expansion potential",
      "Fast results for experienced users",
      "Combines advantages of both techniques"
    ],
    relatedMethods: ["stage2_static_pumping", "stage3_soft_clamping"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "stage3_bundles_with_pumping",
    stage: 3,
    classification: "Advanced",
    title: "Bundles with Pumping",
    description: "Advanced technique combining rotational stretching with vacuum pumping",
    instructionsText: `1. Achieve flaccid or semi-flaccid state
2. PHASE 1 - Bundles (10 minutes):
   - Grip behind glans
   - Rotate penis 360 degrees while stretched
   - Hold rotated position for 30 seconds
   - Reverse rotation direction
   - Perform 10-15 rotations each direction
3. PHASE 2 - Pumping (20 minutes):
   - Apply lubricant
   - Pump to working pressure (5-7 inHg)
   - Perform interval or static pumping
4. Total session: 30 minutes

THEORY: Rotational stress before pumping may enhance expansion in all dimensions.`,
    categories: ["girth", "length"],
    equipmentNeeded: ["pump", "lube"],
    estimatedDurationMinutes: 30,
    safetyNotes: createSafetyNotes(
      [
        "Peyronie's disease or penile curvature issues",
        "Recent injury or surgery",
        "All pumping contraindications"
      ],
      [
        "Advanced technique requiring experience with both bundles and pumping",
        "Be very gentle with rotations - do not force",
        "Stop if you feel sharp pain during rotation",
        "Never combine with clamping",
        "Limit frequency due to combination stress",
        "Master both techniques separately before combining"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Addresses multiple dimensions of expansion",
      "May enhance overall pumping results",
      "Used by advanced practitioners for plateau breaking"
    ],
    relatedMethods: ["stage1_basic_manual_stretch", "stage2_static_pumping"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

// ========================================
// CONDITIONING & EQ - Stage 1
// ========================================

const CONDITIONING_METHODS = [
  {
    id: "stage1_heat_application",
    stage: 1,
    classification: "Beginner",
    title: "Heat Application",
    description: "Therapeutic heat therapy to improve tissue elasticity and circulation before or after exercises",
    instructionsText: `1. Prepare heat source:
   - Rice sock: Microwave for 30-60 seconds
   - Heating pad: Set to low-medium
   - Warm cloth: Soak in warm (not hot) water
2. Test temperature on inner wrist first
3. Apply to area for 5-10 minutes
4. Can be used as:
   - Warm-up before exercises
   - Active therapy during rest periods
   - Cooldown after exercises
5. Maintain comfortable warmth, never hot

IMPORTANT: This is adjuvant therapy, not a standalone PE exercise.`,
    categories: ["conditioning", "eq"],
    equipmentNeeded: ["heat"],
    estimatedDurationMinutes: 10,
    timerConfig: {
      recommended_duration_seconds: 600,
      is_countdown: true,
      has_intervals: false,
      max_recommended_duration_seconds: 600
    },
    safetyNotes: createSafetyNotes(
      [
        "Reduced temperature sensitivity",
        "Diabetes with nerve damage",
        "Active infection or inflammation"
      ],
      [
        "NEVER use hot temperatures - warm only",
        "Always test temperature first",
        "Do not apply directly to skin without barrier if using rice sock",
        "Stop if skin becomes red or irritated",
        "Heat should be comfortable, never painful",
        "Do not use heat if area is injured or inflamed"
      ]
    ),
    isFeatured: false,
    benefits: [
      "Improves tissue elasticity for better exercise results",
      "Enhances circulation and blood flow",
      "Reduces injury risk when used as warm-up",
      "Promotes recovery when used as cooldown",
      "Very low risk when done correctly"
    ],
    relatedMethods: ["stage1_milking_eq", "stage1_basic_manual_stretch"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

// Combine all exercises
const ALL_EXERCISES = [
  ...MANUAL_METHODS,
  ...DEVICE_METHODS,
  ...ADVANCED_METHODS,
  ...CONDITIONING_METHODS
];

// ========================================
// VALIDATION & DEPLOYMENT
// ========================================

/**
 * Validates exercise data before deployment
 */
function validateExercises() {
  const errors = [];

  ALL_EXERCISES.forEach((exercise, index) => {
    // Check required fields
    if (!exercise.id) errors.push(`Exercise ${index}: Missing id`);
    if (!exercise.stage || exercise.stage < 1) errors.push(`Exercise ${index} (${exercise.id}): Invalid stage - must be >= 1`);
    if (!exercise.title) errors.push(`Exercise ${index} (${exercise.id}): Missing title`);
    if (!exercise.description) errors.push(`Exercise ${index} (${exercise.id}): Missing description`);
    if (!exercise.instructionsText) errors.push(`Exercise ${index} (${exercise.id}): Missing instructionsText`);
    if (!exercise.classification) errors.push(`Exercise ${index} (${exercise.id}): Missing classification`);
    if (!exercise.safetyNotes) errors.push(`Exercise ${index} (${exercise.id}): Missing safetyNotes`);
    if (!exercise.categories || exercise.categories.length === 0) errors.push(`Exercise ${index} (${exercise.id}): Missing categories`);

    // Validate classification values
    const validClassifications = ['Beginner', 'Intermediate', 'Advanced'];
    if (exercise.classification && !validClassifications.includes(exercise.classification)) {
      errors.push(`Exercise ${index} (${exercise.id}): Invalid classification "${exercise.classification}"`);
    }

    // Validate categories
    const validCategories = ['length', 'girth', 'conditioning', 'eq'];
    exercise.categories?.forEach(cat => {
      if (!validCategories.includes(cat)) {
        errors.push(`Exercise ${index} (${exercise.id}): Invalid category "${cat}"`);
      }
    });
  });

  return errors;
}

/**
 * Deploy exercises to Firestore
 */
async function deployExercises() {
  console.log('🚀 Starting PE Exercise Library Deployment\n');

  // Validate exercises first
  console.log('✓ Validating exercise data...');
  const errors = validateExercises();

  if (errors.length > 0) {
    console.error('❌ Validation failed:');
    errors.forEach(err => console.error(`  - ${err}`));
    process.exit(1);
  }

  console.log(`✓ Validation passed: ${ALL_EXERCISES.length} exercises ready for deployment\n`);

  // Create batch write
  const batch = db.batch();

  ALL_EXERCISES.forEach((exercise) => {
    const docRef = db.collection('growth_exercises').doc(exercise.id);
    batch.set(docRef, exercise);
  });

  // Commit batch
  console.log('📤 Deploying to Firestore...');
  await batch.commit();

  console.log(`\n✅ Successfully deployed ${ALL_EXERCISES.length} exercises to growth_exercises collection`);
  console.log('\nExercise breakdown:');
  console.log(`  - Manual Methods: ${MANUAL_METHODS.length}`);
  console.log(`  - Device-Based Methods: ${DEVICE_METHODS.length}`);
  console.log(`  - Advanced Techniques: ${ADVANCED_METHODS.length}`);
  console.log(`  - Conditioning & EQ: ${CONDITIONING_METHODS.length}`);
  console.log('\nNext steps:');
  console.log('  1. Verify in Firebase Console: https://console.firebase.google.com/project/growth-training-app/firestore');
  console.log('  2. Test in app: Open Methods Guide to see new exercises');
  console.log('  3. Test filtering by category and classification');
}

// Run deployment
deployExercises().catch((error) => {
  console.error('❌ Deployment failed:', error);
  process.exit(1);
});
