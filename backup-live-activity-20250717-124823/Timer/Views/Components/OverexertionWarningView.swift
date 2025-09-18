//
//  OverexertionWarningView.swift
//  Growth
//
//  Created by Developer on 4/10/2023.
//

import SwiftUI

// View for displaying overexertion warning as part of Story 7.3
struct OverexertionWarningView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) var dismissSheet

    var body: some View {
        VStack(spacing: AppTheme.Layout.spacingL) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.errorColor)
            
            Text("Overexertion Warning")
                .font(AppTheme.Typography.title1Font())
                .foregroundColor(AppTheme.Colors.errorColor)
            
            Text("You have exceeded the recommended maximum duration for this activity. Please consider taking a break.")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Dismiss Warning") {
                viewModel.acknowledgeOverexertion()
                dismissSheet()
            }
            .buttonStyle(
                WarningButtonStyle(
                    backgroundColor: AppTheme.Colors.errorColor,
                    foregroundColor: AppTheme.Colors.textOnPrimary
                )
            )
            .padding(.top)
        }
        .padding(AppTheme.Layout.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .ignoresSafeArea()
    }
}

// Custom button style for warning button
struct WarningButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(AppTheme.Layout.cornerRadiusM)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#if DEBUG
struct OverexertionWarningView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock view model for preview
        let viewModel = TimerViewModel(timerService: TimerService.shared)
        
        return OverexertionWarningView(viewModel: viewModel)
    }
}
#endif 