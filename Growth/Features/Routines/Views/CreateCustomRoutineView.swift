//
//  CreateCustomRoutineView.swift
//  Growth
//
//  Created by Developer on 6/9/25.
//

import SwiftUI
import Firebase
import Foundation  // For Logger

struct CreateCustomRoutineView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateCustomRoutineViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var methodsViewModel = MethodSelectionViewModel()
    
    @State private var routineName = ""
    @State private var routineDescription = ""
    @State private var selectedDifficulty = "Beginner"
    @State private var numberOfDays = 7
    @State private var selectedMethods: Set<String> = []
    @State private var daySchedules: [DaySchedule] = []
    @State private var showingMethodSelection = false
    @State private var editingDay: DaySchedule?
    @State private var showingSaveConfirmation = false
    @State private var saveError: String?
    @State private var shareWithCommunity = false
    @State private var showingCustomDurationPicker = false
    @State private var customDurationText = ""
    @State private var useCustomDuration = false
    @State private var selectedSchedulingType: RoutineSchedulingType = .sequential
    
    let difficulties = ["Beginner", "Intermediate", "Advanced"]
    let dayOptions = [7, 14, 21, 28]
    
    private func getAllAvailableMethodIds() -> [String] {
        // If we have loaded all methods, use them
        if !methodsViewModel.methods.isEmpty {
            return methodsViewModel.methods.compactMap { $0.id }
        }
        // Otherwise use the selected methods as a fallback
        return Array(selectedMethods)
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Basic Info Section
                    basicInfoSection
                    
                    // Difficulty Section
                    difficultySection
                    
                    // Duration Section
                    durationSection
                    
                    // Scheduling Type Section
                    schedulingTypeSection
                    
                    // Schedule Builder Section
                    scheduleBuilderSection
                    
                    // Contextual help section
                    contextualHelpSection
                    
                    // Community Sharing Option
                    communityShareSection
                    
                    // Save Button
                    saveButton
                }
                .padding()
            }
            .background(Color("GrowthBackgroundLight"))
            .navigationTitle("Create Custom Routine")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
        .onAppear {
            // Load all available methods when the view appears
            methodsViewModel.loadMethods()
        }
        .storeKit2FeatureGated("customRoutines")
        .sheet(isPresented: $showingMethodSelection) {
            LegacyMethodSelectionView(selectedMethods: $selectedMethods)
        }
        .sheet(item: $editingDay) { day in
            EditDayScheduleView(
                daySchedule: day,
                availableMethods: getAllAvailableMethodIds(),
                onSave: { updatedDay in
                    Logger.debug("=== Saving day \(updatedDay.day) (ID: \(updatedDay.id)) ===")
                    Logger.debug("Updated day has \(updatedDay.methods.count) methods:")
                    for method in updatedDay.methods {
                        Logger.debug("  - Method: \(method.methodId), Duration: \(method.duration)")
                    }
                    
                    // Store the current state before update for comparison
                    let beforeUpdate = daySchedules.map { day in
                        (day: day.day, id: day.id, methodCount: day.methods.count)
                    }
                    
                    // Create a new array with the updated day
                    // IMPORTANT: Create complete new instances to avoid any reference sharing
                    daySchedules = daySchedules.map { existingDay in
                        if existingDay.id == updatedDay.id {
                            Logger.debug("Updating day \(existingDay.day) (ID match: \(existingDay.id) == \(updatedDay.id))")
                            // Create a completely new DaySchedule instance
                            var newDay = DaySchedule(
                                day: updatedDay.day,
                                isRestDay: updatedDay.isRestDay,
                                methods: updatedDay.methods.map { m in
                                    MethodSchedule(
                                        methodId: m.methodId,
                                        duration: m.duration,
                                        order: m.order
                                    )
                                },
                                notes: updatedDay.notes
                            )
                            newDay.id = updatedDay.id
                            newDay.description = updatedDay.description
                            return newDay
                        } else {
                            Logger.debug("Keeping day \(existingDay.day) unchanged (ID: \(existingDay.id) != \(updatedDay.id))")
                            // Also create a new instance for unchanged days to ensure complete isolation
                            var copyDay = DaySchedule(
                                day: existingDay.day,
                                isRestDay: existingDay.isRestDay,
                                methods: existingDay.methods.map { m in
                                    MethodSchedule(
                                        methodId: m.methodId,
                                        duration: m.duration,
                                        order: m.order
                                    )
                                },
                                notes: existingDay.notes
                            )
                            copyDay.id = existingDay.id
                            copyDay.description = existingDay.description
                            return copyDay
                        }
                    }
                    
                    // Compare before and after
                    Logger.debug("\n=== BEFORE vs AFTER comparison ===")
                    for i in 0..<min(beforeUpdate.count, daySchedules.count) {
                        let before = beforeUpdate[i]
                        let after = daySchedules[i]
                        Logger.debug("Day \(after.day):")
                        Logger.debug("  Before: \(before.methodCount) methods")
                        Logger.debug("  After: \(after.methods.count) methods")
                        if before.methodCount != after.methods.count {
                            Logger.debug("  ⚠️ CHANGED!")
                        }
                    }
                    
                    Logger.debug("\nDay schedules after update:")
                    for (idx, schedule) in daySchedules.enumerated() {
                        Logger.debug("  Day \(schedule.day) (index \(idx), id: \(schedule.id)):")
                        Logger.debug("    - Is Rest Day: \(schedule.isRestDay)")
                        Logger.debug("    - Methods: \(schedule.methods.count)")
                        for method in schedule.methods {
                            Logger.debug("      * \(method.methodId) (\(method.duration) min)")
                        }
                    }
                    
                    // CRITICAL CHECK: Verify no duplicate method IDs across different days
                    Logger.debug("\n=== METHOD UNIQUENESS CHECK ===")
                    var allMethodIds: [String] = []
                    for (_, schedule) in daySchedules.enumerated() {
                        Logger.debug("Day \(schedule.day) has \(schedule.methods.count) methods")
                        for method in schedule.methods {
                            allMethodIds.append(method.id)
                        }
                    }
                    
                    // Since arrays are value types in Swift, they are automatically copied
                    // We can verify uniqueness by checking if methods were properly deep copied
                    let uniqueMethodIds = Set(allMethodIds)
                    if uniqueMethodIds.count == allMethodIds.count {
                        Logger.debug("✅ All method instances have unique IDs (proper deep copy)")
                    } else {
                        Logger.warning("⚠️ WARNING: Duplicate method IDs found (may indicate shallow copy)")
                    }
                }
            )
            .onDisappear {
                Logger.debug("=== EditDayScheduleView disappeared ===")
                Logger.debug("Current state of all days:")
                for (idx, day) in daySchedules.enumerated() {
                    Logger.debug("  Day \(day.day) (index \(idx)): \(day.methods.count) methods")
                }
            }
        }
        .alert("Routine Created!", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your custom routine has been created successfully.")
        }
        .alert("Error", isPresented: .constant(saveError != nil)) {
            Button("OK") {
                saveError = nil
            }
        } message: {
            if let error = saveError {
                Text(error)
            }
        }
        .onAppear {
            generateInitialSchedule()
        }
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(spacing: 12) {
                // Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Routine Name")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextField("My Custom Routine", text: $routineName)
                        .font(AppTheme.Typography.bodyFont())
                        .padding()
                        .background(Color("BackgroundColor"))
                        .cornerRadius(12)
                }
                
                // Description Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextEditor(text: $routineDescription)
                        .font(AppTheme.Typography.bodyFont())
                        .frame(height: 80)
                        .padding(8)
                        .background(Color("BackgroundColor"))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Difficulty Level")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(AppTheme.Colors.text)
            
            HStack(spacing: 12) {
                ForEach(difficulties, id: \.self) { difficulty in
                    DifficultyOption(
                        title: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        color: difficultyColor(for: difficulty),
                        icon: difficultyIcon(for: difficulty)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Routine Duration")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(AppTheme.Colors.text)
            
            if selectedSchedulingType == .weekday {
                // For weekday-based scheduling, show an info message
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("GrowthGreen"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekday-based routines repeat weekly")
                                .font(AppTheme.Typography.subheadlineFont())
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Text("You'll create a 7-day weekly pattern that can be repeated indefinitely")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("BackgroundColor"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Optional: Show how many weeks this would be
                    if numberOfDays > 7 {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text("This pattern would run for \(Int(ceil(Double(numberOfDays) / 7.0))) weeks")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
            HStack(spacing: 12) {
                ForEach(dayOptions, id: \.self) { days in
                    DurationOption(
                        days: days,
                        isSelected: numberOfDays == days && !useCustomDuration
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            useCustomDuration = false
                            numberOfDays = days
                            updateSchedulingTypeForDuration(days)
                            generateInitialSchedule()
                        }
                    }
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
                            Text("\(numberOfDays) days")
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(useCustomDuration ? Color("GrowthGreen") : Color("BackgroundColor"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(useCustomDuration ? Color.clear : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showingCustomDurationPicker) {
                CustomRoutineDurationPicker(
                    numberOfDays: $numberOfDays,
                    onConfirm: {
                        withAnimation(.spring(response: 0.3)) {
                            useCustomDuration = true
                            updateSchedulingTypeForDuration(numberOfDays)
                            generateInitialSchedule()
                        }
                    }
                )
            }
            }
        }
    }
    
    private var schedulingTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Scheduling Type")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("Choose how your routine will be structured")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            VStack(spacing: 12) {
                // Sequential option
                SchedulingTypeCard(
                    type: .sequential,
                    isSelected: selectedSchedulingType == .sequential,
                    recommendedDuration: numberOfDays
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSchedulingType = .sequential
                        generateInitialSchedule()
                    }
                }
                
                // Weekday-based option
                SchedulingTypeCard(
                    type: .weekday,
                    isSelected: selectedSchedulingType == .weekday,
                    recommendedDuration: numberOfDays
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSchedulingType = .weekday
                        generateInitialSchedule()
                    }
                }
            }
        }
    }
    
    private var scheduleBuilderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(selectedSchedulingType == .weekday ? "Weekly Schedule" : "Routine Days")
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                Button {
                    showingMethodSelection = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Manage Methods")
                    }
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("GrowthGreen"))
                }
            }
            
            if selectedMethods.isEmpty {
                EmptyMethodsCard {
                    showingMethodSelection = true
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(daySchedules.indices, id: \.self) { index in
                        DayScheduleCard(
                            daySchedule: daySchedules[index],
                            schedulingType: selectedSchedulingType,
                            onEdit: {
                                let day = daySchedules[index]
                                Logger.debug("=== Opening edit for day \(day.day) (ID: \(day.id)) ===")
                                Logger.debug("Current methods: \(day.methods.count)")
                                for method in day.methods {
                                    Logger.debug("  - \(method.methodId)")
                                }
                                
                                // Create deep copy of methods
                                let methodsCopy = day.methods.map { method in
                                    MethodSchedule(
                                        methodId: method.methodId,
                                        duration: method.duration,
                                        order: method.order
                                    )
                                }
                                
                                var dayCopy = DaySchedule(
                                    day: day.day,
                                    isRestDay: day.isRestDay,
                                    methods: methodsCopy,
                                    notes: day.notes
                                )
                                // Explicitly set the ID and description after creation
                                dayCopy.id = day.id
                                dayCopy.description = day.description.isEmpty ? "Day \(day.day)" : day.description
                                
                                Logger.debug("Created copy with ID: \(dayCopy.id)")
                                Logger.debug("Original day has \(day.methods.count) methods")
                                Logger.debug("Copy has \(dayCopy.methods.count) methods")
                                
                                editingDay = dayCopy
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var contextualHelpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !selectedMethods.isEmpty && !daySchedules.isEmpty {
                VStack(spacing: 12) {
                    // Success message
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("GrowthGreen"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Routine Structure Ready!")
                                .font(AppTheme.Typography.gravitySemibold(14))
                                .foregroundColor(Color("GrowthGreen"))
                            
                            Text(getStructureDescription())
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("GrowthGreen").opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("GrowthGreen").opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // Tips based on scheduling type
                    if selectedSchedulingType == .weekday {
                        tipCard(
                            icon: "lightbulb.fill",
                            title: "Weekday Routine Tip",
                            description: "Your routine will repeat every week. Perfect for building consistent habits like 'Meditation Mondays' or 'Workout Wednesdays'.",
                            color: Color.orange
                        )
                    } else {
                        tipCard(
                            icon: "target",
                            title: "Sequential Routine Tip",
                            description: "Each day builds on the previous one. Great for challenges and progressive programs where order matters.",
                            color: Color.blue
                        )
                    }
                }
            }
        }
    }
    
    private func tipCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text(description)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func getStructureDescription() -> String {
        let methodCount = selectedMethods.count
        let dayCount = daySchedules.count
        
        if selectedSchedulingType == .weekday {
            return "Weekly routine with \(methodCount) methods across \(dayCount) weekdays"
        } else {
            return "\(dayCount)-day sequential routine with \(methodCount) methods"
        }
    }
    
    private var communityShareSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community Sharing")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(AppTheme.Colors.text)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Share with Community")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("Allow other users to discover and use your routine")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $shareWithCommunity)
                    .tint(Color("GrowthGreen"))
            }
            .padding()
            .background(Color("BackgroundColor"))
            .cornerRadius(12)
        }
    }
    
    private var saveButton: some View {
        Button {
            saveRoutine()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Create Routine")
            }
            .font(AppTheme.Typography.gravitySemibold(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, y: 4)
        }
        .disabled(routineName.isEmpty || routineDescription.isEmpty || selectedMethods.isEmpty)
        .opacity(routineName.isEmpty || routineDescription.isEmpty || selectedMethods.isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func updateSchedulingTypeForDuration(_ days: Int) {
        // Smart defaults based on duration
        let recommendedType: RoutineSchedulingType = days > 14 ? .sequential : .weekday
        
        // Only update if user hasn't explicitly selected a type yet, or if the current choice seems suboptimal
        let shouldUpdate = selectedSchedulingType == .sequential && days <= 7 || 
                          selectedSchedulingType == .weekday && days > 21
        
        if shouldUpdate {
            selectedSchedulingType = recommendedType
        }
    }
    
    private func generateInitialSchedule() {
        // Create a new array to ensure no reference issues
        let daysToCreate = selectedSchedulingType == .weekday ? 7 : numberOfDays
        let newSchedules = (1...daysToCreate).map { dayNumber in
            // For custom routines, let users decide which days are rest days
            let isRestDay = false
            let schedule = DaySchedule(
                day: dayNumber,
                isRestDay: isRestDay,
                methods: [], // Start with empty methods array
                notes: ""
            )
            Logger.debug("Generated day \(dayNumber) with ID: \(schedule.id)")
            return schedule
        }
        
        // Assign the new array
        daySchedules = newSchedules
        
        Logger.debug("=== Initial Schedule Generated ===")
        Logger.debug("Total days: \(daySchedules.count)")
        for (idx, day) in daySchedules.enumerated() {
            Logger.debug("  Day \(day.day) (index \(idx), id: \(day.id)) - methods: \(day.methods.count)")
        }
        
        // Verify uniqueness of IDs
        let allIds = daySchedules.map { $0.id }
        let uniqueIds = Set(allIds)
        if uniqueIds.count != daySchedules.count {
            Logger.warning("⚠️ WARNING: Duplicate IDs detected!")
            Logger.debug("All IDs: \(allIds)")
            Logger.debug("Unique IDs: \(uniqueIds)")
            
            // Fix duplicate IDs
            for (idx, day) in daySchedules.enumerated() {
                var updatedDay = day
                updatedDay.id = UUID().uuidString
                daySchedules[idx] = updatedDay
                Logger.debug("Regenerated ID for day \(day.day): \(updatedDay.id)")
            }
        }
    }
    
    private func saveRoutine() {
        // Debug: Print the schedule before saving
        Logger.debug("=== Saving Custom Routine ===")
        Logger.debug("Routine Name: \(routineName)")
        Logger.debug("Total Days: \(daySchedules.count)")
        for (index, day) in daySchedules.enumerated() {
            Logger.debug("Day \(day.day) (index \(index)):")
            Logger.debug("  - ID: \(day.id)")
            Logger.debug("  - Is Rest Day: \(day.isRestDay)")
            Logger.debug("  - Methods: \(day.methods.count)")
            for method in day.methods {
                Logger.debug("    - Method: \(method.methodId), Duration: \(method.duration) min")
            }
        }
        Logger.debug("========================")
        
        var customRoutine = Routine(
            id: "custom_\(UUID().uuidString)",
            name: routineName,
            description: routineDescription,
            difficultyLevel: selectedDifficulty,
            schedule: daySchedules,
            createdAt: Date(),
            updatedAt: Date(),
            startDate: nil
        )
        // Mark as custom routine
        customRoutine.isCustom = true
        customRoutine.schedulingType = selectedSchedulingType
        
        viewModel.saveCustomRoutine(customRoutine, shareWithCommunity: shareWithCommunity) { result in
            switch result {
            case .success:
                showingSaveConfirmation = true
            case .failure(let error):
                saveError = error.localizedDescription
            }
        }
    }
    
    private func difficultyColor(for level: String) -> Color {
        switch level {
        case "Beginner": return Color("MintGreen")
        case "Intermediate": return Color.orange
        case "Advanced": return Color.red
        default: return Color.gray
        }
    }
    
    private func difficultyIcon(for level: String) -> String {
        switch level {
        case "Beginner": return "leaf.fill"
        case "Intermediate": return "flame.fill"
        case "Advanced": return "bolt.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Supporting Views

struct DifficultyOption: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct DurationOption: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(days)")
                    .font(AppTheme.Typography.gravitySemibold(20))
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.text)
                
                Text("days")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("GrowthGreen") : Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct EmptyMethodsCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("Add methods to your routine")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .foregroundColor(Color("GrowthGreen").opacity(0.3))
            )
        }
    }
}

struct DayScheduleCard: View {
    let daySchedule: DaySchedule
    let schedulingType: RoutineSchedulingType
    let onEdit: () -> Void
    
    private var totalDuration: Int {
        daySchedule.methods.reduce(0) { $0 + $1.duration }
    }
    
    private var displayName: String {
        if schedulingType == .weekday {
            // For weekday scheduling, show actual weekday names
            let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            let dayIndex = (daySchedule.day - 1) % 7
            return weekdays[dayIndex]
        } else {
            // For sequential scheduling, show Day numbers
            return daySchedule.dayName
        }
    }
    
    private var iconName: String {
        if schedulingType == .weekday {
            // Show weekday-specific icons
            let weekdayIcons = ["briefcase", "dumbbell", "leaf", "brain.head.profile", "figure.run", "gamecontroller", "bed.double"]
            let dayIndex = (daySchedule.day - 1) % 7
            return weekdayIcons[dayIndex]
        } else {
            // Show sequential day icons
            return daySchedule.isRestDay ? "moon.fill" : "calendar.day"
        }
    }
    
    private var dayTypeDescription: String {
        if schedulingType == .weekday {
            let weekdayDescriptions = ["Work & Focus", "Strength & Energy", "Growth & Recovery", "Learning & Mind", "Movement & Vitality", "Play & Joy", "Rest & Reflection"]
            let dayIndex = (daySchedule.day - 1) % 7
            return weekdayDescriptions[dayIndex]
        } else {
            return daySchedule.description
        }
    }
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // Day icon
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(daySchedule.isRestDay ? Color.purple : Color("GrowthGreen"))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(displayName)
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        if schedulingType == .weekday {
                            Text("Weekly")
                                .font(AppTheme.Typography.captionFont())
                                .fontWeight(.medium)
                                .foregroundColor(Color("GrowthGreen"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color("GrowthGreen").opacity(0.1))
                                )
                        }
                    }
                    
                    Text(dayTypeDescription)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    if !daySchedule.methods.isEmpty {
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
                    } else if daySchedule.isRestDay {
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(AppTheme.Typography.captionFont())
                            Text("Rest day")
                                .font(AppTheme.Typography.captionFont())
                        }
                        .foregroundColor(Color.purple)
                    } else {
                        Text("Tap to add methods")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .italic()
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
            .background(Color("BackgroundColor"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(schedulingType == .weekday ? Color("GrowthGreen").opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


// MARK: - Method Selection View

struct LegacyMethodSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedMethods: Set<String>
    @StateObject private var viewModel = MethodSelectionViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextField("Search methods...", text: $searchText)
                        .font(AppTheme.Typography.bodyFont())
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding()
                .background(Color("BackgroundColor"))
                .cornerRadius(12)
                .padding()
                
                // Methods list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredMethods) { method in
                            MethodSelectionRow(
                                method: method,
                                isSelected: selectedMethods.contains(method.id ?? ""),
                                onToggle: {
                                    if let id = method.id {
                                        if selectedMethods.contains(id) {
                                            selectedMethods.remove(id)
                                        } else {
                                            selectedMethods.insert(id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Select Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            viewModel.loadMethods()
        }
    }
    
    private var filteredMethods: [GrowthMethod] {
        if searchText.isEmpty {
            return viewModel.methods
        } else {
            return viewModel.methods.filter { method in
                method.title.localizedCaseInsensitiveContains(searchText) ||
                method.methodDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct MethodSelectionRow: View {
    let method: GrowthMethod
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("Stage \(method.stage)")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color("GrowthGreen") : Color("GrowthNeutralGray"))
                    .font(AppTheme.Typography.title2Font())
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class MethodSelectionViewModel: ObservableObject {
    @Published var methods: [GrowthMethod] = []
    @Published var isLoading = false
    
    private let growthMethodService = GrowthMethodService.shared
    
    func loadMethods() {
        isLoading = true
        growthMethodService.fetchAllMethods { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let methods):
                    self?.methods = methods
                case .failure(let error):
                    Logger.error("Error loading methods: \(error)")
                    // For now, just use an empty array as fallback
                    self?.methods = []
                }
            }
        }
    }
}

// MARK: - Edit Day Schedule View

struct EditDayScheduleView: View {
    @Environment(\.dismiss) var dismiss
    let daySchedule: DaySchedule
    let availableMethods: [String]
    let onSave: (DaySchedule) -> Void
    
    @State private var selectedMethods: [MethodSchedule] = []
    @State private var dayDescription = ""
    @State private var additionalNotes = ""
    @State private var isRestDay = false
    @StateObject private var methodsViewModel = MethodSelectionViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Day Information") {
                    TextField("Description", text: $dayDescription)
                    
                    Toggle("Rest Day", isOn: $isRestDay)
                        .tint(Color("GrowthGreen"))
                }
                
                if !isRestDay {
                    Section("Methods for this Day") {
                        if availableMethods.isEmpty {
                            // No methods have been selected for the routine yet
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text("No methods available")
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(AppTheme.Colors.text)
                                Text("Please go back and select methods for your routine first using the 'Manage Methods' button")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else if selectedMethods.isEmpty {
                            Button {
                                // Add method
                                Logger.debug("=== Add Method Button Tapped ===")
                                Logger.debug("Available methods count: \(availableMethods.count)")
                                Logger.debug("Available methods: \(availableMethods)")
                                
                                if let firstMethodId = availableMethods.first {
                                    Logger.debug("Creating new method with ID: \(firstMethodId)")
                                    // Get default duration from method info if available
                                    let defaultDuration = methodsViewModel.methods.first(where: { $0.id == firstMethodId })?.estimatedDurationMinutes ?? 20
                                    let newMethod = MethodSchedule(
                                        methodId: firstMethodId,
                                        duration: defaultDuration,
                                        order: selectedMethods.count
                                    )
                                    Logger.debug("New method created: \(newMethod.id), methodId: \(newMethod.methodId)")
                                    selectedMethods.append(newMethod)
                                    Logger.debug("Selected methods after append: \(selectedMethods.count)")
                                } else {
                                    Logger.debug("⚠️ No available methods to add!")
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color("GrowthGreen"))
                                    Text("Add methods to this day")
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                        } else {
                            ForEach(Array(selectedMethods.enumerated()), id: \.element.id) { index, method in
                                MethodScheduleRow(
                                    methodSchedule: Binding(
                                        get: { method },
                                        set: { newValue in
                                            if index < selectedMethods.count {
                                                selectedMethods[index] = newValue
                                            }
                                        }
                                    ),
                                    availableMethods: availableMethods,
                                    methodsInfo: methodsViewModel.methods,
                                    onDelete: {
                                        if let deleteIndex = selectedMethods.firstIndex(where: { $0.id == method.id }) {
                                            selectedMethods.remove(at: deleteIndex)
                                            // Update order for remaining methods - create new MethodSchedule instances with correct order
                                            selectedMethods = selectedMethods.enumerated().map { idx, method in
                                                MethodSchedule(
                                                    methodId: method.methodId,
                                                    duration: method.duration,
                                                    order: idx
                                                )
                                            }
                                        }
                                    }
                                )
                            }
                            .onMove { indices, newOffset in
                                selectedMethods.move(fromOffsets: indices, toOffset: newOffset)
                                // Update order after move - create new MethodSchedule instances with correct order
                                selectedMethods = selectedMethods.enumerated().map { idx, method in
                                    MethodSchedule(
                                        methodId: method.methodId,
                                        duration: method.duration,
                                        order: idx
                                    )
                                }
                            }
                            
                            Button {
                                // Add another method
                                Logger.debug("=== Add Another Method Button Tapped ===")
                                Logger.debug("Available methods count: \(availableMethods.count)")
                                Logger.debug("Current selected methods count: \(selectedMethods.count)")
                                
                                if let firstMethodId = availableMethods.first {
                                    Logger.debug("Creating another method with ID: \(firstMethodId)")
                                    // Get default duration from method info if available
                                    let defaultDuration = methodsViewModel.methods.first(where: { $0.id == firstMethodId })?.estimatedDurationMinutes ?? 20
                                    let newMethod = MethodSchedule(
                                        methodId: firstMethodId,
                                        duration: defaultDuration,
                                        order: selectedMethods.count
                                    )
                                    Logger.debug("New method created: \(newMethod.id), methodId: \(newMethod.methodId)")
                                    selectedMethods.append(newMethod)
                                    Logger.debug("Selected methods after append: \(selectedMethods.count)")
                                } else {
                                    Logger.debug("⚠️ No available methods to add!")
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color("GrowthGreen"))
                                    Text("Add another method")
                                }
                            }
                        }
                    }
                }
                
                Section("Additional Notes") {
                    TextEditor(text: $additionalNotes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit \(daySchedule.dayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
                
                if !isRestDay && !selectedMethods.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
        .onAppear {
            Logger.debug("=== EditDayScheduleView onAppear ===")
            Logger.debug("Editing day \(daySchedule.day) (ID: \(daySchedule.id))")
            Logger.debug("Day has \(daySchedule.methods.count) methods initially")
            for (index, method) in daySchedule.methods.enumerated() {
                Logger.debug("  Method \(index): \(method.methodId)")
            }
            
            Logger.debug("Available methods passed to view: \(availableMethods.count)")
            Logger.debug("Available method IDs: \(availableMethods)")
            
            dayDescription = daySchedule.description.isEmpty ? (daySchedule.isRestDay ? "Active recovery and wellness" : "Training day") : daySchedule.description
            additionalNotes = daySchedule.additionalNotes ?? ""
            isRestDay = daySchedule.isRestDay
            
            // Create deep copies of methods to ensure complete isolation
            selectedMethods = daySchedule.methods.map { method in
                MethodSchedule(
                    methodId: method.methodId,
                    duration: method.duration,
                    order: method.order
                )
            }
            
            Logger.debug("After initialization, selectedMethods has \(selectedMethods.count) methods")
            Logger.debug("Original day methods count: \(daySchedule.methods.count)")
            methodsViewModel.loadMethods()
        }
    }
    
    private func saveChanges() {
        Logger.debug("=== EditDayScheduleView saveChanges ===" )
        Logger.debug("Saving changes for day \(daySchedule.day) (ID: \(daySchedule.id))")
        Logger.debug("Current selectedMethods count: \(selectedMethods.count)")
        for (index, method) in selectedMethods.enumerated() {
            Logger.debug("  Method \(index): \(method.methodId) (ID: \(method.id))")
        }
        
        // Create deep copies of the method schedules to ensure no shared references
        let methodsCopy = selectedMethods.map { method in
            MethodSchedule(
                methodId: method.methodId,
                duration: method.duration,
                order: method.order
            )
        }
        
        Logger.debug("Created \(methodsCopy.count) method copies")
        
        // Create a new DaySchedule with updated values, preserving the ID
        var updatedSchedule = DaySchedule(
            day: daySchedule.day,
            isRestDay: isRestDay,
            methods: isRestDay ? [] : methodsCopy,
            notes: additionalNotes
        )
        
        // Preserve the original ID to maintain day identity
        updatedSchedule.id = daySchedule.id
        updatedSchedule.description = dayDescription
        
        Logger.debug("Created updated schedule for day \(updatedSchedule.day) with \(updatedSchedule.methods.count) methods")
        Logger.debug("Calling onSave callback...")
        
        onSave(updatedSchedule)
        dismiss()
    }
}

// MARK: - Method Schedule Row

struct MethodScheduleRow: View {
    @Binding var methodSchedule: MethodSchedule
    let availableMethods: [String]
    let methodsInfo: [GrowthMethod]
    let onDelete: () -> Void
    
    @State private var showingDurationPicker = false
    @State private var currentDuration: Int = 20
    
    private var methodTitle: String {
        if let method = methodsInfo.first(where: { $0.id == methodSchedule.methodId }) {
            return method.title
        }
        return methodSchedule.methodId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Method selector
            HStack {
                Menu {
                    ForEach(availableMethods, id: \.self) { methodId in
                        Button {
                            methodSchedule.methodId = methodId
                            // Update duration to method's default when switching methods
                            if let method = methodsInfo.first(where: { $0.id == methodId }) {
                                methodSchedule.duration = method.estimatedDurationMinutes ?? 20
                                currentDuration = methodSchedule.duration
                            }
                        } label: {
                            if let method = methodsInfo.first(where: { $0.id == methodId }) {
                                VStack(alignment: .leading) {
                                    Text(method.title)
                                    Text("Stage \(method.stage)")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(methodId)
                            }
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(methodTitle)
                                .font(AppTheme.Typography.bodyFont())
                                .foregroundColor(AppTheme.Colors.text)
                            
                            if let method = methodsInfo.first(where: { $0.id == methodSchedule.methodId }) {
                                Text("Stage \(method.stage)")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Duration selector
            HStack {
                Text("Duration:")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Button {
                    currentDuration = methodSchedule.duration
                    showingDurationPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text("\(currentDuration) minutes")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(Color("GrowthGreen"))
                        
                        // Show if using recommended duration
                        if let method = methodsInfo.first(where: { $0.id == methodSchedule.methodId }),
                           let recommendedDuration = method.estimatedDurationMinutes,
                           currentDuration == recommendedDuration {
                            Text("(recommended)")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(Color("GrowthGreen").opacity(0.7))
                        }
                        
                        Image(systemName: "clock")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(Color("GrowthGreen"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Color("GrowthGreen"), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDurationPicker) {
            DurationPickerView(duration: $currentDuration)
                .onDisappear {
                    methodSchedule.duration = currentDuration
                }
        }
        .onAppear {
            // Use local state to avoid binding issues
            currentDuration = methodSchedule.duration
        }
        .onChangeCompat(of: methodSchedule.duration) { _ in
            currentDuration = methodSchedule.duration
        }
    }
}

// MARK: - Duration Picker View

struct DurationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var duration: Int
    
    let durationOptions = [5, 10, 15, 20, 25, 30, 45, 60]
    @State private var customDuration = ""
    @State private var useCustomDuration = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Duration")
                    .font(AppTheme.Typography.gravitySemibold(20))
                    .padding(.top)
                
                // Preset options
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        Button {
                            duration = minutes
                            dismiss()
                        } label: {
                            Text("\(minutes) min")
                                .font(AppTheme.Typography.bodyFont())
                                .foregroundColor(duration == minutes ? .white : AppTheme.Colors.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(duration == minutes ? Color("GrowthGreen") : Color("BackgroundColor"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color("GrowthGreen").opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // Custom duration
                VStack(spacing: 12) {
                    Text("Custom Duration")
                        .font(AppTheme.Typography.gravitySemibold(16))
                    
                    HStack {
                        TextField("Minutes", text: $customDuration)
                            .keyboardType(.numberPad)
                            .font(AppTheme.Typography.bodyFont())
                            .padding()
                            .frame(width: 100)
                            .background(Color("BackgroundColor"))
                            .cornerRadius(8)
                        
                        Text("minutes")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Button {
                        if let minutes = Int(customDuration), minutes > 0 && minutes <= 180 {
                            duration = minutes
                            dismiss()
                        }
                    } label: {
                        Text("Set Custom Duration")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color("GrowthGreen"))
                            .cornerRadius(8)
                    }
                    .disabled(Int(customDuration) == nil || Int(customDuration) ?? 0 <= 0 || Int(customDuration) ?? 0 > 180)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            customDuration = "\(duration)"
        }
    }
}

// MARK: - Custom Duration Picker
struct CustomRoutineDurationPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var numberOfDays: Int
    let onConfirm: () -> Void
    
    @State private var customDays = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Set Custom Duration")
                        .font(AppTheme.Typography.gravitySemibold(24))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("Choose how many days your routine will last")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 8) {
                    HStack {
                        TextField("30", text: $customDays)
                            .keyboardType(.numberPad)
                            .font(AppTheme.Typography.gravitySemibold(48))
                            .multilineTextAlignment(.center)
                            .frame(width: 120)
                            .onChangeCompat(of: customDays) { newValue in
                                showError = false
                                // Limit to 3 digits
                                if newValue.count > 3 {
                                    customDays = String(newValue.prefix(3))
                                }
                            }
                        
                        Text("days")
                            .font(AppTheme.Typography.gravitySemibold(24))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if showError {
                        Text("Please enter a number between 1 and 365 days")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.red)
                    }
                    
                    Text("Recommended: 21-90 days for best results")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                Button {
                    if let days = Int(customDays), days > 0, days <= 365 {
                        numberOfDays = days
                        onConfirm()
                        dismiss()
                    } else {
                        showError = true
                    }
                } label: {
                    Text("Set Duration")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("GrowthGreen"))
                        .cornerRadius(12)
                }
                .disabled(Int(customDays) == nil || Int(customDays) ?? 0 <= 0)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            customDays = "\(numberOfDays)"
        }
    }
}

// MARK: - Scheduling Type Card

struct SchedulingTypeCard: View {
    let type: RoutineSchedulingType
    let isSelected: Bool
    let recommendedDuration: Int
    let action: () -> Void
    
    private var iconName: String {
        switch type {
        case .sequential:
            return "calendar.day.timeline.left"
        case .weekday:
            return "calendar"
        }
    }
    
    private var isRecommended: Bool {
        switch type {
        case .sequential:
            return recommendedDuration > 14
        case .weekday:
            return recommendedDuration <= 14
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : Color("GrowthGreen"))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(type.displayName)
                                .font(AppTheme.Typography.gravitySemibold(16))
                                .foregroundColor(isSelected ? .white : AppTheme.Colors.text)
                            
                            if isRecommended {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                    Text("RECOMMENDED")
                                        .font(AppTheme.Typography.captionFont())
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(isSelected ? .white.opacity(0.9) : Color("GrowthGreen"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.white.opacity(0.2) : Color("GrowthGreen").opacity(0.1))
                                )
                            }
                            
                            Spacer()
                        }
                        
                        Text(type.detailedDescription)
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(isSelected ? .white.opacity(0.85) : AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(type.exampleText)
                            .font(AppTheme.Typography.captionFont())
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .white.opacity(0.9) : Color("GrowthGreen"))
                            .padding(.top, 2)
                    }
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : Color("GrowthGreen"))
                }
                .padding()
                
                // Visual preview section
                if isSelected {
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    HStack(spacing: 12) {
                        Image(systemName: "eye")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(getPreviewText())
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("GrowthGreen") : Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : (isRecommended ? Color("GrowthGreen").opacity(0.5) : Color("GrowthNeutralGray").opacity(0.3)), lineWidth: isRecommended && !isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func getPreviewText() -> String {
        switch type {
        case .sequential:
            return "Will show: Day 1 → Day 2 → Day 3..."
        case .weekday:
            return "Will show: Mon → Tue → Wed → Thu..."
        }
    }
}

#Preview {
    CreateCustomRoutineView()
}