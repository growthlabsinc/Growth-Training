import SwiftUI
import Foundation  // For Logger

/// Intermediate value proposition screen shown after splash screen
/// Provides additional context about the app's benefits before account creation
struct ValuePropositionView: View {
    var onContinue: () -> Void
    
    @State private var isAnimating = false
    @State private var benefitAnimations = [false, false, false]
    
    private let benefits: [(icon: String, title: String, description: String)] = [
        ("chart.line.uptrend.xyaxis", "Guided, Science-Based Methods", "Proven techniques backed by research for sustainable vascular health improvement"),
        ("lock.shield.fill", "Private and Secure Tracking", "Your health data stays private with end-to-end encryption and local storage options"),
        ("person.3.fill", "Supportive Community Insights", "Learn from collective progress while maintaining your personal privacy")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo and headline section
            VStack(spacing: 24) {
                AppLogo(size: 100, showText: false)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isAnimating)
                
                VStack(spacing: 12) {
                    Text("GROWTH")
                        .font(AppTheme.Typography.gravityBoldFont(36))
                        .foregroundColor(Color("GrowthGreen"))
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: isAnimating)
                    
                    Text("A Structured Path to\nVascular Health")
                        .font(AppTheme.Typography.gravityBoldFont(24))
                        .foregroundColor(Color("TextColor"))
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: isAnimating)
                }
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Benefits section
            VStack(spacing: 20) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    BenefitRow(
                        icon: benefit.icon,
                        title: benefit.title,
                        description: benefit.description,
                        isAnimating: benefitAnimations[index]
                    )
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5).delay(0.4 + Double(index) * 0.15)) {
                            benefitAnimations[index] = true
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue button
            Button(action: {
                ThemeManager.shared.performHapticFeedback(style: .medium)
                onContinue()
            }) {
                HStack {
                    Text("Continue")
                        .font(AppTheme.Typography.gravitySemibold(17))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.5).delay(0.8), value: isAnimating)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("GrowthBackgroundLight"))
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Benefit Row Component
private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let isAnimating: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon container
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen").opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("TextColor"))
                
                Text(description)
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .opacity(isAnimating ? 1.0 : 0.0)
        .offset(x: isAnimating ? 0 : -20)
    }
}

// MARK: - Preview
#Preview {
    ValuePropositionView {
        Logger.debug("Continue tapped")
    }
}