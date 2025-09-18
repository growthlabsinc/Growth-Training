//
//  CurrentRoutineView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//  Updated for Story 15.3: Integration with existing RoutinesViewModel
//

import SwiftUI
import FirebaseAuth

struct CurrentRoutineView: View {
    @ObservedObject var routinesViewModel: RoutinesViewModel
    @Binding var showRoutineSelection: Bool
    @State private var showCreateCustomRoutine = false
    @State private var expandedDayCards: Set<String> = []
    @State private var currentDaySchedule: DaySchedule?
    @State private var currentProgress: RoutineProgress?
    @State private var showResetConfirmation = false
    
    init(routinesViewModel: RoutinesViewModel, showRoutineSelection: Binding<Bool>) {
        self.routinesViewModel = routinesViewModel
        self._showRoutineSelection = showRoutineSelection
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    if routinesViewModel.isLoading {
                        loadingView
                    } else if let selectedRoutine = currentRoutine {
                        activeRoutineView(routine: selectedRoutine)
                    } else {
                        noRoutineView
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Current Routine")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showCreateCustomRoutine) {
            PremiumCreateCustomRoutineView()
        }
        .alert("Reset Progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                routinesViewModel.resetRoutineProgress { success in
                    if success {
                        // Reload the current routine day after reset
                        loadCurrentRoutineDay()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to reset your progress? This will start you back at Day 1.")
        }
        .onAppear {
            routinesViewModel.loadRoutines()
            loadCurrentRoutineDay()
        }
        .onChangeCompat(of: routinesViewModel.selectedRoutineId) { _ in
            loadCurrentRoutineDay()
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentRoutine: Routine? {
        guard let selectedId = routinesViewModel.selectedRoutineId else { return nil }
        return routinesViewModel.routines.first { $0.id == selectedId }
    }
    
    private var todaysSchedule: DaySchedule? {
        return currentDaySchedule
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentRoutineDay() {
        guard let routine = currentRoutine,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        RoutineProgressService.shared.getCurrentRoutineDay(userId: userId, routine: routine) { daySchedule, progress in
            DispatchQueue.main.async {
                self.currentDaySchedule = daySchedule
                self.currentProgress = progress
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your routine...")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - No Routine View
    
    private var noRoutineView: some View {
        VStack(spacing: 24) {
            // Icon and Title
            VStack(spacing: 16) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("No Active Routine")
                    .font(AppTheme.Typography.title2Font())
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextColor"))
                
                Text("Select a routine to start your growth journey with structured daily sessions")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Browse Routines Button
            Button(action: {
                showRoutineSelection = true
            }) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .font(AppTheme.Typography.headlineFont())
                    Text("Browse Routines")
                        .font(AppTheme.Typography.headlineFont())
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("GrowthGreen"))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Create Custom Routine Button
            Button(action: {
                showCreateCustomRoutine = true
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(AppTheme.Typography.headlineFont())
                    Text("Create Custom Routine")
                        .font(AppTheme.Typography.headlineFont())
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color("GrowthGreen"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("BackgroundColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("GrowthGreen"), lineWidth: 2)
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding(.top, 40)
    }
    
    // MARK: - Active Routine View
    
    private func activeRoutineView(routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Routine Header Card
            routineHeaderCard(routine: routine)
            
            // Routine Adherence Card
            if let userId = Auth.auth().currentUser?.uid {
                RoutineAdherenceView(routine: routine, userId: userId)
            }
            
            // Today's Focus
            if let todaySchedule = todaysSchedule {
                todaysFocusCard(schedule: todaySchedule)
            }
            
            // Action Buttons
            actionButtonsSection(routine: routine)
            
            // Weekly Overview
            weeklyOverviewCard(routine: routine)
        }
    }
    
    private func routineHeaderCard(routine: Routine) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(routine.name)
                            .font(AppTheme.Typography.gravitySemibold(20))
                            .foregroundColor(Color("TextColor"))
                        
                        Text(routine.description)
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(Color("TextSecondaryColor"))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: difficultyIcon(for: routine.difficultyLevel))
                            .font(AppTheme.Typography.title3Font())
                            .foregroundColor(difficultyColor(for: routine.difficultyLevel))
                        
                        Text(routine.difficultyLevel)
                            .font(AppTheme.Typography.gravityBook(11))
                            .fontWeight(.medium)
                            .foregroundColor(difficultyColor(for: routine.difficultyLevel))
                    }
                }
                
                // Routine Stats
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Days")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(.secondary)
                        Text("\(routine.schedule.count) days")
                            .font(AppTheme.Typography.gravitySemibold(14))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Active Days")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(.secondary)
                        Text("\(routine.schedule.filter { !$0.isRestDay }.count)")
                            .font(AppTheme.Typography.gravitySemibold(14))
                    }
                }
            }
        }
    }
    
    private func todaysFocusCard(schedule: DaySchedule) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Focus")
                        .font(AppTheme.Typography.headlineFont())
                        .fontWeight(.semibold)
                        .foregroundColor(Color("TextColor"))
                    
                    Spacer()
                    
                    Text(dayOfWeekText())
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(.secondary)
                }
                
                Text(schedule.dayName)
                    .font(AppTheme.Typography.title3Font())
                    .fontWeight(.medium)
                    .foregroundColor(Color("GrowthGreen"))
                
                Text(schedule.description)
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(Color("TextSecondaryColor"))
                
                if schedule.isRestDay {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color("BrightTeal"))
                        Text("Rest Day - Focus on recovery")
                            .font(AppTheme.Typography.calloutFont())
                            .fontWeight(.medium)
                            .foregroundColor(Color("BrightTeal"))
                    }
                    .padding(.top, 8)
                } else if let methodCount = schedule.methodIds?.count, methodCount > 0 {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(Color("GrowthGreen"))
                        Text("\(methodCount) method\(methodCount == 1 ? "" : "s") planned")
                            .font(AppTheme.Typography.calloutFont())
                            .fontWeight(.medium)
                            .foregroundColor(Color("GrowthGreen"))
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private func weeklyOverviewCard(routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Overview")
                .font(AppTheme.Typography.headlineFont())
                .fontWeight(.semibold)
                .foregroundColor(Color("TextColor"))
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(routine.schedule.sorted(by: { $0.dayNumber < $1.dayNumber })) { daySchedule in
                    DayCardView(
                        daySchedule: daySchedule,
                        isExpanded: Binding(
                            get: { expandedDayCards.contains(daySchedule.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedDayCards.insert(daySchedule.id)
                                } else {
                                    expandedDayCards.remove(daySchedule.id)
                                }
                            }
                        ),
                        isToday: isToday(dayNumber: daySchedule.dayNumber)
                    )
                }
            }
        }
    }
    
    private func actionButtonsSection(routine: Routine) -> some View {
        VStack(spacing: 12) {
            // Change Routine Button
            Button(action: {
                showRoutineSelection = true
            }) {
                HStack {
                    Image(systemName: "arrow.2.squarepath")
                        .font(AppTheme.Typography.headlineFont())
                    Text("Change Routine")
                        .font(AppTheme.Typography.headlineFont())
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color("GrowthGreen"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("GrowthGreen").opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("GrowthGreen"), lineWidth: 1)
                )
            }
            
            // View Details Button
            NavigationLink(destination: RoutineDetailView(routineId: routine.id)) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(AppTheme.Typography.headlineFont())
                    Text("View Routine Details")
                        .font(AppTheme.Typography.headlineFont())
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("GrowthGreen"))
                .cornerRadius(12)
            }
            
            // Reset Progress Button - only show if there's progress to reset
            if let progress = routinesViewModel.routineProgress,
               (progress.currentDayNumber > 1 || !progress.completedDays.isEmpty) {
                Button(action: {
                    showResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(AppTheme.Typography.headlineFont())
                        Text("Reset Progress")
                            .font(AppTheme.Typography.headlineFont())
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func dayOfWeekText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    private func dayNumberToWeekday(_ dayNumber: Int) -> String {
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let index = (dayNumber - 1) % 7
        return weekdays[index]
    }
    
    private func isToday(dayNumber: Int) -> Bool {
        // Check if this is the current day based on routine progress
        guard let currentDay = currentDaySchedule else { return false }
        return currentDay.dayNumber == dayNumber
    }
    
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

#Preview {
    NavigationStack {
        CurrentRoutineView(
            routinesViewModel: RoutinesViewModel(userId: "preview"),
            showRoutineSelection: .constant(false)
        )
    }
}