import Foundation

struct SampleGrowthMethods {

    private static let samples: [String: TrainingProtocol] = {
        var dict: [String: TrainingProtocol] = [:]

        // S2S Stretches
        dict["s2s_stretch"] = TrainingProtocol(
            id: "s2s_stretch",
            stage: 1,
            classification: "Foundation",
            title: "S2S Stretches",
            protocolDescription: "Side-to-Side stretches performed manually to improve flexibility and capacity.",
            instructionsText: "With a 60-80% erection, grip below the glans. Stretch penis to one side for 30 seconds, then switch. Repeat for desired duration. Can be done seated or standing.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: [],
            estimatedDurationMinutes: 15,
            categories: ["Stretching", "Foundation"],
            isFeatured: true
        )

        // S2S Advanced
        dict["s2s_advanced"] = TrainingProtocol(
            id: "s2s_advanced",
            stage: 3,
            classification: "Advanced",
            title: "Advanced S2S Stretches",
            protocolDescription: "Advanced variation of S2S stretches with increased intensity and duration.",
            instructionsText: "Similar to basic S2S but with longer hold times (45-60 seconds), greater stretch intensity, and incorporation of rotational movements. Requires good conditioning.",
            visualPlaceholderUrl: nil,
            equipmentNeeded: [],
            estimatedDurationMinutes: 20,
            categories: ["Stretching", "Advanced"],
            isFeatured: false
        )

        // BFR Cyclic Bending
        dict["bfr_cyclic_bending"] = TrainingProtocol(
            id: "bfr_cyclic_bending",
            stage: 3,
            classification: "Intermediate",
            title: "BFR Cyclic Bending",
            protocolDescription: "Blood Flow Restriction technique using cyclic pressure to encourage venous arterialization.",
            instructionsText: "While heavily engorged, clamp base with one hand. With other hand, take overhand grip on upper shaft. Kegel blood in, then gently bend member left/right cyclically. Release clamp every 30 seconds.",
            equipmentNeeded: [],
            estimatedDurationMinutes: 20,
            categories: ["BFR", "Pressure"],
            isFeatured: false
        )

        // BFR Glans Pulsing
        dict["bfr_glans_pulsing"] = TrainingProtocol(
            id: "bfr_glans_pulsing",
            stage: 3,
            classification: "Intermediate",
            title: "BFR Glans Pulsing",
            protocolDescription: "Targeted glans expansion technique using blood flow restriction.",
            instructionsText: "Achieve full erection, clamp base firmly. Use other hand to pulse squeeze the glans rhythmically. Release base grip every 20-30 seconds for circulation. Focus on controlled pressure.",
            equipmentNeeded: [],
            estimatedDurationMinutes: 15,
            categories: ["BFR", "Glans"],
            isFeatured: false
        )

        // Angio Pumping
        dict["angio_pumping"] = TrainingProtocol(
            id: "angio_pumping",
            stage: 2,
            classification: "Foundation",
            title: "Angio Pumping",
            protocolDescription: "Vacuum-based technique for promoting vascular expansion and recovery.",
            instructionsText: "Use vacuum pump at moderate pressure (5-7 HG) for 5-minute sets with 2-minute breaks. Focus on controlled, gradual pressure increase. Monitor for discoloration and adjust accordingly.",
            equipmentNeeded: ["Vacuum pump", "Cylinder", "Gauge"],
            estimatedDurationMinutes: 20,
            categories: ["Pumping", "Vascular"],
            isFeatured: true
        )

        return dict
    }()

    static func getSampleGrowthMethod(for id: String) -> TrainingProtocol? {
        return samples[id]
    }

    static func getAllSampleGrowthMethods() -> [TrainingProtocol] {
        return Array(samples.values)
    }

    static func getSampleGrowthMethods(for ids: [String]) -> [TrainingProtocol] {
        return ids.compactMap { samples[$0] }
    }

    // Helper to get methods by stage
    static func getMethodsByStage(_ stage: Int) -> [TrainingProtocol] {
        return samples.values.filter { $0.stage == stage }
    }

    // Helper to get featured methods
    static func getFeaturedMethods() -> [TrainingProtocol] {
        return samples.values.filter { $0.isFeatured }
    }
}