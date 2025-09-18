//
//  GrowthTimerLiveActivitySimplified.swift
//  GrowthTimerWidget
//
//  Simplified Live Activity implementation following Apple best practices
//  Based on official Apple documentation and reference implementations
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Live Activity Widget
// Note: Using TimerActivityAttributes from the main app for consistency

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct GrowthTimerLiveActivitySimplified: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI - following Apple design guidelines
            GrowthLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.1, green: 0.1, blue: 0.12))
                .activitySystemActionForegroundColor(.white)
                
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - following Apple layout guidelines
                GrowthExpandedContent(context: context)
            } compactLeading: {
                // App icon/logo - simple and recognizable
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
            } compactTrailing: {
                // Timer display - essential information only
                if !context.state.isRunning {
                    Text(context.state.getFormattedElapsedTime())
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .monospacedDigit()
                } else {
                    Text(timerInterval: context.state.startedAt...context.state.getFutureDate,
                         pauseTime: nil,
                         countsDown: false,
                         showsHours: false)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            } minimal: {
                // Minimal view - most essential info only
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
            }
            .widgetURL(URL(string: "growth://timer"))
            .keylineTint(Color(red: 0.2, green: 0.8, blue: 0.4))
        }
    }
}

// MARK: - Lock Screen View (Following Apple Guidelines)

@available(iOS 16.1, *)
struct GrowthLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with app branding - keep it simple
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                
                Text("Growth")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
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
            
            // Main content - method name and timer
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(context.state.methodName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Timer display with live updates
                    if !context.state.isRunning {
                        Text(context.state.getFormattedElapsedTime())
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    } else {
                        Text(timerInterval: context.state.startedAt...context.state.getFutureDate,
                             pauseTime: nil,
                             countsDown: false,
                             showsHours: false)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                }
                
                Spacer()
                
                // Simple visual indicator
                VStack {
                    Spacer()
                    
                    Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(context.state.isRunning ? 
                                       Color(red: 0.2, green: 0.8, blue: 0.4) : .orange)
                    
                    Spacer()
                }
            }
            
            // Control buttons - iOS 17+ only for App Intents
            if #available(iOS 17.0, *) {
                HStack(spacing: 12) {
                    Button(intent: GrowthTimerIntent(
                        action: context.state.isRunning ? .pause : .resume,
                        activityId: context.activityID
                    )) {
                        HStack {
                            Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                            Text(context.state.isRunning ? "Pause" : "Resume")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2)))
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: GrowthTimerIntent(
                        action: .stop,
                        activityId: context.activityID
                    )) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.3)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Dynamic Island Expanded Content

@available(iOS 16.1, *)
@DynamicIslandExpandedContentBuilder
private func GrowthExpandedContent(context: ActivityViewContext<TimerActivityAttributes>) -> DynamicIslandExpandedContent<some View> {
    DynamicIslandExpandedRegion(.leading) {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                
                Text(context.state.methodName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            if context.state.pausedAt != nil {
                Text("PAUSED")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
            }
        }
    }
    
    DynamicIslandExpandedRegion(.trailing) {
        VStack(spacing: 4) {
            // Timer display
            if !context.state.isRunning {
                Text(context.state.getFormattedElapsedTime())
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
            } else {
                Text(timerInterval: context.state.startedAt...context.state.getFutureDate,
                     pauseTime: nil,
                     countsDown: false,
                     showsHours: false)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            
            Text("elapsed")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    DynamicIslandExpandedRegion(.bottom) {
        if #available(iOS 17.0, *) {
            HStack(spacing: 12) {
                Button(intent: GrowthTimerIntent(
                    action: context.state.isRunning ? .pause : .resume,
                    activityId: context.activityID
                )) {
                    HStack(spacing: 4) {
                        Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                        Text(context.state.isRunning ? "Pause" : "Resume")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2)))
                }
                .buttonStyle(.plain)
                
                Button(intent: GrowthTimerIntent(
                    action: .stop,
                    activityId: context.activityID
                )) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.red.opacity(0.3)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - App Intent (iOS 17+)

@available(iOS 17.0, *)
struct GrowthTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Control Growth Timer"
    static var description = IntentDescription("Control the Growth timer from Live Activity")
    
    @Parameter(title: "Action")
    var action: GrowthTimerAction
    
    @Parameter(title: "Activity ID")
    var activityId: String
    
    init(action: GrowthTimerAction, activityId: String) {
        self.action = action
        self.activityId = activityId
    }
    
    init() {
        self.action = .pause
        self.activityId = ""
    }
    
    func perform() async throws -> some IntentResult {
        // Store action in app group for main app to handle
        if let sharedDefaults = AppGroupConstants.sharedDefaults {
            sharedDefaults.set(action.rawValue, forKey: AppGroupConstants.Keys.lastTimerAction)
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: AppGroupConstants.Keys.lastTimerActionTime)
            sharedDefaults.set(activityId, forKey: AppGroupConstants.Keys.currentTimerActivityId)
            sharedDefaults.synchronize()
        }
        
        // Update Live Activity state immediately for instant feedback
        switch action {
        case .pause, .resume:
            await LiveActivityUpdateManager.shared.updateActivityState(
                activityId: activityId, 
                isPaused: action == .pause
            )
        case .stop:
            await LiveActivityUpdateManager.shared.endActivity(activityId: activityId)
        }
        
        return .result()
    }
}

@available(iOS 16.1, *)
enum GrowthTimerAction: String, AppEnum {
    case pause = "pause"
    case resume = "resume"
    case stop = "stop"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Timer Action"
    
    static var caseDisplayRepresentations: [GrowthTimerAction: DisplayRepresentation] = [
        .pause: "Pause",
        .resume: "Resume", 
        .stop: "Stop"
    ]
}

// Note: Live Activity management is handled by LiveActivityManager in the main app target
// This file contains only the Live Activity widget UI implementation

// MARK: - Error Handling

enum LiveActivityError: Error {
    case notAuthorized
    case failedToStart
    case failedToUpdate
}

// Note: Preview support now uses TimerActivityAttributes from main app

// MARK: - Previews

// Preview support requires iOS 17+
#if os(iOS) && swift(>=5.9)
@available(iOS 17.0, *)
// Previews disabled - would need TimerActivityAttributes preview extensions
#endif