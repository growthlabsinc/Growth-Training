//
//  NotificationPermissionsView.swift
//  Growth
//
//  Created by Developer on 6/7/25.
//

import SwiftUI
import UserNotifications
import Foundation  // For Logger

/// Onboarding view to request notification permissions with context
struct NotificationPermissionsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let notificationsManager = NotificationsManager.shared
    
    // State for button animations
    @State private var isEnableButtonPressed = false
    @State private var showingContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            ScrollView {
                VStack(spacing: AppTheme.Layout.spacingXL) {
                    // Icon
                    Image(systemName: "bell.badge")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(Color("GrowthGreen"))
                        .padding(.top, AppTheme.Layout.spacingXL)
                        .scaleEffect(showingContent ? 1.0 : 0.8)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Title
                    Text("Stay on Track")
                        .font(AppTheme.Typography.title1Font())
                        .foregroundColor(AppTheme.Colors.text)
                        .multilineTextAlignment(.center)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Explanation
                    Text("Allow notifications to receive helpful reminders for your scheduled routine sessions and celebrate your progress.")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, AppTheme.Layout.spacingL)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Button Stack
                    VStack(spacing: AppTheme.Layout.spacingM) {
                        // Enable Notifications Button
                        Button {
                            handleEnableNotifications()
                        } label: {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(AppTheme.Typography.bodyFont())
                                Text("Enable Notifications")
                                    .font(AppTheme.Typography.gravitySemibold(17))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, GrowthUITheme.ComponentSize.primaryButtonHeight / 3)
                            .background(
                                RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                                    .fill(Color("GrowthGreen"))
                                    .shadow(
                                        color: Color("GrowthGreen").opacity(0.25),
                                        radius: isEnableButtonPressed ? 2 : AppTheme.Layout.shadowRadius,
                                        x: 0,
                                        y: isEnableButtonPressed ? 1 : 2
                                    )
                            )
                        }
                        .scaleEffect(isEnableButtonPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isEnableButtonPressed)
                        .opacity(showingContent ? 1.0 : 0.0)
                        
                        // Maybe Later Button
                        Button {
                            handleMaybeLater()
                        } label: {
                            Text("Maybe Later")
                                .font(AppTheme.Typography.bodyFont())
                                .foregroundColor(AppTheme.Colors.text)
                                .padding(.vertical, AppTheme.Layout.spacingS)
                        }
                        .opacity(showingContent ? 0.7 : 0.0)
                        
                        // Back Button
                        Button {
                            viewModel.regress()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14))
                                Text("Back")
                                    .font(AppTheme.Typography.captionFont())
                            }
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.vertical, AppTheme.Layout.spacingS)
                        }
                        .opacity(showingContent ? 0.5 : 0.0)
                    }
                    .padding(.horizontal, AppTheme.Layout.spacingL)
                    .padding(.top, AppTheme.Layout.spacingL)
                    
                    // Additional Context
                    Text("You can always change this in Settings")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, AppTheme.Layout.spacingM)
                        .opacity(showingContent ? 1.0 : 0.0)
                }
                .padding(.bottom, AppTheme.Layout.spacingXL)
            }
            
            Spacer()
        }
        .background(Color("GrowthBackgroundLight").ignoresSafeArea())
        .onAppear {
            // Animate content appearance
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showingContent = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleEnableNotifications() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
        
        // Animate button press
        withAnimation(.easeInOut(duration: 0.1)) {
            isEnableButtonPressed = true
        }
        
        // First check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    // Already authorized, just advance
                    Logger.debug("Notifications already authorized")
                    self.resetButtonAndAdvance()
                case .denied:
                    // User previously denied, guide them to settings
                    Logger.debug("Notifications previously denied - would guide to settings")
                    // In a production app, you might show an alert here explaining
                    // how to enable notifications in Settings
                    self.resetButtonAndAdvance()
                case .notDetermined:
                    // Not yet asked, request permission
                    self.requestNotificationPermissions()
                case .provisional:
                    // Provisional authorization, request full permission
                    self.requestNotificationPermissions()
                case .ephemeral:
                    // Ephemeral authorization (App Clips), request full permission
                    self.requestNotificationPermissions()
                @unknown default:
                    // Handle any future cases
                    self.requestNotificationPermissions()
                }
            }
        }
    }
    
    private func requestNotificationPermissions() {
        notificationsManager.requestPermissions { (granted: Bool) in
            DispatchQueue.main.async {
                let status = granted ? "granted" : "denied"
                Logger.debug("Notification permissions \(status)")
                self.resetButtonAndAdvance()
            }
        }
    }
    
    private func resetButtonAndAdvance() {
        // Reset button animation
        withAnimation(.easeInOut(duration: 0.1)) {
            self.isEnableButtonPressed = false
        }
        
        // Advance to next onboarding step
        self.viewModel.advance()
    }
    
    private func handleMaybeLater() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
        
        // User chose to skip - advance to next step
        viewModel.advance()
    }
}

// MARK: - Preview

#if DEBUG
struct NotificationPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPermissionsView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.light)
        
        NotificationPermissionsView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif