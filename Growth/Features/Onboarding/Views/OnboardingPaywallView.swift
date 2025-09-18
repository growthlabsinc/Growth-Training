//
//  OnboardingPaywallView.swift
//  Growth
//
//  Specialized paywall view for the onboarding flow with trial emphasis
//

import SwiftUI
import StoreKit
import Foundation

struct OnboardingPaywallView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @EnvironmentObject private var purchaseManager: SimplifiedPurchaseManager
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManager
    @State private var selectedPlan: SubscriptionDuration = .yearly
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var privacyDocument: LegalDocument?
    @State private var termsDocument: LegalDocument?
    @State private var showSuccessAlert = false
    @State private var purchaseSuccess = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Value Proposition
                    valuePropositionSection
                    
                    // Pricing Options
                    pricingOptionsSection
                    
                    // CTA Buttons
                    actionButtonsSection
                    
                    // Terms and Restore
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color("GrowthBackgroundLight"))
        .onChange(of: entitlementManager.hasPremium) { hasPremium in
            if hasPremium {
                onboardingViewModel.advance()
            }
        }
        .overlay(
            ZStack {
                if purchaseManager.isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("GrowthGreen")))
                        
                        Text("Processing...")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(Color("TextColor"))
                    }
                    .padding(32)
                    .background(Color("BackgroundColor"))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                }
            }
            .ignoresSafeArea()
        )
        .onAppear {
            loadDocuments()
        }
        .task {
            do {
                try await purchaseManager.loadProducts()
            } catch {
                print("Failed to load products: \(error)")
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            if let document = privacyDocument {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(document.content)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.Colors.text)
                                .padding()
                        }
                    }
                    .background(Color(UIColor.systemBackground))
                    .navigationTitle(document.title)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showPrivacyPolicy = false
                            }
                            .foregroundColor(Color("GrowthGreen"))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showTermsOfService) {
            if let document = termsDocument {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(document.content)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.Colors.text)
                                .padding()
                        }
                    }
                    .background(Color(UIColor.systemBackground))
                    .navigationTitle(document.title)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showTermsOfService = false
                            }
                            .foregroundColor(Color("GrowthGreen"))
                        }
                    }
                }
            }
        }
        .alert("Welcome to Premium!", isPresented: $showSuccessAlert) {
            Button("Continue") {
                onboardingViewModel.advance()
            }
        } message: {
            if selectedPlan == .yearly || selectedPlan == .quarterly {
                Text("Your free trial has started! You now have access to all premium features.")
            } else {
                Text("Welcome to Growth Premium! You now have access to all premium features.")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Premium Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("GrowthGreen"), Color("BrightTeal")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Start Your Free Trial")
                    .font(AppTheme.Typography.gravityBoldFont(26))
                    .foregroundColor(Color("TextColor"))
                    .multilineTextAlignment(.center)
                
                Text("Choose your plan below")
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Value Proposition
    private var valuePropositionSection: some View {
        VStack(spacing: 16) {
            // Premium Features
            VStack(spacing: 12) {
                OnboardingFeatureRow(icon: "figure.mind.and.body", title: "Custom Routines", subtitle: "Personalized for your goals")
                OnboardingFeatureRow(icon: "bubble.left.and.text.bubble.right", title: "AI Coach", subtitle: "Get expert guidance 24/7")
                OnboardingFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", subtitle: "Track your progress in detail")
                OnboardingFeatureRow(icon: "livephoto.play", title: "Live Activities", subtitle: "Stay focused with timers")
            }
            
            // Social Proof
            HStack(spacing: 8) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color("GrowthGreen"))
                }
                Text("4.8")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))
                Text("• 10,000+ users")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color("GrowthGreen").opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Pricing Options
    private var pricingOptionsSection: some View {
        VStack(spacing: 12) {
            // Annual Plan (with trial)
            PricingCard(
                duration: .yearly,
                isSelected: selectedPlan == .yearly,
                hasTrial: true,
                onTap: {
                    selectedPlan = .yearly
                }
            )
            
            // Quarterly Plan (with trial)
            PricingCard(
                duration: .quarterly,
                isSelected: selectedPlan == .quarterly,
                hasTrial: true,
                onTap: {
                    selectedPlan = .quarterly
                }
            )
            
            // Weekly Plan (no trial)
            PricingCard(
                duration: .weekly,
                isSelected: selectedPlan == .weekly,
                hasTrial: false,
                onTap: {
                    selectedPlan = .weekly
                }
            )
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Primary CTA
            Button(action: {
                Task {
                    await startTrial()
                }
            }) {
                HStack {
                    if selectedPlan == .yearly || selectedPlan == .quarterly {
                        Text("Start Free Trial")
                    } else {
                        Text("Subscribe Now")
                    }
                }
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("GrowthGreen"))
                .cornerRadius(12)
            }
            .disabled(purchaseManager.isLoading)
            
            // Skip Option
            Button(action: {
                skipPaywall()
            }) {
                Text("Maybe Later")
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .disabled(purchaseManager.isLoading)
            
            // Back Button
            Button(action: {
                onboardingViewModel.regress()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                    Text("Back")
                        .font(AppTheme.Typography.gravityBook(14))
                }
                .foregroundColor(Color("TextSecondaryColor"))
            }
            .disabled(purchaseManager.isLoading)
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 12) {
            // Terms Text
            Text("Cancel anytime. No commitment required.")
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
            
            // Restore Purchases
            Button(action: {
                restorePurchases()
            }) {
                Text("Restore Purchases")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("BrightTeal"))
            }
            .disabled(purchaseManager.isLoading)
            
            // Legal Links
            HStack(spacing: 16) {
                Button("Terms of Service") {
                    showTermsOfService = true
                }
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
                
                Text("•")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
                
                Button("Privacy Policy") {
                    showPrivacyPolicy = true
                }
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
            }
        }
    }
    
    // MARK: - Actions
    private func startTrial() async {
        let productId: String
        switch selectedPlan {
        case .yearly:
            productId = SubscriptionProductIDs.premiumYearly
        case .quarterly:
            productId = SubscriptionProductIDs.premiumQuarterly
        case .weekly:
            productId = SubscriptionProductIDs.premiumWeekly
        }
        
        let success = await purchaseManager.purchase(productID: productId)
        
        if success {
            await MainActor.run {
                purchaseSuccess = true
                showSuccessAlert = true
            }
        }
    }
    
    private func skipPaywall() {
        // Track skip event
        PaywallAnalyticsService.shared.trackFunnelStep(
            .paywallDismissed,
            context: .onboarding,
            metadata: ["action": "skip", "source": "onboarding_paywall"]
        )
        
        // Continue onboarding
        onboardingViewModel.advance()
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await purchaseManager.restorePurchases()
                
                // Check if subscription was restored by checking entitlement status
                if entitlementManager.hasPremium {
                    await MainActor.run {
                        // Continue onboarding if subscription found
                        onboardingViewModel.advance()
                    }
                }
            } catch {
                print("Failed to restore purchases: \(error)")
            }
        }
    }
    
    private func loadDocuments() {
        // Load privacy policy
        LegalDocumentService.shared.fetchDocument(withId: "privacy_policy") { document in
            self.privacyDocument = document
        }
        
        // Load terms of service
        LegalDocumentService.shared.fetchDocument(withId: "terms_of_use") { document in
            self.termsDocument = document
        }
    }
}

// MARK: - Feature Row Component
private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("GrowthGreen"))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("TextColor"))
                
                Text(subtitle)
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Spacer()
        }
    }
}

// MARK: - Pricing Card Component
private struct PricingCard: View {
    let duration: SubscriptionDuration
    let isSelected: Bool
    let hasTrial: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(duration.displayName)
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(Color("TextColor"))
                        
                        if hasTrial {
                            Text(trialBadgeText)
                                .font(AppTheme.Typography.gravityBoldFont(10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color("GrowthGreen"))
                                .cornerRadius(4)
                        }
                        
                        if duration == .yearly {
                            Text("BEST VALUE")
                                .font(AppTheme.Typography.gravityBoldFont(10))
                                .foregroundColor(Color("GrowthGreen"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color("GrowthGreen").opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(priceDescription)
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(duration.price)
                        .font(AppTheme.Typography.gravityBoldFont(20))
                        .foregroundColor(Color("TextColor"))
                    
                    if let savings = savingsText {
                        Text(savings)
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color("GrowthGreen") : Color("TextSecondaryColor"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("CardBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color("GrowthGreen") : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priceDescription: String {
        switch duration {
        case .weekly:
            return "Billed weekly"
        case .quarterly:
            return "Billed every 3 months"
        case .yearly:
            return "Billed annually after trial"
        }
    }
    
    private var trialBadgeText: String {
        switch duration {
        case .weekly:
            return "" // No trial for weekly
        case .quarterly:
            return "3-DAY TRIAL"
        case .yearly:
            return "1-WEEK TRIAL"
        }
    }
    
    private var savingsText: String? {
        switch duration {
        case .weekly:
            return nil
        case .quarterly:
            return "Save 40%"
        case .yearly:
            return "Save 80%"
        }
    }
}

#Preview {
    OnboardingPaywallView()
        .environmentObject(OnboardingViewModel())
}