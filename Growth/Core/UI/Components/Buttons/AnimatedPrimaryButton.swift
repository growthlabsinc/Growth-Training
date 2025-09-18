//
//  AnimatedPrimaryButton.swift
//  Growth
//
//  Created by Developer on 6/7/25.
//

import SwiftUI
import Foundation  // For Logger

// Note: The following types are defined in the project:
// - AppTheme: Growth/Core/UI/Theme/AppTheme.swift
// - GrowthUITheme: Growth/Core/UI/Theme/AppTheme.swift
// - ThemeManager: Growth/Core/UI/Theme/ThemeManager.swift

/// A primary button with haptic feedback and scale animation
struct AnimatedPrimaryButton: View {
    let title: String
    let action: () -> Void
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    @State private var isPressed = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium, action: @escaping () -> Void) {
        self.title = title
        self.hapticStyle = hapticStyle
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            performAction()
        }) {
            Text(title)
                .font(AppTheme.Typography.gravitySemibold(17))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GrowthUITheme.ComponentSize.primaryButtonHeight / 3)
                .background(
                    RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                        .fill(Color.dynamicButtonGradient(for: colorScheme))
                        .shadow(
                            color: colorScheme == .dark 
                                ? Color(UIColor(hex: "26A69A")).opacity(0.3)
                                : Color("GrowthGreen").opacity(0.25),
                            radius: isPressed ? 2 : AppTheme.Layout.shadowRadius,
                            x: 0,
                            y: isPressed ? 1 : 2
                        )
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func performAction() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: hapticStyle)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
        
        // Animate button press
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        
        // Reset animation and perform action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
            action()
        }
    }
}

/// A variant with icon support
struct AnimatedPrimaryButtonWithIcon: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    @State private var isPressed = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, systemImage: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.hapticStyle = hapticStyle
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            performAction()
        }) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(AppTheme.Typography.bodyFont())
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(17))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GrowthUITheme.ComponentSize.primaryButtonHeight / 3)
            .background(
                RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                    .fill(Color.dynamicButtonGradient(for: colorScheme))
                    .shadow(
                        color: colorScheme == .dark 
                            ? Color(UIColor(hex: "26A69A")).opacity(0.3)
                            : Color("GrowthGreen").opacity(0.25),
                        radius: isPressed ? 2 : AppTheme.Layout.shadowRadius,
                        x: 0,
                        y: isPressed ? 1 : 2
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func performAction() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: hapticStyle)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
        
        // Animate button press
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        
        // Reset animation and perform action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
            action()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AnimatedPrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AnimatedPrimaryButton(title: "Get Started") {
                print("[DEBUG] Button tapped")
            }
            
            AnimatedPrimaryButton(title: "Continue", hapticStyle: .light) {
                print("[DEBUG] Continue tapped")
            }
            
            AnimatedPrimaryButtonWithIcon(title: "Enable Notifications", systemImage: "bell.fill") {
                print("[DEBUG] Enable notifications tapped")
            }
        }
        .padding()
        .background(Color("GrowthBackgroundLight"))
    }
}
#endif