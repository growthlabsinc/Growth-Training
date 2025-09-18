//
//  AppearanceSettingsView.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Form {
            // Theme Section
            Section(header: Text("Theme").font(AppTheme.Typography.gravitySemibold(13))) {
                Picker("Appearance", selection: $themeManager.appThemeString) {
                    Label("System", systemImage: "gear")
                        .tag("system")
                    Label("Light", systemImage: "sun.max.fill")
                        .tag("light")
                    Label("Dark", systemImage: "moon.fill")
                        .tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text("Choose how Growth appears on your device")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // Accent Color Section
            Section(header: Text("Accent Color").font(AppTheme.Typography.gravitySemibold(13))) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                    ForEach(AccentColorOption.allCases, id: \.self) { option in
                        Button(action: {
                            themeManager.accentColorString = option.rawValue
                            // Apply haptic feedback if enabled
                            themeManager.performHapticFeedback(style: .light)
                        }) {
                            Circle()
                                .fill(option.color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: themeManager.accentColorString == option.rawValue ? 3 : 0)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                        .opacity(themeManager.accentColorString == option.rawValue ? 1 : 0)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Accessibility Section
            Section(header: Text("Accessibility").font(AppTheme.Typography.gravitySemibold(13))) {
                Toggle(isOn: $themeManager.useLargeText) {
                    HStack {
                        Image(systemName: "textformat.size")
                            .foregroundColor(.blue)
                        Text("Use Large Text")
                            .font(AppTheme.Typography.gravityBook(14))
                    }
                }
                
                Toggle(isOn: $themeManager.reduceMotion) {
                    HStack {
                        Image(systemName: "figure.walk.motion")
                            .foregroundColor(.orange)
                        Text("Reduce Motion")
                            .font(AppTheme.Typography.gravityBook(14))
                    }
                }
                
                Text("Simplifies animations throughout the app")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // Feedback Section
            Section(header: Text("Feedback").font(AppTheme.Typography.gravitySemibold(13))) {
                Toggle(isOn: $themeManager.hapticFeedback) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.purple)
                        Text("Haptic Feedback")
                            .font(AppTheme.Typography.gravityBook(14))
                    }
                }
                
                Text("Provides tactile feedback for interactions")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // Visual Effects Section
            Section(header: Text("Visual Effects").font(AppTheme.Typography.gravitySemibold(13))) {
                Toggle(isOn: $themeManager.timerGlowEnabled) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color("GrowthGreen"))
                        Text("Timer Glow Effect")
                            .font(AppTheme.Typography.gravityBook(14))
                    }
                }
                
                Text("Shows a glowing animation when timers are running")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Accent Color Options
enum AccentColorOption: String, CaseIterable {
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case orange = "orange"
    case red = "red"
    
    var color: Color {
        switch self {
        case .green: return Color("GrowthGreen")
        case .blue: return .blue
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
    .environmentObject(ThemeManager.shared)
}