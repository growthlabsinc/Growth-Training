// Firebase Admin SDK Update Script for SABRE Methods
// This script contains the update commands for all 4 SABRE types

const admin = require('firebase-admin');

// Initialize admin SDK (ensure you have credentials configured)
// admin.initializeApp();

const db = admin.firestore();

async function updateSABREMethods() {
  const updates = {
    // SABRE Type A Updates
    'sabre_type_a': {
      description: "Foundation SABRE strikes (1-3 per second, light force) for EQ improvement and vascular development. Phase One of the Path of Eleven.",
      instructionsText: "Shockwave/Strike Activated Bayliss Response Exercise. Using hand strikes at 1-3 per second with light force on heavily engorged but non-erect member. Timed session approach: 10 minutes each on left corporal, right corporal, and glans. Total 20-30 minutes.",
      safetyNotes: "Must be performed lying down. Never use painful force. Stop when fullness peaks and begins dropping. Maximum 30 minutes per session due to diminishing returns. Schedule: 1 day on, 2 days off.",
      benefits: [
        "Foundation for future gains",
        "EQ improvements",
        "Vascular network development",
        "Shear stress stimulation",
        "Prepares for advanced SABRE types"
      ],
      creator: "Janus Bifrons",
      hasMultipleSteps: true,
      estimatedDurationMinutes: 40,
      steps: [
        {
          stepNumber: 1,
          title: "Initial Warm-Up Preparation",
          description: "Begin with your member heavily engorged but NOT erect. Apply water or silicone-based lubricant liberally. This warm-up phase is crucial for endothelial cell channel activation and connective tissue protection.",
          duration: 120,
          tips: [
            "Member should be engorged but not erect",
            "Silicone lubricant is ideal for longer sessions",
            "Tissues become stronger with water content"
          ],
          warnings: ["Never begin with a fully erect member during warm-up"]
        },
        {
          stepNumber: 2,
          title: "Glans Preparation - Palm Rotations",
          description: "Liberally lubricate your glans. Place palm over glans and rotate in circular motions - 60 rotations clockwise, then 60 counter-clockwise. This activates the Bulbo-Dorsal circuit and prepares for strikes.",
          duration: 180,
          tips: [
            "Use plenty of lubricant to prevent chafing",
            "Gentle circular motions",
            "This activates Bayliss Effect in glans"
          ],
          warnings: ["Do not attempt without lubrication - very easy to chafe glans"]
        },
        {
          stepNumber: 3,
          title: "Glans Strike Warm-Up",
          description: "While loosely supporting shaft (not restricting blood flow), strike glans like pressing a button. Use controlled, tempered strikes. Perform 30 strikes per hand, switching hands halfway.",
          duration: 120,
          tips: [
            "Strike glans like a button",
            "Avoid hitting corporal nose cones directly",
            "Support shaft without restricting flow",
            "Kegel blood into glans if fullness decreases"
          ],
          intensity: "low"
        },
        {
          stepNumber: 4,
          title: "Left Corporal Body - Type A Strikes",
          description: "Tuck glans under thumb, angle hand to expose left corporal body. Make fist with exposed thumb. Perform strikes at 1-3 per second with LOW force. Focus on fluid displacement and shear stress.",
          duration: 600,
          tips: [
            "1-3 strikes per second",
            "Light force only",
            "Each strike pushes fluid through sinusoidal spaces",
            "Wait for erection to subside if it occurs"
          ],
          intensity: "low",
          warnings: ["Stop if any pain occurs", "Light force only for Type A"]
        },
        {
          stepNumber: 5,
          title: "Right Corporal Body - Type A Strikes",
          description: "Switch to expose right corporal body. Continue Type A strikes at 1-3 per second with low force. Maintain consistent rhythm and pressure throughout.",
          duration: 600,
          tips: [
            "Same technique as left side",
            "Monitor fullness levels",
            "Switch every 5 minutes if preferred",
            "Focus on shear stress stimulation"
          ],
          intensity: "low"
        },
        {
          stepNumber: 6,
          title: "Glans Strikes - Main Session",
          description: "Return to glans strikes using palm or fist. Maintain Type A parameters (1-3 per second, low force). This completes the circuit of stimulation.",
          duration: 600,
          tips: [
            "Can use palm strikes or button strikes",
            "Maintain low intensity throughout",
            "Re-lubricate if needed",
            "Monitor overall fullness"
          ],
          intensity: "low"
        },
        {
          stepNumber: 7,
          title: "Cool Down Assessment",
          description: "Gradually reduce strike frequency. Assess fullness levels - if fullness has peaked and is dropping, end session. Otherwise, can continue alternating between structures.",
          duration: 180,
          tips: [
            "Monitor peak fullness",
            "Stop when fullness begins to drop",
            "20-30 minutes total is optimal",
            "Never exceed 30 minutes"
          ],
          warnings: ["Diminishing returns after 30 minutes per research"]
        }
      ],
      timerConfig: {
        intervals: [
          { name: "Warm-Up & Lubrication", duration: 120, type: "preparation" },
          { name: "Glans Preparation", duration: 180, type: "preparation" },
          { name: "Glans Strike Warm-Up", duration: 120, type: "work" },
          { name: "Left Corporal Strikes", duration: 600, type: "work" },
          { name: "Right Corporal Strikes", duration: 600, type: "work" },
          { name: "Glans Main Strikes", duration: 600, type: "work" },
          { name: "Cool Down", duration: 180, type: "rest" }
        ],
        totalDuration: 2400,
        hasRest: true,
        restBetweenSets: 0
      },
      progressionCriteria: {
        minimumSessions: 10,
        consistencyDays: 14,
        keyIndicators: [
          "Improved EQ throughout sessions",
          "Can complete 20-30 minute sessions",
          "Noticeable vascular development",
          "Ready for Type B intensity"
        ],
        schedule: "1 day on, 2 days off"
      }
    },

    // SABRE Type B Updates
    'sabre_type_b': {
      description: "Increased speed SABRE (2-5 per second, light force) for enhanced shear stress and Bayliss Effect activation via calcium cycling. Phase Two progression.",
      instructionsText: "Higher speed strikes elicit Bayliss Effect driven smooth muscle activation. Work with heavily engorged flaccid to partially erect state. Same 10-minute divisions between structures. Increased speed causes calcium cycling between smooth muscles and endothelial cells.",
      safetyNotes: "Speed increases but force remains low. Calcium cycling creates powerful vasodilation. Stop at peak fullness. 1 on 2 off schedule mandatory for recovery.",
      benefits: [
        "Bayliss Effect activation",
        "Enhanced calcium cycling",
        "Smooth muscle stimulation",
        "Marked vasodilation",
        "Superior engorgement"
      ],
      creator: "Janus Bifrons",
      hasMultipleSteps: true,
      estimatedDurationMinutes: 40,
      steps: [
        {
          stepNumber: 1,
          title: "Enhanced Warm-Up Preparation",
          description: "Begin with heavily engorged but non-erect member. Type B requires better vascular preparation due to increased speed. Apply liberal lubrication.",
          duration: 120,
          tips: [
            "Focus on achieving heavy engorgement",
            "Extra lubrication for faster strikes",
            "Prepare mentally for increased pace"
          ],
          warnings: ["Ensure adequate warm-up before high-speed strikes"]
        },
        {
          stepNumber: 2,
          title: "Glans Activation - Rapid Rotations",
          description: "Perform palm rotations at increased speed. 60 rapid clockwise, 60 rapid counter-clockwise. This primes the Bayliss Effect for higher intensity work.",
          duration: 150,
          tips: [
            "Faster rotations than Type A",
            "Maintain control despite speed",
            "Feel for increased blood flow"
          ],
          intensity: "medium"
        },
        {
          stepNumber: 3,
          title: "Rapid Glans Strikes",
          description: "Strike glans at 2-5 per second with light force. The increased speed enhances shear stress while maintaining safety. 30-60 strikes total.",
          duration: 120,
          tips: [
            "2-5 strikes per second",
            "Light force despite high speed",
            "Focus on rhythm over power"
          ],
          intensity: "medium",
          warnings: ["Speed increases, force stays low"]
        },
        {
          stepNumber: 4,
          title: "Left Corporal - Type B Strikes",
          description: "Expose left corporal body. Execute strikes at 2-5 per second with LOW force. Increased speed elicits Bayliss Effect via calcium cycling while maintaining safety.",
          duration: 600,
          tips: [
            "2-5 strikes per second",
            "Maintain light force throughout",
            "Feel for fluid displacement",
            "Switch sides every 5 minutes if preferred"
          ],
          intensity: "medium",
          warnings: ["Do not increase force with speed"]
        },
        {
          stepNumber: 5,
          title: "Right Corporal - Type B Strikes",
          description: "Switch to right corporal body. Continue rapid strikes at 2-5 per second. Monitor for enhanced Bayliss Effect activation and smooth muscle response.",
          duration: 600,
          tips: [
            "Same rapid pace as left side",
            "Watch for increased fullness",
            "Calcium cycling increases with speed",
            "Re-lubricate if needed"
          ],
          intensity: "medium"
        },
        {
          stepNumber: 6,
          title: "Glans Strikes - Peak Session",
          description: "Return to glans with Type B parameters. The accumulated stimulation should produce noticeable fullness increases. Maintain 2-5 strikes per second.",
          duration: 600,
          tips: [
            "Peak fullness often occurs here",
            "Monitor for fullness drop-off",
            "Can alternate between structures",
            "Stop if fullness decreases"
          ],
          intensity: "medium"
        },
        {
          stepNumber: 7,
          title: "Controlled Deceleration",
          description: "Gradually reduce strike speed back to Type A levels before stopping. This allows proper vascular adjustment and prevents abrupt cessation.",
          duration: 180,
          tips: [
            "Slow reduction in speed",
            "End at peak fullness if possible",
            "Total session 20-30 minutes",
            "Rest 2 days before next session"
          ],
          warnings: ["1 on, 2 off schedule is mandatory"]
        }
      ],
      timerConfig: {
        intervals: [
          { name: "Warm-Up Preparation", duration: 120, type: "preparation" },
          { name: "Rapid Glans Activation", duration: 150, type: "preparation" },
          { name: "Glans Speed Strikes", duration: 120, type: "work" },
          { name: "Left Corporal Rapid", duration: 600, type: "work" },
          { name: "Right Corporal Rapid", duration: 600, type: "work" },
          { name: "Glans Peak Strikes", duration: 600, type: "work" },
          { name: "Deceleration", duration: 180, type: "rest" }
        ],
        totalDuration: 2370,
        hasRest: true,
        restBetweenSets: 0
      },
      progressionCriteria: {
        minimumSessions: 15,
        consistencyDays: 21,
        keyIndicators: [
          "Consistent Bayliss Effect activation",
          "Improved fullness response",
          "Ready for stretch-based strikes",
          "Can maintain 2-5 strikes per second"
        ],
        schedule: "1 day on, 2 days off"
      }
    },

    // SABRE Type C Updates
    'sabre_type_c': {
      description: "Introduction of metal rod implements. Low speed (1 per second) with moderate force for stretch-based stimulation. Phase Three/Four advancement.",
      instructionsText: "Transition from hand to smooth metal rod (8-10 inch bolt, 0.5 inch diameter). After Type B warm-up and Vascion preparation, perform 3 sets of 60 strikes per corporal body. Focus on elastic deformation without bruising.",
      safetyNotes: "First implement use requires extreme caution. Start very gentle to acclimate. Never use painful force. Control is critical. Extended recovery needed.",
      benefits: [
        "Stretch-based tissue stimulation",
        "Enhanced morning erections",
        "Tissue conditioning",
        "Preparation for Type D",
        "Advanced vascular development"
      ],
      equipmentNeeded: [
        "Smooth metal rod (8-10 inch bolt, 0.5 inch diameter)",
        "Long shank preferred with minimal threads",
        "Water or silicone lubricant",
        "Towel for cleanup"
      ],
      creator: "Janus Bifrons",
      hasMultipleSteps: true,
      estimatedDurationMinutes: 53,
      steps: [
        {
          stepNumber: 1,
          title: "Type B Warm-Up Phase",
          description: "Begin with 10 minutes of Type B strikes (high speed, low intensity) to prepare tissues. Use hand strikes only during warm-up. Member should be flaccid(b) to partially erect(d).",
          duration: 600,
          tips: [
            "Start with familiar Type B technique",
            "5 minutes left corporal, 5 minutes right",
            "Prepares for higher intensity work",
            "Hand strikes only for warm-up"
          ],
          intensity: "medium"
        },
        {
          stepNumber: 2,
          title: "Glans and Vascion Preparation",
          description: "Perform 5 minutes of palm-based glans striking followed by 15 minutes of Vascion work on the Corpora Spongiosum. This enhances blood flow before rod work.",
          duration: 1200,
          tips: [
            "Palm strikes for glans safety",
            "Vascion primes vascular networks",
            "Builds significant engorgement",
            "Prepares for implement use"
          ],
          intensity: "medium"
        },
        {
          stepNumber: 3,
          title: "Rod Introduction - Acclimation",
          description: "Transition to smooth metal rod (8-10 inch bolt, 0.5 inch diameter). Begin with VERY gentle strikes at 1 per second to acclimate tissues to implement.",
          duration: 120,
          tips: [
            "Start extremely gentle",
            "One strike per second maximum",
            "Feel for tissue response",
            "Stop if any discomfort"
          ],
          intensity: "low",
          warnings: ["First time using implements - extreme caution required"]
        },
        {
          stepNumber: 4,
          title: "Left Corporal - Type C Strikes",
          description: "Using rod, perform 60 strikes to left corporal body at 1 strike per second with moderate force. Focus on elastic deformation without bruising.",
          duration: 180,
          tips: [
            "1 strike per second pace",
            "Moderate force for stretch effect",
            "Count 60 strikes precisely",
            "Support member with other hand"
          ],
          intensity: "high",
          warnings: ["Never use painful force", "Stop if bruising occurs"]
        },
        {
          stepNumber: 5,
          title: "Right Corporal - Type C Strikes",
          description: "Switch to right corporal body. Perform 60 strikes with rod at same pace and force. Maintain partially to fully erect state for optimal effect.",
          duration: 180,
          tips: [
            "Same technique as left side",
            "Partially erect(d) to fully erect(f)",
            "Monitor tissue response",
            "60 strikes total"
          ],
          intensity: "high"
        },
        {
          stepNumber: 6,
          title: "Repeat Sets",
          description: "Perform 2 more sets of 60 strikes per corporal body (total 3 sets each side). Rest briefly between sets to assess tissue response.",
          duration: 600,
          tips: [
            "3 sets total per side",
            "Brief rest between sets",
            "360 total strikes for session",
            "Maintain consistent force"
          ],
          intensity: "high"
        },
        {
          stepNumber: 7,
          title: "Cool Down and Assessment",
          description: "Return to gentle hand strikes or light massage. Assess fullness and tissue condition. Notable engorgement should be present.",
          duration: 180,
          tips: [
            "Gentle hand work to finish",
            "Expect significant fullness",
            "Morning erections will be enhanced",
            "Rest 2 full days minimum"
          ],
          warnings: ["Implement work requires extra recovery time"]
        }
      ],
      timerConfig: {
        intervals: [
          { name: "Type B Warm-Up", duration: 600, type: "preparation" },
          { name: "Glans & Vascion", duration: 1200, type: "preparation" },
          { name: "Rod Acclimation", duration: 120, type: "work" },
          { name: "First Set L/R", duration: 360, type: "work" },
          { name: "Second Set L/R", duration: 360, type: "work" },
          { name: "Third Set L/R", duration: 360, type: "work" },
          { name: "Cool Down", duration: 180, type: "rest" }
        ],
        totalDuration: 3180,
        hasRest: true,
        restBetweenSets: 60
      },
      progressionCriteria: {
        minimumSessions: 15,
        consistencyDays: 30,
        keyIndicators: [
          "Comfortable with rod strikes",
          "No bruising or discomfort",
          "Enhanced morning erections",
          "Ready for Type D intensity"
        ],
        schedule: "1 day on, 2 days off"
      }
    },

    // SABRE Type D Updates
    'sabre_type_d': {
      description: "Maximum intensity SABRE using rod at 2-5 strikes per second with moderate force. Peak of Phase Four training. The ultimate expression of SABRE techniques.",
      instructionsText: "After comprehensive warm-up including Type B and Type C preparation, execute 2 sets of 60 strikes per corporal body at 2-5 per second with moderate force. Unprecedented tissue stimulation combining speed and force.",
      safetyNotes: "Only after mastering Type C. Requires exceptional control and conditioning. Extended cool down mandatory. Never on consecutive days. Stop immediately if pain occurs.",
      benefits: [
        "Maximum tissue stimulation",
        "Peak vascular development",
        "Extreme morning erections",
        "Ultimate conditioning",
        "Renders traditional PE obsolete"
      ],
      equipmentNeeded: [
        "Smooth metal rod (8-10 inch bolt, 0.5 inch diameter)",
        "Premium silicone lubricant",
        "Warm towels for aftercare",
        "Timer for precise intervals"
      ],
      creator: "Janus Bifrons",
      sabrePhilosophy: "The culmination of 16 years of vascular research. SABRE techniques render all other forms of PE obsolete.",
      hasMultipleSteps: true,
      estimatedDurationMinutes: 47,
      steps: [
        {
          stepNumber: 1,
          title: "Comprehensive Type B Warm-Up",
          description: "Full Type B session for warm-up. 10 minutes divided between corporal bodies using hand strikes at 2-5 per second, low force. Critical for Type D preparation.",
          duration: 600,
          tips: [
            "Never skip warm-up for Type D",
            "High speed, low force to start",
            "Builds necessary engorgement",
            "Primes Bayliss Effect"
          ],
          intensity: "medium"
        },
        {
          stepNumber: 2,
          title: "Glans and Vascion Circuit",
          description: "5 minutes palm glans strikes plus 15 minutes Vascion. This 20-minute preparation ensures maximum vascular dilation before high-intensity rod work.",
          duration: 1200,
          tips: [
            "Extended preparation crucial",
            "Vascion maximizes blood flow",
            "Achieve peak engorgement",
            "Mental preparation for intensity"
          ],
          intensity: "medium"
        },
        {
          stepNumber: 3,
          title: "Type C Acclimation Set",
          description: "Perform one full set of Type C strikes (60 per corporal body) at 1 per second with moderate force. This bridges to Type D intensity.",
          duration: 240,
          tips: [
            "Standard Type C execution",
            "1 strike per second",
            "Moderate force",
            "Final preparation for Type D"
          ],
          intensity: "high"
        },
        {
          stepNumber: 4,
          title: "Type D Left Corporal - Set 1",
          description: "Using rod, execute 60 strikes at 2-5 per second with moderate force. This dramatic increase in speed with maintained force creates maximum stimulation.",
          duration: 120,
          tips: [
            "2-5 strikes per second",
            "Maintain control despite speed",
            "60 strikes total",
            "Extreme focus required"
          ],
          intensity: "extreme",
          warnings: ["Maximum intensity - absolute control essential"]
        },
        {
          stepNumber: 5,
          title: "Type D Right Corporal - Set 1",
          description: "Switch to right corporal body. 60 strikes at Type D parameters. The combination of speed and force creates unprecedented tissue stimulation.",
          duration: 120,
          tips: [
            "Match left side intensity",
            "Monitor tissue response closely",
            "Stop if any pain",
            "Partially to fully erect state"
          ],
          intensity: "extreme"
        },
        {
          stepNumber: 6,
          title: "Type D Second Sets",
          description: "Perform second set of 60 strikes per corporal body at Type D parameters. Total 240 strikes at maximum intensity for the session.",
          duration: 240,
          tips: [
            "Final sets at peak intensity",
            "4 sets total (2 per side)",
            "Brief rest between if needed",
            "Unprecedented stimulation level"
          ],
          intensity: "extreme"
        },
        {
          stepNumber: 7,
          title: "Extended Cool Down",
          description: "Mandatory extended cool down with gentle hand work. Expect extreme fullness and enhanced morning erections. Minimum 2 days rest required.",
          duration: 300,
          tips: [
            "Longer cool down for Type D",
            "Gentle massage beneficial",
            "Extreme fullness expected",
            "Morning erections will be intense"
          ],
          warnings: ["Never perform Type D on consecutive days"]
        }
      ],
      timerConfig: {
        intervals: [
          { name: "Type B Full Warm-Up", duration: 600, type: "preparation" },
          { name: "Glans & Vascion", duration: 1200, type: "preparation" },
          { name: "Type C Bridge Set", duration: 240, type: "work" },
          { name: "Type D Set 1", duration: 240, type: "work" },
          { name: "Type D Set 2", duration: 240, type: "work" },
          { name: "Extended Cool Down", duration: 300, type: "rest" }
        ],
        totalDuration: 2820,
        hasRest: true,
        restBetweenSets: 60
      },
      progressionCriteria: {
        minimumSessions: 20,
        consistencyDays: 45,
        keyIndicators: [
          "Mastered all previous SABRE types",
          "No adverse tissue response",
          "Peak conditioning achieved",
          "Consider Phase 5 training"
        ],
        schedule: "1 day on, 2 days off minimum",
        notes: "Type D represents maximum achievable intensity"
      }
    }
  };

  // Update each document
  for (const [docId, updateData] of Object.entries(updates)) {
    try {
      await db.collection('growthMethods').doc(docId).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log(`Successfully updated ${docId}`);
    } catch (error) {
      console.error(`Error updating ${docId}:`, error);
    }
  }
}

// Execute the update
updateSABREMethods()
  .then(() => console.log('All SABRE methods updated successfully'))
  .catch(error => console.error('Error in update process:', error));

module.exports = { updateSABREMethods };