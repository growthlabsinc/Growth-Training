//
//  InterFont.swift
//  Growth
//
//  Created by Developer on 7/18/25.
//

import UIKit
import SwiftUI
import Foundation  // For Logger

/// InterFont provides access to the Inter font family
enum InterFont {
    
    /// Represents the different weights available in the Inter font family
    enum InterWeight {
        case thin
        case extraLight
        case light
        case regular
        case medium
        case semibold
        case bold
        case extraBold
        case black
        
        /// Returns the UIFont weight equivalent
        var uiFontWeight: UIFont.Weight {
            switch self {
            case .thin:         return .thin      // 100
            case .extraLight:   return .ultraLight // 200
            case .light:        return .light     // 300
            case .regular:      return .regular   // 400
            case .medium:       return .medium    // 500
            case .semibold:     return .semibold  // 600
            case .bold:         return .bold      // 700
            case .extraBold:    return .heavy     // 800
            case .black:        return .black     // 900
            }
        }
        
        /// Returns the Inter font name for this weight
        var fontName: String {
            switch self {
            case .thin:         return "Inter-Thin"
            case .extraLight:   return "Inter-ExtraLight"
            case .light:        return "Inter-Light"
            case .regular:      return "Inter"
            case .medium:       return "Inter-Medium"
            case .semibold:     return "Inter-SemiBold"
            case .bold:         return "Inter-Bold"
            case .extraBold:    return "Inter-ExtraBold"
            case .black:        return "Inter-Black"
            }
        }
    }
    
    /// Returns a UIFont with the Inter font at the specified size and weight
    /// - Parameters:
    ///   - size: The size of the font
    ///   - weight: The weight of the font (default: .regular)
    /// - Returns: A UIFont instance
    static func font(size: CGFloat, weight: InterWeight = .regular) -> UIFont {
        let fontName = weight.fontName
        
        // Try to get custom font, fall back to system font with appropriate weight if not available
        if let customFont = UIFont(name: fontName, size: size) {
            return customFont
        } else {
            Logger.debug("⚠️ Could not find Inter font: \(fontName). Using system font instead.")
            return UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
        }
    }
    
    /// Returns a SwiftUI Font with the Inter font at the specified size and weight
    /// - Parameters:
    ///   - size: The size of the font
    ///   - weight: The weight of the font (default: .regular)
    /// - Returns: A SwiftUI Font instance
    static func swiftUIFont(size: CGFloat, weight: InterWeight = .regular) -> Font {
        return Font.custom(weight.fontName, size: size)
    }
    
    /// Returns a font for a specific text style with automatic scaling for Dynamic Type
    /// - Parameters:
    ///   - style: The text style to match
    ///   - weight: The weight of the font (default: weight specified in AppTypography)
    /// - Returns: A UIFont that scales with Dynamic Type
    static func font(for style: AppTypography.TextStyle, weight: InterWeight? = nil) -> UIFont {
        // Determine the weight to use (provided or from style)
        let interWeight: InterWeight
        if let weight = weight {
            interWeight = weight
        } else {
            // Map AppTypography.FontWeight to InterWeight
            switch style.weight {
            case .light:    interWeight = .light
            case .regular:  interWeight = .regular
            case .medium:   interWeight = .medium
            case .semibold: interWeight = .semibold
            case .bold:     interWeight = .bold
            }
        }
        
        return font(size: style.size, weight: interWeight)
    }
} 