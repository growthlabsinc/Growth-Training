#!/usr/bin/env node

/**
 * Deploy PE Routine Templates to Firestore
 *
 * This script deploys 6 structured PE routine templates to the routines
 * collection in Firestore. All routines include:
 * - Beginner, Intermediate, and Advanced difficulty levels
 * - Complete daily schedules with DaySchedule and MethodSchedule structures
 * - Exercise references from Story 8.2 (growth_exercises collection)
 * - Focus areas (length, girth, balanced)
 * - Progression criteria and recovery schedules
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/deploy-pe-routines.js
 *
 * Prerequisites:
 *   - Firebase Admin SDK installed
 *   - Application Default Credentials configured
 *   - Access to Firestore routines collection
 *   - Story 8.2 exercises deployed to growth_exercises collection
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (uses Application Default Credentials)
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

/**
 * Helper to create MethodSchedule object
 * @param {string} methodId - Exercise document ID from growth_exercises
 * @param {number} duration - Duration in minutes
 * @param {number} order - Order in the day (0, 1, 2, ...)
 * @returns {object} MethodSchedule object
 */
function createMethodSchedule(methodId, duration, order) {
  return {
    id: `method_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    methodId: methodId,
    duration: duration,
    order: order
  };
}

/**
 * Helper to create DaySchedule object
 * @param {number} day - Day number (1, 2, 3, ...)
 * @param {string} description - Day description
 * @param {boolean} isRestDay - true for rest days, false for training days
 * @param {Array} methods - Array of MethodSchedule objects
 * @param {string} notes - Additional notes
 * @returns {object} DaySchedule object
 */
function createDaySchedule(day, description, isRestDay, methods = [], notes = "") {
  return {
    id: `day_${day}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    day: day,
    description: description,
    isRestDay: isRestDay,
    methods: methods,
    notes: notes
  };
}

// =============================================================================
// ROUTINE DEFINITIONS
// =============================================================================

/**
 * Beginner Routine 1: Length-Focused Beginner
 * - Focus: Length gains through manual stretches or device wear
 * - Pattern: Daily training with rest days
 * - Duration: 7-day repeating cycle
 */
const ROUTINE_BEGINNER_LENGTH_FOCUSED = {
  id: "routine_beginner_length_focused",
  name: "Length-Focused Beginner",
  description: "Daily manual stretches focusing on length gains. Perfect for beginners with minimal equipment. Build foundational technique and conditioning with low-risk exercises.",
  difficulty: "beginner",
  duration: 7,
  focusAreas: ["length"],
  stages: [1],
  schedule: [
    createDaySchedule(1, "Manual Stretch Day", false, [
      createMethodSchedule("stage1_basic_manual_stretch", 25, 0),
      createMethodSchedule("stage1_heat_application", 10, 1)
    ], "Warm up tissue before stretching. Keep total session under 40 minutes."),

    createDaySchedule(2, "Extended Device Wear", false, [
      createMethodSchedule("stage1_all_day_stretcher", 240, 0)
    ], "All-day stretcher (ADS) for passive length work. Wear during work/daily activities."),

    createDaySchedule(3, "Manual Stretch Day", false, [
      createMethodSchedule("stage1_basic_manual_stretch", 25, 0),
      createMethodSchedule("stage2_timed_pressure_hold", 20, 1)
    ], "Add timed pressure holds for variety. Focus on proper form."),

    createDaySchedule(4, "Rest Day", true, [], "Complete rest for tissue recovery."),

    createDaySchedule(5, "Combined Length Session", false, [
      createMethodSchedule("stage1_basic_manual_stretch", 20, 0),
      createMethodSchedule("stage2_vacuum_extending", 60, 1)
    ], "Active stretching followed by vacuum extending. Monitor for fatigue."),

    createDaySchedule(6, "Light Recovery Day", false, [
      createMethodSchedule("stage1_basic_manual_stretch", 15, 0)
    ], "Gentle stretching only. No intensity - focus on blood flow."),

    createDaySchedule(7, "Rest Day", true, [], "Complete rest. Assess weekly progress and check for negative PI.")
  ],
  isCustom: false,
  createdBy: null,
  shareWithCommunity: false,
  schedulingType: "sequential",
  tags: ["beginner", "length", "manual", "ads"],
  version: 1,
  createdDate: admin.firestore.FieldValue.serverTimestamp(),
  lastUpdated: admin.firestore.FieldValue.serverTimestamp()
};

/**
 * Beginner Routine 2: Balanced Beginner
 * - Focus: Alternating length and girth days for balanced gains
 * - Pattern: Alternating focus with recovery days
 * - Duration: 7-day repeating cycle
 */
const ROUTINE_BEGINNER_BALANCED = {
  id: "routine_beginner_balanced",
  name: "Balanced Beginner",
  description: "Alternating length and girth training for balanced gains. Ideal for beginners seeking overall development. Recovery-focused schedule prevents overtraining.",
  difficulty: "beginner",
  duration: 7,
  focusAreas: ["length", "girth"],
  stages: [1],
  schedule: [
    createDaySchedule(1, "Length Day", false, [
      createMethodSchedule("stage1_basic_manual_stretch", 25, 0),
      createMethodSchedule("stage1_heat_application", 10, 1)
    ], "Focus on length work. Warm up thoroughly before stretching."),

    createDaySchedule(2, "Rest Day", true, [], "Recovery day. Allow tissues to adapt."),

    createDaySchedule(3, "Girth Day", false, [
      createMethodSchedule("stage1_modified_jelq", 20, 0),
      createMethodSchedule("stage1_milking_eq", 10, 1)
    ], "Girth-focused session. Monitor EQ and adjust intensity as needed."),

    createDaySchedule(4, "Rest Day", true, [], "Recovery day. Check for any negative signs."),

    createDaySchedule(5, "Combined Session", false, [
      createMethodSchedule("stage1_basic_manual_stretch", 15, 0),
      createMethodSchedule("stage1_modified_jelq", 15, 1),
      createMethodSchedule("stage1_timed_squash", 10, 2)
    ], "Light combined work. Keep intensity moderate - this is conditioning."),

    createDaySchedule(6, "Rest Day", true, [], "Recovery before weekly restart."),

    createDaySchedule(7, "Rest Day", true, [], "Complete rest. Take measurements and photos for progress tracking.")
  ],
  isCustom: false,
  createdBy: null,
  shareWithCommunity: false,
  schedulingType: "sequential",
  tags: ["beginner", "balanced", "length", "girth"],
  version: 1,
  createdDate: admin.firestore.FieldValue.serverTimestamp(),
  lastUpdated: admin.firestore.FieldValue.serverTimestamp()
};

/**
 * Intermediate Routine 3: Shock Loading Protocol
 * - Focus: 5-10 min girth work before length for accelerated gains
 * - Pattern: Daily training with active recovery days
 * - Duration: 7-day repeating cycle
 */
const ROUTINE_INTERMEDIATE_SHOCK_LOADING = {
  id: "routine_intermediate_shock_loading",
  name: "Intermediate Shock Loading",
  description: "5-10 minute girth work before length exercises for accelerated gains. Requires understanding of proper intensity. Monitor closely for overtraining.",
  difficulty: "intermediate",
  duration: 7,
  focusAreas: ["length", "girth"],
  stages: [1, 2],
  schedule: [
    createDaySchedule(1, "Heavy Shock Loading", false, [
      createMethodSchedule("stage1_modified_jelq", 10, 0),
      createMethodSchedule("stage2_shock_loading", 30, 1)
    ], "Brief girth work followed by length protocol. This is an intense session."),

    createDaySchedule(2, "Active Recovery", false, [
      createMethodSchedule("stage1_basic_manual_stretch", 15, 0),
      createMethodSchedule("stage1_milking_eq", 10, 1)
    ], "Light work for blood flow. No intensity - just movement."),

    createDaySchedule(3, "Heavy Shock Loading", false, [
      createMethodSchedule("stage2_static_pumping", 10, 0),
      createMethodSchedule("stage2_vacuum_extending", 60, 1)
    ], "Pump shock before extending. Monitor pressure carefully."),

    createDaySchedule(4, "Active Recovery", false, [
      createMethodSchedule("stage1_basic_manual_stretch", 15, 0)
    ], "Gentle stretching only. Check EQ and recovery status."),

    createDaySchedule(5, "Heavy Shock Loading", false, [
      createMethodSchedule("stage1_modified_jelq", 10, 0),
      createMethodSchedule("stage2_shopping_bag_hanger", 30, 1)
    ], "Jelq shock before hanging. Use appropriate weight for experience level."),

    createDaySchedule(6, "Active Recovery", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage1_timed_squash", 10, 1)
    ], "Heat and light conditioning. Prepare for rest day."),

    createDaySchedule(7, "Rest Day", true, [], "Complete rest. Assess weekly progress and check for negative PI.")
  ],
  isCustom: false,
  createdBy: null,
  shareWithCommunity: false,
  schedulingType: "sequential",
  tags: ["intermediate", "shock_loading", "length", "girth"],
  version: 1,
  createdDate: admin.firestore.FieldValue.serverTimestamp(),
  lastUpdated: admin.firestore.FieldValue.serverTimestamp()
};

/**
 * Intermediate Routine 4: Pumping Protocol
 * - Focus: Girth expansion through pumping
 * - Pattern: 1 on / 1 off schedule
 * - Duration: 7-day repeating cycle
 */
const ROUTINE_INTERMEDIATE_PUMPING = {
  id: "routine_intermediate_pumping",
  name: "Intermediate Pumping",
  description: "Static and interval pumping for girth expansion. 1 on / 1 off schedule for optimal recovery. Requires pump device and pressure monitoring.",
  difficulty: "intermediate",
  duration: 7,
  focusAreas: ["girth"],
  stages: [1, 2],
  schedule: [
    createDaySchedule(1, "Static Pumping Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage2_static_pumping", 30, 1)
    ], "Warm up before pumping. Stay under 5-7 HG pressure for safety."),

    createDaySchedule(2, "Rest Day", true, [], "Recovery day. Monitor for fluid retention."),

    createDaySchedule(3, "Interval Pumping Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage2_vanilla_interval_pumping", 30, 1)
    ], "Interval protocol for enhanced expansion. Follow timer strictly."),

    createDaySchedule(4, "Rest Day", true, [], "Recovery day. Check EQ and tissue condition."),

    createDaySchedule(5, "Static Pumping Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage2_static_pumping", 30, 1),
      createMethodSchedule("stage1_milking_eq", 10, 2)
    ], "Static pump plus post-pump milking for EQ. Keep pressure moderate."),

    createDaySchedule(6, "Rest Day", true, [], "Recovery day. Prepare for weekly restart."),

    createDaySchedule(7, "Rest Day", true, [], "Complete rest. Take measurements for weekly progress tracking.")
  ],
  isCustom: false,
  createdBy: null,
  shareWithCommunity: false,
  schedulingType: "sequential",
  tags: ["intermediate", "pumping", "girth", "1on1off"],
  version: 1,
  createdDate: admin.firestore.FieldValue.serverTimestamp(),
  lastUpdated: admin.firestore.FieldValue.serverTimestamp()
};

/**
 * Advanced Routine 5: RIP Protocol
 * - Focus: Maximum girth expansion through rapid interval pumping
 * - Pattern: 1 on / 1 off with active recovery
 * - Duration: 7-day repeating cycle
 */
const ROUTINE_ADVANCED_RIP = {
  id: "routine_advanced_rip",
  name: "Advanced RIP Protocol",
  description: "Rapid Interval Pumping (30s pump / 30s release) for maximum girth. Experienced users only. Strict pressure limits and emergency protocols required.",
  difficulty: "advanced",
  duration: 7,
  focusAreas: ["girth"],
  stages: [2, 3],
  schedule: [
    createDaySchedule(1, "RIP Training Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage3_rapid_interval_pumping", 30, 1),
      createMethodSchedule("stage1_milking_eq", 10, 2)
    ], "Rapid interval pumping session. Stay under 7-10 HG. Post-pump milking essential."),

    createDaySchedule(2, "Rest Day", true, [], "Recovery day. Monitor for excessive fluid buildup."),

    createDaySchedule(3, "RIP Training Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage3_rapid_interval_pumping", 30, 1),
      createMethodSchedule("stage1_timed_squash", 10, 2)
    ], "RIP session with squash jelq for EQ maintenance. Watch for dark spots."),

    createDaySchedule(4, "Active Recovery", false, [
      createMethodSchedule("stage1_milking_eq", 15, 0)
    ], "Light milking only. Promote circulation without intensity."),

    createDaySchedule(5, "RIP Training Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage3_rapid_interval_pumping", 30, 1),
      createMethodSchedule("stage1_milking_eq", 10, 2)
    ], "Final RIP session of week. Reduce pressure if fatigued."),

    createDaySchedule(6, "Active Recovery", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage1_milking_eq", 10, 1)
    ], "Heat and light milking. Check for negative PI signs."),

    createDaySchedule(7, "Rest Day", true, [], "Complete rest. Measure girth gains and assess tissue health.")
  ],
  isCustom: false,
  createdBy: null,
  shareWithCommunity: false,
  schedulingType: "sequential",
  tags: ["advanced", "rip", "pumping", "girth", "1on1off"],
  version: 1,
  createdDate: admin.firestore.FieldValue.serverTimestamp(),
  lastUpdated: admin.firestore.FieldValue.serverTimestamp()
};

/**
 * Advanced Routine 6: PAC Protocol
 * - Focus: Pump-assisted clamping for extreme girth
 * - Pattern: 2 on / 1 off with strict safety
 * - Duration: 7-day repeating cycle
 */
const ROUTINE_ADVANCED_PAC = {
  id: "routine_advanced_pac",
  name: "Advanced PAC Protocol",
  description: "Pump-Assisted Clamping for extreme girth expansion. Requires extensive PE experience. Emergency protocols and strict monitoring essential.",
  difficulty: "advanced",
  duration: 7,
  focusAreas: ["girth"],
  stages: [1, 2, 3],
  schedule: [
    createDaySchedule(1, "PAC Training Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage3_pump_assisted_clamping", 25, 1),
      createMethodSchedule("stage1_milking_eq", 10, 2)
    ], "Pump to expansion then clamp. NEVER exceed 10 minutes clamped. Post-clamp milking mandatory."),

    createDaySchedule(2, "PAC Training Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage3_pump_assisted_clamping", 25, 1),
      createMethodSchedule("stage1_timed_squash", 10, 2)
    ], "Second PAC session. Reduce clamp time if tissue shows stress. Monitor for dark spots."),

    createDaySchedule(3, "Rest Day", true, [], "Recovery day. Check for excessive fluid retention or discoloration."),

    createDaySchedule(4, "PAC Training Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage3_bundles_with_pumping", 30, 1)
    ], "Bundles with pumping for length/girth combo. Advanced technique - strict form required."),

    createDaySchedule(5, "PAC Training Day", false, [
      createMethodSchedule("stage1_heat_application", 10, 0),
      createMethodSchedule("stage3_soft_clamping", 15, 1),
      createMethodSchedule("stage1_milking_eq", 10, 2)
    ], "Soft clamping day (lower intensity). Essential EQ maintenance work."),

    createDaySchedule(6, "Rest Day", true, [], "Recovery day. Assess tissue condition and EQ status."),

    createDaySchedule(7, "Rest Day", true, [], "Complete rest. Measure gains and plan next week intensity.")
  ],
  isCustom: false,
  createdBy: null,
  shareWithCommunity: false,
  schedulingType: "sequential",
  tags: ["advanced", "pac", "clamping", "pumping", "girth", "2on1off"],
  version: 1,
  createdDate: admin.firestore.FieldValue.serverTimestamp(),
  lastUpdated: admin.firestore.FieldValue.serverTimestamp()
};

// =============================================================================
// ROUTINE ARRAY
// =============================================================================

const ALL_ROUTINES = [
  ROUTINE_BEGINNER_LENGTH_FOCUSED,
  ROUTINE_BEGINNER_BALANCED,
  ROUTINE_INTERMEDIATE_SHOCK_LOADING,
  ROUTINE_INTERMEDIATE_PUMPING,
  ROUTINE_ADVANCED_RIP,
  ROUTINE_ADVANCED_PAC
];

// =============================================================================
// VALIDATION LOGIC
// =============================================================================

/**
 * Validates all routine data before deployment
 * @returns {Array<string>} Array of validation error messages (empty if valid)
 */
function validateRoutines() {
  const errors = [];

  ALL_ROUTINES.forEach((routine, index) => {
    // Check required fields
    if (!routine.id) {
      errors.push(`Routine ${index}: Missing id`);
    }

    if (!routine.name) {
      errors.push(`Routine ${index}: Missing name`);
    }

    if (!routine.description) {
      errors.push(`Routine ${index}: Missing description`);
    }

    if (!routine.difficulty || !["beginner", "intermediate", "advanced"].includes(routine.difficulty)) {
      errors.push(`Routine ${index} (${routine.id}): Invalid difficulty - must be beginner, intermediate, or advanced`);
    }

    if (!routine.schedule || routine.schedule.length === 0) {
      errors.push(`Routine ${index} (${routine.id}): Missing or empty schedule`);
    }

    if (routine.isCustom !== false) {
      errors.push(`Routine ${index} (${routine.id}): Standard routines must have isCustom=false`);
    }

    if (!routine.focusAreas || routine.focusAreas.length === 0) {
      errors.push(`Routine ${index} (${routine.id}): Missing focusAreas array`);
    }

    if (!routine.stages || routine.stages.length === 0) {
      errors.push(`Routine ${index} (${routine.id}): Missing stages array`);
    }

    // Validate schedule structure
    if (routine.schedule) {
      routine.schedule.forEach((day, dayIndex) => {
        if (!day.id) {
          errors.push(`Routine ${index} (${routine.id}), Day ${dayIndex}: Missing day id`);
        }
        if (typeof day.day !== 'number') {
          errors.push(`Routine ${index} (${routine.id}), Day ${dayIndex}: Day number must be a number`);
        }
        if (typeof day.isRestDay !== 'boolean') {
          errors.push(`Routine ${index} (${routine.id}), Day ${dayIndex}: isRestDay must be boolean`);
        }
        if (!day.description) {
          errors.push(`Routine ${index} (${routine.id}), Day ${dayIndex}: Missing description`);
        }

        // Validate methods array for non-rest days
        if (!day.isRestDay) {
          if (!Array.isArray(day.methods)) {
            errors.push(`Routine ${index} (${routine.id}), Day ${dayIndex}: Training days must have methods array`);
          }
        }
      });
    }
  });

  return errors;
}

// =============================================================================
// DEPLOYMENT LOGIC
// =============================================================================

/**
 * Main deployment function
 * Validates routine data and deploys to Firestore using batch write
 */
async function deployRoutines() {
  console.log("🏋️ PE Routine Deployment Script");
  console.log("================================\n");

  // Step 1: Validate all routine data
  console.log("🔍 Validating routine data...");
  const validationErrors = validateRoutines();

  if (validationErrors.length > 0) {
    console.error("\n❌ Validation failed:");
    validationErrors.forEach(err => console.error(`  - ${err}`));
    console.error(`\nFound ${validationErrors.length} validation error(s). Fix these issues before deployment.\n`);
    process.exit(1);
  }

  console.log("✅ Validation passed - all routines are valid\n");

  // Step 2: Create batch write
  console.log(`📦 Preparing to deploy ${ALL_ROUTINES.length} routines to Firestore...`);
  console.log(`   Target collection: routines`);
  console.log(`   Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}\n`);

  const batch = db.batch();

  ALL_ROUTINES.forEach(routine => {
    const docRef = db.collection('routines').doc(routine.id);
    batch.set(docRef, routine);
    console.log(`   ✓ Queued: ${routine.id} (${routine.difficulty})`);
  });

  // Step 3: Commit batch
  console.log("\n🚀 Committing batch write to Firestore...");

  try {
    await batch.commit();
    console.log("✅ Batch write successful!\n");
  } catch (error) {
    console.error("❌ Batch write failed:", error.message);
    console.error("\nFull error:", error);
    process.exit(1);
  }

  // Step 4: Print deployment summary
  const beginnerCount = ALL_ROUTINES.filter(r => r.difficulty === "beginner").length;
  const intermediateCount = ALL_ROUTINES.filter(r => r.difficulty === "intermediate").length;
  const advancedCount = ALL_ROUTINES.filter(r => r.difficulty === "advanced").length;

  console.log("📊 Deployment Summary:");
  console.log("=====================");
  console.log(`  Total Routines: ${ALL_ROUTINES.length}`);
  console.log(`  - Beginner: ${beginnerCount}`);
  console.log(`  - Intermediate: ${intermediateCount}`);
  console.log(`  - Advanced: ${advancedCount}`);
  console.log("\n✨ Deployment complete! Routines are now available in the app.\n");

  // Print routine details
  console.log("📋 Deployed Routines:");
  console.log("====================");
  ALL_ROUTINES.forEach(routine => {
    console.log(`\n  ${routine.name} (${routine.difficulty})`);
    console.log(`    ID: ${routine.id}`);
    console.log(`    Focus: ${routine.focusAreas.join(", ")}`);
    console.log(`    Duration: ${routine.duration} days`);
    console.log(`    Schedule: ${routine.schedule.length} days defined`);
  });

  console.log("\n🎉 All routines deployed successfully!");
  console.log("\n📝 Next Steps:");
  console.log("  1. Verify routines in Firebase Console:");
  console.log("     https://console.firebase.google.com/project/growth-training-app/firestore");
  console.log("  2. Test in app: Navigate to Routines view");
  console.log("  3. Verify filtering by difficulty level");
  console.log("  4. Test routine selection and schedule display\n");

  process.exit(0);
}

// Run deployment
deployRoutines().catch(error => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});
