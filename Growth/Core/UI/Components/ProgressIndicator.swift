//
//  ProgressIndicator.swift
//  Growth
//
//  Created by Developer on 6/7/25.
//

import SwiftUI

/// A reusable animated progress bar component with gradient fill
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    // Animation state
    @State private var animateGradient = false
    
    var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("PaleGreen"))
                    .frame(height: 8)
                
                // Animated progress fill
                if progress > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("GrowthGreen"),
                                    animateGradient ? Color("BrightTeal") : Color("GrowthGreen")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: progress)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateGradient)
                }
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Progress")
        .accessibilityValue("Step \(currentStep) of \(totalSteps)")
        .onAppear {
            // Start gradient animation
            withAnimation {
                animateGradient = true
            }
        }
        .onChangeCompat(of: currentStep) { newValue in
            // Pulse animation on step change
            withAnimation(.easeInOut(duration: 0.3)) {
                animateGradient = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
        }
    }
}

// MARK: - Reduced Motion Support

extension ProgressIndicator {
    var reducedMotionProgress: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("PaleGreen"))
                    .frame(height: 8)
                
                if progress > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("GrowthGreen"))
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Progress")
        .accessibilityValue("Step \(currentStep) of \(totalSteps)")
    }
    
    var shouldReduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    @ViewBuilder
    var adaptiveBody: some View {
        if shouldReduceMotion {
            reducedMotionProgress
        } else {
            body
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressIndicator(currentStep: 0, totalSteps: 8)
            ProgressIndicator(currentStep: 3, totalSteps: 8)
            ProgressIndicator(currentStep: 5, totalSteps: 8)
            ProgressIndicator(currentStep: 8, totalSteps: 8)
        }
        .padding()
        .background(Color("GrowthBackgroundLight"))
    }
}
#endif