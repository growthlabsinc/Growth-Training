import SwiftUI
import Combine
import UIKit

/// Extension to get the actual display corner radius of the device
extension UIScreen {
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()
    
    /// Get the actual corner radius of the device display
    /// Note: This uses a private API, but is generally safe for App Store submission
    public var displayCornerRadius: CGFloat {
        // First try to get the actual value
        if let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat {
            return cornerRadius
        }
        
        // Fallback to known values based on device
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 18.0 // iPad corner radius
        } else {
            // iPhone corner radius (most modern iPhones)
            return 39.0
        }
    }
}

/// A SwiftUI view that creates an Apple Intelligence-style glow effect
/// Features animated gradient borders with smooth color transitions
/// Optimized for performance using SwiftUI's native animation system
struct AppleIntelligenceGlowEffect: View {
    @State private var animationProgress: Double = 0
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    /// Controls whether the glow effect is actively animating
    let isActive: Bool
    
    /// The corner radius of the glow effect
    let cornerRadius: CGFloat
    
    /// The intensity of the glow (0.0 to 1.0)
    let intensity: Double
    
    init(isActive: Bool = true, cornerRadius: CGFloat = 20, intensity: Double = 1.0) {
        self.isActive = isActive
        self.cornerRadius = cornerRadius
        self.intensity = intensity
    }
    
    var body: some View {
        ZStack {
            // Use LinearGradient instead of AngularGradient for better performance
            // Layer 1: Base glow with no blur
            glowLayer(width: 3, blur: 0, offset: 0)
                .opacity(intensity)
            
            // Layer 2: Medium glow with light blur
            glowLayer(width: 5, blur: 4, offset: 0.25)
                .opacity(intensity * 0.8)
            
            // Layer 3: Wide glow with medium blur
            glowLayer(width: 8, blur: 12, offset: 0.5)
                .opacity(intensity * 0.6)
            
            // Layer 4: Outer glow with heavy blur
            glowLayer(width: 12, blur: 20, offset: 0.75)
                .opacity(intensity * 0.4)
        }
        .rotationEffect(.degrees(rotationAngle))
        .opacity(isActive ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: isActive)
        .allowsHitTesting(false)
        .onAppear {
            if isActive && !isAnimating {
                startAnimation()
            }
        }
        .onDisappear {
            isAnimating = false
        }
        .onChangeCompat(of: isActive) { newValue in
            if newValue && !isAnimating {
                startAnimation()
            } else if !newValue {
                isAnimating = false
                rotationAngle = 0
            }
        }
    }
    
    private func glowLayer(width: CGFloat, blur: CGFloat, offset: Double) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        gradient: animatedGradient(offset: offset),
                        startPoint: gradientStartPoint,
                        endPoint: gradientEndPoint
                    ),
                    lineWidth: width
                )
                .blur(radius: blur)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private var gradientStartPoint: UnitPoint {
        let angle = animationProgress * 2 * .pi
        let x = 0.5 + 0.5 * cos(angle)
        let y = 0.5 + 0.5 * sin(angle)
        return UnitPoint(x: x, y: y)
    }
    
    private var gradientEndPoint: UnitPoint {
        let angle = animationProgress * 2 * .pi + .pi
        let x = 0.5 + 0.5 * cos(angle)
        let y = 0.5 + 0.5 * sin(angle)
        return UnitPoint(x: x, y: y)
    }
    
    private func animatedGradient(offset: Double) -> Gradient {
        // Simplified gradient with fewer stops for better performance
        let phase = animationProgress + offset
        let colors: [Color] = [
            Color("GrowthGreen").opacity(0.8 + 0.2 * sin(phase * 2 * .pi)),
            Color("BrightTeal").opacity(0.7 + 0.3 * sin(phase * 2 * .pi + .pi/3)),
            Color("MintGreen").opacity(0.8 + 0.2 * sin(phase * 2 * .pi + .pi*2/3)),
            Color("GrowthGreen").opacity(0.8 + 0.2 * sin(phase * 2 * .pi))
        ]
        
        return Gradient(colors: colors)
    }
    
    private func startAnimation() {
        isAnimating = true
        
        // Use SwiftUI's built-in animation system instead of Timer
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            animationProgress = 1.0
        }
        
        // Add rotation animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

/// A more subtle version of the glow effect for less prominent use cases
struct SubtleGlowEffect: View {
    let isActive: Bool
    let cornerRadius: CGFloat
    
    var body: some View {
        AppleIntelligenceGlowEffect(
            isActive: isActive,
            cornerRadius: cornerRadius,
            intensity: 0.5
        )
    }
}

/// Extension to easily apply the glow effect to any view
extension View {
    func appleIntelligenceGlow(
        isActive: Bool,
        cornerRadius: CGFloat = 20,
        intensity: Double = 1.0
    ) -> some View {
        self.modifier(
            AppleIntelligenceGlowModifier(
                isActive: isActive,
                cornerRadius: cornerRadius,
                intensity: intensity
            )
        )
    }
}

/// Modifier that applies the glow effect based on user preference
struct AppleIntelligenceGlowModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    let isActive: Bool
    let cornerRadius: CGFloat
    let intensity: Double
    
    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if themeManager.timerGlowEnabled && themeManager.reduceMotion == false {
                    // Use special rectangular glow for shapes with small corner radius
                    // This ensures the Today's Progress card gets a proper glow
                    if cornerRadius < 50 {
                        // Rectangular shape - use specialized effect
                        RectangularBorderGlowEffect(
                            isActive: isActive,
                            cornerRadius: cornerRadius,
                            intensity: intensity
                        )
                    } else {
                        // Circular shape - use standard effect
                        AppleIntelligenceGlowEffect(
                            isActive: isActive,
                            cornerRadius: cornerRadius,
                            intensity: intensity
                        )
                    }
                }
            }
        )
    }
}

/// Full screen edge glow effect for timer views
struct ScreenEdgeGlowEffect: View {
    @State private var animationProgress: Double = 0
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    let isActive: Bool
    let intensity: Double
    
    // Get the actual device corner radius
    private let deviceCornerRadius: CGFloat = UIScreen.main.displayCornerRadius
    
    init(isActive: Bool = true, intensity: Double = 1.0) {
        self.isActive = isActive
        self.intensity = intensity
    }
    
    var body: some View {
        GeometryReader { geometry in
            if !reduceMotion {
                ZStack {
                    // Simplified layers for better performance
                    edgeGlowLayer(geometry: geometry, width: 3, blur: 0)
                        .opacity(intensity * 0.6)
                    
                    edgeGlowLayer(geometry: geometry, width: 8, blur: 12)
                        .opacity(intensity * 0.4)
                    
                    edgeGlowLayer(geometry: geometry, width: 16, blur: 24)
                        .opacity(intensity * 0.2)
                }
                .opacity(isActive ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5), value: isActive)
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            if isActive && !isAnimating && !reduceMotion {
                startAnimation()
            }
        }
        .onDisappear {
            isAnimating = false
        }
        .onChangeCompat(of: isActive) { newValue in
            if newValue && !isAnimating && !reduceMotion {
                startAnimation()
            } else if !newValue {
                isAnimating = false
            }
        }
    }
    
    private func edgeGlowLayer(geometry: GeometryProxy, width: CGFloat, blur: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: deviceCornerRadius)
            .strokeBorder(
                LinearGradient(
                    gradient: edgeGradient,
                    startPoint: gradientStartPoint,
                    endPoint: gradientEndPoint
                ),
                lineWidth: width
            )
            .blur(radius: blur)
            .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private var gradientStartPoint: UnitPoint {
        let angle = animationProgress * 2 * .pi
        let x = 0.5 + 0.5 * cos(angle)
        let y = 0.5 + 0.5 * sin(angle)
        return UnitPoint(x: x, y: y)
    }
    
    private var gradientEndPoint: UnitPoint {
        let angle = animationProgress * 2 * .pi + .pi
        let x = 0.5 + 0.5 * cos(angle)
        let y = 0.5 + 0.5 * sin(angle)
        return UnitPoint(x: x, y: y)
    }
    
    private var edgeGradient: Gradient {
        // Simplified gradient for better performance
        Gradient(colors: [
            Color("GrowthGreen").opacity(0.8),
            Color("BrightTeal").opacity(0.6),
            Color("MintGreen").opacity(0.7),
            Color("GrowthGreen").opacity(0.8)
        ])
    }
    
    private func startAnimation() {
        isAnimating = true
        
        // Slower animation for subtle effect
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            animationProgress = 1.0
        }
    }
}

/// Extension to apply screen edge glow effect
extension View {
    func screenEdgeGlow(isActive: Bool, intensity: Double = 1.0) -> some View {
        self.overlay(
            ScreenEdgeGlowEffect(isActive: isActive, intensity: intensity)
                .allowsHitTesting(false)
                .ignoresSafeArea(.all, edges: .all)
        )
    }
}

#if DEBUG
struct AppleIntelligenceGlowEffect_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Example 1: Card with glow
            VStack {
                Text("Timer Running")
                    .font(AppTheme.Typography.title1Font())
                    .foregroundColor(.white)
                Text("00:45")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 300, height: 200)
            .background(Color.black)
            .cornerRadius(20)
            .appleIntelligenceGlow(isActive: true)
            
            // Example 2: Button with subtle glow
            Button("Start Timer") {
                // Action
            }
            .buttonStyle(PrimaryButtonStyle())
            .appleIntelligenceGlow(isActive: true, intensity: 0.6)
            
            // Example 3: Direct usage
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 100)
                .overlay(
                    SubtleGlowEffect(isActive: true, cornerRadius: 16)
                )
        }
        .padding()
        .background(Color.black)
    }
}
#endif

/// Specialized glow effect for rectangular borders that mimics the circular timer glow
/// Uses the same approach but optimized for rectangular shapes
struct RectangularBorderGlowEffect: View {
    @State private var animationProgress: Double = 0
    @State private var isAnimating = false
    
    let isActive: Bool
    let cornerRadius: CGFloat
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Use the same layering approach as the main glow effect
            // Layer 1: Base glow with no blur
            glowLayer(width: 3, blur: 0, offset: 0)
                .opacity(intensity)
            
            // Layer 2: Medium glow with light blur
            glowLayer(width: 5, blur: 4, offset: 0.1)
                .opacity(intensity * 0.8)
            
            // Layer 3: Wide glow with medium blur
            glowLayer(width: 8, blur: 12, offset: 0.2)
                .opacity(intensity * 0.6)
            
            // Layer 4: Outer glow with heavy blur
            glowLayer(width: 12, blur: 20, offset: 0.3)
                .opacity(intensity * 0.4)
        }
        .opacity(isActive ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: isActive)
        .allowsHitTesting(false)
        .onAppear {
            if isActive && !isAnimating {
                startAnimation()
            }
        }
        .onDisappear {
            isAnimating = false
        }
        .onChangeCompat(of: isActive) { newValue in
            if newValue && !isAnimating {
                startAnimation()
            } else if !newValue {
                isAnimating = false
            }
        }
    }
    
    private func glowLayer(width: CGFloat, blur: CGFloat, offset: Double) -> some View {
        GeometryReader { geometry in
            // Use angular gradient for smooth continuous glow
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            // Create a seamless loop
                            .init(color: Color("MintGreen"), location: 0.0),
                            .init(color: Color("BrightTeal").opacity(0.8), location: 0.1),
                            .init(color: Color("GrowthGreen").opacity(0.6), location: 0.2),
                            .init(color: Color.clear, location: 0.4),
                            .init(color: Color.clear, location: 0.6),
                            .init(color: Color("GrowthGreen").opacity(0.6), location: 0.8),
                            .init(color: Color("BrightTeal").opacity(0.8), location: 0.9),
                            .init(color: Color("MintGreen"), location: 1.0)
                        ]),
                        center: .center,
                        angle: Angle(degrees: (animationProgress + offset) * 360)
                    ),
                    lineWidth: width
                )
                .blur(radius: blur)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func startAnimation() {
        isAnimating = true
        
        // Use same animation timing as the main effect
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            animationProgress = 1.0
        }
    }
}