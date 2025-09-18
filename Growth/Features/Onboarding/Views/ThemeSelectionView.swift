import SwiftUI

struct ThemeSelectionView: View {
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var selectedTheme: String = "system"
    @State private var animateOptions = false
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            // Header
            VStack(spacing: AppTheme.Layout.spacingS) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Colors.primary)
                    .accessibilityHidden(true)
                
                Text("Choose Your Theme")
                    .font(AppTheme.Typography.largeTitleFont())
                    .fontWeight(.bold)
                
                Text("Select your preferred appearance mode")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppTheme.Layout.spacingXL)
            
            Spacer()
            
            // Theme Options
            VStack(spacing: AppTheme.Layout.spacingM) {
                ThemeOptionCard(
                    title: "System",
                    description: "Automatically match your device settings",
                    icon: "gear",
                    isSelected: selectedTheme == "system",
                    colorScheme: .light
                ) {
                    selectedTheme = "system"
                    themeManager.appThemeString = "system"
                    themeManager.performHapticFeedback()
                }
                .opacity(animateOptions ? 1 : 0)
                .offset(y: animateOptions ? 0 : 20)
                .animation(.easeOut(duration: 0.3).delay(0.1), value: animateOptions)
                
                ThemeOptionCard(
                    title: "Light",
                    description: "Classic bright appearance",
                    icon: "sun.max.fill",
                    isSelected: selectedTheme == "light",
                    colorScheme: .light
                ) {
                    selectedTheme = "light"
                    themeManager.appThemeString = "light"
                    themeManager.performHapticFeedback()
                }
                .opacity(animateOptions ? 1 : 0)
                .offset(y: animateOptions ? 0 : 20)
                .animation(.easeOut(duration: 0.3).delay(0.2), value: animateOptions)
                
                ThemeOptionCard(
                    title: "Dark",
                    description: "Easy on the eyes in low light",
                    icon: "moon.fill",
                    isSelected: selectedTheme == "dark",
                    colorScheme: .dark
                ) {
                    selectedTheme = "dark"
                    themeManager.appThemeString = "dark"
                    themeManager.performHapticFeedback()
                }
                .opacity(animateOptions ? 1 : 0)
                .offset(y: animateOptions ? 0 : 20)
                .animation(.easeOut(duration: 0.3).delay(0.3), value: animateOptions)
            }
            .padding(.horizontal, AppTheme.Layout.spacingL)
            
            Spacer()
            
            // Navigation Buttons
            VStack(spacing: AppTheme.Layout.spacingS) {
                // Continue Button
                AnimatedPrimaryButton(title: "Continue") {
                    onboardingViewModel.advance()
                }
                .padding(.horizontal, AppTheme.Layout.spacingL)
                
                // Back Button
                Button(action: {
                    onboardingViewModel.regress()
                }) {
                    Text("Back")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.bottom, AppTheme.Layout.spacingM)
            }
            .padding(.bottom, AppTheme.Layout.spacingXL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .onAppear {
            selectedTheme = themeManager.appThemeString
            withAnimation {
                animateOptions = true
            }
        }
    }
}

// MARK: - Theme Option Card
struct ThemeOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Layout.spacingM) {
                // Icon with preview background
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                        .fill(colorScheme == .dark ? Color.black : Color.white)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text(description)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.Colors.primary : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Colors.primary)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(AppTheme.Layout.spacingM)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                    .fill(AppTheme.Colors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                            .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThemeSelectionView(onboardingViewModel: OnboardingViewModel())
}