//
//  TodaysFocusView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

struct TodaysFocusView: View {
    @ObservedObject var viewModel: TodayViewViewModel
    let onStartRoutine: () -> Void
    let onQuickPractice: () -> Void
    let onLogRestDay: () -> Void
    var onSelectRoutine: (() -> Void)? = nil
    
    
    var body: some View {
        ZStack {
            // Background image layer
            if shouldShowBackgroundImage {
                backgroundImageView
            }
            
            // Content layer
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(headerTitle)
                            .font(AppTheme.Typography.gravityBoldFont(20))
                            .foregroundColor(shouldShowBackgroundImage ? .white : Color("TextColor"))
                            .shadow(color: shouldShowBackgroundImage ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
                        
                        if !isToday {
                            Text(selectedDateFormatted)
                                .font(AppTheme.Typography.gravitySemibold(14))
                                .foregroundColor(shouldShowBackgroundImage ? .white.opacity(0.9) : Color("TextSecondaryColor"))
                                .shadow(color: shouldShowBackgroundImage ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
                        }
                    }
                    Spacer()
                    Image(systemName: focusIconName)
                        .font(AppTheme.Typography.title2Font())
                        .foregroundColor(shouldShowBackgroundImage ? .white : Color("GrowthGreen"))
                        .shadow(color: shouldShowBackgroundImage ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
                }
                
                Spacer()
                
                // Dynamic Content
                switch viewModel.todayFocusState {
                case .loading:
                    loadingView
                case .routineDay(let schedule):
                    routineDayContentView(schedule)
                case .quickPractice, .noRoutine:
                    quickPracticeView
                case .restDay(let message):
                    restDayView(message)
                case .completed:
                    completedView
                }
            }
            .padding()
        }
        .background(shouldShowBackgroundImage ? Color.clear : Color("BackgroundColor"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        .modifier(TourTarget(id: "todays_focus"))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading today's focus...")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Routine Day Content View (without image)
    private func routineDayContentView(_ schedule: DaySchedule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Schedule info
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.dayName)
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                if let methodIds = schedule.methodIds {
                    Text("\(methodIds.count) Method\(methodIds.count == 1 ? "" : "s") Planned")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // Description
            Text(schedule.description)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(2)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Action Button
            Button(action: { 
                if isToday {
                    onStartRoutine() // Navigate to practice tab with routine
                }
            }) {
                HStack {
                    Image(systemName: isToday ? "play.circle.fill" : "calendar.circle.fill")
                        .font(AppTheme.Typography.title2Font())
                    Text(isToday ? "Start Today's Routine" : "Scheduled for \(dayOfWeek)")
                        .font(AppTheme.Typography.gravitySemibold(16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: isToday ? [Color("GrowthGreen"), Color("BrightTeal")] : [Color("NeutralGray"), Color("NeutralGray")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .disabled(!isToday)
        }
    }
    
    // MARK: - Quick Practice View
    private var quickPracticeView: some View {
        VStack(spacing: 16) {
            // Icon and Title
            VStack(spacing: 8) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text(viewModel.todayFocusState == .noRoutine ? "No Routine Selected" : "Ready for Practice")
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(Color("TextColor"))
                
                Text(viewModel.todayFocusState == .noRoutine ? 
                     "Select a routine to structure your practice journey" :
                     "Jump into a quick practice session anytime")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                // Primary Action
                if viewModel.todayFocusState == .noRoutine, let selectRoutine = onSelectRoutine {
                    Button(action: selectRoutine) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .font(AppTheme.Typography.title3Font())
                            Text("Select a Routine")
                                .font(AppTheme.Typography.gravitySemibold(16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("GrowthGreen"))
                        .cornerRadius(12)
                    }
                }
                
                // Secondary Action - Quick Practice
                Button(action: onQuickPractice) {
                    HStack {
                        Image(systemName: "timer")
                            .font(AppTheme.Typography.title3Font())
                        Text("Start Quick Session")
                            .font(AppTheme.Typography.gravitySemibold(16))
                    }
                    .foregroundColor(viewModel.todayFocusState == .noRoutine ? Color("GrowthGreen") : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.todayFocusState == .noRoutine 
                        ? Color("GrowthGreen").opacity(0.1) 
                        : Color("GrowthGreen")
                    )
                    .cornerRadius(12)
                    .overlay(
                        viewModel.todayFocusState == .noRoutine
                        ? RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("GrowthGreen"), lineWidth: 1)
                        : nil
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Rest Day View
    private func restDayView(_ message: String) -> some View {
        VStack(spacing: 16) {
            // Hero Image with Rest Day Theme
            ZStack(alignment: .center) {
                // Rest day image or gradient
                if let restImage = UIImage(named: "day4_rest_hero") {
                    Image(uiImage: restImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [Color("PaleGreen"), Color("MintGreen")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 140)
                }
                
                // Content overlay
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    Text("Rest Day")
                        .font(AppTheme.Typography.gravityBoldFont(20))
                        .foregroundColor(.white)
                }
            }
            .cornerRadius(12)
            
            // Rest day message
            Text(message)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
            
            // Rest day wellness action
            Button(action: isToday ? onStartRoutine : {}) { // Changed to navigate to rest day experience
                HStack {
                    Image(systemName: isToday ? "leaf.circle.fill" : "calendar.circle.fill")
                        .font(AppTheme.Typography.title3Font())
                    Text(isToday ? "Explore Rest Day Wellness" : "Rest Day on \(dayOfWeek)")
                        .font(AppTheme.Typography.gravitySemibold(16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: isToday ? [Color("PaleGreen"), Color("MintGreen")] : [Color("NeutralGray"), Color("NeutralGray")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(!isToday)
        }
    }
    
    // MARK: - Completed View
    private var completedView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("Great Job!")
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(Color("TextColor"))
                
                Text("You've completed today's routine. Ready for more?")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
            }
            
            // Additional practice button
            Button(action: onQuickPractice) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(AppTheme.Typography.title3Font())
                    Text("Add Extra Practice")
                        .font(AppTheme.Typography.gravitySemibold(16))
                }
                .foregroundColor(Color("GrowthGreen"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("GrowthGreen").opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("GrowthGreen"), lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Background Image View
    private var backgroundImageView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Image
                if let heroImage = backgroundImage {
                    Image(uiImage: heroImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    // Fallback gradient
                    LinearGradient(
                        colors: backgroundGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                
                // Overlay gradient for text readability
                LinearGradient(
                    colors: [Color.black.opacity(0.4), Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .cornerRadius(20)
    }
    
    // MARK: - Helper Properties
    private var shouldShowBackgroundImage: Bool {
        switch viewModel.todayFocusState {
        case .routineDay(_), .restDay(_):
            return true
        default:
            return false
        }
    }
    
    private var backgroundImage: UIImage? {
        switch viewModel.todayFocusState {
        case .routineDay(_):
            return UIImage(named: "hero_today")
        case .restDay(_):
            return UIImage(named: "day4_rest_hero")
        default:
            return nil
        }
    }
    
    private var backgroundGradientColors: [Color] {
        switch viewModel.todayFocusState {
        case .routineDay(_):
            return [Color("GrowthGreen"), Color("BrightTeal")]
        case .restDay(_):
            return [Color("PaleGreen"), Color("MintGreen")]
        default:
            return [Color("GrowthGreen"), Color("BrightTeal")]
        }
    }
    
    private var focusIconName: String {
        switch viewModel.todayFocusState {
        case .loading:
            return "clock.fill"
        case .routineDay(_):
            return "list.bullet.clipboard.fill"
        case .quickPractice, .noRoutine:
            return "bolt.fill"
        case .restDay(_):
            return "leaf.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }
    
    private var headerTitle: String {
        isToday ? "Today's Focus" : "Focus for \(dayOfWeek)"
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.selectedDate)
    }
    
    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.selectedDate)
    }
}

#Preview {
    let mockRoutinesVM = RoutinesViewModel(userId: "mock")
    let mockProgressVM = ProgressViewModel()
    let mockTodayVM = TodayViewViewModel(routinesViewModel: mockRoutinesVM, progressViewModel: mockProgressVM)
    
    return TodaysFocusView(
        viewModel: mockTodayVM,
        onStartRoutine: { print("Start routine") }, // Release OK - Preview
        onQuickPractice: { print("Quick practice") }, // Release OK - Preview
        onLogRestDay: { print("Log rest day") } // Release OK - Preview
    )
    .padding()
}