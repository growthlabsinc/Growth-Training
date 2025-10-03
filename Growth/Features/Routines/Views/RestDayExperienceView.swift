import SwiftUI

struct RestDayExperienceView: View {
    let schedule: DaySchedule
    @StateObject private var viewModel: RestDayViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(schedule: DaySchedule) {
        self.schedule = schedule
        _viewModel = StateObject(wrappedValue: RestDayViewModel(schedule: schedule))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Section
                restDayHeroSection
                
                // Today's Wellness Summary
                if viewModel.hasActivitiesToday {
                    todaysWellnessSummary
                }
                
                // Wellness Activity Suggestions
                wellnessActivitySuggestions
                
                // Recovery Tips Section
                recoveryTipsSection
                
                // Reflection Prompt
                if let prompt = viewModel.currentPrompt {
                    reflectionPromptSection(prompt: prompt)
                }
                
                // Today's Logged Activities
                if !viewModel.todaysActivities.isEmpty {
                    loggedActivitiesSection
                }
            }
            .padding()
        }
        .breadcrumb(style: .practice)
        .sheet(isPresented: $viewModel.showingActivityLogger) {
            WellnessActivityLogView(viewModel: viewModel)
        }
        .refreshable {
            viewModel.refreshWellnessPrompt()
        }
    }
    
    // MARK: - Hero Section
    private var restDayHeroSection: some View {
        VStack(spacing: 16) {
            // Hero Image
            Image("day4_rest_hero")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 180)
                .cornerRadius(16)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(Color("PaleGreen"))
                        .font(AppTheme.Typography.title2Font())
                    
                    Text("Rest & Recovery Day")
                        .font(AppTheme.Typography.title2Font())
                        .fontWeight(.semibold)
                        .foregroundColor(Color("TextColor"))
                }
                
                Text("Take time to nurture your body and mind with gentle activities that support your recovery and overall well-being.")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Today's Wellness Summary
    private var todaysWellnessSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Wellness")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("TextColor"))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.activitySummaryText)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                    
                    if viewModel.totalWellnessTime > 0 {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Color("PaleGreen"))
                                .font(AppTheme.Typography.captionFont())
                            Text("\(viewModel.totalWellnessTime) minutes of wellness time")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(Color("PaleGreen"))
                        }
                    }
                }
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("PaleGreen"))
                    .font(AppTheme.Typography.title3Font())
            }
            .padding()
            .background(Color("GrowthBackgroundLight"))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Wellness Activity Suggestions
    private var wellnessActivitySuggestions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Activities")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("TextColor"))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(WellnessActivitySuggestion.suggestions, id: \.type) { suggestion in
                    WellnessActivitySuggestionCard(
                        suggestion: suggestion,
                        onTap: {
                            viewModel.showActivityLogger(for: suggestion.type)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Recovery Tips Section
    private var recoveryTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recovery Tips")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 12) {
                RecoveryTipCard(
                    icon: "drop.fill",
                    title: "Stay Hydrated",
                    description: "Drink plenty of water throughout the day to support recovery and overall health.",
                    color: Color("BrightTeal")
                )
                
                RecoveryTipCard(
                    icon: "bed.double.fill",
                    title: "Quality Sleep",
                    description: "Aim for 7-9 hours of quality sleep to allow your body to repair and recharge.",
                    color: Color("MintGreen")
                )
                
                RecoveryTipCard(
                    icon: "heart.fill",
                    title: "Listen to Your Body",
                    description: "Pay attention to how you feel and adjust your activities accordingly.",
                    color: Color("PaleGreen")
                )
            }
        }
    }
    
    // MARK: - Reflection Prompt Section
    private func reflectionPromptSection(prompt: JournalingPrompt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflection")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("TextColor"))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color("PaleGreen"))
                    Text("Today's Prompt")
                        .font(AppTheme.Typography.subheadlineFont())
                        .fontWeight(.medium)
                        .foregroundColor(Color("TextColor"))
                    Spacer()
                    Button("New Prompt") {
                        viewModel.refreshWellnessPrompt()
                    }
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("PaleGreen"))
                }
                
                Text(prompt.text)
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color("GrowthBackgroundLight"))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Logged Activities Section
    private var loggedActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Activities")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(Color("TextColor"))
            
            ForEach(viewModel.todaysActivities) { activity in
                WellnessActivitySummaryCard(activity: activity)
            }
        }
    }
}

// MARK: - Supporting Views

struct WellnessActivitySuggestionCard: View {
    let suggestion: WellnessActivitySuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(suggestion.type.emoji)
                    .font(AppTheme.Typography.title1Font())
                
                Text(suggestion.title)
                    .font(AppTheme.Typography.headlineFont())
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("TextColor"))
                
                Text("\(suggestion.estimatedDuration) min")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("GrowthBackgroundLight"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecoveryTipCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(AppTheme.Typography.title3Font())
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.subheadlineFont())
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextColor"))
                
                Text(description)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color("GrowthBackgroundLight"))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct RestDayExperienceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RestDayExperienceView(schedule: DaySchedule(
                id: "rest-day",
                dayNumber: 4,
                dayName: "Day 4: Rest",
                description: "Recovery day",
                methodIds: nil,
                isRestDay: true,
                additionalNotes: "Take time to recover and prepare for the next training session"
            ))
        }
    }
}