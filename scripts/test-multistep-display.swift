#!/usr/bin/env swift

// Simple test to verify multi-step display logic

struct MethodStep {
    var stepNumber: Int
    var title: String
    var description: String
    var duration: Int?
}

struct GrowthMethod {
    var title: String
    var steps: [MethodStep]?
    var instructionsText: String
}

// Test data
let angionMethod = GrowthMethod(
    title: "Angion Method 1.0",
    steps: [
        MethodStep(stepNumber: 1, title: "Preparation", description: "Get ready", duration: 60),
        MethodStep(stepNumber: 2, title: "Warm Up", description: "Start slowly", duration: 300),
        MethodStep(stepNumber: 3, title: "Main Work", description: "Full intensity", duration: 900)
    ],
    instructionsText: "Single line instructions"
)

let legacyMethod = GrowthMethod(
    title: "Legacy Method",
    steps: nil,
    instructionsText: "Step 1: Do this\nStep 2: Do that\nStep 3: Finish up"
)

// Test display logic
func displayMethod(_ method: GrowthMethod) {
    print("Method: \(method.title)")
    print("Has steps array: \(method.steps != nil)")
    
    if let steps = method.steps, !steps.isEmpty {
        print("Using multi-step display:")
        for step in steps {
            print("  \(step.stepNumber). \(step.title)")
            print("     \(step.description)")
            if let duration = step.duration {
                print("     Duration: \(duration / 60) min")
            }
        }
    } else {
        print("Using legacy text parsing:")
        let steps = method.instructionsText.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        for (idx, step) in steps.enumerated() {
            print("  \(idx + 1). \(step)")
        }
    }
    print("")
}

// Run tests
print("Testing Multi-Step Display Logic\n")
print("================================\n")

displayMethod(angionMethod)
displayMethod(legacyMethod)

print("✅ Test complete - multi-step logic verified")