//
//  TimerControlsView.swift
//  Growth
//
//  Created by Developer on <CURRENT_DATE>.
//

import SwiftUI

struct TimerControlsView: View {
    @ObservedObject var viewModel: TimerViewModel
    var onExit: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            // Main control buttons
            HStack(spacing: 40) {
                // Stop/Reset Button
                VStack(spacing: 8) {
                    Button(action: {
                        viewModel.stopTimer()
                    }) {
                        Circle()
                            .fill(AppTheme.Colors.errorColor.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.errorColor)
                            )
                    }
                    .disabled(viewModel.timerState == .stopped && viewModel.displayTime == "00:00")
                    
                    Text("Stop")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(width: 64)
                }

                // Start/Pause/Resume Button
                VStack(spacing: 8) {
                    Button(action: {
                        viewModel.startPauseResumeTimer()
                    }) {
                        Circle()
                            .fill(AppTheme.Colors.primary.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: viewModel.timerState == .running ? "pause.fill" : "play.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.primary)
                            )
                    }
                    
                    Text(viewModel.timerState == .running ? "Pause" : "Start")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(width: 80)
                }
            }
            
            // Exit button - only show if onExit callback is provided
            if let onExit = onExit {
                Button(action: onExit) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Exit Practice")
                            .font(AppTheme.Typography.bodyFont())
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.top, AppTheme.Layout.spacingM)
            }
        }
        .padding()
    }
}

#if DEBUG
struct TimerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        TimerControlsView(viewModel: TimerViewModel())
            .background(AppTheme.Colors.background)
            .previewLayout(.sizeThatFits)
    }
}
#endif 