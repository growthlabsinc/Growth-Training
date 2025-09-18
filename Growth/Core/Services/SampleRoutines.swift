import Foundation

/// Provides local fallback `Routine` objects when Firestore is missing entries (dev/demo).
struct SampleRoutines {
    private static let samples: [String: Routine] = {
        var dict: [String: Routine] = [:]
        
        // Standard Growth Routine (Beginner)
        dict["standard_growth_routine"] = Routine(
            id: "standard_growth_routine",
            name: "Standard Growth Routine",
            description: "A balanced weekly routine based on the 1on1off principle, focusing on Angion Methods for optimal vascular development and recovery.",
            difficultyLevel: "Beginner",
            schedule: [
                DaySchedule(
                    id: "day1",
                    dayNumber: 1,
                    dayName: "Day 1: Heavy Day",
                    description: "Perform Angio Pumping or Angion Method 1.0/2.0, plus optional pumping and S2S stretches.",
                    methodIds: ["angio_pumping", "am1_0", "am2_0"],
                    isRestDay: false,
                    additionalNotes: "Keep session under 30 minutes."
                ),
                DaySchedule(
                    id: "day2",
                    dayNumber: 2,
                    dayName: "Day 2: Rest",
                    description: "Rest and recover. Focus on hydration, gentle stretching, and quality sleep to support your body's recovery process.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "day3",
                    dayNumber: 3,
                    dayName: "Day 3: Moderate Day",
                    description: "Angion Method 2.0 and S2S stretches. Optional light pumping.",
                    methodIds: ["am2_0", "s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Focus on form over intensity."
                ),
                DaySchedule(
                    id: "day4",
                    dayNumber: 4,
                    dayName: "Day 4: Rest",
                    description: "Rest and recover. Prioritize nutrition and mindful eating to fuel your body's recovery and growth.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "day5",
                    dayNumber: 5,
                    dayName: "Day 5: Light Day",
                    description: "S2S stretches and optional light Angion work.",
                    methodIds: ["s2s_stretch", "am1_0"],
                    isRestDay: false,
                    additionalNotes: "Keep it light, focus on recovery."
                ),
                DaySchedule(
                    id: "day6",
                    dayNumber: 6,
                    dayName: "Day 6: Rest",
                    description: "Rest and recover. Focus on vascular health and circulation through gentle movement and deep breathing.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "day7",
                    dayNumber: 7,
                    dayName: "Day 7: Active Recovery",
                    description: "Light stretching or complete rest based on how you feel.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Optional - can take as rest day if needed."
                )
            ],
            createdAt: Date(),
            updatedAt: Date(),
            startDate: nil
        )
        
        // Beginner Express (5 days)
        dict["beginner_express"] = Routine(
            id: "beginner_express",
            name: "Beginner Express",
            description: "A shorter 5-day introduction routine for those new to the practice. Perfect for building consistency and learning proper form.",
            difficultyLevel: "Beginner",
            schedule: [
                DaySchedule(
                    id: "be_day1",
                    dayNumber: 1,
                    dayName: "Day 1: Introduction",
                    description: "Start with basic Angion Method 1.0 to learn the fundamentals.",
                    methodIds: ["am1_0"],
                    isRestDay: false,
                    additionalNotes: "Focus on technique, not intensity. 15-20 minutes max."
                ),
                DaySchedule(
                    id: "be_day2",
                    dayNumber: 2,
                    dayName: "Day 2: Rest",
                    description: "Rest and recover. Stay hydrated throughout the day and prioritize quality sleep for optimal recovery.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: "Track your water intake and aim for 8+ hours of sleep."
                ),
                DaySchedule(
                    id: "be_day3",
                    dayNumber: 3,
                    dayName: "Day 3: Stretching Focus",
                    description: "Introduction to S2S stretches with light AM1.0.",
                    methodIds: ["s2s_stretch", "am1_0"],
                    isRestDay: false,
                    additionalNotes: "Gentle stretching, no forcing."
                ),
                DaySchedule(
                    id: "be_day4",
                    dayNumber: 4,
                    dayName: "Day 4: Rest",
                    description: "Rest and recover.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "be_day5",
                    dayNumber: 5,
                    dayName: "Day 5: Assessment",
                    description: "Light session to assess progress and comfort level.",
                    methodIds: ["am1_0"],
                    isRestDay: false,
                    additionalNotes: "Note any improvements in technique or comfort."
                )
            ],
            createdAt: Date(),
            updatedAt: Date(),
            startDate: nil
        )
        
        // Intermediate Progressive
        dict["intermediate_progressive"] = Routine(
            id: "intermediate_progressive",
            name: "Intermediate Progressive",
            description: "A progressive routine for those ready to advance beyond basics. Introduces AM2.5 and more structured training.",
            difficultyLevel: "Intermediate",
            schedule: [
                DaySchedule(
                    id: "ip_day1",
                    dayNumber: 1,
                    dayName: "Day 1: Power Day",
                    description: "Advanced Angion Methods with focus on intensity.",
                    methodIds: ["am2_0", "am2_5", "angio_pumping"],
                    isRestDay: false,
                    additionalNotes: "30-40 minute session. Monitor fatigue."
                ),
                DaySchedule(
                    id: "ip_day2",
                    dayNumber: 2,
                    dayName: "Day 2: Active Recovery",
                    description: "Light stretching and mobility work.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Keep it light, focus on recovery."
                ),
                DaySchedule(
                    id: "ip_day3",
                    dayNumber: 3,
                    dayName: "Day 3: Rest",
                    description: "Complete rest day. Focus on nutrition and meal planning to support your training goals.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: "Plan healthy meals rich in nutrients that support recovery."
                ),
                DaySchedule(
                    id: "ip_day4",
                    dayNumber: 4,
                    dayName: "Day 4: Technique Day",
                    description: "Focus on perfecting AM2.5 technique.",
                    methodIds: ["am2_5", "am2_0"],
                    isRestDay: false,
                    additionalNotes: "Quality over quantity. Perfect form."
                ),
                DaySchedule(
                    id: "ip_day5",
                    dayNumber: 5,
                    dayName: "Day 5: Rest",
                    description: "Rest and recover.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "ip_day6",
                    dayNumber: 6,
                    dayName: "Day 6: Endurance",
                    description: "Longer session focusing on endurance.",
                    methodIds: ["am2_0", "s2s_stretch", "angio_pumping"],
                    isRestDay: false,
                    additionalNotes: "40-45 minutes. Pace yourself."
                ),
                DaySchedule(
                    id: "ip_day7",
                    dayNumber: 7,
                    dayName: "Day 7: Rest",
                    description: "Complete rest to prepare for next week.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: "Assess weekly progress."
                )
            ],
            createdAt: Date(),
            updatedAt: Date(),
            startDate: nil
        )
        
        // Advanced Intensive
        dict["advanced_intensive"] = Routine(
            id: "advanced_intensive",
            name: "Advanced Intensive",
            description: "High-intensity routine for experienced practitioners. Requires excellent technique and recovery capacity.",
            difficultyLevel: "Advanced",
            schedule: [
                DaySchedule(
                    id: "ai_day1",
                    dayNumber: 1,
                    dayName: "Day 1: Maximum Intensity",
                    description: "Full spectrum training with all advanced methods.",
                    methodIds: ["am2_5", "am3_0", "angio_pumping", "s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "45-60 minutes. Full intensity."
                ),
                DaySchedule(
                    id: "ai_day2",
                    dayNumber: 2,
                    dayName: "Day 2: Recovery Methods",
                    description: "Active recovery with light methods.",
                    methodIds: ["am1_0", "s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "20-30 minutes. Focus on blood flow."
                ),
                DaySchedule(
                    id: "ai_day3",
                    dayNumber: 3,
                    dayName: "Day 3: Power Focus",
                    description: "High-intensity Angion Method 3.0 focus.",
                    methodIds: ["am3_0", "am2_5"],
                    isRestDay: false,
                    additionalNotes: "35-45 minutes. Maximum effort."
                ),
                DaySchedule(
                    id: "ai_day4",
                    dayNumber: 4,
                    dayName: "Day 4: Rest",
                    description: "Complete rest for recovery.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: "Critical recovery day."
                ),
                DaySchedule(
                    id: "ai_day5",
                    dayNumber: 5,
                    dayName: "Day 5: Endurance Challenge",
                    description: "Extended session for endurance building.",
                    methodIds: ["am2_5", "am2_0", "angio_pumping", "s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "60+ minutes. Pace strategically."
                ),
                DaySchedule(
                    id: "ai_day6",
                    dayNumber: 6,
                    dayName: "Day 6: Rest",
                    description: "Rest and assess weekly progress.",
                    methodIds: nil,
                    isRestDay: true,
                    additionalNotes: nil
                ),
                DaySchedule(
                    id: "ai_day7",
                    dayNumber: 7,
                    dayName: "Day 7: Optional Session",
                    description: "Optional light session or complete rest.",
                    methodIds: ["s2s_stretch"],
                    isRestDay: false,
                    additionalNotes: "Listen to your body."
                )
            ],
            createdAt: Date(),
            updatedAt: Date(),
            startDate: nil
        )
        
        // Two Week Transformation
        dict["two_week_transformation"] = Routine(
            id: "two_week_transformation",
            name: "Two Week Transformation",
            description: "An intensive 14-day program designed to kickstart your journey with progressive overload and strategic recovery.",
            difficultyLevel: "Intermediate",
            schedule: createTwoWeekSchedule(),
            createdAt: Date(),
            updatedAt: Date(),
            startDate: nil
        )
        
        // Janus Protocol - 12 Week Advanced (Firebase fallback)
        dict["janus_protocol_12week"] = Routine(
            id: "janus_protocol_12week",
            name: "Janus Protocol - 84 Day Advanced",
            description: "The complete 84-day (12-week) advanced routine based on the original Janus Protocol. Features a 4-week rotating pattern with 3 full cycles, incorporating Angion Methods (15 min), SABRE techniques (10 min), and BFR training (15 min) with strategic recovery weeks.",
            difficultyLevel: "Advanced",
            schedule: createJanusProtocolSchedule(),
            createdAt: Date(),
            updatedAt: Date(),
            startDate: nil
        )
        
        return dict
    }()
    
    static func routine(for id: String) -> Routine? {
        samples[id]
    }
    
    static var standardRoutine: Routine? {
        samples["standard_growth_routine"]
    }
    
    static var allRoutines: [Routine] {
        Array(samples.values).sorted { $0.createdAt < $1.createdAt }
    }
    
    // Helper to create full 84-day Janus Protocol schedule
    private static func createJanusProtocolSchedule() -> [DaySchedule] {
        var schedule: [DaySchedule] = []
        
        // The Janus Protocol follows a 4-week rotating pattern
        // Week 1 Pattern: Mon(Heavy), Tue(Rest), Wed(Angion), Thu(SABRE/BFR), Fri(Angion), Sat(Rest), Sun(Heavy)
        // Week 2 Pattern: Mon(Rest), Tue(Angion), Wed(SABRE/BFR), Thu(Angion), Fri(Rest), Sat(Heavy), Sun(Rest)
        // Week 3 Pattern: Mon(Angion), Tue(SABRE/BFR), Wed(Angion), Thu(Rest), Fri(Heavy), Sat(Rest), Sun(Angion)
        // Week 4 Pattern: Mon(Rest), Tue(Rest), Wed(Rest), Thu(Rest), Fri(Rest), Sat(Rest), Sun(Rest) - Recovery week
        
        // Method IDs for Janus Protocol
        let sabreMethods = ["sabre_type_a", "sabre_type_b", "sabre_type_c", "sabre_type_d"] // All 4 SABRE variations
        let bfrMethods = ["bfr_cyclic_bending", "bfr_glans_pulsing"]
        
        // Helper function to get Angion methods based on progression
        func getAngionMethods(cycle: Int, week: Int) -> [String] {
            // Progressive Angion difficulty:
            // Early cycle 1: AM1
            // Mid cycle 1: AM2
            // Late cycle 1/Early cycle 2: AM1 & AM2
            // Mid cycle 2: AM3
            // Late cycle 2/Early cycle 3: AM1 & AM2 & AM3
            // Late cycle 3: AM2 & AM3
            
            let dayNumber = cycle * 28 + (week - 1) * 7 + 1
            
            if dayNumber <= 14 {
                return ["am1_0"] // First 2 weeks: AM1 only
            } else if dayNumber <= 21 {
                return ["am2_0"] // Week 3: AM2 only
            } else if dayNumber <= 35 {
                return ["am1_0", "am2_0"] // Weeks 4-5: AM1 & AM2
            } else if dayNumber <= 42 {
                return ["am3_0"] // Week 6: AM3 only
            } else if dayNumber <= 56 {
                return ["am1_0", "am2_0", "am3_0"] // Weeks 7-8: All three
            } else {
                return ["am2_0", "am3_0"] // Weeks 9+: AM2 & AM3
            }
        }
        
        // Helper function to get SABRE method based on cycle and week
        func getSabreMethod(cycle: Int, week: Int) -> String {
            // Progressive SABRE difficulty:
            // Cycle 1: Type A (weeks 1-2), Type B (week 3)
            // Cycle 2: Type B (weeks 1-2), Type C (week 3)
            // Cycle 3: Type C (weeks 1-2), Type D (week 3)
            if cycle == 0 {
                return week < 3 ? sabreMethods[0] : sabreMethods[1] // A -> B
            } else if cycle == 1 {
                return week < 3 ? sabreMethods[1] : sabreMethods[2] // B -> C
            } else {
                return week < 3 ? sabreMethods[2] : sabreMethods[3] // C -> D
            }
        }
        
        // Helper function to get BFR method - alternates between cycles
        func getBFRMethod(cycle: Int, isHeavyDay: Bool) -> String {
            // Cycle through both BFR methods
            // Heavy days emphasize cyclic bending, other days use glans pulsing
            if isHeavyDay {
                return bfrMethods[0] // Cyclic bending for heavy days
            } else {
                return bfrMethods[1] // Glans pulsing for other days
            }
        }
        
        // Create 3 cycles of the 4-week pattern (12 weeks total = 84 days)
        for cycle in 0..<3 {
            let cycleOffset = cycle * 28
            
            // Week 1 of cycle
            schedule.append(contentsOf: [
                DaySchedule(id: "jp_c\(cycle+1)_w1d1", dayNumber: cycleOffset + 1, 
                           dayName: "Cycle \(cycle+1) Week 1 Day 1: Heavy Day",
                           description: "Angion Methods (15 min) + SABRE (10 min) + BFR (15 min)",
                           methodIds: getAngionMethods(cycle: cycle, week: 1) + [getSabreMethod(cycle: cycle, week: 1), getBFRMethod(cycle: cycle, isHeavyDay: true)],
                           isRestDay: false, 
                           additionalNotes: "Full 40-minute session. Monitor fatigue levels."),
                
                DaySchedule(id: "jp_c\(cycle+1)_w1d2", dayNumber: cycleOffset + 2, 
                           dayName: "Cycle \(cycle+1) Week 1 Day 2: Rest",
                           description: "Complete rest day for recovery",
                           methodIds: nil, isRestDay: true, additionalNotes: "Focus on hydration and nutrition"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w1d3", dayNumber: cycleOffset + 3, 
                           dayName: "Cycle \(cycle+1) Week 1 Day 3: Angion Focus",
                           description: "Angion Methods only (15 minutes)",
                           methodIds: getAngionMethods(cycle: cycle, week: 1), 
                           isRestDay: false, 
                           additionalNotes: "Focus on perfect technique"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w1d4", dayNumber: cycleOffset + 4, 
                           dayName: "Cycle \(cycle+1) Week 1 Day 4: SABRE/BFR",
                           description: "SABRE (10 min) + BFR (15 min)",
                           methodIds: [getSabreMethod(cycle: cycle, week: 1), getBFRMethod(cycle: cycle, isHeavyDay: false)], 
                           isRestDay: false, 
                           additionalNotes: "25-minute combined session"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w1d5", dayNumber: cycleOffset + 5, 
                           dayName: "Cycle \(cycle+1) Week 1 Day 5: Angion Focus",
                           description: "Angion Methods only (15 minutes)",
                           methodIds: getAngionMethods(cycle: cycle, week: 1), 
                           isRestDay: false, 
                           additionalNotes: "Maintain consistent technique"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w1d6", dayNumber: cycleOffset + 6, 
                           dayName: "Cycle \(cycle+1) Week 1 Day 6: Rest",
                           description: "Complete rest day",
                           methodIds: nil, isRestDay: true, additionalNotes: nil),
                
                DaySchedule(id: "jp_c\(cycle+1)_w1d7", dayNumber: cycleOffset + 7, 
                           dayName: "Cycle \(cycle+1) Week 1 Day 7: Heavy Day",
                           description: "Angion Methods (15 min) + SABRE (10 min) + BFR (15 min)",
                           methodIds: getAngionMethods(cycle: cycle, week: 1) + [getSabreMethod(cycle: cycle, week: 1), getBFRMethod(cycle: cycle, isHeavyDay: true)],
                           isRestDay: false, 
                           additionalNotes: "End week strong with full session")
            ])
            
            // Week 2 of cycle
            schedule.append(contentsOf: [
                DaySchedule(id: "jp_c\(cycle+1)_w2d1", dayNumber: cycleOffset + 8, 
                           dayName: "Cycle \(cycle+1) Week 2 Day 1: Rest",
                           description: "Complete rest day",
                           methodIds: nil, isRestDay: true, additionalNotes: "Start week with recovery"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w2d2", dayNumber: cycleOffset + 9, 
                           dayName: "Cycle \(cycle+1) Week 2 Day 2: Angion Focus",
                           description: "Angion Methods only (15 minutes)",
                           methodIds: getAngionMethods(cycle: cycle, week: 2), 
                           isRestDay: false, 
                           additionalNotes: nil),
                
                DaySchedule(id: "jp_c\(cycle+1)_w2d3", dayNumber: cycleOffset + 10, 
                           dayName: "Cycle \(cycle+1) Week 2 Day 3: SABRE/BFR",
                           description: "SABRE (10 min) + BFR (15 min)",
                           methodIds: [getSabreMethod(cycle: cycle, week: 2), getBFRMethod(cycle: cycle, isHeavyDay: false)], 
                           isRestDay: false, 
                           additionalNotes: nil),
                
                DaySchedule(id: "jp_c\(cycle+1)_w2d4", dayNumber: cycleOffset + 11, 
                           dayName: "Cycle \(cycle+1) Week 2 Day 4: Angion Focus",
                           description: "Angion Methods only (15 minutes)",
                           methodIds: getAngionMethods(cycle: cycle, week: 2), 
                           isRestDay: false, 
                           additionalNotes: nil),
                
                DaySchedule(id: "jp_c\(cycle+1)_w2d5", dayNumber: cycleOffset + 12, 
                           dayName: "Cycle \(cycle+1) Week 2 Day 5: Rest",
                           description: "Complete rest day",
                           methodIds: nil, isRestDay: true, additionalNotes: nil),
                
                DaySchedule(id: "jp_c\(cycle+1)_w2d6", dayNumber: cycleOffset + 13, 
                           dayName: "Cycle \(cycle+1) Week 2 Day 6: Heavy Day",
                           description: "Angion Methods (15 min) + SABRE (10 min) + BFR (15 min)",
                           methodIds: getAngionMethods(cycle: cycle, week: 2) + [getSabreMethod(cycle: cycle, week: 2), getBFRMethod(cycle: cycle, isHeavyDay: true)],
                           isRestDay: false, 
                           additionalNotes: "Peak session of the week"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w2d7", dayNumber: cycleOffset + 14, 
                           dayName: "Cycle \(cycle+1) Week 2 Day 7: Rest",
                           description: "Complete rest day",
                           methodIds: nil, isRestDay: true, additionalNotes: "Prepare for week 3")
            ])
            
            // Week 3 of cycle
            schedule.append(contentsOf: [
                DaySchedule(id: "jp_c\(cycle+1)_w3d1", dayNumber: cycleOffset + 15, 
                           dayName: "Cycle \(cycle+1) Week 3 Day 1: Angion Focus",
                           description: "Angion Methods only (15 minutes)",
                           methodIds: getAngionMethods(cycle: cycle, week: 3), 
                           isRestDay: false, 
                           additionalNotes: "Start week with focused work"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w3d2", dayNumber: cycleOffset + 16, 
                           dayName: "Cycle \(cycle+1) Week 3 Day 2: SABRE/BFR",
                           description: "SABRE (10 min) + BFR (15 min)",
                           methodIds: [getSabreMethod(cycle: cycle, week: 3), getBFRMethod(cycle: cycle, isHeavyDay: false)], 
                           isRestDay: false, 
                           additionalNotes: "Progress in difficulty this week"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w3d3", dayNumber: cycleOffset + 17, 
                           dayName: "Cycle \(cycle+1) Week 3 Day 3: Angion Focus",
                           description: "Angion Methods only (15 minutes)",
                           methodIds: getAngionMethods(cycle: cycle, week: 3), 
                           isRestDay: false, 
                           additionalNotes: "Mid-week consistency"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w3d4", dayNumber: cycleOffset + 18, 
                           dayName: "Cycle \(cycle+1) Week 3 Day 4: Rest",
                           description: "Complete rest day",
                           methodIds: nil, isRestDay: true, 
                           additionalNotes: "Critical mid-week recovery"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w3d5", dayNumber: cycleOffset + 19, 
                           dayName: "Cycle \(cycle+1) Week 3 Day 5: Heavy Day",
                           description: "Angion Methods (15 min) + SABRE (10 min) + BFR (15 min)",
                           methodIds: getAngionMethods(cycle: cycle, week: 3) + [getSabreMethod(cycle: cycle, week: 3), getBFRMethod(cycle: cycle, isHeavyDay: true)],
                           isRestDay: false, 
                           additionalNotes: "Last heavy session before recovery week"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w3d6", dayNumber: cycleOffset + 20, 
                           dayName: "Cycle \(cycle+1) Week 3 Day 6: Rest",
                           description: "Complete rest day",
                           methodIds: nil, isRestDay: true, additionalNotes: nil),
                
                DaySchedule(id: "jp_c\(cycle+1)_w3d7", dayNumber: cycleOffset + 21, 
                           dayName: "Cycle \(cycle+1) Week 3 Day 7: Angion Focus",
                           description: "Angion Methods only (15 minutes)",
                           methodIds: getAngionMethods(cycle: cycle, week: 3), 
                           isRestDay: false, 
                           additionalNotes: "Light session before recovery week")
            ])
            
            // Week 4 of cycle - Recovery Week
            let recoveryWeekNote = cycle == 2 ? 
                "Final recovery week. Assess progress and prepare for next phase." : 
                "Full recovery week. Light activity and stretching only."
            
            schedule.append(contentsOf: [
                DaySchedule(id: "jp_c\(cycle+1)_w4d1", dayNumber: cycleOffset + 22, 
                           dayName: "Cycle \(cycle+1) Week 4 Day 1: Recovery",
                           description: "Complete rest - recovery week begins",
                           methodIds: nil, isRestDay: true, 
                           additionalNotes: recoveryWeekNote),
                
                DaySchedule(id: "jp_c\(cycle+1)_w4d2", dayNumber: cycleOffset + 23, 
                           dayName: "Cycle \(cycle+1) Week 4 Day 2: Recovery",
                           description: "Complete rest - focus on nutrition",
                           methodIds: nil, isRestDay: true, 
                           additionalNotes: "Increase protein intake"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w4d3", dayNumber: cycleOffset + 24, 
                           dayName: "Cycle \(cycle+1) Week 4 Day 3: Recovery",
                           description: "Complete rest - gentle stretching allowed",
                           methodIds: nil, isRestDay: true, 
                           additionalNotes: "Light mobility work only"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w4d4", dayNumber: cycleOffset + 25, 
                           dayName: "Cycle \(cycle+1) Week 4 Day 4: Recovery",
                           description: "Complete rest - mid-recovery week",
                           methodIds: nil, isRestDay: true, 
                           additionalNotes: "Continue focus on recovery"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w4d5", dayNumber: cycleOffset + 26, 
                           dayName: "Cycle \(cycle+1) Week 4 Day 5: Recovery",
                           description: "Complete rest - assess recovery",
                           methodIds: nil, isRestDay: true, 
                           additionalNotes: "Note any improvements in EQ"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w4d6", dayNumber: cycleOffset + 27, 
                           dayName: "Cycle \(cycle+1) Week 4 Day 6: Recovery",
                           description: "Complete rest - prepare for next cycle",
                           methodIds: nil, isRestDay: true, 
                           additionalNotes: cycle == 2 ? "Nearly complete!" : "Prepare for next cycle"),
                
                DaySchedule(id: "jp_c\(cycle+1)_w4d7", dayNumber: cycleOffset + 28, 
                           dayName: "Cycle \(cycle+1) Week 4 Day 7: Recovery",
                           description: "Complete rest - end of recovery week",
                           methodIds: nil, isRestDay: true, 
                           additionalNotes: cycle == 2 ? "Congratulations on completing 84 days!" : "Ready for cycle \(cycle+2)")
            ])
        }
        
        return schedule
    }
    
    // Helper to create 14-day schedule
    private static func createTwoWeekSchedule() -> [DaySchedule] {
        return [
            // Week 1
            DaySchedule(id: "tw_day1", dayNumber: 1, dayName: "Week 1, Day 1: Foundation", 
                       description: "Establish baseline with core methods.", 
                       methodIds: ["am1_0", "s2s_stretch"], isRestDay: false,
                       additionalNotes: "Start conservative, focus on form."),
            DaySchedule(id: "tw_day2", dayNumber: 2, dayName: "Week 1, Day 2: Rest", 
                       description: "Rest and recover.", methodIds: nil, isRestDay: true, additionalNotes: nil),
            DaySchedule(id: "tw_day3", dayNumber: 3, dayName: "Week 1, Day 3: Progress", 
                       description: "Introduce AM2.0 with stretching.", 
                       methodIds: ["am2_0", "s2s_stretch"], isRestDay: false,
                       additionalNotes: "Note differences from Day 1."),
            DaySchedule(id: "tw_day4", dayNumber: 4, dayName: "Week 1, Day 4: Rest", 
                       description: "Rest and recover.", methodIds: nil, isRestDay: true, additionalNotes: nil),
            DaySchedule(id: "tw_day5", dayNumber: 5, dayName: "Week 1, Day 5: Integration", 
                       description: "Combine methods learned so far.", 
                       methodIds: ["am1_0", "am2_0", "angio_pumping"], isRestDay: false,
                       additionalNotes: "30 minute session max."),
            DaySchedule(id: "tw_day6", dayNumber: 6, dayName: "Week 1, Day 6: Active Recovery", 
                       description: "Light stretching only.", 
                       methodIds: ["s2s_stretch"], isRestDay: false,
                       additionalNotes: "Keep it very light."),
            DaySchedule(id: "tw_day7", dayNumber: 7, dayName: "Week 1, Day 7: Rest", 
                       description: "Complete rest before Week 2.", methodIds: nil, isRestDay: true,
                       additionalNotes: "Prepare for next week."),
            // Week 2
            DaySchedule(id: "tw_day8", dayNumber: 8, dayName: "Week 2, Day 1: Advancement", 
                       description: "Introduce AM2.5 if ready.", 
                       methodIds: ["am2_0", "am2_5", "angio_pumping"], isRestDay: false,
                       additionalNotes: "Only add AM2.5 if comfortable."),
            DaySchedule(id: "tw_day9", dayNumber: 9, dayName: "Week 2, Day 2: Rest", 
                       description: "Rest and recover.", methodIds: nil, isRestDay: true, additionalNotes: nil),
            DaySchedule(id: "tw_day10", dayNumber: 10, dayName: "Week 2, Day 3: Intensity", 
                       description: "Higher intensity session.", 
                       methodIds: ["am2_5", "am2_0", "s2s_stretch"], isRestDay: false,
                       additionalNotes: "Push harder but maintain form."),
            DaySchedule(id: "tw_day11", dayNumber: 11, dayName: "Week 2, Day 4: Recovery", 
                       description: "Active recovery day.", 
                       methodIds: ["am1_0", "s2s_stretch"], isRestDay: false,
                       additionalNotes: "Light session only."),
            DaySchedule(id: "tw_day12", dayNumber: 12, dayName: "Week 2, Day 5: Peak", 
                       description: "Peak performance day.", 
                       methodIds: ["am2_5", "angio_pumping", "s2s_stretch"], isRestDay: false,
                       additionalNotes: "Best effort of the program."),
            DaySchedule(id: "tw_day13", dayNumber: 13, dayName: "Week 2, Day 6: Rest", 
                       description: "Rest before final assessment.", methodIds: nil, isRestDay: true, additionalNotes: nil),
            DaySchedule(id: "tw_day14", dayNumber: 14, dayName: "Week 2, Day 7: Assessment", 
                       description: "Final session to assess progress.", 
                       methodIds: ["am2_0", "s2s_stretch"], isRestDay: false,
                       additionalNotes: "Compare to Week 1 performance.")
        ]
    }
}