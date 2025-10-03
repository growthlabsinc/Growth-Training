import SwiftUI

struct RoutinesListView: View {
    @StateObject var viewModel: RoutinesViewModel
    @State private var selectedRoutine: Routine?
    @Environment(\.dismiss) private var dismiss
    var isOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color("GrowthGreen").opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error: error)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Header
                        heroHeader
                            .padding(.top, 20)
                        
                        // Onboarding prompt
                        if isOnboarding && viewModel.selectedRoutineId == nil {
                            onboardingPrompt
                        }
                        
                        // Routines List
                        VStack(spacing: 16) {
                            ForEach(viewModel.routines) { routine in
                                routineCard(routine: routine)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Change Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Change Routine?", isPresented: $viewModel.showRoutineChangeConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelRoutineChange()
            }
            Button("Change") {
                viewModel.confirmRoutineChange()
                dismiss()
            }
        } message: {
            if let routineName = viewModel.pendingRoutineName {
                Text("Are you sure you want to change to \"\(routineName)\"? Your current routine will be reset and you'll start fresh with the new routine.")
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading routines...")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("ErrorColor"))
            
            Text("Unable to load routines")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(.primary)
            
            Text(error)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GrowthGreen"),
                        Color("BrightTeal")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
                
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Choose Your Path")
                        .font(AppTheme.Typography.gravityBoldFont(28))
                        .foregroundColor(.white)
                    
                    Text("Select a routine that matches your goals and experience level")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .cornerRadius(16)
            .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Routine Card
    
    private func routineCard(routine: Routine) -> some View {
        NavigationLink(destination: RoutineDetailView(routineId: routine.id)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    // Icon based on difficulty
                    ZStack {
                        Circle()
                            .fill(Color("GrowthGreen").opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: difficultyIcon(for: routine.difficultyLevel))
                            .font(AppTheme.Typography.title3Font())
                            .foregroundColor(Color("GrowthGreen"))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(routine.name)
                                .font(AppTheme.Typography.gravitySemibold(15))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedRoutineId == routine.id {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(AppTheme.Typography.captionFont())
                                    Text("Selected")
                                        .font(AppTheme.Typography.captionFont())
                                }
                                .foregroundColor(Color("GrowthGreen"))
                            }
                        }
                        
                        Text(routine.description)
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            // Difficulty Badge
                            HStack(spacing: 3) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 10))
                                Text(routine.difficultyLevel)
                            }
                            .font(AppTheme.Typography.gravityBook(11))
                            .foregroundColor(difficultyColor(for: routine.difficultyLevel))
                            
                            // Schedule Info
                            HStack(spacing: 3) {
                                Text("Total")
                                    .foregroundColor(.secondary)
                                Text("\(routine.schedule.count) days")
                                    .fontWeight(.medium)
                            }
                            .font(AppTheme.Typography.gravityBook(11))
                            
                            Spacer()
                            
                            // Active Days
                            HStack(spacing: 3) {
                                Text("Active Days")
                                    .foregroundColor(.secondary)
                                Text("\(routine.schedule.filter { !$0.isRestDay }.count)")
                                    .fontWeight(.medium)
                            }
                            .font(AppTheme.Typography.gravityBook(11))
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.secondary)
                }
                .padding(14)
                
                // Action Bar
                if viewModel.selectedRoutineId != routine.id {
                    Divider()
                    
                    Button {
                        viewModel.requestRoutineChange(routine.id, routineName: routine.name)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(AppTheme.Typography.subheadlineFont())
                            Text("Select This Routine")
                                .font(AppTheme.Typography.gravitySemibold(14))
                            Spacer()
                        }
                        .foregroundColor(Color("GrowthGreen"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.selectedRoutineId == routine.id ? Color("GrowthGreen") : Color.clear,
                        lineWidth: viewModel.selectedRoutineId == routine.id ? 2 : 0
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Onboarding Prompt
    
    private var onboardingPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(Color("GrowthGreen"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Your First Routine")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.primary)
                    
                    Text("Choose a routine that matches your experience level. You can always change it later.")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("GrowthGreen").opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("GrowthGreen").opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func difficultyIcon(for level: String) -> String {
        switch level.lowercased() {
        case "beginner":
            return "leaf.fill"
        case "intermediate":
            return "flame.fill"
        case "advanced":
            return "bolt.fill"
        default:
            return "star.fill"
        }
    }
    
    private func difficultyColor(for level: String) -> Color {
        switch level.lowercased() {
        case "beginner":
            return Color("GrowthGreen")
        case "intermediate":
            return Color.orange
        case "advanced":
            return Color.red
        default:
            return Color.gray
        }
    }
}

// MARK: - Preview

struct RoutinesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RoutinesListView(viewModel: RoutinesViewModel(userId: "demoUser"))
        }
    }
} 