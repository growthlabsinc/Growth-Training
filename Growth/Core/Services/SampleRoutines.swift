import Foundation

/// Provides local fallback `Routine` objects when Firestore is missing entries (dev/demo).
struct SampleRoutines {
    private static let samples: [String: Routine] = {
        var dict: [String: Routine] = [:]

        // Standard Growth Routine (Beginner)
        dict["standard_growth_routine"] = Routine(
            id: "standard_growth_routine",
            name: "Standard Growth Routine",
            description: "A balanced weekly routine based on the 1on1off principle, focusing on growth methods for optimal development and recovery.",
            difficultyLevel: "Beginner",
            schedule: [
                DaySchedule(
                    id: "day1",
                    dayNumber: 1,
                    dayName: "Day 1: Heavy Day",
                    description: "Perform Angio Pumping plus S2S stretches and BFR techniques.",
                    methodIds: ["angio_pumping", "s2s_stretch", "bfr_cyclic_bending"],
                    isRestDay: false,
                    additionalNotes: "Keep session under 30 minutes."
                ),
                DaySchedule(
                    id: "day2",
                    dayNumber: 2,
                    dayName: "Day 2: Rest",
                    description: "Rest and recover.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "day3",
                    dayNumber: 3,
                    dayName: "Day 3: Light Day",
                    description: "Light session with S2S stretches and BFR Glans Pulsing.",
                    methodIds: ["s2s_stretch", "bfr_glans_pulsing"],
                    isRestDay: false,
                    additionalNotes: "Focus on form and controlled movements."
                ),
                DaySchedule(
                    id: "day4",
                    dayNumber: 4,
                    dayName: "Day 4: Rest",
                    description: "Rest and recover.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "day5",
                    dayNumber: 5,
                    dayName: "Day 5: Heavy Day",
                    description: "S2S stretches followed by Angio Pumping.",
                    methodIds: ["s2s_stretch", "angio_pumping"],
                    isRestDay: false,
                    additionalNotes: "Can extend session if feeling good."
                ),
                DaySchedule(
                    id: "day6",
                    dayNumber: 6,
                    dayName: "Day 6: Rest",
                    description: "Rest and recover.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "day7",
                    dayNumber: 7,
                    dayName: "Day 7: Assessment",
                    description: "Light S2S stretches to assess weekly progress.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Take measurements and photos for progress tracking."
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )

        // Beginner Express Routine
        dict["beginner_express"] = Routine(
            id: "beginner_express",
            name: "Beginner Express",
            description: "Fast-track routine for beginners who want quicker results with consistent daily practice.",
            difficultyLevel: "Beginner",
            schedule: [
                DaySchedule(
                    id: "day1",
                    dayNumber: 1,
                    dayName: "Day 1",
                    description: "S2S stretches with light pumping.",
                    methodIds: ["s2s_stretch", "angio_pumping"],
                    isRestDay: false,
                    additionalNotes: "Keep pumping pressure moderate (5-7 HG)."
                ),
                DaySchedule(
                    id: "day2",
                    dayNumber: 2,
                    dayName: "Day 2",
                    description: "Rest day - light stretching only if needed.",
                    methodIds: [],
                    isRestDay: true,
                    additionalNotes: "Focus on recovery."
                ),
                DaySchedule(
                    id: "day3",
                    dayNumber: 3,
                    dayName: "Day 3",
                    description: "BFR Cyclic Bending and S2S stretches.",
                    methodIds: ["bfr_cyclic_bending", "s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Monitor for excessive fatigue."
                ),
                DaySchedule(
                    id: "day4",
                    dayNumber: 4,
                    dayName: "Day 4",
                    description: "Rest day.",
                    methodIds: [],
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "day5",
                    dayNumber: 5,
                    dayName: "Day 5",
                    description: "Combined session with all foundation methods.",
                    methodIds: ["s2s_stretch", "angio_pumping", "bfr_glans_pulsing"],
                    isRestDay: false,
                    additionalNotes: "Extended session - take breaks as needed."
                ),
                DaySchedule(
                    id: "day6",
                    dayNumber: 6,
                    dayName: "Day 6",
                    description: "Light S2S stretches only.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Recovery focus."
                ),
                DaySchedule(
                    id: "day7",
                    dayNumber: 7,
                    dayName: "Day 7",
                    description: "Complete rest.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: "Prepare for next week."
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )

        // Advanced Intensive Routine
        dict["advanced_intensive"] = Routine(
            id: "advanced_intensive",
            name: "Advanced Intensive",
            description: "High-intensity routine for experienced practitioners seeking maximum gains.",
            difficultyLevel: "Advanced",
            schedule: [
                DaySchedule(
                    id: "day1",
                    dayNumber: 1,
                    dayName: "Day 1: Heavy Expansion",
                    description: "Advanced S2S with heavy pumping and BFR work.",
                    methodIds: ["s2s_advanced", "angio_pumping", "bfr_cyclic_bending"],
                    isRestDay: false,
                    additionalNotes: "45+ minute session. Stay hydrated."
                ),
                DaySchedule(
                    id: "day2",
                    dayNumber: 2,
                    dayName: "Day 2: Active Recovery",
                    description: "Light S2S stretches only.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "15 minutes maximum."
                ),
                DaySchedule(
                    id: "day3",
                    dayNumber: 3,
                    dayName: "Day 3: BFR Focus",
                    description: "Intensive BFR session with both techniques.",
                    methodIds: ["bfr_cyclic_bending", "bfr_glans_pulsing"],
                    isRestDay: false,
                    additionalNotes: "Monitor closely for overtraining."
                ),
                DaySchedule(
                    id: "day4",
                    dayNumber: 4,
                    dayName: "Day 4: Rest",
                    description: "Complete rest.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "day5",
                    dayNumber: 5,
                    dayName: "Day 5: Power Session",
                    description: "Full spectrum training with all advanced methods.",
                    methodIds: ["s2s_advanced", "angio_pumping", "bfr_cyclic_bending", "bfr_glans_pulsing"],
                    isRestDay: false,
                    additionalNotes: "60+ minute session. Take breaks between methods."
                ),
                DaySchedule(
                    id: "day6",
                    dayNumber: 6,
                    dayName: "Day 6: Recovery Stretches",
                    description: "Light recovery work.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Focus on flexibility, not intensity."
                ),
                DaySchedule(
                    id: "day7",
                    dayNumber: 7,
                    dayName: "Day 7: Rest",
                    description: "Complete rest and assessment.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: "Review weekly progress."
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )

        // Two Week Transformation
        dict["two_week_transformation"] = Routine(
            id: "two_week_transformation",
            name: "Two Week Transformation",
            description: "Intensive 14-day protocol for rapid initial gains.",
            difficultyLevel: "Intermediate",
            schedule: createTwoWeekSchedule(),
            createdAt: Date(),
            updatedAt: Date()
        )

        return dict
    }()

    // Helper function to create two week schedule
    private static func createTwoWeekSchedule() -> [DaySchedule] {
        var schedule: [DaySchedule] = []

        // Week 1
        for day in 1...7 {
            if day % 2 == 1 { // Odd days - training
                schedule.append(DaySchedule(
                    id: "day\(day)",
                    dayNumber: day,
                    dayName: "Day \(day): Training",
                    description: "Progressive intensity training.",
                    methodIds: ["s2s_stretch", "angio_pumping", day > 3 ? "bfr_cyclic_bending" : nil].compactMap { $0 },
                    isRestDay: false,
                    additionalNotes: "Week 1 - Building foundation."
                ))
            } else { // Even days - rest
                schedule.append(DaySchedule(
                    id: "day\(day)",
                    dayNumber: day,
                    dayName: "Day \(day): Rest",
                    description: "Recovery day.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ))
            }
        }

        // Week 2
        for day in 8...14 {
            if day == 14 { // Final assessment day
                schedule.append(DaySchedule(
                    id: "day\(day)",
                    dayNumber: day,
                    dayName: "Day \(day): Final Assessment",
                    description: "Light work and progress evaluation.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Take final measurements and photos."
                ))
            } else if day % 2 == 0 { // Even days - training in week 2
                schedule.append(DaySchedule(
                    id: "day\(day)",
                    dayNumber: day,
                    dayName: "Day \(day): Intensive",
                    description: "High intensity training.",
                    methodIds: ["s2s_advanced", "angio_pumping", "bfr_cyclic_bending", "bfr_glans_pulsing"],
                    isRestDay: false,
                    additionalNotes: "Week 2 - Maximum intensity."
                ))
            } else { // Odd days - active recovery in week 2
                schedule.append(DaySchedule(
                    id: "day\(day)",
                    dayNumber: day,
                    dayName: "Day \(day): Active Recovery",
                    description: "Light stretching.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Keep it light."
                ))
            }
        }

        return schedule
    }

    // MARK: - Public Access Methods

    static func getSampleRoutine(for id: String) -> Routine? {
        return samples[id]
    }

    static func getAllSampleRoutines() -> [Routine] {
        return Array(samples.values)
    }

    static func getRoutinesByDifficulty(_ difficulty: String) -> [Routine] {
        return samples.values.filter { $0.difficultyLevel == difficulty }
    }

    static func getFeaturedRoutines() -> [Routine] {
        // Return a curated list of featured routines
        return ["standard_growth_routine", "beginner_express", "advanced_intensive"]
            .compactMap { samples[$0] }
    }
}