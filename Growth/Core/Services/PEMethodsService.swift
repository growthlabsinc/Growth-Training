//
//  PEMethodsService.swift
//  Growth
//
//  Created for PE Methods Integration
//

import Foundation

/// Service for providing PE (Penis Enlargement) exercise methods
class PEMethodsService {

    static let shared = PEMethodsService()

    private init() {}

    /// Returns all PE methods organized by category
    func getAllPEMethods() -> [GrowthMethod] {
        return lengthMethods + girthMethods + eqMethods + staminaMethods
    }

    /// PE Length Methods
    private var lengthMethods: [GrowthMethod] {
        return [
            GrowthMethod(
                id: "basic_stretch",
                stage: 1,
                classification: "Beginner",
                title: "Basic Manual Stretch",
                methodDescription: "The fundamental length exercise using manual traction to promote tissue elongation.",
                instructionsText: """
                1. Ensure completely flaccid state
                2. Grip firmly behind the glans (head) with OK grip
                3. Pull straight out with moderate tension (should feel stretch, not pain)
                4. Hold for 30 seconds
                5. Release and massage for 30 seconds
                6. Repeat in different directions (up, down, left, right)
                7. Total session: 5-10 minutes
                """,
                equipmentNeeded: [],
                estimatedDurationMinutes: 10,
                categories: ["Length", "Beginner"],
                isFeatured: true,
                safetyNotes: "Never grip the glans directly. Stop if numbness or tingling occurs.",
                benefits: ["Improves length", "Foundation exercise", "No equipment needed"],
                timerConfig: TimerConfiguration(
                    recommendedDurationSeconds: 30,
                    isCountdown: false,
                    hasIntervals: true,
                    intervals: [
                        MethodInterval(name: "Stretch", durationSeconds: 30),
                        MethodInterval(name: "Rest", durationSeconds: 30)
                    ]
                )
            ),

            GrowthMethod(
                id: "extender_length",
                stage: 2,
                classification: "Intermediate",
                title: "Penis Extender Protocol",
                methodDescription: "Traction device usage for consistent length gains.",
                instructionsText: """
                1. Secure base ring behind glans
                2. Attach to extender cradle or noose
                3. Adjust bars to comfortable stretch
                4. Start with 1-2 hours daily
                5. Build up to 4-6 hours over weeks
                6. Take breaks every hour
                7. Increase tension gradually (weekly)
                8. Track measurements monthly
                """,
                equipmentNeeded: ["Penis extender device"],
                estimatedDurationMinutes: 240,
                categories: ["Length", "Intermediate"],
                isFeatured: false,
                safetyNotes: "Start with minimal tension. Never sleep with device on.",
                benefits: ["Consistent length gains", "Hands-free", "Proven results"]
            ),

            GrowthMethod(
                id: "hanging_weight",
                stage: 3,
                classification: "Advanced",
                title: "Weight Hanging",
                methodDescription: "Gravitational traction using weights for length development.",
                instructionsText: """
                1. Attach hanger behind glans (vacuum or compression)
                2. Start with 2.5-5 lbs maximum
                3. Hang for 20 minutes per set
                4. Rest 10 minutes between sets
                5. Perform 2-3 sets per session
                6. Increase weight by 1-2 lbs monthly
                7. Always warm up first
                8. Use rice sock heating between sets
                """,
                equipmentNeeded: ["Hanger device", "Weights", "Rice sock"],
                estimatedDurationMinutes: 90,
                categories: ["Length", "Advanced"],
                isFeatured: false,
                safetyNotes: "ADVANCED - high injury potential. Never exceed comfortable weight.",
                benefits: ["Maximum length gains", "Progressive overload", "Time-efficient"],
                timerConfig: TimerConfiguration(
                    recommendedDurationSeconds: 1200,
                    isCountdown: true,
                    hasIntervals: false
                )
            )
        ]
    }

    /// PE Girth Methods
    private var girthMethods: [GrowthMethod] {
        return [
            GrowthMethod(
                id: "wet_jelq",
                stage: 1,
                classification: "Beginner",
                title: "Wet Jelq",
                methodDescription: "Classic girth exercise using lubrication for controlled blood flow manipulation.",
                instructionsText: """
                1. Apply water-based lubricant generously
                2. Achieve 40-60% erection level
                3. Form OK grip at base of shaft
                4. Slowly slide grip toward glans (3-4 seconds)
                5. Stop before reaching glans
                6. Release and repeat with alternating hands
                7. Maintain consistent pressure throughout stroke
                8. Session: 50-100 strokes initially, build up gradually
                """,
                equipmentNeeded: ["Lubricant"],
                estimatedDurationMinutes: 15,
                categories: ["Girth", "Beginner"],
                isFeatured: true,
                safetyNotes: "Never jelq at 100% erection. Stop if bruising appears.",
                benefits: ["Girth development", "Improved blood flow", "Foundation exercise"],
                timerConfig: TimerConfiguration(
                    recommendedDurationSeconds: 4,
                    isCountdown: false,
                    hasIntervals: false
                )
            ),

            GrowthMethod(
                id: "bathmate_pump",
                stage: 2,
                classification: "Intermediate",
                title: "Bathmate Water Pump",
                methodDescription: "Water-based vacuum pumping for temporary and permanent girth gains.",
                instructionsText: """
                1. Fill pump with warm water in shower/bath
                2. Insert flaccid or semi-erect penis
                3. Create seal against pubic bone
                4. Pump to create vacuum (3-5 pumps initially)
                5. Hold for 3-5 minutes
                6. Release pressure and remove
                7. Massage for 2 minutes
                8. Repeat 2-3 times per session
                9. Monitor pressure - should feel stretch, not pain
                """,
                equipmentNeeded: ["Bathmate pump", "Warm water"],
                estimatedDurationMinutes: 20,
                categories: ["Girth", "Intermediate"],
                isFeatured: false,
                safetyNotes: "Start with minimal pressure. Never exceed 20 minutes total.",
                benefits: ["Girth gains", "Temporary size increase", "Water cushions pressure"]
            ),

            GrowthMethod(
                id: "bfr_clamping",
                stage: 3,
                classification: "Advanced",
                title: "BFR Clamping",
                methodDescription: "Blood flow restriction for advanced girth development.",
                instructionsText: """
                1. Achieve 90-95% erection
                2. Apply cable clamp at base with padding
                3. Tighten to restrict outflow (not inflow)
                4. Maintain for 5-10 minutes maximum
                5. Perform light jelqs or squeezes during session
                6. Release immediately if numbness occurs
                7. Massage thoroughly after removal
                8. Limit to 2-3 sets per session
                """,
                equipmentNeeded: ["Cable clamp", "Padding material"],
                estimatedDurationMinutes: 15,
                categories: ["Girth", "Advanced"],
                isFeatured: false,
                safetyNotes: "ADVANCED ONLY - high injury risk. Never exceed 10 minutes per set.",
                benefits: ["Maximum girth gains", "Intense expansion", "Advanced technique"]
            )
        ]
    }

    /// PE EQ (Erection Quality) Methods
    private var eqMethods: [GrowthMethod] {
        return [
            GrowthMethod(
                id: "kegels",
                stage: 1,
                classification: "Beginner",
                title: "Kegel Exercises",
                methodDescription: "Pelvic floor strengthening for improved erection quality and control.",
                instructionsText: """
                1. Locate PC muscle (stop urine mid-stream)
                2. Contract PC muscle firmly
                3. Hold for 5 seconds
                4. Release for 5 seconds
                5. Repeat 10-20 times
                6. Perform 3-4 sets daily
                7. Can be done anywhere, anytime
                8. Progress to longer holds over time
                """,
                equipmentNeeded: [],
                estimatedDurationMinutes: 10,
                categories: ["EQ", "Beginner"],
                isFeatured: true,
                safetyNotes: "Don't overdo - can cause tension. Ensure full relaxation between reps.",
                benefits: ["Stronger erections", "Better control", "Improved stamina"],
                timerConfig: TimerConfiguration(
                    recommendedDurationSeconds: 5,
                    isCountdown: false,
                    hasIntervals: true,
                    intervals: [
                        MethodInterval(name: "Contract", durationSeconds: 5),
                        MethodInterval(name: "Relax", durationSeconds: 5)
                    ]
                )
            ),

            GrowthMethod(
                id: "reverse_kegels",
                stage: 1,
                classification: "Beginner",
                title: "Reverse Kegels",
                methodDescription: "Pelvic floor relaxation to balance muscle tone and improve blood flow.",
                instructionsText: """
                1. Assume comfortable position
                2. Instead of contracting, push out gently
                3. Feel slight bulge in perineum area
                4. Hold for 3-5 seconds
                5. Return to neutral
                6. Repeat 10-15 times
                7. Focus on relaxation, not force
                8. Practice alongside regular kegels
                """,
                equipmentNeeded: [],
                estimatedDurationMinutes: 5,
                categories: ["EQ", "Beginner"],
                isFeatured: false,
                safetyNotes: "Use gentle pressure only. Stop if straining occurs.",
                benefits: ["Balanced pelvic floor", "Improved blood flow", "Relaxation"]
            ),

            GrowthMethod(
                id: "ballooning",
                stage: 2,
                classification: "Intermediate",
                title: "Ballooning Technique",
                methodDescription: "Arousal-based exercise for improved erection quality and size.",
                instructionsText: """
                1. Stimulate to 90% arousal
                2. Stop direct stimulation
                3. Massage areas around penis
                4. Focus on perineum and base
                5. Maintain high arousal without direct touch
                6. Allow engorgement to maximize
                7. Hold state for 10-15 minutes
                8. Promotes blood flow capacity
                """,
                equipmentNeeded: ["Lubricant (optional)"],
                estimatedDurationMinutes: 20,
                categories: ["EQ", "Intermediate"],
                isFeatured: false,
                safetyNotes: "Don't edge to exhaustion. Avoid blue balls.",
                benefits: ["Maximum engorgement", "Blood flow training", "Size optimization"]
            )
        ]
    }

    /// PE Stamina Methods
    private var staminaMethods: [GrowthMethod] {
        return [
            GrowthMethod(
                id: "edging",
                stage: 1,
                classification: "Beginner",
                title: "Edging Practice",
                methodDescription: "Arousal control training for improved stamina and EQ.",
                instructionsText: """
                1. Begin stimulation to 70-80% arousal
                2. Stop before point of no return
                3. Allow arousal to decrease to 40-50%
                4. Resume stimulation
                5. Repeat cycle 4-5 times
                6. Finish or stop completely
                7. Focus on awareness of arousal levels
                8. Practice 3-4 times per week
                """,
                equipmentNeeded: ["Lubricant (optional)"],
                estimatedDurationMinutes: 30,
                categories: ["Stamina", "Beginner"],
                isFeatured: true,
                safetyNotes: "Avoid excessive sessions. Don't edge to exhaustion.",
                benefits: ["Improved stamina", "Better control", "Enhanced awareness"]
            )
        ]
    }

    /// Get methods by category
    func getMethods(for category: String) -> [GrowthMethod] {
        switch category.lowercased() {
        case "length":
            return lengthMethods
        case "girth":
            return girthMethods
        case "eq":
            return eqMethods
        case "stamina":
            return staminaMethods
        default:
            return getAllPEMethods()
        }
    }

    /// Get method by ID
    func getMethod(byId id: String) -> GrowthMethod? {
        return getAllPEMethods().first { $0.id == id }
    }

    /// Get beginner methods
    func getBeginnerMethods() -> [GrowthMethod] {
        return getAllPEMethods().filter { $0.classification == "Beginner" }
    }

    /// Get featured methods
    func getFeaturedMethods() -> [GrowthMethod] {
        return getAllPEMethods().filter { $0.isFeatured }
    }
}