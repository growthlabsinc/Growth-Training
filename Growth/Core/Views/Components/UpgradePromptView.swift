/**
 * UpgradePromptView.swift
 * Growth App Contextual Upgrade Prompts
 *
 * Smart upgrade prompts with contextual benefits, social proof integration,
 * and conversion optimization features for different paywall contexts.
 */

import SwiftUI
import Combine

// MARK: - Upgrade Prompt View

/// Contextual upgrade prompt with feature-specific benefits
public struct UpgradePromptView: View {
    let feature: String
    let context: PaywallContext
    
    @EnvironmentObject private var entitlementManager: SimplifiedEntitlementManager
    @EnvironmentObject private var purchaseManager: SimplifiedPurchaseManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedDuration: SubscriptionDuration = .yearly
    @State private var isLoading = false
    @State private var showingSuccess = false
    
    public init(feature: String, context: PaywallContext) {
        self.feature = feature
        self.context = context
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    headerSection
                    
                    // Feature benefits
                    featureBenefitsSection
                    
                    // Social proof
                    socialProofSection
                    
                    // Pricing options
                    pricingSection
                    
                    // Call to action
                    ctaSection
                    
                    // Footer
                    footerSection
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Subscription Active", isPresented: $showingSuccess) {
            Button("Continue") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Welcome to Premium! You now have access to all premium features.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Feature icon with premium overlay
            ZStack {
                Image(systemName: getFeatureIcon(for: feature))
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                PremiumBadge(size: .large)
                    .offset(x: 25, y: -25)
            }
            
            VStack(spacing: 8) {
                Text("Unlock \(getFeatureDisplayName(for: feature))")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(getUpgradePrompt(for: feature))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Feature Benefits Section
    
    private var featureBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Benefits")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 1), spacing: 12) {
                ForEach(getPremiumBenefits(for: feature), id: \.self) { benefit in
                    FeatureBenefitRow(benefit: benefit)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Social Proof Section
    
    private var socialProofSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("4.9")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("Join 100,000+ users who upgraded to Premium")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // User testimonial
            VStack(spacing: 8) {
                Text("\"The AI Coach feature completely transformed my routine. It's like having a personal trainer 24/7!\"")
                    .font(.body)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("- Sarah M., Premium User")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(SubscriptionDuration.allCases, id: \.self) { duration in
                    PricingOptionView(
                        duration: duration,
                        isSelected: selectedDuration == duration,
                        onSelect: { selectedDuration = duration }
                    )
                }
            }
        }
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 16) {
            Button(action: handleUpgrade) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "crown.fill")
                        Text("Start \(selectedDuration.displayName) Premium")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(isLoading)
            
            // Free trial indicator if applicable
            if selectedDuration == .yearly {
                Text("Includes 7-day free trial")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                FeatureHighlight(
                    icon: "xmark.circle",
                    text: "Cancel Anytime"
                )
                
                FeatureHighlight(
                    icon: "shield.checkered",
                    text: "Secure Payment"
                )
                
                FeatureHighlight(
                    icon: "arrow.counterclockwise",
                    text: "Money Back Guarantee"
                )
            }
            
            VStack(spacing: 4) {
                Text("Terms of Service • Privacy Policy")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Subscription automatically renews unless cancelled")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleUpgrade() {
        isLoading = true
        
        Task {
            let success = await purchaseManager.purchase(productID: selectedDuration.productId)
            
            await MainActor.run {
                isLoading = false
                if success {
                    showingSuccess = true
                    
                    // Track successful conversion
                    // Analytics tracking can be added here if needed
                } else {
                    // Handle error - could show error alert
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// Individual feature benefit row
private struct FeatureBenefitRow: View {
    let benefit: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            Text(benefit)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

/// Pricing option view
private struct PricingOptionView: View {
    let duration: SubscriptionDuration
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var isPopular: Bool {
        duration == .yearly
    }
    
    private var savings: String? {
        switch duration {
        case .yearly:
            return "Save 83%"
        case .quarterly:
            return "Save 50%"
        case .weekly:
            return nil
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(duration.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isPopular {
                            Text("MOST POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(duration.price)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Functions

private func getFeatureIcon(for feature: String) -> String {
    switch feature {
    case "aiCoach":
        return "brain.head.profile"
    case "customRoutines":
        return "list.bullet.rectangle"
    case "advancedAnalytics":
        return "chart.xyaxis.line"
    case "allMethods":
        return "star.fill"
    case "liveActivities":
        return "livephoto"
    case "progressTracking":
        return "chart.line.uptrend.xyaxis"
    default:
        return "crown.fill"
    }
}

private func getFeatureDisplayName(for feature: String) -> String {
    switch feature {
    case "aiCoach":
        return "AI Coach"
    case "customRoutines":
        return "Custom Routines"
    case "advancedAnalytics":
        return "Advanced Analytics"
    case "allMethods":
        return "Advanced Timer"
    case "liveActivities":
        return "Live Activities"
    case "progressTracking":
        return "Progress Tracking"
    default:
        return feature.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private func getUpgradePrompt(for feature: String) -> String {
    switch feature {
    case "aiCoach":
        return "Unlock AI-powered coaching and personalized guidance"
    case "customRoutines":
        return "Create unlimited custom routines tailored to your needs"
    case "advancedAnalytics":
        return "Get detailed insights and track your progress"
    case "allMethods":
        return "Access all training methods and techniques"
    default:
        return "Upgrade to Premium for full access"
    }
}

private func getPremiumBenefits(for feature: String) -> [String] {
    switch feature {
    case "aiCoach":
        return [
            "Personalized coaching recommendations",
            "AI-powered progress analysis",
            "Custom training plans"
        ]
    case "customRoutines":
        return [
            "Unlimited custom routines",
            "Save and organize workouts",
            "Share with community"
        ]
    case "advancedAnalytics":
        return [
            "Detailed progress charts",
            "Performance trends",
            "Export data and reports"
        ]
    case "allMethods":
        return [
            "All training methods",
            "Advanced techniques",
            "Premium content library"
        ]
    default:
        return [
            "All premium features",
            "Priority support",
            "Regular updates"
        ]
    }
}

/// Small feature highlight
private struct FeatureHighlight: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
            
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}