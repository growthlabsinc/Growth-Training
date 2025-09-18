/**
 * PurchaseLoadingView.swift
 * Growth App Purchase Loading UI
 *
 * Provides loading indicators and progress feedback during subscription
 * purchase flows with cancellation support.
 */

import SwiftUI

/// Loading view for purchase flow with progress indicators
struct PurchaseLoadingView: View {
    
    // MARK: - Properties
    
    let progressMessage: String
    let canCancel: Bool
    let onCancel: (() -> Void)?
    
    @State private var animationOffset: CGFloat = 0
    
    // MARK: - Initialization
    
    init(
        progressMessage: String = "Processing...",
        canCancel: Bool = false,
        onCancel: (() -> Void)? = nil
    ) {
        self.progressMessage = progressMessage
        self.canCancel = canCancel
        self.onCancel = onCancel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            // Loading animation
            loadingAnimation
            
            // Progress message
            Text(progressMessage)
                .font(AppTheme.Typography.gravitySemibold(16))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Cancel button if allowed
            if canCancel, let onCancel = onCancel {
                Button("Cancel") {
                    onCancel()
                }
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
                .padding(.top, 8)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("BackgroundColor"))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 40)
    }
    
    // MARK: - Loading Animation
    
    private var loadingAnimation: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color("GrowthGreen"))
                    .frame(width: 12, height: 12)
                    .scaleEffect(animationOffset == CGFloat(index) ? 1.3 : 1.0)
                    .animation(
                        Animation
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = 2
        }
    }
}

// MARK: - Purchase Progress View

/// Enhanced progress view with detailed purchase steps
struct PurchaseProgressView: View {
    
    // MARK: - Properties
    
    let currentStep: PurchaseStep
    let progressMessage: String
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("GrowthGreen")))
                .scaleEffect(1.2)
            
            // Step indicator
            VStack(spacing: 12) {
                Text(currentStep.title)
                    .font(AppTheme.Typography.gravitySemibold(18))
                    .foregroundColor(Color("TextColor"))
                
                Text(progressMessage.isEmpty ? currentStep.description : progressMessage)
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
            }
            
            // Step progress
            stepProgressIndicator
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("BackgroundColor"))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Step Progress Indicator
    
    private var stepProgressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(PurchaseStep.allCases, id: \.self) { step in
                Circle()
                    .fill(stepColor(for: step))
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == currentStep ? 1.5 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
    
    private func stepColor(for step: PurchaseStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return Color("GrowthGreen")
        } else if step == currentStep {
            return Color("GrowthGreen")
        } else {
            return Color("TextSecondaryColor").opacity(0.3)
        }
    }
}

// MARK: - Purchase Steps

enum PurchaseStep: Int, CaseIterable {
    case initiating = 0
    case processing = 1
    case verifying = 2
    case activating = 3
    case completed = 4
    
    var title: String {
        switch self {
        case .initiating:
            return "Starting Purchase"
        case .processing:
            return "Processing Payment"
        case .verifying:
            return "Verifying Purchase"
        case .activating:
            return "Activating Subscription"
        case .completed:
            return "Purchase Complete"
        }
    }
    
    var description: String {
        switch self {
        case .initiating:
            return "Preparing your subscription..."
        case .processing:
            return "Securely processing your payment..."
        case .verifying:
            return "Confirming purchase details..."
        case .activating:
            return "Setting up your premium features..."
        case .completed:
            return "Your subscription is now active!"
        }
    }
}

// MARK: - Success Animation View

struct PurchaseSuccessView: View {
    
    // MARK: - Properties
    
    let tier: SubscriptionTier
    let onDismiss: () -> Void
    
    @State private var showCheckmark = false
    @State private var showContent = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen"))
                    .frame(width: 80, height: 80)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(showCheckmark ? 1.0 : 0.1)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: showCheckmark)
            }
            
            if showContent {
                VStack(spacing: 16) {
                    Text("Welcome to \(tier.displayName)!")
                        .font(AppTheme.Typography.gravitySemibold(22))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Your subscription is now active and you have access to all \(tier.displayName) features.")
                        .font(AppTheme.Typography.gravityBook(16))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.center)
                    
                    Button("Get Started") {
                        onDismiss()
                    }
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color("GrowthGreen"))
                    )
                    .padding(.top, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("BackgroundColor"))
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
        )
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation {
                showCheckmark = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Preview

struct PurchaseLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Basic loading view
            PurchaseLoadingView(
                progressMessage: "Processing your purchase...",
                canCancel: true,
                onCancel: {}
            )
            .previewDisplayName("Basic Loading")
            
            // Progress view
            PurchaseProgressView(
                currentStep: .processing,
                progressMessage: "Securely processing your payment..."
            )
            .previewDisplayName("Progress View")
            
            // Success view
            PurchaseSuccessView(
                tier: .premium,
                onDismiss: {}
            )
            .previewDisplayName("Success View")
        }
        .preferredColorScheme(.light)
    }
}