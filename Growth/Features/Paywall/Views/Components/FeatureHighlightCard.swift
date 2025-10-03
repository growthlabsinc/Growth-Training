/**
 * FeatureHighlightCard.swift
 * Growth App Paywall Feature Cards
 *
 * Displays individual premium features with icons and descriptions
 * in an attractive card format for the paywall.
 */

import SwiftUI

/// Card component highlighting a premium feature
struct FeatureHighlightCard: View {
    
    // MARK: - Properties
    let feature: FeatureType
    @State private var isAnimated = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            // Feature Icon
            featureIcon
            
            // Feature Title
            Text(feature.displayName)
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Feature Description
            Text(featureDescription)
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(16)
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color("GrowthGreen").opacity(0.3), Color("GrowthBlue").opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isAnimated ? 1.0 : 0.8)
        .opacity(isAnimated ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isAnimated = true
            }
        }
    }
    
    // MARK: - Feature Icon
    
    private var featureIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [featureColor.opacity(0.2), featureColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
            
            Image(systemName: featureIconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(featureColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var featureIconName: String {
        switch feature {
        case .quickTimer:
            return "timer"
        case .articles:
            return "doc.text"
        case .customRoutines:
            return "list.bullet.rectangle"
        case .advancedTimer:
            return "stopwatch"
        case .progressTracking:
            return "chart.line.uptrend.xyaxis"
        case .advancedAnalytics:
            return "chart.bar.xaxis"
        case .goalSetting:
            return "target"
        case .aiCoach:
            return "brain.head.profile"
        case .liveActivities:
            return "bell.badge"
        case .prioritySupport:
            return "headphones"
        case .unlimitedBackup:
            return "icloud.and.arrow.up"
        case .advancedCustomization:
            return "paintbrush"
        case .expertInsights:
            return "lightbulb"
        case .premiumContent:
            return "star.circle"
        }
    }
    
    private var featureColor: Color {
        switch feature {
        case .aiCoach:
            return Color("GrowthBlue")
        case .customRoutines:
            return Color("GrowthGreen")
        case .progressTracking, .advancedAnalytics:
            return Color.orange
        case .liveActivities:
            return Color.purple
        case .goalSetting:
            return Color.red
        default:
            return Color("GrowthGreen")
        }
    }
    
    private var featureDescription: String {
        switch feature {
        case .quickTimer:
            return "Simple timer for quick sessions"
        case .articles:
            return "Access to educational content"
        case .customRoutines:
            return "Create unlimited personalized routines"
        case .advancedTimer:
            return "Interval timers with custom phases"
        case .progressTracking:
            return "Detailed progress tracking and history"
        case .advancedAnalytics:
            return "In-depth insights and statistics"
        case .goalSetting:
            return "Set and track personal goals"
        case .aiCoach:
            return "Personalized AI guidance and tips"
        case .liveActivities:
            return "Timer on lock screen and Dynamic Island"
        case .prioritySupport:
            return "Faster support response times"
        case .unlimitedBackup:
            return "Secure cloud backup of all data"
        case .advancedCustomization:
            return "Customize appearance and settings"
        case .expertInsights:
            return "Professional tips and recommendations"
        case .premiumContent:
            return "Exclusive content and features"
        }
    }
}

// MARK: - Preview
#Preview("AI Coach") {
    FeatureHighlightCard(feature: .aiCoach)
        .frame(width: 160)
        .padding()
}

#Preview("Custom Routines") {
    FeatureHighlightCard(feature: .customRoutines)
        .frame(width: 160)
        .padding()
}

#Preview("Progress Tracking") {
    FeatureHighlightCard(feature: .progressTracking)
        .frame(width: 160)
        .padding()
}