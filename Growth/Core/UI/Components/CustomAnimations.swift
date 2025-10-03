import SwiftUI

// MARK: - Custom Animation Components
// Since Lottie is not configured, we'll use pure SwiftUI animations

// MARK: - Custom SwiftUI Animations (Fallback)
struct SwiftUISuccessAnimation: View {
    @State private var showCircle = false
    @State private var showCheckmark = false
    @State private var particlesVisible = false
    
    var body: some View {
        ZStack {
            // Particles
            ForEach(0..<12) { index in
                Circle()
                    .fill(Color("GrowthGreen"))
                    .frame(width: 10, height: 10)
                    .offset(particlesVisible ? randomOffset(for: index) : .zero)
                    .opacity(particlesVisible ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.0)
                        .delay(0.5),
                        value: particlesVisible
                    )
            }
            
            // Main circle
            Circle()
                .stroke(Color("GrowthGreen"), lineWidth: 4)
                .frame(width: 100, height: 100)
                .scaleEffect(showCircle ? 1 : 0)
                .opacity(showCircle ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCircle)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(Color("GrowthGreen"))
                .scaleEffect(showCheckmark ? 1 : 0)
                .opacity(showCheckmark ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.6)
                    .delay(0.3),
                    value: showCheckmark
                )
        }
        .onAppear {
            showCircle = true
            showCheckmark = true
            particlesVisible = true
        }
    }
    
    private func randomOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * (.pi / 180)
        let distance: CGFloat = 150
        return CGSize(
            width: CGFloat(cos(angle)) * distance,
            height: CGFloat(sin(angle)) * distance
        )
    }
}

// MARK: - Loading Dots Animation
struct LoadingDotsAnimation: View {
    @State private var animatingDots = [false, false, false]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color("GrowthGreen"))
                    .frame(width: 12, height: 12)
                    .scaleEffect(animatingDots[index] ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animatingDots[index]
                    )
            }
        }
        .onAppear {
            for index in 0..<3 {
                animatingDots[index] = true
            }
        }
    }
}

// MARK: - Wave Loading Animation
struct WaveLoadingAnimation: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background wave
                WaveShape(offset: offset, amplitude: 15)
                    .fill(Color("GrowthGreen").opacity(0.3))
                
                // Foreground wave
                WaveShape(offset: offset + 50, amplitude: 20)
                    .fill(Color("GrowthGreen").opacity(0.6))
            }
        }
        .frame(height: 100)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                offset = 200
            }
        }
    }
}

// MARK: - Confetti Particle
struct ConfettiParticle: View {
    let color: Color
    let size: CGFloat
    @State private var offsetY: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size * 2)
            .rotationEffect(.degrees(rotation))
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...3))) {
                    offsetY = 500
                    rotation = Double.random(in: 180...720)
                    opacity = 0
                }
            }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    let colors: [Color] = [
        Color("GrowthGreen"),
        Color("BrightTeal"),
        .yellow,
        .orange,
        .pink
    ]
    
    var body: some View {
        ZStack {
            // Reduced from 50 to 15 particles to save memory
            ForEach(0..<15) { index in
                ConfettiParticle(
                    color: colors[index % colors.count],
                    size: CGFloat.random(in: 5...10)
                )
                .position(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -20
                )
                .animation(.none, value: index)
            }
        }
    }
}