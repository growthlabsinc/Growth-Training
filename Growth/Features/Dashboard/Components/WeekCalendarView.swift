import SwiftUI

/// Horizontal, scrollable 7-day calendar component to be shown on the Dashboard (Story 12.6).
struct WeekCalendarView: View {
    @ObservedObject var viewModel: WeekCalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Month Year, bold, uppercase, left-aligned
            Text(viewModel.monthYearHeader)
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundColor(.primary)
                .textCase(.uppercase)
                .padding(.horizontal)
                .padding(.bottom, 2)

            // Week row with navigation arrows
            HStack(alignment: .center, spacing: 0) {
                Button(action: { viewModel.goToPreviousWeek() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(.darkGray).opacity(0.85))
                        .frame(width: 36, height: 48)
                }
                .accessibilityLabel("Previous week")

                Spacer(minLength: 0)

                ForEach(viewModel.days) { day in
                    DayCell(day: day,
                            isSelected: Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate),
                            onTap: { viewModel.select(date: day.date) })
                }

                Spacer(minLength: 0)

                Button(action: { viewModel.goToNextWeek() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(.darkGray).opacity(0.85))
                        .frame(width: 36, height: 48)
                }
                .accessibilityLabel("Next week")
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Day Cell
private struct DayCell: View {
    let day: DayViewModel
    let isSelected: Bool
    let onTap: () -> Void

    private var textColor: Color {
        Color(.systemGray)
    }

    private var dotColor: Color {
        // Check if the day is in the future
        let today = Calendar.current.startOfDay(for: Date())
        let dayDate = Calendar.current.startOfDay(for: day.date)
        let isInFuture = dayDate > today
        
        // Only show dots for past/present days with sessions
        if day.hasSession {
            // Show green dot for days with logged sessions
            return Color("GrowthGreen")
        } else if isInFuture {
            // Never show dots for future days
            return Color.clear
        } else if day.isRestDay {
            // Show pale green for rest days (past/present only)
            return Color("PaleGreen")
        } else if day.isRoutineDay {
            // Show teal for scheduled routine days (past/present only)
            return Color("BrightTeal")
        } else if day.isToday {
            // Show neutral for today if no routine
            return Color("NeutralGray")
        } else {
            return Color.clear
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if day.isToday {
                    Capsule()
                        .fill(Color(red: 0.901, green: 0.957, blue: 0.941)) // Pale Green
                        .frame(width: 30, height: 66)
                        .zIndex(0) // ensure background
                }
                if isSelected {
                    Capsule()
                        .stroke(Color(red: 0.04, green: 0.31, blue: 0.26), lineWidth: 2) // Core Green outline only
                        .frame(width: 36, height: 72)
                        .zIndex(1)
                }
                VStack(spacing: 2) {
                    Text(day.weekdaySymbol)
                        .font(.system(size: 10, weight: .medium, design: .default))
                        .foregroundColor(textColor)
                    Text(day.dayNumber)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(textColor)
                    // Dot color-coded for workout vs. rest days
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                        .padding(.top, 2)
                }
                .frame(width: 44, height: 60)
            }
        }
        .frame(width: 36, height: 80)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#if DEBUG
struct WeekCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        WeekCalendarView(viewModel: WeekCalendarViewModel())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 