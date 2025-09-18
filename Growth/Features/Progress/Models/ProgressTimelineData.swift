import Foundation
import SwiftUI

/// Enumeration of selectable time ranges for the progress timeline (Story 14.6)
/// Week = 7 days starting today and going back 6, Month = last 30 days, Quarter = last 90, Year = last 365.
enum TimeRange: String, CaseIterable, Identifiable, Codable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    case all = "All"
    
    var id: String { rawValue }
    
    /// Number of days represented by this range
    var daySpan: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        case .all: return 3650 // 10 years approximate
        }
    }
    
    /// Alias for daySpan to match usage in code
    var numberOfDays: Int {
        return daySpan
    }
    
    /// Returns the start date for this time range relative to today, at start of day.
    var startDate: Date {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: -daySpan + 1, to: Date()) else {
            return Date()
        }
        return calendar.startOfDay(for: date)
    }
    
    /// Get the start date for this time range relative to a given date
    func startDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            guard let date = calendar.date(byAdding: .day, value: -6, to: date) else { return date }
            return calendar.startOfDay(for: date)
        case .month:
            guard let date = calendar.date(byAdding: .day, value: -29, to: date) else { return date }
            return calendar.startOfDay(for: date)
        case .quarter:
            guard let date = calendar.date(byAdding: .day, value: -89, to: date) else { return date }
            return calendar.startOfDay(for: date)
        case .year:
            guard let date = calendar.date(byAdding: .day, value: -364, to: date) else { return date }
            return calendar.startOfDay(for: date)
        case .all:
            guard let date = calendar.date(byAdding: .year, value: -10, to: date) else { return date }
            return calendar.startOfDay(for: date)
        }
    }
    
    /// Get the end date for this time range relative to a given date
    func endDate(from date: Date = Date()) -> Date {
        return date
    }
    
    /// Get the display name for the time range
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "This Quarter"
        case .year: return "This Year"
        case .all: return "All Time"
        }
    }
    
    /// Display title for the time range (alias for displayName)
    var displayTitle: String {
        return displayName
    }
    
    /// Short display title for compact UI
    var shortTitle: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        case .all: return "All"
        }
    }
    
    /// Get date components for use in date calculations
    var dateComponents: DateComponents {
        switch self {
        case .week:
            return DateComponents(weekOfYear: 1)
        case .month:
            return DateComponents(month: 1)
        case .quarter:
            return DateComponents(month: 3)
        case .year:
            return DateComponents(year: 1)
        case .all:
            return DateComponents(year: 10)
        }
    }
}

/// Aggregated practice data for a single date (Story 14.6)
struct ProgressTimelineData: Identifiable {
    var id: Date { date }
    let date: Date
    let totalMinutes: Int
} 