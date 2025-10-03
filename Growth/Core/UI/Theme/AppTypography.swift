import UIKit

/// AppTypography provides centralized access to all text styles used in the Growth app.
enum AppTypography {
    
    /// Font weight enumeration to match style guide definitions
    enum FontWeight {
        case light
        case regular
        case medium
        case semibold
        case bold
        
        var value: UIFont.Weight {
            switch self {
            case .light:
                return .light      // 300
            case .regular:
                return .regular    // 400
            case .medium:
                return .medium     // 500
            case .semibold:
                return .semibold   // 600
            case .bold:
                return .bold       // 700
            }
        }
    }
    
    /// Text style enumeration to provide all typography variants
    enum TextStyle {
        // Headings
        case h1
        case h2
        case h3
        
        // Body Text
        case bodyLarge
        case body
        case bodySmall
        
        // Special Text
        case caption
        case buttonText
        case metricValue
        case progressLabel
        
        /// Returns the font size in points
        var size: CGFloat {
            switch self {
            case .h1:
                return 32.0
            case .h2:
                return 26.0
            case .h3:
                return 20.0
            case .bodyLarge:
                return 17.0
            case .body:
                return 15.0
            case .bodySmall:
                return 13.0
            case .caption:
                return 12.0
            case .buttonText:
                return 16.0
            case .metricValue:
                return 22.0
            case .progressLabel:
                return 14.0
            }
        }
        
        /// Returns the line height
        var lineHeight: CGFloat {
            switch self {
            case .h1:
                return 36.0
            case .h2:
                return 30.0
            case .h3:
                return 24.0
            case .bodyLarge:
                return 24.0
            case .body:
                return 20.0
            case .bodySmall:
                return 18.0
            case .caption:
                return 16.0
            case .buttonText:
                return 20.0
            case .metricValue:
                return 26.0
            case .progressLabel:
                return 18.0
            }
        }
        
        /// Returns the letter spacing
        var letterSpacing: CGFloat {
            switch self {
            case .h1:
                return -0.3
            case .h2:
                return -0.2
            case .h3:
                return -0.1
            case .bodyLarge, .body:
                return 0.0
            case .bodySmall:
                return 0.1
            case .caption:
                return 0.2
            case .buttonText:
                return 0.1
            case .metricValue:
                return 0.0
            case .progressLabel:
                return 0.0
            }
        }
        
        /// Returns the font weight
        var weight: FontWeight {
            switch self {
            case .h1, .h2:
                return .bold
            case .h3, .metricValue:
                return .semibold
            case .caption, .buttonText, .progressLabel:
                return .medium
            default:
                return .regular
            }
        }
    }
    
    /// Returns a UIFont for the given text style
    /// - Parameter style: The text style
    /// - Returns: A configured UIFont
    static func font(for style: TextStyle) -> UIFont {
        // Use Inter font instead of system font
        let font = InterFont.font(for: style)
        
        // Apply scaling for Dynamic Type if needed
        let scaledFont = UIFontMetrics.default.scaledFont(for: font)
        return scaledFont
    }
    
    /// Returns paragraph style for the given text style
    /// - Parameter style: The text style
    /// - Returns: A configured NSParagraphStyle
    static func paragraphStyle(for style: TextStyle) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        
        // Add line spacing that's appropriate for the text style
        switch style {
        case .h1, .h2, .h3:
            paragraphStyle.lineSpacing = 4
        case .bodyLarge, .body, .bodySmall:
            paragraphStyle.lineSpacing = 2
        default:
            paragraphStyle.lineSpacing = 0
        }
        
        return paragraphStyle
    }
    
    /// Returns a dictionary of text attributes for the given text style
    /// - Parameters:
    ///   - style: The text style
    ///   - color: Optional UIColor for the text (defaults to AppColors.darkText)
    /// - Returns: Dictionary of text attributes for NSAttributedString
    static func attributes(for style: TextStyle, with color: UIColor? = nil) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font(for: style),
            .paragraphStyle: paragraphStyle(for: style)
        ]
        
        // Set color
        if let color = color {
            attributes[.foregroundColor] = color
        } else {
            attributes[.foregroundColor] = style == .progressLabel ? AppColors.coreGreen : AppColors.darkText
        }
        
        // Set kerning (letter spacing)
        attributes[.kern] = style.letterSpacing
        
        return attributes
    }
} 