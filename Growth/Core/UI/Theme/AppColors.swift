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
    
    /// Deep Blue - #1E3A8A (Primary brand color for key elements and emphasis)
    /// In dark mode: #3B82F6 (adjusted for better contrast and visibility)
    static let coreGreen = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "3B82F6") : UIColor(hex: "1E3A8A")
    }
    
    // MARK: - Secondary Colors
    
    /// Growth Orange - #F97316 (Secondary brand color for buttons, accents, and highlights)
    /// Used for interactive elements like buttons, links, and selection states
    static let mintGreen = UIColor(hex: "F97316")
    
    /// Pale Green - #E6F4F0 (Subtle backgrounds, selected states)
    /// In dark mode: #F1F8B1 (lighter shade for better visibility)
    static let paleGreen = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "F1F8B1") : UIColor(hex: "E6F4F0")
    }
    
    // MARK: - Accent Colors
    
    /// Energy Orange - #F97316 (Important actions, focus points, and progress indicators)
    static let brightTeal = UIColor(hex: "F97316")
    
    /// Vital Yellow - #FFD54F (Highlights, notifications, and alerts)
    static let vitalYellow = UIColor(hex: "FFD54F")
    
    // MARK: - Functional Colors
    
    /// Success Orange - #F97316 (Completion states and positive feedback)
    static let successGreen = UIColor(hex: "F97316")
    
    /// Warning Amber - #F97316 (Caution states and intermediary alerts - Energy Orange)
    static let warningAmber = UIColor(hex: "F97316")
    
    /// Error Red - #E53935 (Errors and critical notifications)
    static let errorRed = UIColor(hex: "E53935")
    
    /// Neutral Gray - #9E9E9E (Secondary text and disabled states)
    static let neutralGray = UIColor(hex: "9E9E9E")
    
    /// Dark Text - #1E293B (Primary text)
    /// In dark mode: #F1F5F9
    static let darkText = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "F1F5F9") : UIColor(hex: "1E293B")
    }
    
    // MARK: - Background Colors
    
    /// Surface White - #FFFFFF (Cards and foreground elements)
    /// In dark mode: #1E293B (Dark mode card backgrounds)
    static let surfaceWhite = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "1E293B") : UIColor.white
    }
    
    /// Background Light - #F8FAFC (App background, light mode)
    /// In dark mode: #0F172A (Dark mode primary background)
    static let backgroundLight = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "0F172A") : UIColor(hex: "F8FAFC")
    }
    
    // MARK: - Semantic Colors (UIKit Equivalents)
    
    /// Primary label color for text
    static let label = darkText
    
    /// Secondary label color for less emphasized text - #64748B
    /// In dark mode: #94A3B8
    static let secondaryLabel = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "94A3B8") : UIColor(hex: "64748B")
    }
    
    /// Primary background for views
    static let systemBackground = backgroundLight
    
    /// Secondary background for grouped content
    static let secondarySystemBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "1E293B") : UIColor(hex: "F1F5F9")
    }

    /// Tertiary background for content within grouped sections
    static let tertiarySystemBackground = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "334155") : UIColor(hex: "FFFFFF")
    }
} 
