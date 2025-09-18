import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 16.2, *)
struct GrowthTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI
            TimerLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.1, green: 0.1, blue: 0.12))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Leading icon
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundColor(Color("MintGreen"))
                        .font(.system(size: 20))
                        .padding(.horizontal, 2)
                }
                
                // Trailing - show paused indicator
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.pausedAt != nil {
                        Text("PAUSED")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .tracking(1.0)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.orange.opacity(0.2)))
                            .fixedSize()
                    } else {
                        EmptyView()
                    }
                }
                
                // Center content
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        Text(context.state.methodName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TimerDisplayView(state: context.state)
                    }
                }
                
                // Bottom controls
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Progress bar for countdown - conditional based on running state
                        if context.state.isRunning {
                            // Live updating progress when running
                            ProgressView(timerInterval: context.state.startedAt...context.state.endTime, 
                                        countsDown: false,
                                        label: { EmptyView() },
                                        currentValueLabel: { EmptyView() })
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(height: 4)
                                .tint(Color("MintGreen"))
                        } else {
                            // Static progress when paused
                            ProgressView(value: context.state.progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(height: 4)
                                .tint(Color("MintGreen"))
                        }
                        
                    if #available(iOS 17.0, *) {
                        HStack(spacing: 8) {
                            // Use separate intents for pause/resume
                            if context.state.pausedAt != nil {
                                Button(intent: ResumeTimerIntent(
                                    activityId: context.activityID,
                                    timerType: "main"
                                )) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 10))
                                        Text("Resume")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("MintGreen").opacity(0.5)))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(intent: PauseTimerIntent(
                                    activityId: context.activityID,
                                    timerType: "main"
                                )) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "pause.fill")
                                            .font(.system(size: 10))
                                        Text("Pause")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("MintGreen").opacity(0.5)))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Stop button with intent that opens app
                            Button(intent: StopTimerAndOpenAppIntent(
                                activityId: context.activityID,
                                timerType: "main"
                            )) {
                                HStack(spacing: 4) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 10))
                                    Text("Stop")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.5)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                    } else {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: context.state.pausedAt != nil ? "play.fill" : "pause.fill")
                                    .font(.system(size: 10))
                                Text(context.state.pausedAt != nil ? "Resume" : "Pause")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(Color("MintGreen").opacity(0.5)))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 10))
                                Text("Stop")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.5)))
                        }
                        .padding(.horizontal, 12)
                    }
                    }
                }
                
            } compactLeading: {
                if context.state.pausedAt != nil {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "timer")
                        .foregroundColor(Color("MintGreen"))
                }
                    
            } compactTrailing: {
                CompactTimerView(state: context.state)
                    .frame(width: 50)
                    
            } minimal: {
                if context.state.pausedAt != nil {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "timer")
                        .foregroundColor(Color("MintGreen"))
                }
            }
        }
    }
}

// Separate view for timer display using native Text(timerInterval:)
@available(iOS 16.1, *)
struct TimerDisplayView: View {
    let state: TimerActivityAttributes.ContentState
    
    var body: some View {
        // Countdown timer - show static text when paused due to iOS limitation
        if state.pausedAt != nil {
            // When paused, show static remaining time
            Text(state.getFormattedRemainingTime())
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .monospacedDigit()
        } else {
            // When running, show live countdown
            Text(timerInterval: state.startedAt...state.endTime, 
                 countsDown: true,
                 showsHours: true)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .monospacedDigit()
        }
    }
}

// Compact timer view using native Text(timerInterval:)
@available(iOS 16.1, *)
struct CompactTimerView: View {
    let state: TimerActivityAttributes.ContentState
    
    var body: some View {
        // Countdown timer - show static text when paused due to iOS limitation
        if state.pausedAt != nil {
            // When paused, show static remaining time (compact format)
            Text(formatCompactTime(state.getTimeRemaining()))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
        } else {
            // When running, show live countdown
            Text(timerInterval: state.startedAt...state.endTime, 
                 countsDown: true,
                 showsHours: false)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
    
    // Helper function for compact time formatting without hours
    private func formatCompactTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// Lock screen view
@available(iOS 16.2, *)
struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Label {
                    Text(context.state.methodName)
                        .font(.headline)
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "timer")
                        .foregroundColor(Color("MintGreen"))
                }
                
                Spacer()
                
                if context.state.pausedAt != nil {
                    Text("PAUSED")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                }
            }
            
            // Timer display
            TimerDisplayView(state: context.state)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
            
            // Progress bar for countdown - conditional based on running state to handle pause correctly
            if context.state.isRunning {
                // Live updating progress when running
                ProgressView(timerInterval: context.state.startedAt...context.state.endTime, 
                             countsDown: false,
                             label: {
                                 EmptyView()
                             }, 
                             currentValueLabel: {
                                 EmptyView()
                             })
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(Color("MintGreen"))
            } else {
                // Static progress when paused
                ProgressView(value: context.state.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(Color("MintGreen"))
            }
            
            // Control buttons with intents for iOS 17+
            HStack {
                if #available(iOS 17.0, *) {
                    // Use separate intents for pause/resume
                    if context.state.pausedAt != nil {
                        Button(intent: ResumeTimerIntent(
                            activityId: context.activityID,
                            timerType: "main"
                        )) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Resume")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("MintGreen").opacity(0.5)))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(intent: PauseTimerIntent(
                            activityId: context.activityID,
                            timerType: "main"
                        )) {
                            HStack {
                                Image(systemName: "pause.fill")
                                Text("Pause")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("MintGreen").opacity(0.5)))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Stop button with intent that opens app
                    Button(intent: StopTimerAndOpenAppIntent(
                        activityId: context.activityID,
                        timerType: "main"
                    )) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                } else {
                    // Fallback for iOS 16 - visual only
                    HStack {
                        Image(systemName: context.state.pausedAt != nil ? "play.fill" : "pause.fill")
                        Text(context.state.pausedAt != nil ? "Resume" : "Pause")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.15)))
                    
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.5)))
                }
            }
        }
        .padding()
    }
}
