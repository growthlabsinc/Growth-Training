//
//  ColorExtensions.swift
//  Growth
//
//  Created by Developer on 7/16/25.
//

import SwiftUI
import UIKit

/// Extension for SwiftUI Color to provide access to the app's color palette
extension Color {
    // MARK: - Brand Colors
    
    /// Core Green - Main brand color
    static let coreGreenColor = Color("CoreGreen")
    
    /// Mint Green - Secondary brand color for buttons, accents, and highlights
    static let mintGreenColor = Color(AppColors.mintGreen)
    
    /// Pale Green - Subtle backgrounds, selected states
    static let paleGreenColor = Color(AppColors.paleGreen)
    
    // MARK: - Text Colors
    
    /// Dark text color - Primary text
    static let darkTextColor = Color("PrimaryTextColor")
    
    /// Neutral gray for secondary text
    static let neutralGrayColor = Color("NeutralGray")
    
    // MARK: - Background Colors
    
    /// Primary light background color
    static let backgroundLightColor = Color("GrowthBackgroundLight")
    
    /// Secondary background color for cards and content areas
    static let cardBackgroundColor = Color("CardBackground")
    
    // MARK: - Semantic Colors
    
    /// Success color - For positive actions, success states
    static let successColor = Color.green
    
    /// Error color - For error states, destructive actions
    static let errorColor = Color.red
    
    /// Warning color - For warning states, caution actions
    static let warningColor = Color("ErrorColor")
    
    /// Info color - For informational states
    static let infoColor = Color.blue
    
    // MARK: - AI Coach Colors
    
    /// Background color for user message bubbles
    static let userBubbleBackground = mintGreenColor
    
    /// Text color for user message bubbles
    static let userBubbleText = Color.white
    
    /// Background color for AI message bubbles
    static let aiBubbleBackground = paleGreenColor
    
    /// Text color for AI message bubbles
    static let aiBubbleText = darkTextColor
    
    // MARK: - Button Colors
    
    /// Background color for secondary buttons
    static let secondaryButtonBackground = Color.gray
    
    // MARK: - Primary Colors (App Color System)
    
    /// Pure White - #FFFFFF (Clean surfaces, cards, and content areas)
    /// In dark mode: #000000
    static let pureWhite = Color(AppColors.pureWhite)
    
    // MARK: - Accent Colors
    
    /// Bright Teal - #00BFA5 (Important actions, focus points, and progress indicators)
    // Use Color("BrightTeal") from asset catalog instead
    
    /// Vital Yellow - #FFD54F (Highlights, notifications, and alerts)
    static let vitalYellow = Color(AppColors.vitalYellow)
    
    // MARK: - Functional Colors
    
    /// Success Green - #43A047 (Completion states and positive feedback)
    static let successGreen = Color(AppColors.successGreen)
    
    /// Warning Amber - #FFB300 (Caution states and intermediary alerts)
    static let warningAmber = Color(AppColors.warningAmber)
    
    /// Error Red - #E53935 (Errors and critical notifications)
    static let errorRed = Color(AppColors.errorRed)
    
    /// Surface White - #FFFFFF (Cards and foreground elements)
    /// In dark mode: #263A36 (Dark mode card backgrounds)
    static let surfaceWhite = Color(AppColors.surfaceWhite)
    
    // MARK: - Gradients (Story 14.1)
    
    /// Emerald → Teal gradient used for primary interactive elements
    static let emeraldTealGradient: LinearGradient = {
        let emerald = Color(AppColors.coreGreen)
        let teal = Color("BrightTeal")  // Using asset catalog color
        return LinearGradient(
            gradient: Gradient(colors: [emerald, teal]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }()
    
    /// Dynamic gradient that adapts to color scheme
    /// Light mode: Emerald → Teal gradient
    /// Dark mode: Lighter teal → Mint green gradient for better visibility
    static func dynamicButtonGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            // Dark mode: Use lighter, more vibrant colors for better contrast
            let startColor = Color(UIColor(hex: "26A69A"))  // Lighter teal
            let endColor = Color(UIColor(hex: "4CAF92"))    // Mint green
            return LinearGradient(
                gradient: Gradient(colors: [startColor, endColor]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Light mode: Original emerald to teal gradient
            return emeraldTealGradient
        }
    }
    
    // MARK: - Convenience Initializers
    
    /// Initialize a Color from a hex string
    /// - Parameter hex: A hex string in format "RRGGBB" or "RRGGBBAA", with or without "#" prefix
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
    
    // MARK: - Utility Methods
    
    /// Converts a hex string to a Color
    /// - Parameter hex: Hex color string (e.g. "#FF5500")
    /// - Returns: A SwiftUI Color
    static func hex(_ hex: String) -> Color {
        return Color(UIColor(hex: hex))
    }
    
    /// Returns darker version of this color
    /// - Parameter percentage: Percentage to darken (0-100)
    /// - Returns: A darker Color
    func darkened(by percentage: CGFloat = 15) -> Color {
        return Color(UIColor(self).darkened(by: percentage))
    }
    
    /// Returns lighter version of this color
    /// - Parameter percentage: Percentage to lighten (0-100)
    /// - Returns: A lighter Color
    func lightened(by percentage: CGFloat = 15) -> Color {
        return Color(UIColor(self).lightened(by: percentage))
    }
    
    /// Returns a version of this color with adjusted opacity
    /// - Parameter opacity: The opacity value (0-1)
    /// - Returns: A Color with modified opacity
    func withAlpha(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
}

/// Extension for UIKit UIColor with additional functionality
extension UIColor {
    
    /// Initialize a UIColor from a hex string
    /// - Parameter hex: A hex string in format "RRGGBB" or "RRGGBBAA", with or without "#" prefix
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // RGBA (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
    
    /// Returns the hex string representation of the color
    /// - Parameter includeAlpha: Whether to include the alpha component
    /// - Returns: The hex string representation of the color
    func toHexString(includeAlpha: Bool = false) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
        
        if includeAlpha {
            return String(format: "%@%02X", rgb, Int(a * 255))
        } else {
            return rgb
        }
    }
    
    /// Returns a version of this color with adjusted alpha
    /// - Parameter alpha: The alpha value to apply
    /// - Returns: A new UIColor with the same RGB values but with the specified alpha
    func withAlpha(_ alpha: CGFloat) -> UIColor {
        return self.withAlphaComponent(alpha)
    }
    
    /// Returns a darkened version of this color
    /// - Parameter percentage: Percentage by which to darken (0-100)
    /// - Returns: A darker UIColor
    func darkened(by percentage: CGFloat = 15) -> UIColor {
        let multiplier = 1.0 - percentage / 100.0
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: max(red * multiplier, 0.0),
                           green: max(green * multiplier, 0.0),
                           blue: max(blue * multiplier, 0.0),
                           alpha: alpha)
        }
        
        return self
    }
    
    /// Returns a lightened version of this color
    /// - Parameter percentage: Percentage by which to lighten (0-100)
    /// - Returns: A lighter UIColor
    func lightened(by percentage: CGFloat = 15) -> UIColor {
        let multiplier = percentage / 100.0
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + (1.0 - red) * multiplier, 1.0),
                           green: min(green + (1.0 - green) * multiplier, 1.0),
                           blue: min(blue + (1.0 - blue) * multiplier, 1.0),
                           alpha: alpha)
        }
        
        return self
    }
} 