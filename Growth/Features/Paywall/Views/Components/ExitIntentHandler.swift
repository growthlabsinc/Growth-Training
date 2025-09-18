/**
 * ExitIntentHandler.swift
 * Growth App Exit Intent Detection
 *
 * Detects when users are about to leave the paywall and provides
 * retention strategies to recover potential conversions.
 */

import SwiftUI

/// Exit intent detection and retention strategies
struct ExitIntentHandler: ViewModifier {
    
    @Binding var isExitIntentDetected: Bool
    let onRetentionStrategy: () -> Void
    let onFinalDismiss: () -> Void
    
    @State private var showRetentionOffer = false
    @State private var dragOffset: CGSize = .zero
    @State private var retentionOfferShown = false
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        
                        // Detect swipe down gesture (intent to dismiss)
                        if value.translation.height > 100 && !retentionOfferShown {
                            detectExitIntent()
                        }
                    }
                    .onEnded { value in
                        dragOffset = CGSize.zero
                        
                        // If significant downward swipe, trigger exit intent
                        if value.translation.height > 200 && !retentionOfferShown {
                            detectExitIntent()
                        }
                    }
            )
            .sheet(isPresented: $showRetentionOffer) {
                RetentionOfferView(
                    onAccept: {
                        onRetentionStrategy()
                        showRetentionOffer = false
                    },
                    onDecline: {
                        showRetentionOffer = false
                        onFinalDismiss()
                    }
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
            }
    }
    
    private func detectExitIntent() {
        guard !retentionOfferShown else { return }
        
        retentionOfferShown = true
        isExitIntentDetected = true
        
        // Show retention offer after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRetentionOffer = true
        }
    }
}

// MARK: - View Extension

extension View {
    func detectExitIntent(
        isDetected: Binding<Bool>,
        onRetentionStrategy: @escaping () -> Void,
        onFinalDismiss: @escaping () -> Void
    ) -> some View {
        modifier(ExitIntentHandler(
            isExitIntentDetected: isDetected,
            onRetentionStrategy: onRetentionStrategy,
            onFinalDismiss: onFinalDismiss
        ))
    }
}

// MARK: - Retention Offer View

struct RetentionOfferView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                // Animated Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .scaleEffect(showAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showAnimation)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
                
                Text("Wait! Don't Miss Out")
                    .font(AppTheme.Typography.gravityBoldFont(20))
                    .foregroundColor(Color("TextColor"))
                
                Text("Get 20% off your first month")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            // Special Offer Details
            VStack(spacing: 16) {
                specialOfferCard
                
                // Limited Time Notice
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("This offer expires when you leave")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: onAccept) {
                    HStack {
                        Image(systemName: "tag.fill")
                        Text("Claim 20% Discount")
                    }
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                
                Button("No thanks, I'll pay full price", action: onDecline)
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
        }
        .padding(24)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                showAnimation = true
            }
        }
    }
    
    private var specialOfferCard: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Premium")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))
                    
                    HStack(spacing: 8) {
                        Text("$4.79")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                            .strikethrough()
                        
                        Text("$3.83")
                            .font(AppTheme.Typography.gravityBoldFont(16))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("20%")
                        .font(AppTheme.Typography.gravityBoldFont(16))
                        .foregroundColor(.white)
                    Text("OFF")
                        .font(AppTheme.Typography.gravitySemibold(10))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    RetentionOfferView(
        onAccept: {},
        onDecline: {}
    )
    .background(Color(.systemGroupedBackground))
}