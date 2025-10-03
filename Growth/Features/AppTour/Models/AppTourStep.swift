import Foundation
import SwiftUI

/// Represents a single step in the app tour
struct AppTourStep: Identifiable, Equatable {
    let id: String
    let targetViewId: String
    let title: String
    let description: String
    let highlightPadding: CGFloat
    let position: PopoverPosition
    let buttonTitle: String
    let isLastStep: Bool
    
    init(
        id: String,
        targetViewId: String,
        title: String,
        description: String,
        highlightPadding: CGFloat = 8,
        position: PopoverPosition = .automatic,
        buttonTitle: String = "Next",
        isLastStep: Bool = false
    ) {
        self.id = id
        self.targetViewId = targetViewId
        self.title = title
        self.description = description
        self.highlightPadding = highlightPadding
        self.position = position
        self.buttonTitle = buttonTitle
        self.isLastStep = isLastStep
    }
}

/// Defines where the popover should appear relative to the highlighted element
enum PopoverPosition: Equatable {
    case automatic
    case above
    case below
    case leading
    case trailing
    case custom(x: CGFloat, y: CGFloat)
}

/// Configuration for the entire app tour
struct AppTourConfiguration {
    let steps: [AppTourStep]
    let allowSkip: Bool
    let showProgress: Bool
    
    init(
        steps: [AppTourStep],
        allowSkip: Bool = true,
        showProgress: Bool = true
    ) {
        self.steps = steps
        self.allowSkip = allowSkip
        self.showProgress = showProgress
    }
    
    /// Default app tour configuration for first-time users
    static var defaultTour: AppTourConfiguration {
        let steps = [
            // Story 20.2: Dashboard tour steps
            AppTourStep(
                id: "dashboard_overview",
                targetViewId: "dashboard_title",
                title: "Your Daily Dashboard",
                description: "Start each day here. See what to practice and track your progress.",
                highlightPadding: 20,
                position: .below
            ),
            // New step: Today's Focus
            AppTourStep(
                id: "todays_focus",
                targetViewId: "todays_focus",
                title: "Today's Focus",
                description: "Your daily practice recommendation appears here. This section shows what method to focus on today based on your routine.",
                highlightPadding: 16,
                position: .below,
                buttonTitle: "Next",
                isLastStep: false
            ),
            AppTourStep(
                id: "weekly_progress",
                targetViewId: "weekly_progress_snapshot",
                title: "Weekly Progress",
                description: "Monitor your streak and weekly activity at a glance.",
                highlightPadding: 25,
                position: .above,
                buttonTitle: "Next",
                isLastStep: false
            ),
            // Story 20.3: Routines tab tour step
            AppTourStep(
                id: "routines_tab",
                targetViewId: "routines_tab_item",
                title: "Structured Programs",
                description: "Explore the 'Routines' tab to find guided, multi-week programs designed to help you progress consistently.",
                highlightPadding: 16,
                position: .above,
                buttonTitle: "Next",
                isLastStep: false
            ),
            // Story 20.4: Practice tab tour step
            AppTourStep(
                id: "practice_tab",
                targetViewId: "practice_tab_item",
                title: "Quick Practice",
                description: "Want to do a quick, unscheduled session? The 'Practice' tab lets you choose and perform any method you've unlocked.",
                highlightPadding: 12,
                position: .above,
                buttonTitle: "Next",
                isLastStep: false
            ),
            // Story 20.5: Progress tab tour step
            AppTourStep(
                id: "progress_tab",
                targetViewId: "progress_tab_item",
                title: "Track Your Journey",
                description: "Track your journey in the 'Progress' tab. Here you'll find your detailed session history, stats, and achievements all in one place.",
                highlightPadding: 12,
                position: .above,
                buttonTitle: "Next",
                isLastStep: false
            ),
            // Story 20.6: Learn tab tour step
            AppTourStep(
                id: "learn_tab",
                targetViewId: "learn_tab_item",
                title: "Have Questions?",
                description: "Have questions? Our AI 'Coach' is here to help guide you based on the app's content and community insights. Tap the 'Learn' tab and select 'AI Coach' any time you need support.",
                highlightPadding: 12,
                position: .above,
                buttonTitle: "Done",
                isLastStep: true
            )
        ]
        
        return AppTourConfiguration(steps: steps)
    }
}

/// Preference key for capturing view frames
struct TourFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}