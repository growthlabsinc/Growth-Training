//
//  GrowthTimerWidgetLiveActivity.swift
//  GrowthTimerWidget
//
//  Created by TradeFlowJ on 6/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// Helper functions for time formatting
fileprivate func formatTime(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    let seconds = Int(interval) % 60
    
    if hours > 0 {
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

fileprivate func compactTimeFormat(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    let minutes = totalSeconds / 60
    let secs = totalSeconds % 60
    
    if minutes >= 60 {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%d:%02d", hours, mins)
    } else {
        return String(format: "%d:%02d", minutes, secs)
    }
}

@available(iOS 16.1, *)
struct GrowthTimerWidgetLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            TimerLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.1, green: 0.1, blue: 0.12))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            // Get current state
            let state = context.state
            
            return DynamicIsland {
                // Expanded UI with better visual hierarchy
                DynamicIslandExpandedRegion(.leading) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "timer")
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                            .font(.system(size: 20, weight: .medium))
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if #available(iOS 17.0, *) {
                        Button(intent: TimerControlIntent(
                            action: .stop,
                            activityId: context.activityID,
                            timerType: context.attributes.timerType
                        )) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    } else {
                        Button(intent: TimerControlIntentLegacy(
                            action: .stop,
                            activityId: context.activityID,
                            timerType: context.attributes.timerType
                        )) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 0) {
                        // Method name and type at the top (more compact)
                        HStack(spacing: 4) {
                            Text(state.methodName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            Text(state.sessionType.rawValue.uppercased())
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 8)
                        
                        // Timer display with inline PAUSED indicator
                        HStack(spacing: 8) {
                            if state.sessionType == .countdown {
                                // Use Text(timerInterval:) for automatic countdown
                                if !state.isPaused {
                                    Text(timerInterval: state.startTime...state.endTime, countsDown: true)
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                } else {
                                    // Show static time when paused
                                    Text(formatTime(state.currentRemainingTime))
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                }
                            } else {
                                // Count-up timer using timerInterval
                                if !state.isPaused {
                                    Text(timerInterval: state.startTime...Date.distantFuture, countsDown: false)
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                } else {
                                    // Show static time when paused
                                    Text(formatTime(state.currentElapsedTime))
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                }
                            }
                            
                            // Inline PAUSED indicator
                            if state.isPaused {
                                Text("PAUSED")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        // Progress bar for countdown timers in Dynamic Island
                        if state.sessionType == .countdown {
                            if !state.isPaused {
                                // Use timerInterval for automatic progress updates
                                ProgressView(timerInterval: state.startTime...state.endTime, countsDown: false)
                                    .tint(Color(red: 0.2, green: 0.8, blue: 0.4))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 2)
                            } else {
                                // Show static progress when paused
                                let totalDuration = context.attributes.totalDuration
                                let progressValue = totalDuration > 0 ? min(max(state.currentElapsedTime / totalDuration, 0), 1) : 0
                                
                                ProgressView(value: progressValue, total: 1.0)
                                    .tint(Color(red: 0.2, green: 0.8, blue: 0.4))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 0) {
                        if #available(iOS 17.0, *) {
                            Button(intent: TimerControlIntent(
                                action: state.isPaused ? .resume : .pause,
                                activityId: context.activityID,
                                timerType: context.attributes.timerType
                            )) {
                                HStack(spacing: 6) {
                                    Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                                        .font(.system(size: 12, weight: .medium))
                                    Text(state.isPaused ? "Resume" : "Pause")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.3),
                                                Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.2)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(intent: TimerControlIntentLegacy(
                                action: state.isPaused ? .resume : .pause,
                                activityId: context.activityID,
                                timerType: context.attributes.timerType
                            )) {
                                HStack(spacing: 6) {
                                    Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                                        .font(.system(size: 12, weight: .medium))
                                    Text(state.isPaused ? "Resume" : "Pause")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.3),
                                                Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.2)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } // End VStack
                    .padding(.horizontal, 12)
                } // End DynamicIslandExpandedRegion(.bottom)
            } compactLeading: {
                // Compact leading - just a small timer icon
                Image(systemName: state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .frame(width: 36) // Fixed width to prevent expansion
            } compactTrailing: {
                // Compact trailing - minimal time display
                HStack(spacing: 2) {
                    if state.sessionType == .countdown {
                        // Use timer interval for running timers
                        if !state.isPaused {
                            Text(timerInterval: state.startTime...state.endTime, countsDown: true)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 44) // Minimum width to prevent jumping
                        } else {
                            // Show static time when paused
                            Text(compactTimeFormat(state.currentRemainingTime))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 44)
                        }
                    } else {
                        // Count-up timer
                        if !state.isPaused {
                            Text(timerInterval: state.startTime...Date.distantFuture, countsDown: false)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 44)
                        } else {
                            // Show static time when paused
                            Text(compactTimeFormat(state.currentElapsedTime))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 44)
                        }
                    }
                }
                .frame(maxWidth: 52) // Maximum width constraint
            } minimal: {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "timer")
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .font(.system(size: 16, weight: .medium))
                }
            }
        } // End DynamicIsland
    } // End body property
} // End struct

@available(iOS 16.1, *)
struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var state: TimerActivityAttributes.ContentState {
        context.state
    }
    
    // Theme colors that work in widget context
    let primaryGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    let brightTeal = Color(red: 0.0, green: 0.8, blue: 0.8)
    let backgroundDark = Color(red: 0.1, green: 0.1, blue: 0.12)
    
    func formatFullTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        // Check if completed
        if state.isCompleted {
            // Completion view
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(primaryGreen.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(primaryGreen)
                        }
                        
                        Text("Session Complete!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let completionMessage = state.completionMessage {
                            Text(completionMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundDark,
                        backgroundDark.opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else {
            // Normal timer view
            VStack(spacing: 8) {
            // Header with method name and status
            HStack {
                // Method icon and name
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(primaryGreen.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "timer")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(primaryGreen)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.methodName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(state.sessionType.rawValue.capitalized)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if state.isPaused {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 12))
                        Text("PAUSED")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.8)
                    }
                    .foregroundColor(Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
            }
            
            // Timer Display
            VStack(spacing: 2) {
                // Use timer interval for automatic updates
                if state.sessionType == .countdown {
                    if !state.isPaused {
                        // Use timerInterval for automatic countdown
                        Text(timerInterval: state.startTime...state.endTime, countsDown: true)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    } else {
                        // Show static time when paused
                        Text(formatFullTime(state.currentRemainingTime))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                } else {
                    if !state.isPaused {
                        // Use timerInterval for automatic count-up
                        Text(timerInterval: state.startTime...Date.distantFuture, countsDown: false)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    } else {
                        // Show static time when paused
                        Text(formatFullTime(state.currentElapsedTime))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                }
                
                // Progress bar for countdown timers
                if state.sessionType == .countdown {
                    if !state.isPaused {
                        // Use timerInterval for automatic progress updates
                        ProgressView(timerInterval: state.startTime...state.endTime, countsDown: false)
                            .progressViewStyle(.linear)
                            .tint(primaryGreen)
                            .padding(.top, 4)
                    } else {
                        // Show static progress when paused
                        let totalDuration = context.attributes.totalDuration
                        let progressValue = totalDuration > 0 ? min(max(state.currentElapsedTime / totalDuration, 0), 1) : 0
                        
                        ProgressView(value: progressValue, total: 1.0)
                            .progressViewStyle(.linear)
                            .tint(primaryGreen)
                            .padding(.top, 4)
                    }
                }
            }
            
            // Control buttons
            HStack(spacing: 6) {
                if #available(iOS 17.0, *) {
                    // Pause/Resume button using LiveActivityIntent
                    Button(intent: TimerControlIntent(
                        action: state.isPaused ? .resume : .pause,
                        activityId: context.activityID,
                        timerType: context.attributes.timerType
                    )) {
                        HStack(spacing: 3) {
                            Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 13, weight: .medium))
                            Text(state.isPaused ? "Resume" : "Pause")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(primaryGreen.opacity(0.25))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Stop button using LiveActivityIntent
                    Button(intent: TimerControlIntent(
                        action: .stop,
                        activityId: context.activityID,
                        timerType: context.attributes.timerType
                    )) {
                        HStack(spacing: 3) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 13, weight: .medium))
                            Text("Stop")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.25))
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    // Pause/Resume button for iOS 16 using AppIntent
                    Button(intent: TimerControlIntentLegacy(
                        action: state.isPaused ? .resume : .pause,
                        activityId: context.activityID,
                        timerType: context.attributes.timerType
                    )) {
                        HStack(spacing: 3) {
                            Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 13, weight: .medium))
                            Text(state.isPaused ? "Resume" : "Pause")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(primaryGreen.opacity(0.25))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Stop button for iOS 16 using AppIntent
                    Button(intent: TimerControlIntentLegacy(
                        action: .stop,
                        activityId: context.activityID,
                        timerType: context.attributes.timerType
                    )) {
                        HStack(spacing: 3) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 13, weight: .medium))
                            Text("Stop")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.25))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            // Subtle gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    backgroundDark,
                    backgroundDark.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        } // End else block (normal timer view)
    }
}

// TimerControlIntent and TimerAction are defined in AppIntents/TimerControlIntent.swift