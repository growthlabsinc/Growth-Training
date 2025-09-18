//
//  DetailedProgressCalendarView.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import SwiftUI
import UIKit
import Foundation  // For Logger

// Wrapper to make Date Identifiable for sheet presentation
struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

/// Intensity levels for calendar visualization
enum IntensityLevel: CaseIterable {
    case none
    case light    // 1-15 minutes
    case medium   // 15-30 minutes
    case high     // 30+ minutes
    
    /// Calculate intensity level from minutes
    static func fromMinutes(_ minutes: Int) -> IntensityLevel {
        switch minutes {
        case 0:
            return .none
        case 1..<15:
            return .light
        case 15..<30:
            return .medium
        default:
            return .high
        }
    }
    
    /// Color for the intensity level
    var color: UIColor {
        switch self {
        case .none:
            return .clear
        case .light:
            return UIColor(named: "PaleGreen") ?? .systemGreen.withAlphaComponent(0.3)
        case .medium:
            return UIColor(named: "MintGreen") ?? .systemGreen.withAlphaComponent(0.6)
        case .high:
            return UIColor(named: "GrowthGreen") ?? .systemGreen
        }
    }
    
    /// Size multiplier for indicator
    var sizeMultiplier: CGFloat {
        switch self {
        case .none:
            return 0
        case .light:
            return 0.4
        case .medium:
            return 0.6
        case .high:
            return 0.8
        }
    }
}

@available(iOS 16.0, *)
struct DetailedProgressCalendarView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @State private var selectedDate: Date? = nil
    @State private var selectedDateWrapper: IdentifiableDate? = nil
    @State private var showingDayDetails = false
    @State private var displayedMonth = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Card container for calendar, legend, and stats
                VStack(spacing: 8) {
                    // Calendar
                    CalendarViewRepresentable(
                        viewModel: viewModel,
                        selectedDate: $selectedDate,
                        showingDayDetails: $showingDayDetails,
                        displayedMonth: $displayedMonth
                    )
                    .frame(height: 450)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

                    // Divider above legend
                    Divider()
                        .frame(height: 1)
                        .background(Color.black.opacity(0.07))
                        .padding(.horizontal, 16)

                    // Legend
                    compactLegend
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)

                    // Stats
                    summaryStats
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .safeAreaInset(edge: .bottom) { Spacer().frame(height: 16) }
        .sheet(item: $selectedDateWrapper) { wrapper in
            DayDetailSheet(date: wrapper.date, viewModel: viewModel)
                .onDisappear {
                    // Reset selected date when sheet is dismissed
                    selectedDate = nil
                    showingDayDetails = false
                }
        }
        .onChangeCompat(of: selectedDate) { newValue in
            if let date = newValue, showingDayDetails {
                selectedDateWrapper = IdentifiableDate(date: date)
            } else {
                selectedDateWrapper = nil
            }
        }
        .onChangeCompat(of: showingDayDetails) { newValue in
            if newValue, let date = selectedDate {
                selectedDateWrapper = IdentifiableDate(date: date)
            } else {
                selectedDateWrapper = nil
            }
        }
    }
    
    private var monthYearNavigation: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("GrowthGreen"))
                    .frame(width: 30, height: 30)
            }
            
            Spacer()
            
            Text(monthYearFormatter.string(from: displayedMonth))
                .font(AppTheme.Typography.gravitySemibold(16))
                .foregroundColor(Color("TextColor"))
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("GrowthGreen"))
                    .frame(width: 30, height: 30)
            }
            .disabled(!canGoToNextMonth)
        }
    }
    
    private var compactLegend: some View {
        HStack(spacing: 6) {
            ForEach([IntensityLevel.light, .medium, .high], id: \.self) { level in
                HStack(spacing: 1) {
                    Circle()
                        .fill(Color(level.color))
                        .frame(width: 5, height: 5)
                    Text(legendText(for: level))
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            Spacer()
            HStack(spacing: 1) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                Text("Rest")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
        }
    }
    
    private func legendText(for level: IntensityLevel) -> String {
        switch level {
        case .light:
            return "1-15m"
        case .medium:
            return "15-30m"
        case .high:
            return "30m+"
        default:
            return ""
        }
    }
    
    private var summaryStats: some View {
        HStack(spacing: 8) {
            statCard(
                title: "Active Days",
                value: "\(viewModel.loggedDates.count)",
                icon: "calendar.badge.checkmark"
            )
            
            statCard(
                title: "Total Time",
                value: formatTotalTime(),
                icon: "clock.fill"
            )
            
            statCard(
                title: "Streak",
                value: "\(calculateStreak())",
                icon: "flame.fill"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        if let newMonth = Calendar.userPreferred.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if canGoToNextMonth,
           let newMonth = Calendar.userPreferred.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    private var canGoToNextMonth: Bool {
        let calendar = Calendar.userPreferred
        let currentMonth = calendar.dateInterval(of: .month, for: Date())
        let displayedMonthInterval = calendar.dateInterval(of: .month, for: displayedMonth)
        
        guard let current = currentMonth, let displayed = displayedMonthInterval else { return false }
        return displayed.start < current.start
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 1) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color("GrowthGreen"))
            Text(value)
                .font(AppTheme.Typography.footnoteFont())
                .fontWeight(.semibold)
                .foregroundColor(Color("TextColor"))
            Text(title)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(6)
    }
    
    private func formatTotalTime() -> String {
        let totalMinutes = viewModel.totalMinutesInRange
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
    
    private func calculateStreak() -> Int {
        // Use the ProgressViewModel's private method logic
        let calendar = Calendar.userPreferred
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        // Check if user practiced today or yesterday
        let todayMinutes = viewModel.dailyMinutes[today] ?? 0
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let yesterdayMinutes = viewModel.dailyMinutes[yesterdayDate] ?? 0
        
        if todayMinutes > 0 {
            // Start counting from today
        } else if yesterdayMinutes > 0 {
            currentDate = yesterdayDate
        } else {
            return 0
        }
        
        // Count consecutive days backwards
        while true {
            let minutes = viewModel.dailyMinutes[currentDate] ?? 0
            if minutes > 0 {
                streak += 1
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDate
            } else {
                break
            }
        }
        
        return streak
    }
}

// UIViewRepresentable wrapper for the calendar
@available(iOS 16.0, *)
struct CalendarViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var selectedDate: Date?
    @Binding var showingDayDetails: Bool
    @Binding var displayedMonth: Date
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.delegate = context.coordinator
        
        // Create calendar with user's preferred first day of week
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = ThemeManager.shared.firstDayOfWeek
        calendarView.calendar = calendar
        
        calendarView.locale = Locale.current
        calendarView.fontDesign = .rounded
        calendarView.wantsDateDecorations = true
        
        // Customize appearance - compact layout
        calendarView.backgroundColor = .systemBackground
        calendarView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Make the calendar more compact
        calendarView.overrideUserInterfaceStyle = .unspecified
        
        // Set available date range
        if let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()),
           let oneMonthFromNow = calendar.date(byAdding: Calendar.Component.month, value: 1, to: Date()) {
            calendarView.availableDateRange = DateInterval(start: oneYearAgo, end: oneMonthFromNow)
        }
        
        calendarView.tintColor = UIColor(named: "GrowthGreen")
        
        // Single date selection for details
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = dateSelection
        
        // Set initial visible month
        let components = calendar.dateComponents([.year, .month, .day], from: displayedMonth)
        calendarView.setVisibleDateComponents(components, animated: false)
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendarView.widthAnchor.constraint(equalToConstant: 340)
        ])
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Update calendar if firstDayOfWeek changed
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = ThemeManager.shared.firstDayOfWeek
        if uiView.calendar.firstWeekday != calendar.firstWeekday {
            uiView.calendar = calendar
        }
        
        // Update decorations when data changes
        uiView.reloadDecorations(forDateComponents: getDecoratedDateComponents(), animated: true)
        
        // Update visible month when changed via navigation
        let components = uiView.calendar.dateComponents([.year, .month, .day], from: displayedMonth)
        
        // Only update if the visible month has actually changed
        let currentComponents = uiView.visibleDateComponents
        if components.year != currentComponents.year || components.month != currentComponents.month {
            uiView.setVisibleDateComponents(components, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func getDecoratedDateComponents() -> [DateComponents] {
        let calendar = Calendar.userPreferred
        return viewModel.dailyMinutes.keys.compactMap { date in
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard components.year != nil, components.month != nil, components.day != nil else { return nil }
            return components
        }
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarViewRepresentable
        
        init(_ parent: CalendarViewRepresentable) {
            self.parent = parent
        }
        
        // Track visible month changes
        func calendarView(_ calendarView: UICalendarView, didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents) {
            // When the visible month changes in the calendar, update our state
            DispatchQueue.main.async {
                let calendar = Calendar.current
                // Get the current visible date from the calendar view
                let visibleComponents = calendarView.visibleDateComponents
                if let date = calendar.date(from: visibleComponents) {
                    self.parent.displayedMonth = date
                }
            }
        }
        
        // Calendar decoration
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let calendar = Calendar.current
            guard let date = calendar.date(from: dateComponents) else { 
                return nil 
            }
            
            let startOfDay = calendar.startOfDay(for: date)
            let minutes = parent.viewModel.dailyMinutes[startOfDay] ?? 0
            
            // Check if it's a rest day (this would need routine information)
            let isRestDay = false // TODO: Implement rest day detection
            
            if minutes > 0 || isRestDay {
                return .customView {
                    IntensityIndicatorView(minutes: minutes, isRestDay: isRestDay)
                }
            }
            
            return nil
        }
        
        // Date selection
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents = dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            
            parent.selectedDate = date
            parent.showingDayDetails = true
        }
    }
}

// Day detail sheet
@available(iOS 16.0, *)
struct DayDetailSheet: View {
    let date: Date
    @ObservedObject var viewModel: ProgressViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessions: [SessionLog] = []
    @State private var isLoading = true
    @State private var hasLoadedInitialData = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading && sessions.isEmpty {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Loading sessions...")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(Color("TextSecondaryColor"))
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sessions.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle(dateFormatter.string(from: date))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if !hasLoadedInitialData {
                hasLoadedInitialData = true
                loadSessions()
            }
        }
        .onChangeCompat(of: viewModel.sessionLogs) { _ in
            // Reload sessions when the viewModel's data changes
            filterAndSetSessions()
        }
    }
    
    private func loadSessions() {
        Logger.debug("DEBUG: DayDetailSheet - Loading sessions for date: \(date)")
        Logger.debug("DEBUG: Total session logs available: \(viewModel.sessionLogs.count)")
        
        // Show loading state initially
        isLoading = true
        
        // Check if data is loaded
        if viewModel.sessionLogs.isEmpty && !viewModel.isLoading {
            // Trigger a refresh if no data is available
            Logger.debug("DEBUG: No session logs available, triggering refresh")
            viewModel.fetchLoggedDates()
            
            // Wait for data to load, then filter
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.filterAndSetSessions()
            }
        } else if viewModel.isLoading {
            // If already loading, wait a bit then check again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadSessions()
            }
        } else {
            // Data is available, filter immediately
            filterAndSetSessions()
        }
    }
    
    private func filterAndSetSessions() {
        let calendar = Calendar.current
        let filteredSessions = viewModel.sessionLogs.filter { log in
            calendar.isDate(log.startTime, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
        
        Logger.debug("DEBUG: Found \(filteredSessions.count) sessions for selected date")
        
        self.sessions = filteredSessions
        self.isLoading = false
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 60))
                .foregroundColor(Color("GrowthGreen").opacity(0.5))
            
            Text("No Sessions")
                .font(AppTheme.Typography.title2Font())
                .fontWeight(.semibold)
            
            Text("You didn't log any practice on this day")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var sessionsList: some View {
        List {
            Section {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            } header: {
                HStack {
                    Text("\(sessions.count) Session\(sessions.count == 1 ? "" : "s")")
                    Spacer()
                    Text("Total: \(totalDurationText)")
                }
                .font(AppTheme.Typography.subheadlineFont())
                .foregroundColor(Color("TextSecondaryColor"))
            }
        }
    }
    
    private var totalDurationText: String {
        let totalMinutes = sessions.reduce(0) { $0 + $1.duration }
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

// Session row view
struct SessionRow: View {
    let session: SessionLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.variation ?? "Practice Session")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("TextColor"))
                
                Text(timeFormatter.string(from: session.startTime))
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.duration)m")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("GrowthGreen"))
                
                if session.duration >= 30 {
                    Label("Great!", systemImage: "star.fill")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// Simple UIView for showing intensity indicator
@available(iOS 16.0, *)
class IntensityIndicatorView: UIView {
    private let minutes: Int
    private let isRestDay: Bool
    
    init(minutes: Int, isRestDay: Bool) {
        self.minutes = minutes
        self.isRestDay = isRestDay
        super.init(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let intensity = IntensityLevel.fromMinutes(minutes)
        
        if isRestDay && intensity == .none {
            // Draw rest day indicator
            let restColor = UIColor(named: "TextSecondaryColor") ?? .systemGray
            context.setFillColor(restColor.cgColor)
            let circleRect = rect.insetBy(dx: rect.width * 0.3, dy: rect.height * 0.3)
            context.fillEllipse(in: circleRect)
        } else if intensity != .none {
            // Draw intensity indicator
            context.setFillColor(intensity.color.cgColor)
            let size = min(rect.width, rect.height) * intensity.sizeMultiplier
            let indicatorRect = CGRect(
                x: rect.midX - size/2,
                y: rect.midY - size/2,
                width: size,
                height: size
            )
            context.fillEllipse(in: indicatorRect)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 24, height: 24)
    }
}

// Fallback for iOS < 16
struct DetailedProgressCalendarView_Legacy: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "calendar")
                .font(.system(size: 80))
                .foregroundColor(Color("GrowthGreen"))
                .padding(.bottom, 20)
            
            Text("Enhanced Calendar View")
                .font(AppTheme.Typography.largeTitleFont())
                .fontWeight(.bold)
                .foregroundColor(Color("TextColor"))
            
            Text("iOS 16.0 or later required for intensity visualization")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("GrowthBackgroundLight"))
    }
}

struct DetailedProgressCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            DetailedProgressCalendarView(viewModel: ProgressViewModel())
        } else {
            DetailedProgressCalendarView_Legacy(viewModel: ProgressViewModel())
        }
    }
}
