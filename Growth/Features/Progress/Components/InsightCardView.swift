//
//  InsightCardView.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import SwiftUI

struct InsightCardView: View {
    // MARK: - Properties
    let insight: ProgressInsight
    let onDismiss: (() -> Void)?
    let onAction: (() -> Void)?
    
    @State private var isShowing = true
    
    // MARK: - Body
    var body: some View {
        if isShowing {
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with icon and dismiss button
                    HStack(alignment: .top) {
                        // Icon
                        Image(systemName: insight.icon)
                            .font(.system(size: 24))
                            .foregroundColor(Color(insight.type.color))
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Title
                            Text(insight.title)
                                .font(AppTheme.Typography.gravityBoldFont(16))
                                .foregroundColor(Color("TextColor"))
                            
                            // Message
                            Text(insight.message)
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(Color("TextSecondaryColor"))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        // Dismiss button
                        if onDismiss != nil {
                            Button(action: dismissCard) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color("TextSecondaryColor"))
                                    .frame(width: 20, height: 20)
                                    .background(Color("NeutralGray").opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    // Action button if available
                    if let actionText = insight.actionText, onAction != nil {
                        HStack {
                            Spacer()
                            
                            Button(action: { onAction?() }) {
                                Text(actionText)
                                    .font(AppTheme.Typography.gravityBook(14))
                                    .foregroundColor(Color("GrowthGreen"))
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Methods
    private func dismissCard() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
        
        // Notify parent after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Preview Provider
struct InsightCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            InsightCardView(
                insight: ProgressInsight(
                    type: .trendPositive,
                    title: "Great Progress!",
                    message: "You've increased your practice time by 25% this week! Keep up the momentum.",
                    icon: "arrow.up.right.circle.fill",
                    priority: 90
                ),
                onDismiss: {},
                onAction: nil
            )
            
            InsightCardView(
                insight: ProgressInsight(
                    type: .streakMilestone,
                    title: "7-Day Streak! 🔥",
                    message: "Incredible dedication! You've practiced for 7 days in a row.",
                    icon: "flame.fill",
                    priority: 95
                ),
                onDismiss: {},
                onAction: nil
            )
            
            InsightCardView(
                insight: ProgressInsight(
                    type: .inactivityWarning,
                    title: "Time to Practice?",
                    message: "Your last session was 3 days ago. A quick session today keeps the momentum going!",
                    icon: "clock.badge.exclamationmark.fill",
                    actionText: "Quick Practice",
                    priority: 78
                ),
                onDismiss: {},
                onAction: {}
            )
        }
        .padding()
        .background(Color("GrowthBackgroundLight"))
    }
}