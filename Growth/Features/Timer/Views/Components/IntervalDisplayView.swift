//
//  IntervalDisplayView.swift
//  Growth
//
//  Created by Developer on <CURRENT_DATE>.
//

import SwiftUI

struct IntervalDisplayView: View {
    let intervalName: String?
    let intervalProgress: Double // 0.0 to 1.0
    let overallProgress: Double // 0.0 to 1.0
    let currentIntervalIndex: Int?
    let totalIntervals: Int?

    var body: some View {
        // Story 7.3: Determine if current interval is a break
        let isBreakInterval = intervalName?.lowercased().contains("break") == true || 
                              intervalName?.lowercased().contains("rest") == true

        // Uncommented and enhanced for Story 7.3
        return VStack(alignment: .leading, spacing: AppTheme.Layout.spacingS) {
            if let name = intervalName, let index = currentIntervalIndex, let total = totalIntervals {
                Text("Interval \(index + 1) of \(total): \(name)")
                    .font(isBreakInterval ? AppTheme.Typography.title3Font() : AppTheme.Typography.subheadlineFont())
                    .foregroundColor(isBreakInterval ? AppTheme.Colors.secondary : AppTheme.Colors.textSecondary)
                    .padding(isBreakInterval ? AppTheme.Layout.spacingS : 0)
                    .background(isBreakInterval ? AppTheme.Colors.secondary.opacity(0.1) : Color.clear)
                    .cornerRadius(isBreakInterval ? AppTheme.Layout.cornerRadiusS : 0)
                
                SwiftUI.ProgressView(value: intervalProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: isBreakInterval ? AppTheme.Colors.secondary : AppTheme.Colors.accent))
                    .frame(height: AppTheme.Layout.spacingS)
            }
            
            if (totalIntervals ?? 0) > 1 { // Show overall progress only if there are multiple intervals
                 VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
                    Text("Overall Progress")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    SwiftUI.ProgressView(value: overallProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.primary))
                        .frame(height: AppTheme.Layout.spacingS)
                }
                .padding(.top, AppTheme.Layout.spacingM)
            }
        }
        .padding()
        .background(AppTheme.Colors.card.opacity(0.5))
        .cornerRadius(AppTheme.Layout.cornerRadiusM)
    }
}

#if DEBUG
struct IntervalDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IntervalDisplayView(
                intervalName: "Warm Up",
                intervalProgress: 0.5,
                overallProgress: 0.25,
                currentIntervalIndex: 0,
                totalIntervals: 3
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Active Interval")
            
            IntervalDisplayView(
                intervalName: nil, // No active interval (e.g. stopwatch mode)
                intervalProgress: 0,
                overallProgress: 0,
                currentIntervalIndex: nil,
                totalIntervals: nil
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("No Interval (Stopwatch)")
            
             IntervalDisplayView(
                intervalName: "Phase 1",
                intervalProgress: 1.0, // Interval complete
                overallProgress: 0.9, // Overall nearing end
                currentIntervalIndex: 2,
                totalIntervals: 3
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Last Interval Near End")

            // Story 7.3: Add preview for a break interval
            IntervalDisplayView(
                intervalName: "Break Time",
                intervalProgress: 0.3,
                overallProgress: 0.6,
                currentIntervalIndex: 1,
                totalIntervals: 4
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Break Interval")
        }
        .background(AppTheme.Colors.background)
    }
}
#endif 