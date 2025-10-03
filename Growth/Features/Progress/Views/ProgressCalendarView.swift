import SwiftUI

@available(iOS 16.0, *)
struct ProgressCalendarView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var selectedDate: Date?
    
    var body: some View {
        ProgressCalendarUIView(viewModel: viewModel, selectedDate: $selectedDate)
            .padding(.horizontal, 20) // Add horizontal margins as per iOS design guidelines
    }
}

@available(iOS 16.0, *)
private struct ProgressCalendarUIView: UIViewRepresentable {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var selectedDate: Date?
    
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
        
        // Set up single date selection
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection
        
        // Customize the calendar appearance
        calendarView.layer.cornerRadius = 16
        calendarView.backgroundColor = .systemBackground
        
        // Set content insets to make it more compact
        calendarView.layoutMargins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        
        // Set available date range
        if let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()),
           let oneMonthFromNow = calendar.date(byAdding: Calendar.Component.month, value: 1, to: Date()) {
            calendarView.availableDateRange = DateInterval(start: oneYearAgo, end: oneMonthFromNow)
        }
        
        // Configure appearance
        calendarView.tintColor = UIColor(named: "GrowthGreen")
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Update calendar if firstDayOfWeek changed
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = ThemeManager.shared.firstDayOfWeek
        if uiView.calendar.firstWeekday != calendar.firstWeekday {
            uiView.calendar = calendar
        }
        
        // Update decorations when the view model changes
        context.coordinator.parent = self
        uiView.reloadDecorations(forDateComponents: getAllDateComponents(), animated: true)
        
        // Update selection if needed
        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            if let date = selectedDate {
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                selection.selectedDate = components
            } else {
                selection.selectedDate = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    private func getAllDateComponents() -> [DateComponents] {
        let calendar = Calendar.current
        var components: [DateComponents] = []
        
        // Get date components for the last year
        if let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) {
            var currentDate = oneYearAgo
            while currentDate <= Date() {
                components.append(calendar.dateComponents([.year, .month, .day], from: currentDate))
                if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                    currentDate = nextDate
                } else {
                    break
                }
            }
        }
        
        return components
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: ProgressCalendarUIView
        
        init(parent: ProgressCalendarUIView) {
            self.parent = parent
        }
        
        // Handle date selection from UICalendarSelectionSingleDateDelegate
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            if let dateComponents = dateComponents,
               let date = Calendar.current.date(from: dateComponents) {
                parent.selectedDate = date
            } else {
                parent.selectedDate = nil
            }
        }
        
        // Provide decorations for dates
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            
            // Get activity data for this date
            let startOfDay = Calendar.current.startOfDay(for: date)
            let minutes = parent.viewModel.dailyMinutes[startOfDay] ?? 0
            let hasActivity = minutes > 0
            
            // Check if this date is part of logged dates
            let isLogged = parent.viewModel.loggedDates.contains(dateComponents)
            
            if hasActivity || isLogged {
                // Create decoration based on activity duration
                if minutes >= 30 {
                    // Strong green for 30+ minutes
                    return .default(color: UIColor(named: "GrowthGreen") ?? .systemGreen, size: .large)
                } else if minutes >= 15 {
                    // Medium green for 15-29 minutes
                    return .default(color: UIColor(named: "BrightTeal") ?? .systemTeal, size: .medium)
                } else if minutes > 0 {
                    // Light green for 1-14 minutes
                    return .default(color: UIColor(named: "MintGreen") ?? .systemGreen.withAlphaComponent(0.6), size: .small)
                } else if isLogged {
                    // Gray for logged but no duration recorded
                    return .default(color: .systemGray3, size: .small)
                }
            }
            
            return nil
        }
    }
}

// UIKit-based Calendar View for older iOS versions
@available(iOS, deprecated: 16.0, message: "Use ProgressCalendarView instead")
struct LegacyProgressCalendarView: UIViewRepresentable {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var selectedDate: Date?
    
    func makeUIView(context: Context) -> UIView {
        // Create a container view
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        // Add a label indicating calendar is not available
        let label = UILabel()
        label.text = "Calendar view requires iOS 16+"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed for the fallback view
    }
}

// Wrapper view that chooses the appropriate implementation
struct ProgressCalendarViewWrapper: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var selectedDate: Date?
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ProgressCalendarView(viewModel: viewModel, selectedDate: $selectedDate)
        } else {
            LegacyProgressCalendarView(viewModel: viewModel, selectedDate: $selectedDate)
                .frame(height: 350)
                .background(Color(.systemGroupedBackground))
                .cornerRadius(16)
        }
    }
}

@available(iOS 16.0, *)
struct ProgressCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @StateObject var viewModel = ProgressViewModel()
            @State var selectedDate: Date? = nil
            
            var body: some View {
                ProgressCalendarView(viewModel: viewModel, selectedDate: $selectedDate)
                    .frame(height: 400)
                    .background(Color(.systemGroupedBackground))
            }
        }
        
        return PreviewWrapper()
    }
}