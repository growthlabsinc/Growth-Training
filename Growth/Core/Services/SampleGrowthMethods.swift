import Foundation

/// Provides local fallback `GrowthMethod` objects when Firestore is missing entries (dev/demo).
struct SampleGrowthMethods {
    private static let samples: [String: GrowthMethod] = {
        var dict: [String: GrowthMethod] = [:]
        // Angion Method 2.0
        dict["am2_0"] = GrowthMethod(
            id: "am2_0",
            stage: 3,
            classification: "Intermediate",
            title: "Angion Method 2.0",
            methodDescription: "Advanced vascular training focusing on arterial side manipulation.",
            instructionsText: "Obtain an erection, lightly grip the shaft and glans, alternate squeezes to force arterial flow. Maintain low pelvic floor engagement.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: [],
            estimatedDurationMinutes: 30,
            categories: ["Angion"],
            isFeatured: false
        )
        // S2S stretches (side-to-side)
        dict["s2s_stretch"] = GrowthMethod(
            id: "s2s_stretch",
            stage: 1,
            classification: "Beginner",
            title: "S2S Stretches",
            methodDescription: "Gentle side-to-side stretching to improve tissue elasticity and warm-up.",
            instructionsText: "While flaccid, grasp behind the glans and pull gently to left then right, holding each direction ~2 seconds. Repeat for 3 minutes.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: [],
            estimatedDurationMinutes: 5,
            categories: ["Stretching"],
            isFeatured: false
        )
        
        // Angion Method 1.0
        dict["angion_method_1_0"] = GrowthMethod(
            id: "angion_method_1_0",
            stage: 2,
            classification: "Foundation",
            title: "Angion Method 1.0",
            methodDescription: "Venous-focused technique to improve blood flow. Foundational vascular training.",
            instructionsText: "Obtain an erection and apply water or silicone-based lubricant along the dorsal side. Place thumbs on dorsal veins, stroke downward from glans to base alternating thumbs. Start slowly, aim to increase pace. Maintain for 20-30 minutes.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: ["Water or silicone-based lubricant"],
            estimatedDurationMinutes: 30,
            categories: ["Angion", "Foundation"],
            isFeatured: true
        )
        
        // Add alias for am1_0
        dict["am1_0"] = dict["angion_method_1_0"]!
        
        // Angion Method 2.5
        dict["angion_method_2_5"] = GrowthMethod(
            id: "angion_method_2_5",
            stage: 4,
            classification: "Intermediate",
            title: "Angion Method 2.5 (Jelq 2.0)",
            methodDescription: "Bridge technique between AM 2.0 and 3.0, focusing on Corpora Spongiosum development.",
            instructionsText: "Obtain erection, apply lubricant. Using first two fingers, depress corpora spongiosum with thumb facing down. Pull upward with partial grip focusing force on CS. Start slow, increase speed as session progresses.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: ["Water or silicone-based lubricant"],
            estimatedDurationMinutes: 30,
            categories: ["Angion", "Intermediate"],
            isFeatured: false
        )
        
        // Angion Method 3.0 (Vascion)
        dict["angion_method_3_0"] = GrowthMethod(
            id: "angion_method_3_0",
            stage: 5,
            classification: "Expert",
            title: "Angion Method 3.0 (Vascion)",
            methodDescription: "The pinnacle hand technique focusing on Corpora Spongiosum stimulation for maximum vascular development.",
            instructionsText: "Lay on back, apply liberal lubricant to CS. Using middle fingers, depress CS while stroking upward in alternating fashion. Maintain rapid alternating strokes for full session.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: ["Silicone-based lubricant (ideal)"],
            estimatedDurationMinutes: 30,
            categories: ["Angion", "Expert"],
            isFeatured: true
        )
        
        // Add alias for vascion
        dict["vascion"] = dict["angion_method_3_0"]!
        
        // BFR Cyclic Bending
        dict["bfr_cyclic_bending"] = GrowthMethod(
            id: "bfr_cyclic_bending",
            stage: 3,
            classification: "Intermediate",
            title: "BFR Cyclic Bending",
            methodDescription: "Blood Flow Restriction technique using cyclic pressure to encourage venous arterialization.",
            instructionsText: "While heavily engorged, clamp base with one hand. With other hand, take overhand grip on upper shaft. Kegel blood in, then gently bend member left/right cyclically. Release clamp every 30 seconds.",
            equipmentNeeded: [],
            estimatedDurationMinutes: 20,
            categories: ["BFR", "Pressure"],
            isFeatured: false
        )
        
        // SABRE Type A
        dict["sabre_type_a"] = GrowthMethod(
            id: "sabre_type_a",
            stage: 2,
            classification: "Foundation",
            title: "SABRE Type A - Low Speed/Low Intensity",
            methodDescription: "Foundation SABRE strikes for EQ improvement and vascular development.",
            instructionsText: "Using hand strikes at 1-3 per second with light force. Focus 10 minutes each on left corporal body, right corporal body, and glans. Work with flaccid to partially erect state.",
            equipmentNeeded: [],
            estimatedDurationMinutes: 30,
            categories: ["SABRE", "Foundation"],
            isFeatured: false
        )
        
        // SABRE Type B
        dict["sabre_type_b"] = GrowthMethod(
            id: "sabre_type_b",
            stage: 3,
            classification: "Intermediate",
            title: "SABRE Type B - Medium Speed/Medium Intensity",
            methodDescription: "Intermediate SABRE strikes with increased pace and force.",
            instructionsText: "Using hand strikes at 3-5 per second with moderate force. Focus 10 minutes each on left corporal body, right corporal body, and glans. Work with partially erect state.",
            equipmentNeeded: [],
            estimatedDurationMinutes: 30,
            categories: ["SABRE", "Intermediate"],
            isFeatured: false
        )
        
        // SABRE Type C
        dict["sabre_type_c"] = GrowthMethod(
            id: "sabre_type_c",
            stage: 4,
            classification: "Intermediate",
            title: "SABRE Type C - High Speed/Medium Intensity",
            methodDescription: "Advanced SABRE strikes focusing on speed with controlled force.",
            instructionsText: "Using hand strikes at 5-7 per second with moderate force. Focus 10 minutes each on left corporal body, right corporal body, and glans. Maintain control and precision.",
            equipmentNeeded: [],
            estimatedDurationMinutes: 30,
            categories: ["SABRE", "Intermediate"],
            isFeatured: false
        )
        
        // SABRE Type D
        dict["sabre_type_d"] = GrowthMethod(
            id: "sabre_type_d",
            stage: 5,
            classification: "Expert",
            title: "SABRE Type D - High Speed/High Intensity",
            methodDescription: "Peak SABRE technique with maximum speed and intensity. Expert level only.",
            instructionsText: "Using hand strikes at 7+ per second with high force. Focus 10 minutes each on left corporal body, right corporal body, and glans. Requires mastery of Types A-C.",
            equipmentNeeded: [],
            estimatedDurationMinutes: 30,
            categories: ["SABRE", "Expert"],
            isFeatured: false
        )
        
        // BFR Glans Pulsing
        dict["bfr_glans_pulsing"] = GrowthMethod(
            id: "bfr_glans_pulsing",
            stage: 3,
            classification: "Intermediate",
            title: "BFR Glans Pulsing",
            methodDescription: "Blood Flow Restriction technique focusing on glans expansion through pulsing pressure.",
            instructionsText: "While engorged, apply base restriction. Use thumb and fingers to pulse pressure on glans in rhythmic fashion. 2-3 pulses per second. Release restriction every 30 seconds.",
            equipmentNeeded: [],
            estimatedDurationMinutes: 20,
            categories: ["BFR", "Pressure"],
            isFeatured: false
        )
        
        // S2S Advanced
        dict["s2s_advanced"] = GrowthMethod(
            id: "s2s_advanced",
            stage: 2,
            classification: "Foundation",
            title: "S2S Advanced Stretches",
            methodDescription: "Advanced side-to-side stretching with rotation for comprehensive tissue work.",
            instructionsText: "While flaccid, grasp behind glans. Pull to left, hold 5 seconds with slight rotation. Return to center. Pull to right, hold 5 seconds with rotation. Include upward and downward angles.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: [],
            estimatedDurationMinutes: 10,
            categories: ["Stretching"],
            isFeatured: false
        )
        
        // Angio Pumping
        dict["angio_pumping"] = GrowthMethod(
            id: "angio_pumping",
            stage: 2,
            classification: "Foundation",
            title: "Angio Pumping",
            methodDescription: "Light pumping technique to enhance blood flow and prepare for more advanced methods.",
            instructionsText: "Use a vacuum pump at low pressure (3-5 inHg). Pump for 3-5 minutes, then release and massage. Repeat 3-4 times. Focus on engorgement rather than stretching.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: ["Vacuum pump", "Cylinder"],
            estimatedDurationMinutes: 20,
            categories: ["Pumping", "Foundation"],
            isFeatured: false
        )
        
        // Add common aliases
        dict["m1"] = dict["am2_0"]!  // Common method ID used in test data
        dict["m2"] = dict["s2s_stretch"]!  // Common method ID used in test data
        
        return dict
    }()

    static func method(for id: String) -> GrowthMethod? {
        samples[id]
    }
}