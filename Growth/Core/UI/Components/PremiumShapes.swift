import SwiftUI

// MARK: - Animated Wave Shape
struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat = 20
    var frequency: CGFloat = 0.02
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: rect.midY))
        
        for x in stride(from: 0, to: rect.width, by: 1) {
            let y = sin((x + offset) * frequency) * amplitude + rect.midY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Circular Progress Shape
struct CircularProgressShape: Shape {
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + 360 * progress)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        return path
    }
}

// MARK: - Diamond Shape
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.midY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Hexagon Shape
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let xOffset = width * 0.25
        
        path.move(to: CGPoint(x: xOffset, y: 0))
        path.addLine(to: CGPoint(x: width - xOffset, y: 0))
        path.addLine(to: CGPoint(x: width, y: height / 2))
        path.addLine(to: CGPoint(x: width - xOffset, y: height))
        path.addLine(to: CGPoint(x: xOffset, y: height))
        path.addLine(to: CGPoint(x: 0, y: height / 2))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Animated Blob Shape
struct BlobShape: Shape {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let minDimension = min(width, height)
        let radius = minDimension / 2
        
        path.move(to: CGPoint(x: width / 2, y: 0))
        
        // Create blob effect with control points
        let points = 8
        for i in 0..<points {
            let angle = (CGFloat(i) / CGFloat(points)) * 2 * .pi
            let nextAngle = (CGFloat(i + 1) / CGFloat(points)) * 2 * .pi
            
            // Add variation to radius
            let variation = sin(phase + angle * 2) * 0.1 + 1
            let currentRadius = radius * variation
            
            let point = CGPoint(
                x: width / 2 + cos(angle) * currentRadius,
                y: height / 2 + sin(angle) * currentRadius
            )
            
            let nextVariation = sin(phase + nextAngle * 2) * 0.1 + 1
            let nextRadius = radius * nextVariation
            let nextPoint = CGPoint(
                x: width / 2 + cos(nextAngle) * nextRadius,
                y: height / 2 + sin(nextAngle) * nextRadius
            )
            
            // Control points for smooth curves
            let controlRadius = radius * 0.55
            let control1 = CGPoint(
                x: point.x + cos(angle + .pi / 2) * controlRadius,
                y: point.y + sin(angle + .pi / 2) * controlRadius
            )
            let control2 = CGPoint(
                x: nextPoint.x + cos(nextAngle - .pi / 2) * controlRadius,
                y: nextPoint.y + sin(nextAngle - .pi / 2) * controlRadius
            )
            
            if i == 0 {
                path.move(to: point)
            }
            
            path.addCurve(to: nextPoint, control1: control1, control2: control2)
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Gradient Mesh Background
struct GradientMeshView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Multiple blob shapes with different animations
                ForEach(0..<3) { index in
                    BlobShape(phase: phase + CGFloat(index) * 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("GrowthGreen").opacity(0.3),
                                    Color("BrightTeal").opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * 0.8,
                            height: geometry.size.width * 0.8
                        )
                        .offset(
                            x: sin(phase + CGFloat(index)) * 50,
                            y: cos(phase + CGFloat(index)) * 50
                        )
                        .blur(radius: 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Animated Success Checkmark
struct AnimatedCheckmark: View {
    @State private var trimEnd: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("GrowthGreen").opacity(0.2), lineWidth: 4)
                .frame(width: 100, height: 100)
            
            CheckmarkShape()
                .trim(from: 0, to: trimEnd)
                .stroke(Color("GrowthGreen"), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 50, height: 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                trimEnd = 1
            }
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let start = CGPoint(x: rect.width * 0.2, y: rect.height * 0.5)
        let mid = CGPoint(x: rect.width * 0.4, y: rect.height * 0.7)
        let end = CGPoint(x: rect.width * 0.8, y: rect.height * 0.3)
        
        path.move(to: start)
        path.addLine(to: mid)
        path.addLine(to: end)
        
        return path
    }
}

// MARK: - Pulsing Circle
struct PulsingCircle: View {
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0.7
    
    var body: some View {
        Circle()
            .fill(Color("GrowthGreen"))
            .frame(width: 100, height: 100)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.2
                    opacity = 0.3
                }
            }
    }
}

// MARK: - Animated Progress Ring
struct ProgressRing: View {
    let progress: CGFloat
    let lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color("GrowthGreen"), Color("BrightTeal")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            // Center text
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: AppTheme.Typography.title2, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("Complete")
                    .font(.system(size: AppTheme.Typography.caption))
                    .foregroundColor(AppTheme.Colors.text.opacity(0.7))
            }
        }
    }
}

// MARK: - Floating Action Button Style
struct FloatingActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("GrowthGreen"), Color("BrightTeal")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .shadow(
                color: Color("GrowthGreen").opacity(0.3),
                radius: configuration.isPressed ? 5 : 10,
                y: configuration.isPressed ? 2 : 5
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Neumorphic Card Style
struct NeumorphicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 5, y: 5)
                    .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
            )
    }
}

extension View {
    func neumorphicCard() -> some View {
        modifier(NeumorphicCardModifier())
    }
}