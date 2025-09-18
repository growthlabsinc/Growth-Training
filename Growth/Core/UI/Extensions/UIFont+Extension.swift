import UIKit

extension UIFont {
    
    /// Creates a font with the Growth app's typography style
    /// - Parameter style: The text style to use
    /// - Returns: A configured UIFont
    static func growth(style: AppTypography.TextStyle) -> UIFont {
        return AppTypography.font(for: style)
    }
    
    /// Creates a scaled font with the Growth app's typography style that supports Dynamic Type
    /// - Parameters:
    ///   - style: The text style to use
    ///   - maximumPointSize: The maximum point size to scale to
    /// - Returns: A configured, scaled UIFont
    static func scaledGrowth(style: AppTypography.TextStyle, maximumPointSize: CGFloat? = nil) -> UIFont {
        let font = AppTypography.font(for: style)
        
        if let maximumPointSize = maximumPointSize {
            return UIFontMetrics.default.scaledFont(for: font, maximumPointSize: maximumPointSize)
        } else {
            return UIFontMetrics.default.scaledFont(for: font)
        }
    }
    
    /// Returns a modified font with a different weight
    /// - Parameter weight: The desired weight
    /// - Returns: A new UIFont with the specified weight
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weight
            ]
        ])
        
        return UIFont(descriptor: descriptor, size: pointSize)
    }
} 