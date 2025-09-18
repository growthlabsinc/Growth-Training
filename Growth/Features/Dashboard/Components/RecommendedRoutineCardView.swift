import SwiftUI

struct RecommendedRoutineCardView<OnSelectRoutine: View>: View {
    let routine: Routine?
    @ViewBuilder let onSelectRoutine: () -> OnSelectRoutine
    let onViewDetails: (() -> Void)?
    
    // Initialize the view with routine and closure parameters
    init(routine: Routine?, 
         @ViewBuilder onSelectRoutine: @escaping () -> OnSelectRoutine, 
         onViewDetails: (() -> Void)?) {
        self.routine = routine
        self.onSelectRoutine = onSelectRoutine
        self.onViewDetails = onViewDetails
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                // Header image for special routines
                if let routine = routine, (routine.id == "standard_growth_routine" || routine.id == "beginner_express" || routine.id == "advanced_intensive" || routine.id == "janus_protocol_12week" || routine.id == "two_week_transformation") {
                    ZStack(alignment: .bottomLeading) {
                        Image(routineHeroImage(for: routine.id))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(12)
                        
                        // Gradient overlay for text readability
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.black.opacity(routine.id == "beginner_express" ? 0.5 : 0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .cornerRadius(12)
                        
                        // Title overlay
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Routine")
                                    .font(AppTheme.Typography.gravitySemibold(12))
                                    .foregroundColor(.white.opacity(0.8))
                                Text(routine.name)
                                    .font(AppTheme.Typography.gravitySemibold(16))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: routineIcon(for: routine.id))
                                .font(AppTheme.Typography.title2Font())
                                .foregroundColor(.white)
                        }
                        .padding(12)
                    }
                } else {
                    Text(routine == nil ? "Recommended Routine" : "Current Routine")
                        .font(AppTheme.Typography.gravitySemibold(15))
                        .foregroundColor(Color("GrowthGreen"))
                }
                
                if let routine = routine {
                    VStack(alignment: .leading, spacing: 8) {
                        if routine.id != "standard_growth_routine" && routine.id != "beginner_express" && routine.id != "janus_protocol_12week" && routine.id != "two_week_transformation" {
                            Text(routine.name)
                                .font(AppTheme.Typography.headlineFont())
                        }
                        Text(routine.description)
                            .font(AppTheme.Typography.subheadlineFont())
                            .foregroundColor(.secondary)
                        HStack {
                            Text("Difficulty: \(routine.difficultyLevel)")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Show citation badge for science-backed routines
                            if routine.id == "standard_growth_routine" || 
                               routine.id == "janus_protocol_12week" ||
                               routine.focusAreas.contains("vascular") ||
                               routine.focusAreas.contains("flow-mediated") {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                    Text("Science-Backed")
                                        .font(AppTheme.Typography.captionFont())
                                }
                                .foregroundColor(Color("GrowthGreen"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("GrowthGreen").opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        // View Details button navigates to routine details
                        Button(action: {
                            onViewDetails?()
                        }) {
                            Text("View Details")
                                .font(AppTheme.Typography.gravitySemibold(13))
                                .foregroundColor(Color("GrowthGreen"))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                        }

                        // Button to allow changing the current routine
                        onSelectRoutine()
                    }
                } else {
                    // No routine selected prompt (no double card)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No routine selected.")
                            .font(AppTheme.Typography.subheadlineFont())
                            .foregroundColor(.secondary)
                        onSelectRoutine()
                    }
                }
            }
        }
    }
    
    private func routineIcon(for routineId: String) -> String {
        switch routineId {
        case "standard_growth_routine":
            return "leaf.fill"
        case "beginner_express":
            return "sun.max.fill"
        case "janus_protocol_12week":
            return "bolt.circle.fill"
        case "two_week_transformation":
            return "calendar.badge.clock"
        default:
            return "star.fill"
        }
    }
    
    private func routineHeroImage(for routineId: String) -> String {
        switch routineId {
        case "standard_growth_routine":
            return "standard_routine_hero"
        case "beginner_express":
            return "beginner_express_hero"
        case "advanced_intensive":
            return "advanced_intensive_hero"
        case "janus_protocol_12week":
            return "janus_hero"
        case "two_week_transformation":
            return "two_week_transformation_hero"
        default:
            return "standard_routine_hero"
        }
    }
}

#if DEBUG
struct RecommendedRoutineCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRoutine = Routine(
            id: "standard_growth_routine",
            name: "Standard Growth Routine",
            description: "A balanced weekly routine based on the 1on1off principle, focusing on Angion Methods for optimal vascular development and recovery.",
            difficultyLevel: "Beginner",
            schedule: [
                DaySchedule(id: "day1", dayNumber: 1, dayName: "Day 1: Heavy Day", description: "Perform Angio Pumping or Angion Method 1.0/2.0, plus optional pumping and S2S stretches.", methodIds: ["angio_pumping", "am1_0", "am2_0"], isRestDay: false, additionalNotes: "Keep session under 30 minutes."),
                DaySchedule(id: "day2", dayNumber: 2, dayName: "Day 2: Rest", description: "Rest and recover.", methodIds: nil, isRestDay: true, additionalNotes: nil)
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
        return VStack(spacing: 24) {
            RecommendedRoutineCardView(routine: sampleRoutine, onSelectRoutine: { EmptyView() }, onViewDetails: {})
            RecommendedRoutineCardView(routine: nil, onSelectRoutine: { EmptyView() }, onViewDetails: nil)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 