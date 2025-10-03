//
//  InitialAssessmentView.swift
//  Growth
//
//  Created by Developer on 6/7/25.
//

import SwiftUI
import FirebaseAuth

/// Initial assessment screen to determine the user's starting growth method
struct InitialAssessmentView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // State for button selection animation
    @State private var selectedOption: String? = nil
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Constants for assessment results
    private let needsAssistanceResult = "needs_assistance"
    private let canProceedResult = "can_proceed"
    
    // Method IDs from the system
    private let angioPumpingMethodId = "angio_pumping"
    private let s2sStretchMethodId = "s2s_stretch" 
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            ScrollView {
                VStack(spacing: AppTheme.Layout.spacingXL) {
                    // Title Section
                    VStack(spacing: AppTheme.Layout.spacingM) {
                        Text("Let's find your ideal starting point")
                            .font(AppTheme.Typography.title1Font())
                            .foregroundColor(AppTheme.Colors.text)
                            .multilineTextAlignment(.center)
                            .padding(.top, AppTheme.Layout.spacingL)
                        
                        Text("This helps us recommend the most effective method for your current situation")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, AppTheme.Layout.spacingL)
                    
                    // Question Section
                    VStack(spacing: AppTheme.Layout.spacingL) {
                        Text("Can you achieve and maintain an erection suitable for practice without aids?")
                            .font(AppTheme.Typography.headlineFont())
                            .foregroundColor(AppTheme.Colors.text)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, AppTheme.Layout.spacingM)
                        
                        // Response Buttons
                        VStack(spacing: AppTheme.Layout.spacingM) {
                            // Yes Button
                            Button {
                                handleSelection(canProceedResult)
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(AppTheme.Typography.title3Font())
                                        .foregroundColor(.white)
                                    
                                    Text("Yes, I can")
                                        .font(AppTheme.Typography.gravitySemibold(18))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, GrowthUITheme.ComponentSize.primaryButtonHeight / 2.5)
                                .background(
                                    RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                                        .fill(Color("GrowthGreen"))
                                        .shadow(
                                            color: Color("GrowthGreen").opacity(0.25),
                                            radius: AppTheme.Layout.shadowRadius,
                                            x: 0,
                                            y: 2
                                        )
                                )
                                .scaleEffect(selectedOption == canProceedResult ? 0.95 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedOption)
                            }
                            .disabled(isSubmitting)
                            
                            // No Button
                            Button {
                                handleSelection(needsAssistanceResult)
                            } label: {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(AppTheme.Typography.title3Font())
                                        .foregroundColor(AppTheme.Colors.text)
                                    
                                    Text("No, I need assistance")
                                        .font(AppTheme.Typography.gravitySemibold(18))
                                        .foregroundColor(AppTheme.Colors.text)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, GrowthUITheme.ComponentSize.primaryButtonHeight / 2.5)
                                .background(
                                    RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                                        .stroke(Color("NeutralGray"), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                                                .fill(Color("BackgroundColor"))
                                        )
                                )
                                .scaleEffect(selectedOption == needsAssistanceResult ? 0.95 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedOption)
                            }
                            .disabled(isSubmitting)
                        }
                        .padding(.horizontal, AppTheme.Layout.spacingL)
                    }
                    
                    // Support Text
                    Text("Your answer helps us provide the most appropriate guidance. This can be adjusted later in settings.")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Layout.spacingXL)
                        .padding(.top, AppTheme.Layout.spacingM)
                }
                .padding(.bottom, AppTheme.Layout.spacingXL)
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: AppTheme.Layout.spacingM) {
                Button {
                    viewModel.regress()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(AppTheme.Typography.captionFont())
                        Text("Back")
                    }
                    .foregroundColor(AppTheme.Colors.text)
                }
                .disabled(isSubmitting)
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.Layout.spacingL)
            .padding(.bottom, AppTheme.Layout.spacingL)
        }
        .background(Color("GrowthBackgroundLight").ignoresSafeArea())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleSelection(_ result: String) {
        // Haptic feedback if enabled
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
        
        // Animate selection
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedOption = result
        }
        
        // Determine method ID based on selection
        let methodId = result == needsAssistanceResult ? angioPumpingMethodId : s2sStretchMethodId
        
        // Save assessment to user profile
        saveAssessment(result: result, methodId: methodId)
    }
    
    private func saveAssessment(result: String, methodId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            showError(message: "User not authenticated")
            return
        }
        
        isSubmitting = true
        
        UserService.shared.updateInitialAssessment(
            userId: userId,
            assessmentResult: result,
            methodId: methodId
        ) { error in
            DispatchQueue.main.async {
                self.isSubmitting = false
                
                if let error = error {
                    self.showError(message: error.localizedDescription)
                } else {
                    // Success - advance to next step
                    self.viewModel.advance()
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        
        // Reset selection on error
        withAnimation {
            selectedOption = nil
        }
    }
}

// MARK: - Preview

#if DEBUG
struct InitialAssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        InitialAssessmentView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.light)
        
        InitialAssessmentView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif