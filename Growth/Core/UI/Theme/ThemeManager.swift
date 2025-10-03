//
//  ThemeManager.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI
import Combine
import Foundation  // For Logger

/// Manages app-wide theme settings and appearance customization
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("appTheme") var appThemeString: String = "system" {
        didSet {
            updateTheme()
        }
    }
    
    @AppStorage("accentColor") var accentColorString: String = "green" {
        didSet {
            updateAccentColor()
        }
    }
    
    @AppStorage("useLargeText") var useLargeText: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }
    @AppStorage("reduceMotion") var reduceMotion: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("firstDayOfWeek") var firstDayOfWeek: Int = 1 { // 1 = Sunday, 2 = Monday
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("timerGlowEnabled") var timerGlowEnabled: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }
    
    @Published var currentColorScheme: ColorScheme?
    @Published var currentAccentColor: Color = Color("GrowthGreen")
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initial setup
        updateTheme()
        updateAccentColor()
    }
    
    func updateTheme() {
        print("[DEBUG] ThemeManager: Updating theme to \(appThemeString)")
        switch appThemeString {
        case "light":
            currentColorScheme = .light
            print("[DEBUG] ThemeManager: Set color scheme to light")
        case "dark":
            currentColorScheme = .dark
            print("[DEBUG] ThemeManager: Set color scheme to dark")
        default: // "system"
            currentColorScheme = nil
            print("[DEBUG] ThemeManager: Set color scheme to system (nil)")
        }
    }
    
    func updateAccentColor() {
        switch accentColorString {
        case "blue":
            currentAccentColor = .blue
        case "purple":
            currentAccentColor = .purple
        case "orange":
            currentAccentColor = Color("ErrorColor")
        case "red":
            currentAccentColor = .red
        default: // "green"
            currentAccentColor = Color("GrowthGreen")
        }
    }
    
    /// Get the appropriate font size based on large text setting
    func fontSize(base: CGFloat) -> CGFloat {
        return useLargeText ? base * 1.3 : base
    }
    
    /// Get a scaled font style based on the large text setting
    func scaledSystemFont(_ style: Font.TextStyle) -> Font {
        if useLargeText {
            // Use larger accessibility sizes
            switch style {
            case .largeTitle: return .system(.largeTitle, design: .default, weight: .bold)
            case .title: return .system(.largeTitle, design: .default, weight: .semibold)
            case .title2: return .system(.title, design: .default, weight: .semibold)
            case .title3: return .system(.title2, design: .default, weight: .medium)
            case .headline: return .system(.title3, design: .default, weight: .semibold)
            case .body: return .system(.title3, design: .default, weight: .regular)
            case .callout: return .system(.headline, design: .default, weight: .regular)
            case .subheadline: return .system(.body, design: .default, weight: .regular)
            case .footnote: return .system(.callout, design: .default, weight: .regular)
            case .caption: return .system(.subheadline, design: .default, weight: .regular)
            case .caption2: return .system(.footnote, design: .default, weight: .regular)
            default: return .system(style)
            }
        }
        return .system(style)
    }
    
    /// Perform haptic feedback if enabled
    func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard hapticFeedback else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Get animation duration based on reduce motion setting
    func animationDuration(base: Double = 0.3) -> Double {
        return reduceMotion ? 0.0 : base
    }
    
    /// Get animation based on reduce motion setting
    func animation(base: Animation = .easeInOut) -> Animation? {
        return reduceMotion ? nil : base
    }
}

// MARK: - View Extensions for Theme Support
extension View {
    /// Apply the current theme settings to the view
    func applyTheme() -> some View {
        modifier(ThemeModifier())
    }
    
    /// Apply themed font size
    func themedFont(_ style: Font, baseSize: CGFloat) -> some View {
        self.font(ThemeManager.shared.useLargeText ? style : style)
    }
    
    /// Apply themed animation
    func themedAnimation<V>(_ animation: Animation = .easeInOut, value: V) -> some View where V : Equatable {
        if let themedAnimation = ThemeManager.shared.animation(base: animation) {
            return AnyView(self.animation(themedAnimation, value: value))
        } else {
            return AnyView(self)
        }
    }
    
    /// Apply accessibility-aware custom font with size
    func accessibleFont(_ fontName: String, size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(AccessibleFontModifier(fontName: fontName, size: size, weight: weight))
    }
    
    /// Apply themed animations that respect reduce motion
    func themedAnimation() -> some View {
        modifier(ThemedAnimationModifier())
    }
    
    /// Apply accessibility-aware system font
    func accessibleSystemFont(_ style: Font.TextStyle) -> some View {
        self.font(ThemeManager.shared.scaledSystemFont(style))
    }
    
    /// Perform haptic feedback
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light, perform: @escaping () -> Void) -> some View {
        self.onTapGesture {
            ThemeManager.shared.performHapticFeedback(style: style)
            perform()
        }
    }
}

// MARK: - Theme Modifier
struct ThemeModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.currentColorScheme)
            .tint(themeManager.currentAccentColor)
            .environment(\.dynamicTypeSize, themeManager.useLargeText ? .accessibility1 : .medium)
            .onChange(of: themeManager.currentColorScheme) { newValue in
                print("[DEBUG] ThemeModifier: Color scheme changed to \(String(describing: newValue))")
            }
            .onChange(of: themeManager.useLargeText) { newValue in
                print("[DEBUG] ThemeModifier: Large text changed to \(newValue)")
            }
            .onChange(of: themeManager.reduceMotion) { newValue in
                print("[DEBUG] ThemeModifier: Reduce motion changed to \(newValue)")
            }
    }
}

// MARK: - Accessible Font Modifier
struct AccessibleFontModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    let fontName: String
    let size: CGFloat
    let weight: Font.Weight
    
    func body(content: Content) -> some View {
        let scaledSize = themeManager.fontSize(base: size)
        content.font(.custom(fontName, size: scaledSize).weight(weight))
    }
}

// MARK: - Themed Animation Modifier
struct ThemedAnimationModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .transaction { transaction in
                if themeManager.reduceMotion {
                    transaction.animation = nil
                }
            }
    }
}

// MARK: - Calendar Extension
extension Calendar {
    /// Returns a calendar configured with the user's preferred first day of week
    @MainActor
    static var userPreferred: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = ThemeManager.shared.firstDayOfWeek
        return calendar
    }
    
    /// Returns a calendar configured with the specified first day of week
    static func withFirstWeekday(_ firstWeekday: Int) -> Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = firstWeekday
        return calendar
    }
}