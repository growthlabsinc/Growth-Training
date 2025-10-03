import SwiftUI
import FirebaseAuth

struct RoutineEditView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = EditCustomRoutineViewModel()
    
    let routine: Routine
    
    // Animation states
    @State private var currentStep: CreationStep = .naming
    @State private var showSuccessAnimation = false
    @State private var animationProgress: CGFloat = 0
    @State private var showingSaveAlert = false
    @State private var saveError: String?
    @State private var isAutoSaving = false
    @State private var showAutoSaveSuccess = false
    
    enum CreationStep: Int, CaseIterable {
        case naming = 0
        case difficulty = 1
        case duration = 2
        case methods = 3
        case schedule = 4
        case review = 5
        
        var title: String {
            switch self {
            case .naming: return "Edit Name"
            case .difficulty: return "Adjust Difficulty"
            case .duration: return "Modify Duration"
            case .methods: return "Update Methods"
            case .schedule: return "Refine Schedule"
            case .review: return "Review Changes"
            }
        }
        
        var icon: String {
            switch self {
            case .naming: return "pencil.circle.fill"
            case .difficulty: return "chart.line.uptrend.xyaxis"
            case .duration: return "calendar.circle.fill"
            case .methods: return "list.bullet.circle.fill"
            case .schedule: return "calendar.badge.clock"
            case .review: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    AppTheme.Colors.background,
                    Color("GrowthGreen").opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading routine...")
                    .font(AppTheme.Typography.bodyFont())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Header with progress
                    headerView
                    
                    // Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Progress indicator
                            progressView
                            
                            // Current step content
                            stepContent
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 24)
                    }
                    
                    // Bottom navigation
                    bottomNavigation
                }
            }
        }
        .onAppear {
            viewModel.loadRoutine(routine)
        }
        .alert("Save Changes?", isPresented: $showingSaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveChanges()
            }
        } message: {
            Text("Are you sure you want to save these changes to your routine?")
        }
        .overlay(alignment: .top) {
            // Auto-save indicator
            if isAutoSaving || showAutoSaveSuccess {
                HStack(spacing: 8) {
                    if isAutoSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Saving changes...")
                    } else if showAutoSaveSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("GrowthGreen"))
                        Text("Changes saved")
                    }
                }
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.card)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: isAutoSaving)
                .animation(.easeInOut, value: showAutoSaveSuccess)
            }
        }
        .alert("Success!", isPresented: $viewModel.saveSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your routine has been updated successfully!")
        }
        .alert("Error", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "An error occurred")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(AppTheme.Colors.text.opacity(0.6))
                    .background(Circle().fill(Color("BackgroundColor")).frame(width: 32, height: 32))
            }
            
            Spacer()
            
            Text(currentStep.title)
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(AppTheme.Colors.text)
            
            Spacer()
            
            // Step indicator
            HStack(spacing: 4) {
                ForEach(CreationStep.allCases, id: \.self) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? 
                              Color("GrowthGreen") : 
                              AppTheme.Colors.text.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding()
        .background(
            Color("BackgroundColor")
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.text.opacity(0.1))
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color("GrowthGreen"), Color("BrightTeal")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progressAmount, height: 8)
            }
        }
        .frame(height: 8)
        .padding(.horizontal)
    }
    
    private var progressAmount: CGFloat {
        CGFloat(currentStep.rawValue + 1) / CGFloat(CreationStep.allCases.count)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .naming:
            NamingStepView(
                name: $viewModel.routineName, 
                description: $viewModel.routineDescription,
                shareWithCommunity: $viewModel.shareWithCommunity,
                nameValidationError: .constant(nil),
                isCheckingName: .constant(false)
            )
            .id(CreationStep.naming)
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity
            ))
            
        case .difficulty:
            DifficultySelectionView(selectedDifficulty: $viewModel.selectedDifficulty)
                .id(CreationStep.difficulty)
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity
                ))
                
        case .duration:
            DurationSelectionView(
                selectedDuration: $viewModel.selectedDuration,
                selectedSchedulingType: .constant(.sequential)
            )
                .id(CreationStep.duration)
                .onChangeCompat(of: viewModel.selectedDuration) { _ in
                    // Regenerate schedule when duration changes
                    viewModel.regenerateSchedule()
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity
                ))
                
        case .methods:
            PremiumMethodSelectionView(
                selectedMethods: $viewModel.selectedMethods,
                duration: viewModel.selectedDuration,
                schedulingType: .sequential,
                methodSchedulingConfigs: $viewModel.methodSchedulingConfigs
            )
            .id(CreationStep.methods)
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity
            ))
            
        case .schedule:
            ScheduleCustomizationView(
                daySchedules: $viewModel.daySchedules,
                selectedMethods: viewModel.selectedMethods,
                duration: viewModel.selectedDuration,
                schedulingType: .sequential,
                onScheduleUpdate: {
                    // Sync the method configs from the updated schedule
                    viewModel.syncMethodConfigsFromSchedule()
                    
                    // Auto-save the changes when schedule is updated
                    Logger.debug("Schedule updated, auto-saving changes...")
                    Task {
                        await MainActor.run {
                            isAutoSaving = true
                            showAutoSaveSuccess = false
                        }
                        
                        do {
                            try await viewModel.updateRoutine()
                            Logger.debug("Auto-save successful")
                            
                            await MainActor.run {
                                isAutoSaving = false
                                showAutoSaveSuccess = true
                                
                                // Hide success message after 2 seconds
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                    await MainActor.run {
                                        showAutoSaveSuccess = false
                                    }
                                }
                            }
                        } catch {
                            Logger.debug("Auto-save failed: \(error)")
                            await MainActor.run {
                                isAutoSaving = false
                                saveError = error.localizedDescription
                            }
                        }
                    }
                }
            )
            .id(CreationStep.schedule)
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity
            ))
            
        case .review:
            EditReviewStepView(
                originalRoutine: routine,
                name: viewModel.routineName,
                description: viewModel.routineDescription,
                difficulty: viewModel.selectedDifficulty,
                duration: viewModel.selectedDuration,
                methods: viewModel.selectedMethods,
                daySchedules: viewModel.daySchedules,
                shareWithCommunity: $viewModel.shareWithCommunity
            )
            .id(CreationStep.review)
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity
            ))
        }
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack(spacing: 16) {
            if currentStep != .naming {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.text.opacity(0.2), lineWidth: 1)
                    )
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            Button(action: nextStep) {
                HStack {
                    Text(currentStep == .review ? "Save Changes" : "Continue")
                    if currentStep != .review {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(AppTheme.Typography.gravityBoldFont(AppTheme.Typography.body))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color("GrowthGreen"), Color("BrightTeal")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .disabled(!canProceed || viewModel.isSaving)
                .opacity(canProceed && !viewModel.isSaving ? 1 : 0.6)
            }
        }
        .padding()
        .background(
            Color("BackgroundColor")
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
        )
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .naming:
            return !viewModel.routineName.isEmpty
        case .difficulty:
            return true
        case .duration:
            return true
        case .methods:
            return !viewModel.selectedMethods.isEmpty
        case .schedule:
            return !viewModel.daySchedules.isEmpty
        case .review:
            return true
        }
    }
    
    private func previousStep() {
        if let previousStep = CreationStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.spring()) {
                currentStep = previousStep
            }
        }
    }
    
    private func nextStep() {
        if currentStep == .review {
            showingSaveAlert = true
        } else if let nextStep = CreationStep(rawValue: currentStep.rawValue + 1) {
            // Generate schedule when moving from methods to schedule
            if currentStep == .methods && nextStep == .schedule {
                viewModel.regenerateSchedule()
            }
            
            withAnimation(.spring()) {
                currentStep = nextStep
            }
        }
    }
    
    
    private func saveChanges() {
        Task {
            do {
                try await viewModel.updateRoutine()
            } catch {
                await MainActor.run {
                    saveError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Edit Review Step View
struct EditReviewStepView: View {
    let originalRoutine: Routine
    let name: String
    let description: String
    let difficulty: RoutineDifficulty
    let duration: Int
    let methods: [GrowthMethod]
    let daySchedules: [DaySchedule]
    @Binding var shareWithCommunity: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Label("Review Your Changes", systemImage: "checkmark.seal.fill")
                    .font(AppTheme.Typography.gravityBoldFont(24))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("Make sure everything looks good before saving")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.text.opacity(0.8))
            }
            
            // Changes Summary
            VStack(alignment: .leading, spacing: 20) {
                // Name and Description
                changeSection(
                    title: "Name & Description",
                    original: originalRoutine.name,
                    new: name,
                    showChange: originalRoutine.name != name
                )
                
                if originalRoutine.description != description {
                    Text("Updated description")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(Color("BrightTeal"))
                }
                
                // Difficulty
                if originalRoutine.difficulty != difficulty {
                    changeSection(
                        title: "Difficulty",
                        original: originalRoutine.difficulty.rawValue.capitalized,
                        new: difficulty.rawValue.capitalized,
                        showChange: true
                    )
                }
                
                // Duration
                if originalRoutine.duration != duration {
                    changeSection(
                        title: "Duration",
                        original: "\(originalRoutine.duration) days",
                        new: "\(duration) days",
                        showChange: true
                    )
                }
                
                // Methods Summary
                summaryCard(
                    title: "Methods",
                    icon: "figure.strengthtraining.traditional",
                    value: "\(methods.count) selected"
                )
                
                // Schedule Summary
                let trainingDays = daySchedules.filter { !$0.isRestDay }.count
                summaryCard(
                    title: "Schedule",
                    icon: "calendar",
                    value: "\(trainingDays) training days, \(duration - trainingDays) rest days"
                )
                
                // Community Sharing Toggle
                Toggle(isOn: $shareWithCommunity) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(Color("GrowthGreen"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share with Community")
                                .font(AppTheme.Typography.gravitySemibold(16))
                            Text("Let others benefit from your routine")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color("GrowthGreen")))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    private func changeSection(title: String, original: String, new: String, showChange: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.text.opacity(0.6))
            
            if showChange {
                HStack {
                    Text(original)
                        .strikethrough()
                        .foregroundColor(AppTheme.Colors.text.opacity(0.5))
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color("BrightTeal"))
                    Text(new)
                        .foregroundColor(AppTheme.Colors.text)
                }
                .font(AppTheme.Typography.bodyFont())
            } else {
                Text(new)
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.text)
            }
        }
    }
    
    private func summaryCard(title: String, icon: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(Color("GrowthGreen"))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.text.opacity(0.6))
                Text(value)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(AppTheme.Colors.text)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct RoutineEditView_Previews: PreviewProvider {
    static var previews: some View {
        RoutineEditView(routine: Routine(
            id: "test",
            name: "Test Routine",
            description: "A test routine",
            difficulty: .intermediate,
            duration: 14,
            focusAreas: ["Focus"],
            stages: [1, 2],
            createdDate: Date(),
            lastUpdated: Date(),
            schedule: [],
            isCustom: true,
            createdBy: "user123"
        ))
    }
}