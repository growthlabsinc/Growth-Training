//
//  PrimaryButton.swift
//  Growth
//
//  Created by Developer on 5/8/25.
//

import SwiftUI

/// A styled primary button component for the Growth app
struct PrimaryButton: View {
    // MARK: - Properties
    
    let title: String
    let action: () -> Void
    let icon: String? // Optional SF Symbol name
    var isDisabled: Bool = false
    var fullWidth: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Layout.spacingS) {
                // Show icon if provided
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(minWidth: fullWidth ? .infinity : 0)
            .padding(.vertical, AppTheme.Layout.spacingM)
            .padding(.horizontal, AppTheme.Layout.spacingL)
        }
        .background(isDisabled ? Color.gray.opacity(0.5) : AppTheme.Colors.systemBlue)
        .foregroundColor(.white)
        .cornerRadius(AppTheme.Layout.cornerRadiusM)
        .shadow(
            color: AppTheme.Colors.systemBlue.opacity(0.4),
            radius: AppTheme.Layout.shadowRadius,
            x: 0,
            y: 2
        )
        .disabled(isDisabled)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(
            title: "Get Started",
            action: { print("Button tapped") }, // Release OK - Preview
            icon: nil
        )
        
        PrimaryButton(
            title: "Continue with Icon",
            action: { print("Button tapped") }, // Release OK - Preview
            icon: "arrow.right"
        )
        
        PrimaryButton(
            title: "Disabled Button",
            action: { print("Button tapped") }, // Release OK - Preview
            icon: nil,
            isDisabled: true
        )
        
        PrimaryButton(
            title: "Full Width Button",
            action: { print("Button tapped") }, // Release OK - Preview
            icon: nil,
            fullWidth: true
        )
    }
    .padding()
    .background(Color(UIColor.systemBackground))
} 