/**
 * PricingOptionCard.swift
 * Growth App Paywall Pricing Cards
 *
 * Displays subscription pricing options with savings indicators
 * and selection state for the paywall.
 */

import SwiftUI

/// Card component for subscription pricing options
struct PricingOptionCard: View {
    
    // MARK: - Properties
    let duration: SubscriptionDuration
    let price: String
    let savings: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    // MARK: - Body
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color("GrowthGreen") : Color("TextSecondaryColor"), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color("GrowthGreen"))
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Duration & Price Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(duration.displayName)
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(Color("TextColor"))
                        
                        Spacer()
                        
                        // Savings Badge
                        if !savings.isEmpty {
                            Text(savings)
                                .font(AppTheme.Typography.gravitySemibold(12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color("GrowthGreen") : Color.orange)
                                )
                        }
                    }
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(price)
                            .font(AppTheme.Typography.gravityBoldFont(18))
                            .foregroundColor(Color("TextColor"))
                        
                        Text(durationSuffix)
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(Color("TextSecondaryColor"))
                        
                        Spacer()
                        
                        // Per month calculation
                        if duration != .weekly {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(perMonthPrice)
                                    .font(AppTheme.Typography.gravityBook(12))
                                    .foregroundColor(Color("TextSecondaryColor"))
                                Text("per month")
                                    .font(AppTheme.Typography.gravityBook(10))
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                        }
                    }
                    
                    // Trial indicator for annual and quarterly options
                    if duration == .yearly {
                        Text("1-week free trial included")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("GrowthGreen"))
                    } else if duration == .quarterly {
                        Text("3-day free trial included")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected 
                                    ? LinearGradient(
                                        colors: [Color("GrowthGreen"), Color("GrowthBlue")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color("BorderColor"), Color("BorderColor")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected 
                            ? Color("GrowthGreen").opacity(0.2) 
                            : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    // MARK: - Computed Properties
    
    private var durationSuffix: String {
        switch duration {
        case .weekly:
            return "/ week"
        case .quarterly:
            return "/ 3 months"
        case .yearly:
            return "/ year"
        }
    }
    
    private var perMonthPrice: String {
        switch duration {
        case .weekly:
            return ""
        case .quarterly:
            let monthlyPrice = duration.priceCents / 3
            return String(format: "$%.2f", Double(monthlyPrice) / 100.0)
        case .yearly:
            let monthlyPrice = duration.priceCents / 12
            return String(format: "$%.2f", Double(monthlyPrice) / 100.0)
        }
    }
}

// MARK: - Helpers

extension PricingOptionCard {
    
    /// Create a popular badge overlay
    static func popularBadge() -> some View {
        HStack {
            Spacer()
            VStack {
                Text("MOST POPULAR")
                    .font(AppTheme.Typography.gravitySemibold(10))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color("GrowthGreen"))
                    )
                    .offset(y: -8)
                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview("Weekly Option") {
    VStack(spacing: 12) {
        PricingOptionCard(
            duration: SubscriptionDuration.weekly,
            price: "$4.99",
            savings: "",
            isSelected: false,
            onTap: {}
        )
        
        PricingOptionCard(
            duration: SubscriptionDuration.quarterly,
            price: "$29.99",
            savings: "Save 20%",
            isSelected: true,
            onTap: {}
        )
        
        PricingOptionCard(
            duration: SubscriptionDuration.yearly,
            price: "$49.99",
            savings: "Save 45%",
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}