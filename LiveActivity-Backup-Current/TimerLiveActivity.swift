//
//  TimerLiveActivity.swift
//  GrowthTimerWidget
//
//  Built from scratch based on research from:
//  - expo-live-activity-timer patterns
//  - Apple Live Activity documentation
//  - ProgressView and Text(timerInterval:) best practices
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Live Activity Colors
// These colors match the app's dark mode design system
extension Color {
    // Primary text color - light in dark mode, dark in light mode
    static let liveActivityText = Color(
        light: Color(red: 33/255, green: 33/255, blue: 33/255), // #212121
        dark: Color(red: 245/255, green: 245/255, blue: 245/255) // #F5F5F5
    )
    
    // Secondary text color
    static let liveActivitySecondaryText = Color(
        light: Color(red: 158/255, green: 158/255, blue: 158/255), // #9E9E9E
        dark: Color(red: 176/255, green: 190/255, blue: 197/255) // #B0BEC5
    )
    
    // App primary color - Growth app blue
    static let liveActivityPrimary = Color(
        light: Color(red: 0.0, green: 0.478, blue: 1.0), // Light mode blue
        dark: Color(red: 0.2, green: 0.6, blue: 1.0) // Dark mode blue
    )
    
    // Success/accent color - Growth green
    static let liveActivityAccent = Color(
        light: Color(red: 10/255, green: 80/255, blue: 66/255), // #0A5042
        dark: Color(red: 38/255, green: 166/255, blue: 154/255) // #26A69A
    )
    
    // Error color
    static let liveActivityError = Color(red: 229/255, green: 57/255, blue: 53/255) // #E53935
    
    // Background color for dark mode
    static let liveActivityBackground = Color(red: 26/255, green: 42/255, blue: 39/255) // #1A2A27
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

@available(iOS 16.1, *)
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen/Banner UI - based on research best practices
            LockScreenView(context: context)
                .activityBackgroundTint(.liveActivityBackground)
                .activitySystemActionForegroundColor(.liveActivityText)
                
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - following expo-live-activity-timer pattern
                ExpandedContent(context: context)
            } compactLeading: {
                // Timer icon - app colored
                Image(systemName: "timer")
                    .font(.system(size: 16))
                    .foregroundColor(.liveActivityPrimary)
            } compactTrailing: {
                // Timer display - using Text(timerInterval:) as researched
                LiveActivityTimerDisplay(context: context, size: .compact)
                    .frame(width: 40)
            } minimal: {
                // Minimal display - just icon with running indicator
                MinimalView(context: context)
            }
            .widgetURL(URL(string: "growth://timer"))
            .keylineTint(Color("AccentColor"))
        }
    }
}

// MARK: - Lock Screen View (Based on Research)

@available(iOS 16.1, *)
struct LockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with method name
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 16))
                    .foregroundColor(.liveActivityAccent)
                
                Text(context.state.methodName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.liveActivityText)
                    .lineLimit(1)
                
                Spacer()
                
                // Status indicator when paused
                if !context.state.isRunning {
                    Text("PAUSED")
                        .font(.caption)
                        .foregroundColor(.liveActivityError)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.liveActivityError.opacity(0.15)))
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    // Timer display using research-based approach
                    LiveActivityTimerDisplay(context: context, size: .large)
                    
                    // Progress view - as recommended in research
                    ProgressView(value: context.state.progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(height: 4)
                        .tint(Color.liveActivityPrimary)
                }
                
                Spacer()
                
                // Status icon
                Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(context.state.isRunning ? .liveActivityPrimary : .liveActivityError)
            }
            
            // Interactive buttons - iOS 17+ only
            if #available(iOS 17.0, *) {
                InteractiveButtons(context: context)
            }
        }
        .padding(16)
    }
}

// MARK: - Timer Display Component (Based on Text(timerInterval:) Research)

@available(iOS 16.1, *)
struct LiveActivityTimerDisplay: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    let size: DisplaySize
    
    enum DisplaySize {
        case compact, large
        
        var fontSize: CGFloat {
            switch self {
            case .compact: return 12
            case .large: return 32
            }
        }
    }
    
    @ViewBuilder
    var body: some View {
        if context.state.isRunning {
            // Live updating timer - fixed for proper countup display
            if context.state.sessionType == .countdown {
                // Countdown timer - show remaining time
                Text(timerInterval: context.state.startedAt...context.state.endTime,
                     pauseTime: nil,
                     countsDown: true,
                     showsHours: false)
                    .font(.system(size: size.fontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(.liveActivityText)
                    .monospacedDigit()
            } else {
                // Countup timer - show elapsed time
                Text(timerInterval: context.state.startedAt...Date().addingTimeInterval(86400),
                     pauseTime: nil,
                     countsDown: false,
                     showsHours: false)
                    .font(.system(size: size.fontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(.liveActivityText)
                    .monospacedDigit()
            }
        } else {
            // Static time display when paused - show remaining time
            Text(context.state.getFormattedRemainingTime())
                .font(.system(size: size.fontSize, weight: .bold, design: .monospaced))
                .foregroundColor(.liveActivityText)
                .monospacedDigit()
        }
    }
}

// MARK: - Interactive Buttons (Based on App Intent Research)

@available(iOS 17.0, *)
struct InteractiveButtons: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            Button(intent: TimerControlIntent(action: context.state.isRunning ? .pause : .resume, activityId: context.activityID, timerType: context.attributes.timerType)) {
                HStack {
                    Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                    Text(context.state.isRunning ? "Pause" : "Resume")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.liveActivityText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(Color.liveActivityPrimary.opacity(0.3)))
            }
            .buttonStyle(.plain)
            
            Button(intent: TimerControlIntent(action: .stop, activityId: context.activityID, timerType: context.attributes.timerType)) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.liveActivityText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(Color.liveActivityError.opacity(0.3)))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Minimal View

@available(iOS 16.1, *)
struct MinimalView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        ZStack {
            Image(systemName: "timer")
                .font(.system(size: 12))
                .foregroundColor(.liveActivityAccent)
            
            // Pause indicator
            if !context.state.isRunning {
                Circle()
                    .fill(Color.liveActivityError)
                    .frame(width: 4, height: 4)
                    .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Expanded Content (Based on Dynamic Island Research)

@available(iOS 16.1, *)
@DynamicIslandExpandedContentBuilder
private func ExpandedContent(context: ActivityViewContext<TimerActivityAttributes>) -> DynamicIslandExpandedContent<some View> {
    DynamicIslandExpandedRegion(.leading) {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 16))
                    .foregroundColor(.liveActivityAccent)
                
                Text(context.state.methodName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.liveActivityText)
                    .lineLimit(1)
            }
            
            if !context.state.isRunning {
                Text("PAUSED")
                    .font(.caption2)
                    .foregroundColor(.liveActivityError)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.liveActivityError.opacity(0.2)))
            }
        }
    }
    
    DynamicIslandExpandedRegion(.trailing) {
        VStack(spacing: 4) {
            LiveActivityTimerDisplay(context: context, size: .large)
            
            // Progress view as researched
            ProgressView(value: context.state.progress, total: 1.0)
                .progressViewStyle(.linear)
                .frame(width: 60, height: 3)
                .tint(Color.liveActivityPrimary)
            
            Text(context.state.isRunning ? "elapsed" : "remaining")
                .font(.caption2)
                .foregroundColor(.liveActivitySecondaryText)
        }
    }
    
    DynamicIslandExpandedRegion(.bottom) {
        if #available(iOS 17.0, *) {
            HStack(spacing: 12) {
                Button(intent: TimerControlIntent(action: context.state.isRunning ? .pause : .resume, activityId: context.activityID, timerType: context.attributes.timerType)) {
                    HStack(spacing: 4) {
                        Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                        Text(context.state.isRunning ? "Pause" : "Resume")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.liveActivityText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .fill(Color.liveActivityPrimary.opacity(0.3)))
                }
                .buttonStyle(.plain)
                
                Button(intent: TimerControlIntent(action: .stop, activityId: context.activityID, timerType: context.attributes.timerType)) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.liveActivityText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.liveActivityError.opacity(0.3)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - TimerAction is defined in TimerAction.swift

// MARK: - TimerControlIntent is defined in AppIntents/TimerControlIntent.swift