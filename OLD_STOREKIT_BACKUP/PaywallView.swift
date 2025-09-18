/**
 * PaywallView.swift
 * Growth App Paywall UI
 *
 * Main paywall view with pricing display, feature highlights,
 * and conversion-optimized user experience.
 */

import SwiftUI
import Foundation

/// Main paywall view for subscription upgrades
struct PaywallView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showFeatureCarousel = false
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false
    
    // MARK: - Initialization
    init(context: PaywallContext) {
        _viewModel = StateObject(wrappedValue: PaywallViewModel(context: context))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundGradient
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Feature Highlights
                        featureHighlightsSection
                        
                        // Social Proof (A/B tested)
                        if PaywallABTestingService.shared.shouldShowProminentSocialProof() {
                            SocialProofSection()
                        }
                        
                        // Pricing Options
                        pricingSection
                        
                        // Purchase Button
                        purchaseButtonSection
                        
                        // Restore & Terms
                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Close") {
                    viewModel.handleDismissIntent()
                }
                .foregroundColor(.primary)
            )
        }
        .overlay(
            // Loading State
            Group {
                if case .loading = viewModel.uiState {
                    loadingOverlay
                }
            }
        )
        .overlay(
            // Success Animation
            Group {
                if viewModel.showSuccessAnimation {
                    successOverlay
                }
            }
        )
        .alert("Purchase Error", isPresented: $viewModel.showErrorAlert) {
            Button("Try Again") {
                viewModel.retryProductLoad()
            }
            Button("Contact Support") {
                // Open support email
                if let url = URL(string: "mailto:support@growthlabs.app?subject=Subscription%20Issue") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .detectExitIntent(
            isDetected: $viewModel.isExitIntentDetected,
            onRetentionStrategy: {
                // Apply exit intent offer
                let offerPercentage = PaywallABTestingService.shared.getExitIntentOfferPercentage()
                if offerPercentage > 0 {
                    // TODO: Apply discount logic
                    print("Applying \(offerPercentage)% discount")
                }
            },
            onFinalDismiss: {
                viewModel.dismissPaywall()
            }
        )
        .sheet(isPresented: $showTermsOfService) {
            NavigationView {
                LegalDocumentView(documentId: "terms_of_use")
                    .navigationTitle("Terms of Service")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showTermsOfService = false
                        }
                    )
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationView {
                LegalDocumentView(documentId: "privacy_policy")
                    .navigationTitle("Privacy Policy")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showPrivacyPolicy = false
                        }
                    )
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color("GrowthGreen").opacity(0.1),
                Color.clear,
                Color("GrowthBlue").opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Premium Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("GrowthGreen"), Color("GrowthBlue")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .scaleEffect(showFeatureCarousel ? 1.1 : 1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showFeatureCarousel)
            
            // Title & Subtitle
            VStack(spacing: 8) {
                Text("Unlock Premium")
                    .font(AppTheme.Typography.gravityBoldFont(28))
                    .foregroundColor(Color("TextColor"))
                
                Text(PaywallABTestingService.shared.getHeaderMessaging(for: viewModel.context))
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.top, 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                showFeatureCarousel = true
            }
        }
    }
    
    // MARK: - Feature Highlights
    
    private var featureHighlightsSection: some View {
        VStack(spacing: 16) {
            Text("Premium Features")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.featuresToHighlight, id: \.self) { feature in
                    FeatureHighlightCard(feature: feature)
                }
            }
        }
        .opacity(showFeatureCarousel ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6).delay(0.4), value: showFeatureCarousel)
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 12) {
                ForEach(viewModel.subscriptionOptions, id: \.0) { duration, price, savings in
                    PricingOptionCard(
                        duration: duration,
                        price: price,
                        savings: savings,
                        isSelected: viewModel.selectedDuration == duration,
                        onTap: {
                            viewModel.selectDuration(duration)
                        }
                    )
                }
            }
        }
        .opacity(showFeatureCarousel ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6).delay(0.6), value: showFeatureCarousel)
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.purchaseSelected()
            }) {
                HStack {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(purchaseButtonText)
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color("GrowthGreen"), Color("GrowthBlue")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(viewModel.isPurchasing || viewModel.uiState == .loading)
            .scaleEffect(viewModel.isPurchasing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isPurchasing)
            
            // Trial Information
            if viewModel.selectedDuration == .weekly {
                Text("Includes 7-day free trial")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
        }
        .opacity(showFeatureCarousel ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6).delay(0.8), value: showFeatureCarousel)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Restore Purchases
            Button("Restore Purchases") {
                viewModel.restorePurchases()
            }
            .font(AppTheme.Typography.gravityBook(14))
            .foregroundColor(Color("GrowthBlue"))
            
            // Terms & Privacy
            VStack(spacing: 8) {
                Text("By continuing, you agree to our")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
                
                HStack(spacing: 16) {
                    Button("Terms of Service") {
                        showTermsOfService = true
                    }
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("GrowthBlue"))
                    
                    Button("Privacy Policy") {
                        showPrivacyPolicy = true
                    }
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("GrowthBlue"))
                }
            }
        }
        .opacity(showFeatureCarousel ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6).delay(1.0), value: showFeatureCarousel)
    }
    
    // MARK: - Overlays
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("GrowthGreen")))
                    .scaleEffect(1.5)
                
                Text("Loading subscription options...")
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(Color("TextColor"))
            }
            .padding(24)
            .background(Color("CardBackground"))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Success Animation
                ZStack {
                    Circle()
                        .fill(Color("GrowthGreen"))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(viewModel.showSuccessAnimation ? 1.2 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.showSuccessAnimation)
                
                VStack(spacing: 8) {
                    Text("Welcome to Premium!")
                        .font(AppTheme.Typography.gravityBoldFont(20))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("All premium features are now unlocked")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(Color("CardBackground"))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var purchaseButtonText: String {
        switch viewModel.uiState {
        case .purchasing(_):
            return "Processing..."
        case .loading:
            return "Loading..."
        default:
            return PaywallABTestingService.shared.getCTAButtonText(for: viewModel.selectedDuration)
        }
    }
}

// MARK: - Preview
#Preview {
    PaywallView(context: .featureGate(.aiCoach))
}