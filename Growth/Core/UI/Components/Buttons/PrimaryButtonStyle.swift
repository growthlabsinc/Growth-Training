//
//  PrimaryButtonStyle.swift
//  Growth
//
//  Created by Developer on 5/10/25.
//

import SwiftUI
import Foundation  // For Logger

/// A primary button style for the Growth app
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .padding(.vertical, AppTheme.Layout.spacingM)
            .padding(.horizontal, AppTheme.Layout.spacingL)
            .foregroundColor(.white)
            .background(
                Group {
                    if isDisabled {
                        Color.dynamicButtonGradient(for: colorScheme)
                            .opacity(0.5)
                    } else if configuration.isPressed {
                        Color.dynamicButtonGradient(for: colorScheme)
                            .opacity(0.8)
                    } else {
                        Color.dynamicButtonGradient(for: colorScheme)
                    }
                }
            )
            .cornerRadius(AppTheme.Layout.cornerRadiusM)
            .shadow(
                color: colorScheme == .dark 
                    ? Color(UIColor(hex: "26A69A")).opacity(0.3)  // Lighter shadow in dark mode
                    : Color(AppColors.coreGreen).opacity(0.25),
                radius: AppTheme.Layout.shadowRadius,
                x: 0,
                y: 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Extension for a standard primary button with custom variants
extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Standard primary button style
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
    
    /// Disabled primary button style
    static var primaryDisabled: PrimaryButtonStyle {
        PrimaryButtonStyle(isDisabled: true)
    }
}

// MARK: - Preview

#if DEBUG
struct PrimaryButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            VStack(spacing: 20) {
                Text("Light Mode")
                    .font(.headline)
                
                Button("Primary Button") {
                    Logger.debug("Button tapped")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Disabled Button") {
                    Logger.debug("Button tapped")
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: true))
                .disabled(true)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            VStack(spacing: 20) {
                Text("Dark Mode")
                    .font(.headline)
                
                Button("Primary Button") {
                    Logger.debug("Button tapped")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Disabled Button") {
                    Logger.debug("Button tapped")
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: true))
                .disabled(true)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif 