//
//  InlineTimerView.swift
//  Growth
//
//  Created by Developer on 6/5/25.
//

import SwiftUI

/// A compact inline timer view that can be embedded in any view
struct InlineTimerView: View {
    @StateObject private var timerService = TimerService.shared
    let method: GrowthMethod?
    let onExpand: (() -> Void)?
    
    @State private var isExpanded = false
    @StateObject private var quickPracticeTracker = QuickPracticeTimerTracker.shared
    @State private var showTimerConflictAlert = false
    
    init(method: GrowthMethod? = nil,
         onExpand: (() -> Void)? = nil) {
        self.method = method
        self.onExpand = onExpand
    }
    
    var body: some View {
        ZStack {
            if isExpanded {
                expandedView
            } else {
                compactView
            }
        }
        .background(timerConflictAlert)
    }
    
    // MARK: - Compact View
    
    private var compactView: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: toggleTimer) {
                Image(systemName: timerService.state == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color("GrowthGreen"))
                    .clipShape(Circle())
            }
            
            // Timer display
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTime)
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(Color("TextColor"))
                    .monospacedDigit()
                
                if let method = method {
                    Text(method.title)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Expand button
            if onExpand != nil {
                Button(action: { onExpand?() }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            
            // Stop button (only when running or paused)
            if timerService.state != .stopped {
                Button(action: stopTimer) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color("ErrorColor"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Expanded View
    
    private var expandedView: some View {
        VStack(spacing: 16) {
            // Header with collapse button
            HStack {
                Text("Timer")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("TextColor"))
                
                Spacer()
                
                Button(action: { isExpanded = false }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            
            // Timer display
            Text(displayTime)
                .font(AppTheme.Typography.gravitySemibold(48))
                .foregroundColor(Color("TextColor"))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
            
            // Progress bar
            if timerService.timerMode != .stopwatch {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("GrowthGreen")))
                    .frame(height: 6)
                    .background(Color("NeutralGray").opacity(0.2))
                    .cornerRadius(3)
            }
            
            // Method info
            if let method = method {
                VStack(alignment: .leading, spacing: 8) {
                    Text(method.title)
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(method.methodDescription)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Controls
            HStack(spacing: 20) {
                // Stop button
                Button(action: stopTimer) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("ErrorColor"))
                        .frame(width: 60, height: 60)
                        .background(Color("ErrorColor").opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Play/Pause button
                Button(action: toggleTimer) {
                    Image(systemName: timerService.state == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color("GrowthGreen"))
                        .clipShape(Circle())
                }
                
                // Expand to full screen
                if onExpand != nil {
                    Button(action: { onExpand?() }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 24))
                            .foregroundColor(Color("TextSecondaryColor"))
                            .frame(width: 60, height: 60)
                            .background(Color("NeutralGray").opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Computed Properties
    
    private var displayTime: String {
        switch timerService.timerMode {
        case .stopwatch:
            return formatTime(timerService.elapsedTime)
        case .countdown, .interval:
            return formatTime(timerService.remainingTime)
        }
    }
    
    private var progress: Double {
        switch timerService.timerMode {
        case .stopwatch:
            return 0
        case .countdown:
            guard let totalDuration = timerService.totalDuration, totalDuration > 0 else { return 0 }
            return timerService.elapsedTime / totalDuration
        case .interval:
            guard let intervalDuration = timerService.intervalDuration, intervalDuration > 0 else { return 0 }
            let elapsedInInterval = timerService.elapsedTime.truncatingRemainder(dividingBy: intervalDuration)
            return elapsedInInterval / intervalDuration
        }
    }
    
    // MARK: - Actions
    
    private func toggleTimer() {
        switch timerService.state {
        case .running:
            timerService.pause()
        case .paused, .stopped, .completed:
            // Check if quick practice timer is running
            if quickPracticeTracker.isTimerActive {
                showTimerConflictAlert = true
                return
            }
            // Configure timer for method if needed
            if timerService.state == .stopped || timerService.state == .completed, let method = method {
                configureTimer(for: method)
            }
            timerService.start()
        }
    }
    
    private func stopTimer() {
        timerService.stop()
    }
    
    private func configureTimer(for method: GrowthMethod) {
        // Set method ID and name for tracking
        timerService.currentMethodId = method.id
        timerService.currentMethodName = method.title
        
        // Configure timer based on method configuration
        if let config = method.timerConfig {
            timerService.configure(with: config)
        } else {
            // Default to stopwatch mode if no configuration
            timerService.configure(with: TimerConfiguration(
                recommendedDurationSeconds: nil,
                isCountdown: false,
                hasIntervals: false,
                intervals: nil,
                maxRecommendedDurationSeconds: method.estimatedDurationMinutes.map { $0 * 60 }
            ))
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Alert for timer conflict
    private var timerConflictAlert: some View {
        EmptyView()
            .alert("Timer Already Running", isPresented: $showTimerConflictAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please stop the quick practice timer before starting this timer.")
            }
    }
}

// MARK: - Preview

#Preview("Compact") {
    InlineTimerView(
        method: GrowthMethod(
            id: "1",
            stage: 1,
            title: "Manual Stretching",
            methodDescription: "Basic stretching technique",
            instructionsText: "Sample instructions",
            equipmentNeeded: [],
            estimatedDurationMinutes: 10,
            timerConfig: nil
        )
    )
    .padding()
}

#Preview("Expanded") {
    InlineTimerView(
        method: GrowthMethod(
            id: "1",
            stage: 1,
            title: "Manual Stretching",
            methodDescription: "Basic stretching technique",
            instructionsText: "Sample instructions",
            equipmentNeeded: [],
            estimatedDurationMinutes: 10,
            timerConfig: nil
        )
    )
    .padding()
}