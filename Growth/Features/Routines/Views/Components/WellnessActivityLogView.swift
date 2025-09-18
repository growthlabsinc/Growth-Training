import SwiftUI

struct WellnessActivityLogView: View {
    @ObservedObject var viewModel: RestDayViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.selectedActivityType.emoji)
                            .font(AppTheme.Typography.title2Font())
                        Text(viewModel.selectedActivityType.title)
                            .font(AppTheme.Typography.title2Font())
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    Text(viewModel.selectedActivityType.description)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Duration Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(AppTheme.Typography.headlineFont())
                                .foregroundColor(Color("TextColor"))
                            
                            HStack {
                                TextField("Enter minutes", text: $viewModel.activityDuration)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text("minutes")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Notes Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(AppTheme.Typography.headlineFont())
                                .foregroundColor(Color("TextColor"))
                            
                            // Add journaling prompt if available
                            if let prompt = viewModel.currentPrompt {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("💭 Reflection Prompt")
                                        .font(AppTheme.Typography.subheadlineFont())
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("PaleGreen"))
                                    
                                    Text(prompt.text)
                                        .font(AppTheme.Typography.calloutFont())
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 4)
                                }
                            }
                            
                            TextEditor(text: $viewModel.activityNotes)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(AppTheme.Typography.captionFont())
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: viewModel.logWellnessActivity) {
                        HStack {
                            if viewModel.isSavingActivity {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                            
                            Text(viewModel.isSavingActivity ? "Saving..." : "Log Activity")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color("PaleGreen"))
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isSavingActivity || viewModel.activityDuration.isEmpty)
                    
                    Button("Cancel") {
                        viewModel.dismissActivityLogger()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Log Wellness Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.dismissActivityLogger()
                    }
                }
            }
        }
    }
}

// MARK: - Wellness Activity Summary Card
struct WellnessActivitySummaryCard: View {
    let activity: WellnessActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Type Icon
            VStack {
                Text(activity.type.emoji)
                    .font(AppTheme.Typography.title2Font())
                
                Text("\(activity.duration)m")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Activity Details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.title)
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("TextColor"))
                
                if let notes = activity.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("Logged at \(activity.loggedAt, style: .time)")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color("GrowthBackgroundLight"))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct WellnessActivityLogView_Previews: PreviewProvider {
    static var previews: some View {
        let schedule = DaySchedule(
            id: "rest-day",
            dayNumber: 4,
            dayName: "Day 4: Rest",
            description: "Recovery day",
            methodIds: nil,
            isRestDay: true,
            additionalNotes: "Focus on recovery and wellness activities"
        )
        
        WellnessActivityLogView(viewModel: RestDayViewModel(schedule: schedule))
    }
}