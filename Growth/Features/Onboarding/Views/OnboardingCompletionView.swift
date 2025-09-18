//
//  OnboardingCompletionView.swift
//  Growth
//
//  Created by Developer on 6/7/25.
//

import SwiftUI

/// Final onboarding screen that celebrates completion and previews achievements
struct OnboardingCompletionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Animation states
    @State private var showingContent = false
    @State private var showingAchievement = false
    @State private var isContinueButtonPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppTheme.Layout.spacingXL) {
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color("GrowthGreen").opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(showingContent ? 1.0 : 0.8)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("GrowthGreen"))
                            .scaleEffect(showingContent ? 1.0 : 0.5)
                    }
                    .padding(.top, AppTheme.Layout.spacingXXL)
                    .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Title
                    Text("You're All Set!")
                        .font(AppTheme.Typography.title1Font())
                        .foregroundColor(AppTheme.Colors.text)
                        .multilineTextAlignment(.center)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Subtitle
                    Text("Your personalized growth journey begins now")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Layout.spacingL)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Achievement Preview Card
                    if showingAchievement {
                        VStack(spacing: AppTheme.Layout.spacingM) {
                            HStack(spacing: AppTheme.Layout.spacingM) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color("GrowthGreen"))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your First Achievement Awaits!")
                                        .font(AppTheme.Typography.gravitySemibold(16))
                                        .foregroundColor(AppTheme.Colors.text)
                                    
                                    Text("Complete your first session to earn the 'Getting Started' badge")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                            .padding(AppTheme.Layout.spacingM)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("BackgroundColor"))
                                    .shadow(
                                        color: Color.black.opacity(0.05),
                                        radius: 8,
                                        x: 0,
                                        y: 2
                                    )
                            )
                        }
                        .padding(.horizontal, AppTheme.Layout.spacingL)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                    
                    // Continue Button
                    Button {
                        handleContinueToDashboard()
                    } label: {
                        HStack {
                            Text("Continue to Dashboard")
                                .font(AppTheme.Typography.gravitySemibold(17))
                            Image(systemName: "arrow.right")
                                .font(AppTheme.Typography.bodyFont())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, GrowthUITheme.ComponentSize.primaryButtonHeight / 3)
                        .background(
                            RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                                .fill(Color("GrowthGreen"))
                                .shadow(
                                    color: Color("GrowthGreen").opacity(0.25),
                                    radius: isContinueButtonPressed ? 2 : AppTheme.Layout.shadowRadius,
                                    x: 0,
                                    y: isContinueButtonPressed ? 1 : 2
                                )
                        )
                    }
                    .scaleEffect(isContinueButtonPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isContinueButtonPressed)
                    .padding(.horizontal, AppTheme.Layout.spacingL)
                    .padding(.top, AppTheme.Layout.spacingXL)
                    .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Motivational Text
                    Text("Ready to start your first session?")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, AppTheme.Layout.spacingM)
                        .opacity(showingContent ? 1.0 : 0.0)
                }
                .padding(.bottom, AppTheme.Layout.spacingXL)
            }
        }
        .background(Color("GrowthBackgroundLight").ignoresSafeArea())
        .onAppear {
            animateContent()
        }
    }
    
    // MARK: - Private Methods
    
    private func animateContent() {
        // Main content animation
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            showingContent = true
        }
        
        // Achievement card animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8)) {
            showingAchievement = true
        }
    }
    
    private func handleContinueToDashboard() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
        
        // Animate button press
        withAnimation(.easeInOut(duration: 0.1)) {
            isContinueButtonPressed = true
        }
        
        // Mark onboarding as complete and advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.isContinueButtonPressed = false
            }
            
            // Advance to complete status
            self.viewModel.advance()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OnboardingCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCompletionView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.light)
        
        OnboardingCompletionView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif