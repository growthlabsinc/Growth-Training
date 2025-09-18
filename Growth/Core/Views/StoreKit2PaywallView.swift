/**
 * StoreKit2PaywallView.swift
 * Premium Paywall with Clean Men's Health App Design
 * 
 * Modern, non-scrolling paywall optimized for conversions
 */

import SwiftUI
import StoreKit

// Import the models that contain SubscriptionDuration and SubscriptionProductIDs
// These are defined in the Core/Models directory

public struct StoreKit2PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: SimplifiedPurchaseManager
    @EnvironmentObject private var entitlements: SimplifiedEntitlementManager
    
    @State private var selectedPlan: SubscriptionDuration = .quarterly // Default to best value
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with hero image
                backgroundView
                
                // Content
                VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.custom("Inter-Regular", size: 17))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                
                Spacer()
                
                // Main content card
                VStack(spacing: 0) {
                    // Title section
                    titleSection
                    
                    // Features grid (compact)
                    featuresSection
                        .padding(.vertical, 15)
                    
                    // Pricing selection
                    pricingSection
                        .padding(.horizontal, 16)
                    
                    // CTA Button
                    purchaseButton
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    // Footer
                    footerSection
                        .padding(.top, 15)
                        .padding(.bottom, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.black.opacity(0.85))
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        }
        .ignoresSafeArea()
        .overlay {
            if purchaseManager.isLoading {
                loadingOverlay
            }
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: entitlements.hasPremium) { hasPremium in
            if hasPremium {
                dismiss()
            }
        }
        .sheet(isPresented: $showingTerms) {
            NavigationView {
                LegalDocumentView(documentId: "terms_of_service")
                    .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingTerms = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingPrivacy) {
            NavigationView {
                LegalDocumentView(documentId: "privacy_policy")
                    .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingPrivacy = false }
                        }
                    }
            }
        }
        .task {
            do {
                try await purchaseManager.loadProducts()
            } catch {
                print("Failed to load products: \(error)")
            }
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        GeometryReader { geometry in
            ZStack {
                // Hero image
                Image("PaywallBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Unlock Premium")
                .font(.custom("Gravity-Bold", size: 32))
                .foregroundColor(.white)
            
            Text("Transform Your Performance")
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.top, 25)
    }
    
    // MARK: - Features Section (Compact Grid)
    
    private var featuresSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                FeatureCard(
                    icon: "brain", 
                    title: "AI Coach",
                    subtitle: "Personalized AI guidance and tips",
                    color: .blue
                )
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis", 
                    title: "Analytics",
                    subtitle: "In-depth insights and statistics",
                    color: .green
                )
            }
            HStack(spacing: 12) {
                FeatureCard(
                    icon: "figure.strengthtraining.traditional", 
                    title: "Custom Plans",
                    subtitle: "Create unlimited personalized routines",
                    color: .orange
                )
                FeatureCard(
                    icon: "timer", 
                    title: "Advanced Timer",
                    subtitle: "Enhanced timing and tracking",
                    color: .purple
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 10) {
            Text("Choose Your Plan")
                .font(.custom("Gravity-Semibold", size: 18))
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            // Weekly option
            PricingOption(
                title: "1 Week",
                price: "$4.99",
                subtitle: "/ week",
                isSelected: selectedPlan == .weekly,
                badge: nil
            ) {
                selectedPlan = .weekly
            }
            
            // Quarterly option (Best Value)
            PricingOption(
                title: "3 Months",
                price: "$29.99",
                subtitle: "/ 3 months",
                subPrice: "$9.99 per month",
                isSelected: selectedPlan == .quarterly,
                badge: "SAVE 40%",
                badgeColor: .green,
                hasFreeTrial: true,
                trialDuration: .quarterly
            ) {
                selectedPlan = .quarterly
            }
            
            // Annual option
            PricingOption(
                title: "12 Months",
                price: "$49.99",
                subtitle: "/ year",
                subPrice: "$4.16 per month",
                isSelected: selectedPlan == .yearly,
                badge: "SAVE 80%",
                badgeColor: .orange,
                hasFreeTrial: true,
                trialDuration: .yearly
            ) {
                selectedPlan = .yearly
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button(action: {
            Task {
                await purchaseSelectedPlan()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(purchaseButtonTitle)
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundColor(.white)
            }
            .frame(height: 56)
        }
        .disabled(purchaseManager.isLoading)
    }
    
    private var purchaseButtonTitle: String {
        switch selectedPlan {
        case .yearly:
            return "Start 1-Week Free Trial"
        case .quarterly:
            return "Start 3-Day Free Trial"
        case .weekly:
            return "Subscribe Now"
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                Task { 
                    do {
                        try await purchaseManager.restorePurchases()
                    } catch {
                        print("Failed to restore purchases: \(error)")
                    }
                }
            }) {
                Text("Restore Purchases")
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text("By continuing, you agree to our")
                .font(.custom("Inter-Regular", size: 12))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 8) {
                Button("Terms of Service") { showingTerms = true }
                Text("•").foregroundColor(.white.opacity(0.5))
                Button("Privacy Policy") { showingPrivacy = true }
            }
            .font(.custom("Inter-Regular", size: 12))
            .foregroundColor(.blue.opacity(0.9))
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text(purchaseManager.isLoading ? "Processing..." : "Loading...")
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func purchaseSelectedPlan() async {
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
        
        if !success {
            errorMessage = "Purchase failed. Please try again."
            showingError = true
        }
    }
}

// MARK: - Feature Card Component

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.custom("Inter-Semibold", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
            
            Text(subtitle)
                .font(.custom("Inter-Regular", size: 10))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Pricing Option Component

struct PricingOption: View {
    let title: String
    let price: String
    let subtitle: String
    var subPrice: String? = nil
    let isSelected: Bool
    let badge: String?
    var badgeColor: Color = .green
    var hasFreeTrial: Bool = false
    var trialDuration: SubscriptionDuration? = nil
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Radio button
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
                
                // Plan details
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.custom("Inter-Semibold", size: 16))
                            .foregroundColor(.white)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.custom("Inter-Bold", size: 10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(badgeColor)
                                )
                        }
                        
                        if hasFreeTrial {
                            Text(trialBadgeText)
                                .font(.custom("Inter-Bold", size: 9))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.purple)
                                )
                        }
                    }
                    
                    if let subPrice = subPrice {
                        Text(subPrice)
                            .font(.custom("Inter-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(.custom("Gravity-Bold", size: 20))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var trialBadgeText: String {
        guard let duration = trialDuration else {
            return ""
        }
        
        switch duration {
        case .weekly:
            return "" // No trial for weekly
        case .quarterly:
            return "3-DAY TRIAL"
        case .yearly:
            return "1-WEEK TRIAL"
        }
    }
}