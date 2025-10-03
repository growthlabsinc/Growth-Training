//
//  AppTheme.swift
//  Growth
//
//  Created by Developer on 5/8/25.
//

import SwiftUI
import UIKit

// MARK: - UIKit Theme
/// AppTheme provides centralized access to theme-related configurations and utilities for UIKit
enum GrowthUITheme {
    
    // MARK: - Component Sizes
    
    enum ComponentSize {
        // Button heights
        static let primaryButtonHeight: CGFloat = 52.0
        static let secondaryButtonHeight: CGFloat = 52.0
        static let textButtonHeight: CGFloat = 44.0
        static let iconButtonSize: CGFloat = 44.0
        
        // Input field heights
        static let textInputHeight: CGFloat = 56.0
        
        // Corner radii
        static let primaryButtonCornerRadius: CGFloat = 8.0
        static let secondaryButtonCornerRadius: CGFloat = 8.0
        static let standardCardCornerRadius: CGFloat = 12.0
        static let workoutCardCornerRadius: CGFloat = 16.0
        static let progressCardCornerRadius: CGFloat = 12.0
        static let textInputCornerRadius: CGFloat = 8.0
        
        // Touch targets
        static let minimumTouchTarget: CGFloat = 44.0
        
        // Progress indicators
        static let linearProgressHeight: CGFloat = 8.0
        static let circularProgressStrokeWidth: CGFloat = 4.0
        static let activityRingStrokeWidth: CGFloat = 6.0
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let micro: CGFloat = 4.0
        static let small: CGFloat = 8.0
        static let `default`: CGFloat = 16.0
        static let medium: CGFloat = 24.0
        static let large: CGFloat = 32.0
        static let extraLarge: CGFloat = 48.0
    }
    
    // MARK: - Shadow Styles
    
    enum ShadowStyle {
        case none
        case small
        case medium
        case large
        
        /// Apply this shadow style to a UIView
        /// - Parameter view: The view to apply the shadow to
        func apply(to view: UIView) {
            switch self {
            case .none:
                view.layer.shadowOpacity = 0
                view.layer.shadowOffset = .zero
                view.layer.shadowRadius = 0
                
            case .small:
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.04
                view.layer.shadowOffset = CGSize(width: 0, height: 1)
                view.layer.shadowRadius = 4
                
            case .medium:
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.08
                view.layer.shadowOffset = CGSize(width: 0, height: 2)
                view.layer.shadowRadius = 8
                
            case .large:
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.12
                view.layer.shadowOffset = CGSize(width: 0, height: 4)
                view.layer.shadowRadius = 16
            }
        }
    }
    
    // MARK: - Border Styles
    
    enum BorderStyle {
        case none
        case thin(color: UIColor)
        case medium(color: UIColor)
        case thick(color: UIColor)
        
        /// Apply this border style to a UIView
        /// - Parameter view: The view to apply the border to
        func apply(to view: UIView) {
            switch self {
            case .none:
                view.layer.borderWidth = 0
                
            case .thin(let color):
                view.layer.borderWidth = 1.0
                view.layer.borderColor = color.cgColor
                
            case .medium(let color):
                view.layer.borderWidth = 1.5
                view.layer.borderColor = color.cgColor
                
            case .thick(let color):
                view.layer.borderWidth = 2.0
                view.layer.borderColor = color.cgColor
            }
        }
        
        /// Check if this is a "none" border style
        var isNone: Bool {
            if case .none = self {
                return true
            }
            return false
        }
    }
    
    // MARK: - Component States
    
    enum ComponentState {
        case normal
        case pressed
        case disabled
        case focused
        case error
        
        /// Returns the alpha value for the given state
        var alpha: CGFloat {
            switch self {
            case .normal, .focused, .pressed, .error:
                return 1.0
            case .disabled:
                return 0.4
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Updates a view's appearance based on the trait collection
    /// - Parameters:
    ///   - view: The view to update
    ///   - traitCollection: The current trait collection
    static func updateAppearance(for view: UIView, with traitCollection: UITraitCollection) {
        // Update dynamic colors if needed
        view.setNeedsDisplay()
        
        // Update shadows based on dark mode
        if let shadowView = view as? ShadowProvider, let shadowStyle = shadowView.shadowStyle {
            shadowStyle.apply(to: view)
            
            // Adjust shadow opacity for dark mode
            if traitCollection.userInterfaceStyle == .dark {
                view.layer.shadowOpacity *= 1.5 // Increase shadow opacity in dark mode
            }
        }
        
        // Update borders for cards in dark mode
        if let borderView = view as? BorderProvider, let borderStyle = borderView.borderStyle {
            // If we're in dark mode and this is a card with no border, add one
            if traitCollection.userInterfaceStyle == .dark && 
               borderStyle.isNone {
                // Use a dark mode border color
                BorderStyle.thin(color: UIColor(red: 0.219, green: 0.290, blue: 0.274, alpha: 1.0)).apply(to: view)
            } else {
                borderStyle.apply(to: view)
            }
        }
        
        // Recursively update all subviews
        for subview in view.subviews {
            updateAppearance(for: subview, with: traitCollection)
        }
    }
}

// MARK: - Protocols for Theme Providers

/// Protocol for views that provide shadow styles
protocol ShadowProvider {
    var shadowStyle: GrowthUITheme.ShadowStyle? { get }
}

/// Protocol for views that provide border styles
protocol BorderProvider {
    var borderStyle: GrowthUITheme.BorderStyle? { get }
}

// MARK: - SwiftUI Theme
/// The main theme for the Growth app
struct AppTheme {
    
    // MARK: - Colors
    
    /// Color definitions for the app
    struct Colors {
        // Primary Brand Colors
        static let primary = Color("AppPrimaryColor") // A calming, growth-oriented color defined in Assets
        static let secondary = Color("GrowthGreen") // Secondary brand color
        static let accent = Color("AccentColor") // Accent color for highlights and CTAs
        
        // UI Element Colors
        static let background = Color("BackgroundColor")
        static let card = Color("BackgroundColor").opacity(0.95) // Using background with slight opacity for card
        static let text = Color("TextColor")
        static let textSecondary = Color("TextSecondaryColor")
        static let textOnPrimary = Color.white // Added for text on primary-colored backgrounds
        
        // Functional Colors
        static let success = Color("SuccessColor") // For positive actions and progress
        static let warning = Color("ErrorColor") // For cautionary states
        static let errorColor = Color("ErrorColor") // For errors and critical states
        
        // System colors for fallback or initial state
        static let systemBackground = Color("BackgroundColor")
        static let systemGray = Color(UIColor.systemGray)
        static let systemBlue = Color(UIColor.systemBlue)
    }
    
    // MARK: - Typography
    
    /// Typography specifications for the app
    struct Typography {
        // Font Families (based on actual font file names)
        static let gravityBold = "gravity-bold"
        static let gravityBook = "gravity-book"
        static let gravityLight = "gravity-light"
        static let gravityUltralight = "gravity-ultralight"
        static let interRegular = "Inter-Regular"
        static let interMedium = "Inter-Medium"
        static let interBold = "Inter-Bold"
        
        // Font Sizes
        static let largeTitle: CGFloat = 34.0
        static let title1: CGFloat = 28.0
        static let title2: CGFloat = 22.0
        static let title3: CGFloat = 20.0
        static let headline: CGFloat = 17.0
        static let body: CGFloat = 17.0
        static let callout: CGFloat = 16.0
        static let subheadline: CGFloat = 15.0
        static let footnote: CGFloat = 13.0
        static let caption: CGFloat = 12.0
        
        // Font Weights
        static let light = Font.Weight.light
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
    }
    
    // MARK: - Layout
    
    /// Layout metrics and spacing
    struct Layout {
        // Standard Spacing
        static let spacingXS: CGFloat = 4.0
        static let spacingS: CGFloat = 8.0
        static let spacingM: CGFloat = 16.0
        static let spacingL: CGFloat = 24.0
        static let spacingXL: CGFloat = 32.0
        static let spacingXXL: CGFloat = 48.0
        
        // Corner Radii
        static let cornerRadiusS: CGFloat = 4.0
        static let cornerRadiusM: CGFloat = 8.0
        static let cornerRadiusL: CGFloat = 16.0
        
        // Shadow Properties
        static let shadowOpacity: CGFloat = 0.1
        static let shadowRadius: CGFloat = 4.0
        static let shadowOffset = CGSize(width: 0, height: 2)
    }
    
    // MARK: - Animation
    
    /// Animation presets
    struct Animation {
        static let defaultAnimation = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quickAnimation = SwiftUI.Animation.easeOut(duration: 0.2)
        static let slowAnimation = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - Typography Font Methods
extension AppTheme.Typography {
    // MARK: - Gravity Font Implementation
    /// Regular weight using Gravity Book font
    static func gravityBook(_ size: CGFloat) -> Font {
        Font.custom(gravityBook, size: size)
    }
    /// Semibold weight using Gravity Book font with medium fallback
    static func gravitySemibold(_ size: CGFloat) -> Font {
        Font.custom(gravityBook, size: size).weight(.semibold)
    }
    /// Bold weight using Gravity Bold font
    static func gravityBoldFont(_ size: CGFloat) -> Font {
        Font.custom(gravityBold, size: size)
    }
    /// Light weight using Gravity Light font
    static func gravityLight(_ size: CGFloat) -> Font {
        Font.custom(gravityLight, size: size)
    }
    /// Ultralight weight using Gravity Ultralight font
    static func gravityUltralight(_ size: CGFloat) -> Font {
        Font.custom(gravityUltralight, size: size)
    }
    // Pre-configured Text Styles (Gravity)
    static func largeTitleFont() -> Font {
        gravityBoldFont(largeTitle)
    }
    static func title1Font() -> Font {
        gravityBoldFont(title1)
    }
    static func title2Font() -> Font {
        gravityBook(title2)
    }
    static func title3Font() -> Font {
        gravityBook(title3)
    }
    static func headlineFont() -> Font {
        gravitySemibold(headline)
    }
    static func bodyFont() -> Font {
        gravityBook(body)
    }
    static func captionFont() -> Font {
        gravityBook(caption)
    }
    static func calloutFont() -> Font {
        gravityBook(callout)
    }
    static func subheadlineFont() -> Font {
        gravitySemibold(subheadline)
    }
    static func footnoteFont() -> Font {
        gravityBook(footnote)
    }
    // Deprecated: Inter font helpers (for removal)
    @available(*, deprecated, message: "Use Gravity font helpers instead.")
    static func interBodyFont() -> Font {
        Font.custom(interRegular, size: body)
    }
    @available(*, deprecated, message: "Use Gravity font helpers instead.")
    static func interCaptionFont() -> Font {
        Font.custom(interRegular, size: caption)
    }
    @available(*, deprecated, message: "Use Gravity font helpers instead.")
    static func interCalloutFont() -> Font {
        Font.custom(interRegular, size: callout)
    }
    @available(*, deprecated, message: "Use Gravity font helpers instead.")
    static func interSubheadlineFont() -> Font {
        Font.custom(interMedium, size: subheadline)
    }
    @available(*, deprecated, message: "Use Gravity font helpers instead.")
    static func interFootnoteFont() -> Font {
        Font.custom(interRegular, size: footnote)
    }
}

// MARK: - Accessibility Extensions
extension View {
    /// Apply Gravity font with accessibility support
    func gravityFont(_ style: AppTheme.Typography.Type, size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.accessibleFont(AppTheme.Typography.gravityBook, size: size, weight: weight)
    }
    
    /// Apply themed animation that respects reduce motion setting
    func animateIfEnabled<V: Equatable>(_ animation: Animation = AppTheme.Animation.defaultAnimation, value: V) -> some View {
        if let themedAnimation = ThemeManager.shared.animation(base: animation) {
            return AnyView(self.animation(themedAnimation, value: value))
        } else {
            return AnyView(self)
        }
    }
}

// MARK: - Markdown Theme Extensions
extension AppTheme {
    /// Markdown-specific theme configurations
    struct Markdown {
        // Special block colors
        static let tipBackground = Color.yellow.opacity(0.1)
        static let tipBorder = Color.yellow.opacity(0.3)
        static let tipIcon = Color.yellow
        
        static let warningBackground = Colors.errorColor.opacity(0.1)
        static let warningBorder = Colors.errorColor.opacity(0.3)
        static let warningIcon = Colors.errorColor
        
        static let infoBackground = Colors.systemBlue.opacity(0.1)
        static let infoBorder = Colors.systemBlue.opacity(0.3)
        static let infoIcon = Colors.systemBlue
        
        static let successBackground = Colors.success.opacity(0.1)
        static let successBorder = Colors.success.opacity(0.3)
        static let successIcon = Colors.success
        
        // Code block styling
        static let codeBackground = Color(.tertiarySystemBackground)
        static let codeBorder = Color(.separator)
        
        // Block quote styling
        static let quoteIndicatorColor = Colors.textSecondary.opacity(0.3)
        static let quoteTextColor = Colors.textSecondary
    }
}



