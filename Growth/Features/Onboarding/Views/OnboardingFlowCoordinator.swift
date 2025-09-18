import SwiftUI

/// Orchestrates the onboarding flow, presenting each step in order and showing progress
struct OnboardingFlowCoordinator: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let totalSteps = OnboardingStep.celebration.rawValue

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Indicator (Style-guide: Core Green, Pale Green, 8pt height, 16pt padding)
                ProgressIndicator(currentStep: viewModel.currentStep.rawValue, totalSteps: totalSteps)
                    .adaptiveBody
                    .padding(.top, 24)
                    .padding(.horizontal, 16)

                Spacer(minLength: 16)

                // Main content: switch on currentStep
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeView(onNext: viewModel.advance, onBack: viewModel.regress)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .themeSelection:
                    ThemeSelectionView(onboardingViewModel: viewModel)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .disclaimer:
                    DisclaimerView(onAccepted: viewModel.advance, onBack: viewModel.regress)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .privacy:
                    PrivacyTermsConsentView(onNext: viewModel.advance, onBack: viewModel.regress)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .initialAssessment:
                    InitialAssessmentView(viewModel: viewModel)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .paywall:
                    OnboardingPaywallView()
                        .environmentObject(viewModel)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .routineGoalSelection:
                    RoutineGoalSelectionView()
                        .environmentObject(viewModel)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .notificationPermissions:
                    NotificationPermissionsView(viewModel: viewModel)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .profileSetup:
                    ProfileSetupView(onNext: viewModel.advance, onBack: viewModel.regress)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .celebration:
                    OnboardingCompletionView(viewModel: viewModel)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                Spacer(minLength: 16)
            }
            .background(Color("GrowthBackgroundLight").ignoresSafeArea())
        }
    }
}

// MARK: - ProgressBar (Style-guide compliant)

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("PaleGreen"))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("GrowthGreen"))
                    .frame(width: geo.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Onboarding Progress")
        .accessibilityValue("Step \(currentStep) of \(totalSteps)")
    }
}

// MARK: - Placeholder Views for Each Step (Replace with actual implementations)

struct WelcomeView: View {
    var onNext: () -> Void
    var onBack: () -> Void
    @State private var showingContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppTheme.Layout.spacingXL) {
                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, AppTheme.Layout.spacingXXL)
                        .scaleEffect(showingContent ? 1.0 : 0.8)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Headline
                    Text("A Structured Path to Vascular Health")
                        .font(AppTheme.Typography.title1Font())
                        .foregroundColor(AppTheme.Colors.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Layout.spacingL)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                        OnboardingBenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Guided, Science-Based Methods")
                        OnboardingBenefitRow(icon: "lock.shield", text: "Private and Secure Tracking")
                        OnboardingBenefitRow(icon: "person.2", text: "Supportive Community Insights")
                    }
                    .padding(.horizontal, AppTheme.Layout.spacingXL)
                    .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Get Started Button
                    AnimatedPrimaryButton(title: "Get Started", action: onNext)
                        .padding(.horizontal, AppTheme.Layout.spacingL)
                        .padding(.top, AppTheme.Layout.spacingXL)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Back to Sign Up Button
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                            Text("Back to Sign Up")
                                .font(AppTheme.Typography.captionFont())
                        }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.top, AppTheme.Layout.spacingM)
                    .opacity(showingContent ? 0.7 : 0.0)
                }
                .padding(.bottom, AppTheme.Layout.spacingXL)
            }
        }
        .background(Color("GrowthBackgroundLight").ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showingContent = true
            }
        }
    }
}

struct OnboardingBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("GrowthGreen"))
                .frame(width: 32)
            
            Text(text)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.text)
            
            Spacer()
        }
    }
}


struct PrivacyPolicyView: View {
    var onNext: () -> Void
    var onBack: () -> Void
    var body: some View {
        VStack {
            Text("Privacy Policy & Terms of Use")
                .font(AppTheme.Typography.title1Font())
            // TODO: Integrate actual privacy policy UI
            Button("Next", action: onNext)
            Button("Back", action: onBack)
        }
    }
}


 