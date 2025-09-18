import SwiftUI

// Test view to verify multi-step display logic
struct TestMultiStepView: View {
    let testMethod = GrowthMethod(
        id: "test",
        stage: 1,
        title: "Test Method (Detailed)",
        methodDescription: "Test description",
        instructionsText: "Single line instruction",
        steps: [
            MethodStep(
                stepNumber: 1,
                title: "Step 1 Title",
                description: "Step 1 description goes here",
                duration: 300,
                tips: ["Tip 1", "Tip 2"],
                warnings: ["Warning 1"],
                intensity: "low"
            ),
            MethodStep(
                stepNumber: 2,
                title: "Step 2 Title",
                description: "Step 2 description goes here",
                duration: 600,
                tips: ["Another tip"],
                warnings: nil,
                intensity: "medium"
            ),
            MethodStep(
                stepNumber: 3,
                title: "Step 3 Title",
                description: "Step 3 description goes here",
                duration: 900,
                tips: nil,
                warnings: nil,
                intensity: "high"
            )
        ],
        visualPlaceholderUrl: nil,
        equipmentNeeded: [],
        estimatedDurationMinutes: 30,
        categories: []
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title without "(Detailed)"
            Text(testMethod.title.replacingOccurrences(of: " (Detailed)", with: ""))
                .font(.title2)
                .bold()
            
            // Show step count
            if let steps = testMethod.steps {
                Text("\(steps.count) steps available")
                    .foregroundColor(.green)
            }
            
            Divider()
            
            // Display steps
            if let steps = testMethod.steps, !steps.isEmpty {
                Text("Multi-step display:")
                    .font(.headline)
                
                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(step.stepNumber).")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.headline)
                            Text(step.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let duration = step.duration {
                                Text("Duration: \(duration / 60) min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("Legacy display:")
                    .font(.headline)
                Text(testMethod.instructionsText)
                    .font(.caption)
            }
        }
        .padding()
    }
}

// Preview
#Preview {
    TestMultiStepView()
}