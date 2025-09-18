import UIKit

/// AppColors provides centralized access to all colors used in the Growth app.
/// Colors are dynamic and support both light and dark mode.
enum AppColors {
    
    // MARK: - Primary Colors
    
    /// Pure White - #FFFFFF (Clean surfaces, cards, and content areas)
    /// In dark mode: #000000
    static let pureWhite = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
    }
    
    /// Core Green - #0A5042 (Primary brand color for key elements and emphasis)
    /// In dark mode: #26A69A (adjusted for better contrast)
    static let coreGreen = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "26A69A") : UIColor(hex: "0A5042")
    }
    
    // MARK: - Secondary Colors
    
    /// Mint Green - #4CAF92 (Secondary brand color for buttons, accents, and highlights)
    /// Used for interactive elements like buttons, links, and selection states
    static let mintGreen = UIColor(hex: "4CAF92")
    
    /// Pale Green - #E6F4F0 (Subtle backgrounds, selected states)
    /// In dark mode: #F1F8B1 (lighter shade for better visibility)
    static let paleGreen = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "F1F8B1") : UIColor(hex: "E6F4F0")
    }
    
    // MARK: - Accent Colors
    
    /// Bright Teal - #00BFA5 (Important actions, focus points, and progress indicators)
    static let brightTeal = UIColor(hex: "00BFA5")
    
    /// Vital Yellow - #FFD54F (Highlights, notifications, and alerts)
    static let vitalYellow = UIColor(hex: "FFD54F")
    
    // MARK: - Functional Colors
    
    /// Success Green - #43A047 (Completion states and positive feedback)
    static let successGreen = UIColor(hex: "43A047")
    
    /// Warning Amber - #FFB300 (Caution states and intermediary alerts)
    static let warningAmber = UIColor(hex: "FFB300")
    
    /// Error Red - #E53935 (Errors and critical notifications)
    static let errorRed = UIColor(hex: "E53935")
    
    /// Neutral Gray - #9E9E9E (Secondary text and disabled states)
    static let neutralGray = UIColor(hex: "9E9E9E")
    
    /// Dark Text - #212121 (Primary text)
    /// In dark mode: #F5F5F5
    static let darkText = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "F5F5F5") : UIColor(hex: "212121")
    }
    
    // MARK: - Background Colors
    
    /// Surface White - #FFFFFF (Cards and foreground elements)
    /// In dark mode: #263A36 (Dark mode card backgrounds)
    static let surfaceWhite = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "263A36") : UIColor.white
    }
    
    /// Background Light - #F8FAFA (App background, light mode)
    /// In dark mode: #1A2A27 (Dark mode primary background)
    static let backgroundLight = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "1A2A27") : UIColor(hex: "F8FAFA")
    }
    
    // MARK: - Semantic Colors (UIKit Equivalents)
    
    /// Primary label color for text
    static let label = darkText
    
    /// Secondary label color for less emphasized text
    static let secondaryLabel = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "B0BEC5") : neutralGray
    }
    
    /// Primary background for views
    static let systemBackground = backgroundLight
    
    /// Secondary background for grouped content
    static let secondarySystemBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "232F2C") : UIColor(hex: "F0F2F2")
    }
    
    /// Tertiary background for content within grouped sections
    static let tertiarySystemBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "2A3A37") : UIColor(hex: "FFFFFF")
    }
} 
