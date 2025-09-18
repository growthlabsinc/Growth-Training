import SwiftUI
import FirebaseAuth
import Foundation  // For Logger

struct PremiumCreateCustomRoutineView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateCustomRoutineViewModel()
    
    // Animation states
    @State private var currentStep: CreationStep = .naming
    @State private var showSuccessAnimation = false
    @State private var animationProgress: CGFloat = 0
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedMethods: [GrowthMethod] = []
    @State private var routineName = ""
    @State private var routineDescription = ""
    @State private var selectedDifficulty: RoutineDifficulty = .intermediate
    @State private var selectedDuration = 14
    @State private var shareWithCommunity = false
    @State private var daySchedules: [DaySchedule] = []
    @State private var methodSchedulingConfigs: [String: MethodSchedulingConfig] = [:]
    @State private var selectedSchedulingType: RoutineSchedulingType = .sequential
    
    // Username handling
    @State private var showingUsernameCreation = false
    @State private var currentUser: User?
    
    // Name validation
    @State private var nameValidationError: String?
    @State private var isCheckingName = false
    
    enum CreationStep: Int, CaseIterable {
        case naming = 0
        case difficulty = 1
        case duration = 2
        case methods = 3
        case schedule = 4
        case review = 5
        
        var title: String {
            switch self {
            case .naming: return "Name Your Journey"
            case .difficulty: return "Choose Your Level"
            case .duration: return "Set Your Timeline"
            case .methods: return "Select Methods"
            case .schedule: return "Customize Schedule"
            case .review: return "Review & Create"
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
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.Colors.background,
                        Color("GrowthGreen").opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Removed animated gradient mesh to reduce memory usage
            }
            
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
        .alert("Success!", isPresented: $showSuccessAnimation) {
            Button("OK") { dismiss() }
        } message: {
            Text("\(routineName) has been created successfully!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadCurrentUser()
        }
        .sheet(isPresented: $showingUsernameCreation) {
            CreateUsernameView { username, displayName in
                // Reload user after username creation
                loadCurrentUser()
            }
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
        Group {
            switch currentStep {
            case .naming:
                NamingStepView(
                    name: $routineName, 
                    description: $routineDescription,
                    shareWithCommunity: $shareWithCommunity,
                    nameValidationError: $nameValidationError,
                    isCheckingName: $isCheckingName
                )
                    .id(CreationStep.naming)
            case .difficulty:
                DifficultySelectionView(selectedDifficulty: $selectedDifficulty)
                    .id(CreationStep.difficulty)
            case .duration:
                DurationSelectionView(
                    selectedDuration: $selectedDuration,
                    selectedSchedulingType: $selectedSchedulingType
                )
                    .id(CreationStep.duration)
            case .methods:
                PremiumMethodSelectionView(
                    selectedMethods: $selectedMethods, 
                    duration: selectedDuration,
                    schedulingType: selectedSchedulingType,
                    methodSchedulingConfigs: $methodSchedulingConfigs
                )
                    .id(CreationStep.methods)
            case .schedule:
                ScheduleCustomizationView(
                    daySchedules: $daySchedules,
                    selectedMethods: selectedMethods,
                    duration: selectedDuration,
                    schedulingType: selectedSchedulingType,
                    onScheduleUpdate: updateSelectedMethodsFromSchedule
                )
                .id(CreationStep.schedule)
            case .review:
                ReviewStepView(
                    name: routineName,
                    description: routineDescription,
                    difficulty: selectedDifficulty,
                    duration: selectedDuration,
                    methods: selectedMethods,
                    daySchedules: daySchedules,
                    schedulingType: selectedSchedulingType,
                    shareWithCommunity: $shareWithCommunity,
                    currentUser: currentUser,
                    onUsernameRequired: {
                        showingUsernameCreation = true
                    },
                    nameValidationError: $nameValidationError,
                    isCheckingName: $isCheckingName
                )
                .id(CreationStep.review)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity,
            removal: .opacity
        ))
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
                    Text(currentStep == .review ? "Create Routine" : "Continue")
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
                .disabled(!canProceed)
                .opacity(canProceed ? 1 : 0.6)
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
            return !routineName.isEmpty && nameValidationError == nil && !isCheckingName
        case .difficulty:
            return true
        case .duration:
            return true
        case .methods:
            return !selectedMethods.isEmpty
        case .schedule:
            return !daySchedules.isEmpty
        case .review:
            return nameValidationError == nil && !isCheckingName
        }
    }
    
    private func previousStep() {
        if let previousStep = CreationStep(rawValue: currentStep.rawValue - 1) {
            // When going back from schedule to methods, update selected methods based on what's actually in the schedule
            if currentStep == .schedule && previousStep == .methods {
                updateSelectedMethodsFromSchedule()
            }
            currentStep = previousStep
        }
    }
    
    private func nextStep() {
        if currentStep == .review {
            createRoutine()
        } else {
            if let nextStep = CreationStep(rawValue: currentStep.rawValue + 1) {
                // Generate initial schedule when moving to schedule step
                if nextStep == .schedule {
                    // Only regenerate if we don't have a schedule or if methods have changed
                    if daySchedules.isEmpty {
                        generateInitialSchedule()
                    } else {
                        // Update existing schedule to add any new methods
                        updateScheduleWithNewMethods()
                    }
                }
                currentStep = nextStep
            }
        }
    }
    
    private func generateInitialSchedule() {
        // Initialize day schedules
        let scheduleLength = selectedSchedulingType == .weekday ? 7 : selectedDuration
        daySchedules = (1...scheduleLength).map { dayNumber in
            // For custom routines, start with all days as training days
            // Users can manually set rest days in the schedule customization step
            let isRestDay = false
            var methods: [MethodSchedule] = []
            
            // Apply method scheduling based on configurations
            for method in selectedMethods {
                guard let methodId = method.id else { continue }
                let config = methodSchedulingConfigs[methodId] ?? MethodSchedulingConfig(methodId: methodId, duration: method.estimatedDurationMinutes ?? 20)
                
                if shouldIncludeMethod(methodId: methodId, dayNumber: dayNumber, config: config) {
                    methods.append(MethodSchedule(
                        methodId: methodId,
                        duration: config.duration,
                        order: methods.count
                    ))
                }
            }
            
            return DaySchedule(
                day: dayNumber,
                isRestDay: isRestDay,
                methods: methods,
                notes: ""
            )
        }
    }
    
    private func shouldIncludeMethod(methodId: String, dayNumber: Int, config: MethodSchedulingConfig) -> Bool {
        // Check custom days first
        if !config.selectedDays.isEmpty {
            let dayOfWeek = ((dayNumber - 1) % 7) + 1
            return config.selectedDays.contains(dayOfWeek)
        }
        
        // Check frequency
        switch config.frequency {
        case .everyDay:
            return true
        case .everyOtherDay:
            return dayNumber % 2 == 1
        case .every2Days:
            return dayNumber % 3 == 1
        case .every3Days:
            return dayNumber % 4 == 1
        case .custom:
            return false // Already handled above
        }
    }
    
    private func updateSelectedMethodsFromSchedule() {
        Logger.debug("=== updateSelectedMethodsFromSchedule called ===")
        
        // First, collect all method IDs and their days from the schedule
        var methodDaysMap: [String: Set<Int>] = [:]
        
        // Process the entire schedule duration, not just 7 days
        for (dayIndex, daySchedule) in daySchedules.enumerated() {
            let dayNumber = dayIndex + 1
            
            for method in daySchedule.methods {
                if methodDaysMap[method.methodId] == nil {
                    methodDaysMap[method.methodId] = []
                }
                // Store the actual day number for proper tracking
                methodDaysMap[method.methodId]?.insert(dayNumber)
            }
        }
        
        Logger.debug("Method days map: \(methodDaysMap)")
        
        // Update method scheduling configs based on actual schedule
        for method in selectedMethods {
            guard let methodId = method.id else { continue }
            
            if let daysInSchedule = methodDaysMap[methodId] {
                // Convert day numbers to day of week for the scheduling config
                var daysOfWeek = Set<Int>()
                for dayNumber in daysInSchedule {
                    let dayOfWeek = ((dayNumber - 1) % 7) + 1
                    daysOfWeek.insert(dayOfWeek)
                }
                
                // Method exists in schedule, update its configuration
                var config = methodSchedulingConfigs[methodId] ?? MethodSchedulingConfig(methodId: methodId, duration: 20)
                config.selectedDays = daysOfWeek
                config.frequency = .custom // Set to custom since user manually edited days
                methodSchedulingConfigs[methodId] = config
                
                Logger.debug("Updated config for \(methodId): selectedDays = \(daysOfWeek)")
            } else {
                // Method was removed from all days
                methodSchedulingConfigs.removeValue(forKey: methodId)
                Logger.debug("Removed config for \(methodId)")
            }
        }
        
        // Only remove methods that are completely removed from all days
        let previousCount = selectedMethods.count
        selectedMethods = selectedMethods.filter { method in
            guard let methodId = method.id else { return false }
            
            // If method is not in any day, remove it from selection
            return methodDaysMap[methodId] != nil
        }
        
        if previousCount != selectedMethods.count {
            Logger.debug("Removed \(previousCount - selectedMethods.count) methods from selection")
        }
        
        Logger.info("=== updateSelectedMethodsFromSchedule completed ===")
    }
    
    private func getExpectedDaysForMethod(methodId: String, config: MethodSchedulingConfig) -> Set<Int> {
        var expectedDays = Set<Int>()
        
        for dayNumber in 1...selectedDuration {
            if shouldIncludeMethod(methodId: methodId, dayNumber: dayNumber, config: config) {
                expectedDays.insert(dayNumber)
            }
        }
        
        return expectedDays
    }
    
    private func updateScheduleWithNewMethods() {
        Logger.debug("=== updateScheduleWithNewMethods called ===")
        
        // First, capture the current state of the schedule for comparison
        var currentScheduleState: [String: Set<Int>] = [:]
        for (dayIndex, daySchedule) in daySchedules.enumerated() {
            for method in daySchedule.methods {
                if currentScheduleState[method.methodId] == nil {
                    currentScheduleState[method.methodId] = []
                }
                currentScheduleState[method.methodId]?.insert(dayIndex + 1)
            }
        }
        
        // Process each selected method to ensure its schedule matches its configuration
        for method in selectedMethods {
            guard let methodId = method.id else { continue }
            let config = methodSchedulingConfigs[methodId] ?? MethodSchedulingConfig(methodId: methodId, duration: method.estimatedDurationMinutes ?? 20)
            
            // Only add new methods that weren't in the schedule before, or add methods to days
            // that should have them according to the config but don't currently have them
            // BUT don't re-add to days where user manually removed them
            for (dayIndex, _) in daySchedules.enumerated() {
                let dayNumber = dayIndex + 1
                let shouldBePresent = shouldIncludeMethod(methodId: methodId, dayNumber: dayNumber, config: config)
                let isCurrentlyPresent = daySchedules[dayIndex].methods.contains { $0.methodId == methodId }
                
                if shouldBePresent && !isCurrentlyPresent {
                    // Only add if this is a completely new method (not in any day of current schedule)
                    // OR if the user has modified the configuration since the last sync
                    let wasInScheduleBefore = currentScheduleState[methodId] != nil
                    
                    if !wasInScheduleBefore {
                        // This is a completely new method, safe to add
                        let methodSchedule = MethodSchedule(
                            methodId: methodId,
                            duration: method.estimatedDurationMinutes ?? 20,
                            order: daySchedules[dayIndex].methods.count
                        )
                        daySchedules[dayIndex].methods.append(methodSchedule)
                        Logger.debug("Added new method \(methodId) to day \(dayNumber)")
                    } else {
                        // Method existed before - don't re-add to days where user manually removed it
                        Logger.debug("Skipping re-add of \(methodId) to day \(dayNumber) - user may have manually removed it")
                    }
                } else if !shouldBePresent && isCurrentlyPresent {
                    // Remove method from this day if config says it shouldn't be there
                    daySchedules[dayIndex].methods.removeAll { $0.methodId == methodId }
                    Logger.debug("Removed method \(methodId) from day \(dayNumber) per configuration")
                }
            }
        }
        
        // Remove any methods from schedule that are no longer selected
        let selectedMethodIds = Set(selectedMethods.compactMap { $0.id })
        for (dayIndex, _) in daySchedules.enumerated() {
            let originalCount = daySchedules[dayIndex].methods.count
            daySchedules[dayIndex].methods.removeAll { method in
                !selectedMethodIds.contains(method.methodId)
            }
            if daySchedules[dayIndex].methods.count != originalCount {
                Logger.debug("Removed unselected methods from day \(dayIndex + 1)")
            }
        }
        
        Logger.info("=== updateScheduleWithNewMethods completed ===")
    }
    
    private func generateDefaultSchedule() -> [DaySchedule] {
        var schedule: [DaySchedule] = []
        let methodsPerDay = selectedMethods
        
        for day in 1...selectedDuration {
            if day % 4 == 0 {
                // Rest day
                schedule.append(DaySchedule(
                    day: day,
                    isRestDay: true,
                    methods: [],
                    notes: "Recovery and regeneration day"
                ))
            } else {
                // Training day with selected methods
                let dayMethods = methodsPerDay.enumerated().map { index, method in
                    MethodSchedule(
                        methodId: method.id ?? "",
                        duration: method.estimatedDurationMinutes ?? 20,
                        order: index
                    )
                }
                schedule.append(DaySchedule(
                    day: day,
                    isRestDay: false,
                    methods: dayMethods,
                    notes: ""
                ))
            }
        }
        
        return schedule
    }
    
    private func createRoutine() {
        // Check username requirement if sharing with community
        if shareWithCommunity && currentUser?.username == nil {
            showingUsernameCreation = true
            return
        }
        
        // Final validation check for community sharing
        if shareWithCommunity {
            isCheckingName = true
            Task {
                do {
                    let nameExists = try await RoutineService.shared.checkCommunityRoutineNameExists(name: routineName)
                    
                    await MainActor.run {
                        isCheckingName = false
                        
                        if nameExists {
                            nameValidationError = "A community routine with this name already exists. Please choose a unique name."
                            return
                        }
                        
                        // If validation passes, continue with routine creation
                        performRoutineCreation()
                    }
                } catch {
                    await MainActor.run {
                        isCheckingName = false
                        nameValidationError = "Unable to verify name. Please try again."
                    }
                }
            }
        } else {
            // No validation needed for private routines
            performRoutineCreation()
        }
    }
    
    private func performRoutineCreation() {
        // Use the customized schedule if available
        let finalSchedule = !daySchedules.isEmpty ? daySchedules : generateDefaultSchedule()
        
        var routine = Routine(
            id: "custom_\(UUID().uuidString)",
            name: routineName,
            description: routineDescription,
            difficulty: selectedDifficulty,
            duration: selectedDuration,
            focusAreas: selectedMethods.flatMap { $0.categories },
            stages: Array(Set(selectedMethods.compactMap { $0.stage })).sorted(),
            createdDate: Date(),
            lastUpdated: Date(),
            schedule: finalSchedule,
            isCustom: true,
            createdBy: Auth.auth().currentUser?.uid,
            shareWithCommunity: shareWithCommunity
        )
        
        // Set the scheduling type
        routine.schedulingType = selectedSchedulingType
        
        // Add creator info if sharing
        if shareWithCommunity, let user = currentUser {
            routine.creatorUsername = user.username
            routine.creatorDisplayName = user.displayName ?? user.firstName ?? "Anonymous"
            routine.sharedDate = Date()
        }
        
        viewModel.saveCustomRoutine(routine, shareWithCommunity: shareWithCommunity) { result in
            switch result {
            case .success:
                showSuccessAnimation = true
            case .failure(let error):
                Logger.error("Error saving routine: \(error)")
                // Show error message to user
                if case AICoachError.premiumRequired = error {
                    errorMessage = "Premium subscription required to create custom routines. Please upgrade your account to access this feature."
                } else {
                    errorMessage = error.localizedDescription
                }
                showErrorAlert = true
            }
        }
    }
    
    private func loadCurrentUser() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        UserService.shared.fetchUser(userId: userId) { result in
            switch result {
            case .success(let user):
                self.currentUser = user
            case .failure(let error):
                Logger.error("Error loading user: \(error)")
            }
        }
    }
}

// MARK: - Step Views

struct NamingStepView: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var shareWithCommunity: Bool
    @Binding var nameValidationError: String?
    @Binding var isCheckingName: Bool
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            // Simple icon without animation
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen").opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 50))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            VStack(spacing: 24) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Routine Name")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                    
                    TextField("My Custom Routine", text: $name)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.text)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("BackgroundColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isNameFocused ? Color("GrowthGreen") : Color.gray.opacity(0.2), lineWidth: 2)
                                )
                        )
                        .focused($isNameFocused)
                        .onChangeCompat(of: name) { _ in
                            // Validate when shareWithCommunity is already on
                            if shareWithCommunity && !name.isEmpty {
                                validateNameWithDebounce()
                            } else {
                                nameValidationError = nil
                            }
                        }
                    
                    // Show validation error inline
                    if let error = nameValidationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(error)
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Description input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                    
                    TextEditor(text: $description)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.text)
                        .padding(8)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("BackgroundColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isDescriptionFocused ? Color("GrowthGreen") : Color.gray.opacity(0.2), lineWidth: 2)
                                )
                        )
                        .focused($isDescriptionFocused)
                }
            }
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
    
    private func validateNameWithDebounce() {
        // Cancel any existing validation
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        // Debounce for 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if shareWithCommunity && !name.isEmpty {
                validateRoutineName()
            }
        }
    }
    
    private func validateRoutineName() {
        isCheckingName = true
        nameValidationError = nil
        
        Task {
            do {
                let nameExists = try await RoutineService.shared.checkCommunityRoutineNameExists(name: name)
                
                await MainActor.run {
                    isCheckingName = false
                    
                    if nameExists {
                        nameValidationError = "This name is already taken. Try adding your username or a unique identifier."
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingName = false
                    // Don't show error for network issues during typing
                }
            }
        }
    }
}

struct DifficultySelectionView: View {
    @Binding var selectedDifficulty: RoutineDifficulty
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What's your experience level?")
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(AppTheme.Colors.text)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                ForEach(RoutineDifficulty.allCases, id: \.self) { difficulty in
                    DifficultyCard(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        action: {
                            selectedDifficulty = difficulty
                        }
                    )
                }
            }
        }
        .padding()
    }
}

struct DifficultyCard: View {
    let difficulty: RoutineDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Animated icon
                ZStack {
                    // Background gradient
                    Circle()
                        .fill(
                            isSelected ? 
                            LinearGradient(
                                colors: [Color("GrowthGreen"), Color("BrightTeal")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : 
                            LinearGradient(
                                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: difficulty.icon)
                        .font(AppTheme.Typography.title2Font())
                        .foregroundColor(isSelected ? .white : AppTheme.Colors.text.opacity(0.6))
                        .scaleEffect(isSelected ? 1.1 : 1)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(difficulty.rawValue.capitalized)
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text(difficulty.description)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                        .multilineTextAlignment(.leading)
                    
                    // Difficulty indicator dots
                    HStack(spacing: 4) {
                        ForEach(0..<difficulty.level, id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? Color("GrowthGreen") : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                        ForEach(difficulty.level..<3, id: \.self) { _ in
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.Typography.title2Font())
                        .foregroundColor(Color("GrowthGreen"))
                }
            }
            .padding()
            .background(
                ZStack {
                    // Neumorphic effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("BackgroundColor"))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 5, y: 5)
                        .shadow(color: Color("BackgroundColor").opacity(0.7), radius: 10, x: -5, y: -5)
                    
                    // Border overlay
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? 
                            LinearGradient(
                                colors: [Color("GrowthGreen"), Color("BrightTeal")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : 
                            LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

extension RoutineDifficulty {
    var level: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

struct DurationSelectionView: View {
    @Binding var selectedDuration: Int
    @Binding var selectedSchedulingType: RoutineSchedulingType
    @State private var showingCustomDurationPicker = false
    @State private var useCustomDuration = false
    let durations = [7, 14, 21, 28]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How long is your journey?")
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(AppTheme.Colors.text)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(durations, id: \.self) { duration in
                    DurationCard(
                        duration: duration,
                        isSelected: selectedDuration == duration && !useCustomDuration,
                        action: {
                            useCustomDuration = false
                            selectedDuration = duration
                        }
                    )
                }
            }
            
            // Custom duration card
            Button {
                showingCustomDurationPicker = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(useCustomDuration ? .white : Color("GrowthGreen"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Duration")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(useCustomDuration ? .white : AppTheme.Colors.text)
                        
                        if useCustomDuration {
                            Text("\(selectedDuration) days")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Set your own journey length")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(useCustomDuration ? .white : AppTheme.Colors.textSecondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(useCustomDuration ? Color("GrowthGreen") : Color("BackgroundColor"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(useCustomDuration ? Color.clear : Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: useCustomDuration ? Color("GrowthGreen").opacity(0.2) : .black.opacity(0.05), 
                               radius: useCustomDuration ? 10 : 5)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showingCustomDurationPicker) {
                CustomRoutineDurationPicker(
                    numberOfDays: $selectedDuration,
                    onConfirm: {
                        useCustomDuration = true
                    }
                )
            }
            
            // Visual timeline
            TimelineVisualization(duration: selectedDuration)
                .padding(.top)
            
            // Scheduling Type Selection
            VStack(spacing: 16) {
                Text("Scheduling Type")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(AppTheme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    // Sequential option
                    Button {
                        selectedSchedulingType = .sequential
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(selectedSchedulingType == .sequential ? .white : Color("GrowthGreen"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(RoutineSchedulingType.sequential.displayName)
                                    .font(AppTheme.Typography.gravitySemibold(16))
                                    .foregroundColor(selectedSchedulingType == .sequential ? .white : AppTheme.Colors.text)
                                
                                Text(RoutineSchedulingType.sequential.description)
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(selectedSchedulingType == .sequential ? .white.opacity(0.8) : AppTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            if selectedSchedulingType == .sequential {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedSchedulingType == .sequential ? Color("GrowthGreen") : Color("BackgroundColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedSchedulingType == .sequential ? Color.clear : Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Weekday-based option
                    Button {
                        selectedSchedulingType = .weekday
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(selectedSchedulingType == .weekday ? .white : Color("GrowthGreen"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(RoutineSchedulingType.weekday.displayName)
                                    .font(AppTheme.Typography.gravitySemibold(16))
                                    .foregroundColor(selectedSchedulingType == .weekday ? .white : AppTheme.Colors.text)
                                
                                Text(RoutineSchedulingType.weekday.description)
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(selectedSchedulingType == .weekday ? .white.opacity(0.8) : AppTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            if selectedSchedulingType == .weekday {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedSchedulingType == .weekday ? Color("GrowthGreen") : Color("BackgroundColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedSchedulingType == .weekday ? Color.clear : Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.top)
        }
        .padding()
    }
}

struct DurationCard: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(duration)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? Color("GrowthGreen") : AppTheme.Colors.text)
                
                Text("Days")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                
                Text("\(duration / 7) weeks")
                    .font(AppTheme.Typography.footnoteFont())
                    .foregroundColor(AppTheme.Colors.text.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color("GrowthGreen") : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color("GrowthGreen").opacity(0.2) : .black.opacity(0.05), 
                           radius: isSelected ? 10 : 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct TimelineVisualization: View {
    let duration: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Your Timeline")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.text.opacity(0.7))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background line
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress indicators
                    HStack(spacing: 0) {
                        ForEach(0..<duration, id: \.self) { day in
                            Rectangle()
                                .fill(day % 4 == 3 ? AppTheme.Colors.errorColor : Color("GrowthGreen"))
                                .frame(width: geometry.size.width / CGFloat(duration), height: 4)
                        }
                    }
                }
            }
            .frame(height: 4)
            
            HStack {
                Label("Training Days", systemImage: "circle.fill")
                    .font(AppTheme.Typography.footnoteFont())
                    .foregroundColor(Color("GrowthGreen"))
                
                Spacer()
                
                Label("Rest Days", systemImage: "circle.fill")
                    .font(AppTheme.Typography.footnoteFont())
                    .foregroundColor(AppTheme.Colors.errorColor)
            }
        }
    }
}

struct PremiumMethodSelectionView: View {
    @Binding var selectedMethods: [GrowthMethod]
    @Binding var methodSchedulingConfigs: [String: MethodSchedulingConfig]
    @StateObject private var methodsLoader = MethodsLoader()
    @State private var searchText = ""
    @State private var expandedMethodId: String? = nil
    let duration: Int
    let schedulingType: RoutineSchedulingType
    
    init(selectedMethods: Binding<[GrowthMethod]>, duration: Int = 14, schedulingType: RoutineSchedulingType, methodSchedulingConfigs: Binding<[String: MethodSchedulingConfig]>) {
        self._selectedMethods = selectedMethods
        self._methodSchedulingConfigs = methodSchedulingConfigs
        self.duration = duration
        self.schedulingType = schedulingType
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Choose your methods")
                    .font(AppTheme.Typography.title3Font())
                    .foregroundColor(AppTheme.Colors.text)
                    .multilineTextAlignment(.center)
                
                Text(schedulingType == .weekday 
                    ? "Select which days of the week each method should occur"
                    : "Choose how often each method should repeat")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.text.opacity(0.4))
                
                TextField("Search methods", text: $searchText)
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.text)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("BackgroundColor"))
                    .shadow(color: .black.opacity(0.05), radius: 5)
            )
            
            // Selected methods count
            if !selectedMethods.isEmpty {
                HStack {
                    Text("\(selectedMethods.count) methods selected")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                    
                    Spacer()
                    
                    Button("Clear All") {
                        withAnimation {
                            selectedMethods.removeAll()
                            methodSchedulingConfigs.removeAll()
                            expandedMethodId = nil
                        }
                    }
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.errorColor)
                }
            }
            
            // Methods list with pagination for memory efficiency
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredMethods.prefix(20), id: \.id) { method in
                        if let methodId = method.id {
                            EnhancedMethodSelectionCard(
                                method: method,
                                isSelected: selectedMethods.contains(where: { $0.id == methodId }),
                                isExpanded: expandedMethodId == methodId,
                                schedulingConfig: methodSchedulingConfigs[methodId] ?? MethodSchedulingConfig(methodId: methodId, duration: method.estimatedDurationMinutes ?? 20),
                                duration: duration,
                                schedulingType: schedulingType,
                                onToggle: {
                                    toggleMethod(method)
                                },
                                onSchedulingUpdate: { config in
                                    methodSchedulingConfigs[methodId] = config
                                },
                                onDeselect: selectedMethods.contains(where: { $0.id == methodId }) ? {
                                    deselectMethod(method)
                                } : nil
                            )
                        }
                    }
                    
                    if filteredMethods.count > 20 {
                        Text("\(filteredMethods.count - 20) more methods available. Use search to find specific methods.")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.text.opacity(0.6))
                            .padding()
                    }
                }
            }
        }
        .padding()
        .onAppear {
            methodsLoader.loadMethods()
        }
        .onDisappear {
            // Clear expanded state to free memory
            expandedMethodId = nil
            searchText = ""
            // Clear methods to free memory
            methodsLoader.clearMethods()
        }
    }
    
    private var filteredMethods: [GrowthMethod] {
        if searchText.isEmpty {
            return methodsLoader.methods
        } else {
            return methodsLoader.methods.filter { method in
                method.title.localizedCaseInsensitiveContains(searchText) ||
                method.methodDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func toggleMethod(_ method: GrowthMethod) {
        guard let methodId = method.id else { return }
        
        if selectedMethods.contains(where: { $0.id == methodId }) {
            // Method is already selected
            if expandedMethodId == methodId {
                // If it's expanded, collapse it
                expandedMethodId = nil
            } else {
                // If it's not expanded, expand it (don't deselect)
                expandedMethodId = methodId
            }
        } else {
            // Method is not selected, add it and expand
            selectedMethods.append(method)
            expandedMethodId = methodId
            // Initialize scheduling config with smart defaults based on scheduling type
            if schedulingType == .weekday {
                // For weekday-based: Default to weekdays (Mon-Fri)
                methodSchedulingConfigs[methodId] = MethodSchedulingConfig(
                    methodId: methodId,
                    selectedDays: [2, 3, 4, 5, 6], // Monday through Friday
                    frequency: .custom,
                    duration: method.estimatedDurationMinutes ?? 20
                )
            } else {
                // For sequential: Default to every day
                methodSchedulingConfigs[methodId] = MethodSchedulingConfig(
                    methodId: methodId,
                    selectedDays: [],
                    frequency: .everyDay,
                    duration: method.estimatedDurationMinutes ?? 20
                )
            }
        }
    }
    
    private func deselectMethod(_ method: GrowthMethod) {
        guard let methodId = method.id else { return }
        
        if let index = selectedMethods.firstIndex(where: { $0.id == methodId }) {
            selectedMethods.remove(at: index)
            methodSchedulingConfigs.removeValue(forKey: methodId)
            if expandedMethodId == methodId {
                expandedMethodId = nil
            }
        }
    }
}

struct MethodSelectionCard: View {
    let method: GrowthMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Method icon/stage
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color("GrowthGreen") : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text("S\(method.stage)")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(isSelected ? .white : AppTheme.Colors.text.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(AppTheme.Typography.gravityBoldFont(AppTheme.Typography.body))
                        .foregroundColor(AppTheme.Colors.text)
                        .multilineTextAlignment(.leading)
                    
                    Text(method.methodDescription)
                        .font(AppTheme.Typography.footnoteFont())
                        .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Label("\(method.estimatedDurationMinutes ?? 20) min", systemImage: "clock")
                            .font(AppTheme.Typography.footnoteFont())
                            .foregroundColor(AppTheme.Colors.text.opacity(0.5))
                        
                        if let classification = method.classification {
                            Text("• \(classification)")
                                .font(AppTheme.Typography.footnoteFont())
                                .foregroundColor(AppTheme.Colors.text.opacity(0.5))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(isSelected ? Color("GrowthGreen") : Color.gray.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color("GrowthGreen") : Color.clear, lineWidth: 1)
                    )
                    .shadow(color: isSelected ? Color("GrowthGreen").opacity(0.1) : .black.opacity(0.05), 
                           radius: isSelected ? 8 : 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct EnhancedMethodSelectionCard: View {
    let method: GrowthMethod
    let isSelected: Bool
    let isExpanded: Bool
    let schedulingConfig: MethodSchedulingConfig
    let duration: Int
    let schedulingType: RoutineSchedulingType
    let onToggle: () -> Void
    let onSchedulingUpdate: (MethodSchedulingConfig) -> Void
    let onDeselect: (() -> Void)?
    
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]
    private let fullDaysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card
            Button(action: onToggle) {
                HStack(spacing: 16) {
                    // Method icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color("GrowthGreen") : Color.gray.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Text("S\(method.stage)")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(isSelected ? .white : AppTheme.Colors.text.opacity(0.6))
                    }
                    
                    // Method info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(method.title)
                            .font(AppTheme.Typography.gravityBoldFont(AppTheme.Typography.body))
                            .foregroundColor(AppTheme.Colors.text)
                            .multilineTextAlignment(.leading)
                        
                        Text(method.methodDescription)
                            .font(AppTheme.Typography.footnoteFont())
                            .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        // Show duration and schedule preview if method is selected
                        if isSelected {
                            HStack(spacing: 12) {
                                // Duration
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(Color("GrowthGreen"))
                                    
                                    Text("\(schedulingConfig.duration) min")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(Color("GrowthGreen"))
                                }
                                
                                // Schedule preview
                                HStack(spacing: 4) {
                                    Image(systemName: schedulingType == .weekday ? "calendar" : "arrow.right")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(Color("GrowthGreen"))
                                    
                                    if schedulingType == .weekday && !schedulingConfig.selectedDays.isEmpty {
                                        let dayAbbreviations = schedulingConfig.selectedDays.sorted().map { 
                                            String(fullDaysOfWeek[$0 - 1].prefix(3)) 
                                        }
                                        Text(dayAbbreviations.joined(separator: ", "))
                                            .font(AppTheme.Typography.captionFont())
                                            .foregroundColor(Color("GrowthGreen"))
                                    } else if schedulingType == .sequential {
                                        Text(schedulingConfig.frequency.rawValue)
                                            .font(AppTheme.Typography.captionFont())
                                            .foregroundColor(Color("GrowthGreen"))
                                    }
                                }
                            }
                        } else {
                            // Show default duration for unselected methods
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Text("\(method.estimatedDurationMinutes ?? 20) min")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(AppTheme.Typography.title2Font())
                        .foregroundColor(isSelected ? Color("GrowthGreen") : Color.gray.opacity(0.3))
                }
                .padding()
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Expansion area
            if isExpanded && isSelected {
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal)
                    
                    // Show different options based on scheduling type
                    if schedulingType == .weekday {
                        // Weekday-based: Show only day selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select days of the week")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                            
                            HStack(spacing: 8) {
                                ForEach(0..<7) { dayIndex in
                                    DayToggle(
                                        day: fullDaysOfWeek[dayIndex],
                                        dayNumber: dayIndex + 1,
                                        isSelected: schedulingConfig.selectedDays.contains(dayIndex + 1),
                                        onToggle: {
                                            var updatedConfig = schedulingConfig
                                            if updatedConfig.selectedDays.contains(dayIndex + 1) {
                                                updatedConfig.selectedDays.remove(dayIndex + 1)
                                            } else {
                                                updatedConfig.selectedDays.insert(dayIndex + 1)
                                            }
                                            updatedConfig.frequency = .custom
                                            onSchedulingUpdate(updatedConfig)
                                        }
                                    )
                                }
                            }
                            
                            // Show preview of selected days
                            if !schedulingConfig.selectedDays.isEmpty {
                                let selectedDayNames = schedulingConfig.selectedDays.sorted().map { fullDaysOfWeek[$0 - 1] }
                                Text("This method will appear on: \(selectedDayNames.joined(separator: ", "))")
                                    .font(AppTheme.Typography.footnoteFont())
                                    .foregroundColor(Color("GrowthGreen"))
                                    .italic()
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Sequential: Show only frequency options
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How often should this method repeat?")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                            
                            // Simplified frequency selector
                            VStack(spacing: 8) {
                                ForEach(MethodSchedulingConfig.ScheduleFrequency.allCases.filter { $0 != .custom }, id: \.self) { frequency in
                                    Button {
                                        var updatedConfig = schedulingConfig
                                        updatedConfig.frequency = frequency
                                        updatedConfig.selectedDays.removeAll()
                                        onSchedulingUpdate(updatedConfig)
                                    } label: {
                                        HStack {
                                            Text(frequency.rawValue)
                                                .font(AppTheme.Typography.bodyFont())
                                                .foregroundColor(schedulingConfig.frequency == frequency ? .white : AppTheme.Colors.text)
                                            
                                            Spacer()
                                            
                                            if schedulingConfig.frequency == frequency {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(AppTheme.Typography.captionFont())
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(schedulingConfig.frequency == frequency ? Color("GrowthGreen") : Color("BackgroundColor"))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                            
                            // Show preview of frequency
                            Text("This method will repeat \(schedulingConfig.frequency.rawValue.lowercased())")
                                .font(AppTheme.Typography.footnoteFont())
                                .foregroundColor(Color("GrowthGreen"))
                                .italic()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Duration selector
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                            
                            Spacer()
                            
                            if schedulingConfig.duration == (method.estimatedDurationMinutes ?? 20) {
                                Text("(recommended)")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(Color("GrowthGreen").opacity(0.7))
                            }
                        }
                        
                        CompactDurationPicker(
                            duration: schedulingConfig.duration,
                            onDurationChange: { newDuration in
                                var updatedConfig = schedulingConfig
                                updatedConfig.duration = newDuration
                                onSchedulingUpdate(updatedConfig)
                            }
                        )
                    }
                    .padding(.horizontal)
                    
                    // Deselect button
                    if let onDeselect = onDeselect {
                        Button(action: onDeselect) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Remove Method")
                            }
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(Color.red)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("BackgroundColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color("GrowthGreen") : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: isSelected ? Color("GrowthGreen").opacity(0.1) : .black.opacity(0.05), 
                radius: isSelected ? 8 : 5)
    }
}

struct DayToggle: View {
    let day: String
    let dayNumber: Int
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 4) {
                Text(day)
                    .font(AppTheme.Typography.captionFont())
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.text)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.text.opacity(0.3))
            }
            .frame(width: 40, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color("GrowthGreen") : Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.clear : Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CompactDurationPicker: View {
    let duration: Int
    let onDurationChange: (Int) -> Void
    
    private let presetDurations = [5, 10, 15, 20, 25, 30, 45, 60]
    @State private var showCustomInput = false
    @State private var customDurationText = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Current duration display
            HStack {
                Image(systemName: "clock")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("\(duration) minutes")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("GrowthGreen"))
                
                Spacer()
                
                Button("Custom") {
                    customDurationText = "\(duration)"
                    showCustomInput.toggle()
                }
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(Color("GrowthGreen"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("GrowthGreen").opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Quick preset selector - horizontal scrollable
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presetDurations, id: \.self) { preset in
                        Button {
                            onDurationChange(preset)
                        } label: {
                            Text("\(preset)m")
                                .font(AppTheme.Typography.captionFont())
                                .fontWeight(.medium)
                                .foregroundColor(duration == preset ? .white : AppTheme.Colors.text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(duration == preset ? Color("GrowthGreen") : Color("BackgroundColor"))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Custom input field (shown when Custom is tapped)
            if showCustomInput {
                HStack {
                    TextField("Minutes", text: $customDurationText)
                        .keyboardType(.numberPad)
                        .font(AppTheme.Typography.bodyFont())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    
                    Button("Set") {
                        if let customDuration = Int(customDurationText), 
                           customDuration > 0, 
                           customDuration <= 180 {
                            onDurationChange(customDuration)
                            showCustomInput = false
                        }
                    }
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("GrowthGreen"))
                    .cornerRadius(6)
                    .disabled(Int(customDurationText) == nil || Int(customDurationText) ?? 0 <= 0)
                    
                    Button("Cancel") {
                        showCustomInput = false
                    }
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCustomInput)
    }
}

struct ScheduleCustomizationView: View {
    @Binding var daySchedules: [DaySchedule]
    let selectedMethods: [GrowthMethod]
    let duration: Int
    let schedulingType: RoutineSchedulingType
    let onScheduleUpdate: () -> Void
    @State private var editingDay: DaySchedule?
    @StateObject private var methodsViewModel = MethodSelectionViewModel()
    
    private func getAllAvailableMethodIds() -> [String] {
        // If we have loaded all methods, use them
        if !methodsViewModel.methods.isEmpty {
            return methodsViewModel.methods.compactMap { $0.id }
        }
        // Otherwise use the selected methods as a fallback
        return selectedMethods.compactMap { $0.id }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 50))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("Customize Your Schedule")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("Adjust methods and duration for each day")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Day cards
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(daySchedules.indices, id: \.self) { index in
                        DayScheduleEditCard(
                            daySchedule: daySchedules[index],
                            schedulingType: schedulingType,
                            onTap: {
                                editingDay = daySchedules[index]
                            }
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .onAppear {
            // Load all available methods when the view appears
            methodsViewModel.loadMethods()
        }
        .sheet(item: $editingDay) { day in
            EditDayScheduleView(
                daySchedule: day,
                availableMethods: getAllAvailableMethodIds(),
                onSave: { updatedDay in
                    if let index = daySchedules.firstIndex(where: { $0.id == updatedDay.id }) {
                        daySchedules[index] = updatedDay
                        onScheduleUpdate()
                    }
                }
            )
        }
    }
}

struct DayScheduleEditCard: View {
    let daySchedule: DaySchedule
    let schedulingType: RoutineSchedulingType
    let onTap: () -> Void
    
    private var totalDuration: Int {
        daySchedule.methods.reduce(0) { $0 + $1.duration }
    }
    
    private var dayLabel: String {
        if schedulingType == .weekday {
            let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            let index = (daySchedule.day - 1) % 7
            return weekdays[index]
        } else {
            return daySchedule.dayName
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Day number circle
                ZStack {
                    Circle()
                        .fill(daySchedule.isRestDay ? Color.purple.opacity(0.2) : Color("GrowthGreen").opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if schedulingType == .weekday {
                        Text(String(dayLabel.prefix(3)))
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(daySchedule.isRestDay ? Color.purple : Color("GrowthGreen"))
                    } else {
                        Text("\(daySchedule.day)")
                            .font(AppTheme.Typography.gravitySemibold(18))
                            .foregroundColor(daySchedule.isRestDay ? Color.purple : Color("GrowthGreen"))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayLabel)
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    if daySchedule.isRestDay {
                        Text("Rest Day")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(Color.purple)
                    } else if !daySchedule.methods.isEmpty {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(AppTheme.Typography.captionFont())
                                Text("\(daySchedule.methods.count) methods")
                                    .font(AppTheme.Typography.captionFont())
                            }
                            .foregroundColor(Color("GrowthGreen"))
                            
                            Text("•")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(AppTheme.Typography.captionFont())
                                Text("\(totalDuration) min")
                                    .font(AppTheme.Typography.captionFont())
                            }
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    } else {
                        Text("Tap to add methods")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("BackgroundColor"))
                    .shadow(color: .black.opacity(0.05), radius: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ReviewStepView: View {
    let name: String
    let description: String
    let difficulty: RoutineDifficulty
    let duration: Int
    let methods: [GrowthMethod]
    let daySchedules: [DaySchedule]
    let schedulingType: RoutineSchedulingType
    @Binding var shareWithCommunity: Bool
    let currentUser: User?
    let onUsernameRequired: () -> Void
    @Binding var nameValidationError: String?
    @Binding var isCheckingName: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen").opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            Text("Ready to Create!")
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(AppTheme.Colors.text)
            
            // Summary cards
            VStack(spacing: 16) {
                SummaryCard(title: "Name", value: name, icon: "pencil")
                
                if !description.isEmpty {
                    SummaryCard(title: "Description", value: description, icon: "text.alignleft")
                }
                
                SummaryCard(title: "Difficulty", value: difficulty.rawValue.capitalized, icon: "chart.line.uptrend.xyaxis")
                
                SummaryCard(title: "Duration", value: "\(duration) days", icon: "calendar")
                
                SummaryCard(title: "Scheduling", value: schedulingType.displayName, icon: schedulingType == .sequential ? "arrow.right.circle" : "calendar.circle")
                
                SummaryCard(title: "Methods", value: "\(methods.count) selected", icon: "list.bullet")
                
                // Schedule summary
                if !daySchedules.isEmpty {
                    let trainingDays = daySchedules.filter { !$0.isRestDay }.count
                    let totalMinutes = daySchedules.reduce(0) { sum, day in
                        sum + day.methods.reduce(0) { $0 + $1.duration }
                    }
                    SummaryCard(title: "Schedule", value: "\(trainingDays) training days, \(totalMinutes) total minutes", icon: "calendar.badge.clock")
                }
            }
            
            // Community sharing toggle
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(AppTheme.Typography.title3Font())
                        .foregroundColor(Color("GrowthGreen"))
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share with Community")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Text("Allow other users to discover and use your routine")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $shareWithCommunity)
                        .tint(Color("GrowthGreen"))
                        .disabled(isCheckingName)
                        .onChangeCompat(of: shareWithCommunity) { newValue in
                            if newValue {
                                validateRoutineName()
                            } else {
                                nameValidationError = nil
                            }
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("BackgroundColor"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(shareWithCommunity ? Color("GrowthGreen").opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                )
                
                // Username requirement notice
                if shareWithCommunity && currentUser?.username == nil {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username Required")
                                .font(AppTheme.Typography.gravitySemibold(14))
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Text("You'll need to create a username to share with the community")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button("Create") {
                            onUsernameRequired()
                        }
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(Color("GrowthGreen"))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            
            // Methods preview
            if !methods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Methods")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(methods, id: \.id) { method in
                                MethodChip(method: method)
                            }
                        }
                    }
                }
            }
            
            // Show name validation error if exists
            if let error = nameValidationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
            }
            
            // Show loading indicator when checking
            if isCheckingName {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Checking name availability...")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                }
            }
        }
        .padding()
    }
    
    private func validateRoutineName() {
        isCheckingName = true
        nameValidationError = nil
        
        Task {
            do {
                let nameExists = try await RoutineService.shared.checkCommunityRoutineNameExists(name: name)
                
                await MainActor.run {
                    isCheckingName = false
                    
                    if nameExists {
                        nameValidationError = "A community routine with this name already exists. Please choose a unique name."
                        shareWithCommunity = false
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingName = false
                    nameValidationError = "Unable to verify name. Please try again."
                    shareWithCommunity = false
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(Color("GrowthGreen"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.text.opacity(0.7))
                
                Text(value)
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.text)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("BackgroundColor"))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

struct MethodChip: View {
    let method: GrowthMethod
    
    var body: some View {
        Text(method.title)
            .font(AppTheme.Typography.footnoteFont())
            .foregroundColor(Color("GrowthGreen"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color("GrowthGreen").opacity(0.1))
            )
    }
}


// MARK: - Helper Views and Extensions

extension RoutineDifficulty {
    var icon: String {
        switch self {
        case .beginner: return "figure.walk"
        case .intermediate: return "figure.run"
        case .advanced: return "figure.climbing"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "New to growth training"
        case .intermediate: return "Some experience with methods"
        case .advanced: return "Experienced practitioner"
        }
    }
}

// Methods Loader
class MethodsLoader: ObservableObject {
    @Published var methods: [GrowthMethod] = []
    @Published var isLoading = false
    private let growthMethodService = GrowthMethodService.shared
    private var loadTask: DispatchWorkItem?
    
    deinit {
        loadTask?.cancel()
        methods.removeAll()
    }
    
    func loadMethods() {
        // Cancel any existing load task
        loadTask?.cancel()
        
        isLoading = true
        
        let task = DispatchWorkItem { [weak self] in
            self?.growthMethodService.fetchAllMethods { result in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch result {
                    case .success(let methods):
                        self.methods = methods.sorted { $0.stage < $1.stage }
                    case .failure(let error):
                        Logger.error("Error loading methods: \(error)")
                        self.methods = []
                    }
                }
            }
        }
        
        loadTask = task
        DispatchQueue.global(qos: .userInitiated).async(execute: task)
    }
    
    func clearMethods() {
        loadTask?.cancel()
        methods.removeAll()
    }
}

// Preview
struct PremiumCreateCustomRoutineView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumCreateCustomRoutineView()
    }
}