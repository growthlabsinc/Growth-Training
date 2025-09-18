import SwiftUI

/// Individual coach mark/spotlight component
struct CoachMark: View {
    let step: AppTourStep
    let targetFrame: CGRect?
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let showPrevious: Bool
    
    @State private var animateIn = false
    
    var body: some View {
        if let frame = targetFrame {
            let position = calculatePosition(for: frame, with: step.position)
            
            VStack(spacing: 12) {
                // Title and description
                VStack(alignment: .leading, spacing: 6) {
                    Text(step.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("TextColor"))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(step.description)
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                
                // Controls
                TourControls(
                    showPrevious: showPrevious,
                    buttonTitle: step.buttonTitle,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onSkip: onSkip
                )
            }
            .padding(16)
            .frame(width: min(240, UIScreen.main.bounds.width - 40)) // Fixed width but responsive on small screens
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .overlay(
                // Arrow pointing to target
                Group {
                    if let frame = targetFrame {
                        ArrowShape(direction: arrowDirection(for: step.position))
                            .fill(Color(UIColor.systemBackground))
                            .frame(width: 20, height: 10)
                            .offset(arrowOffset(for: step.position, targetFrame: frame, popoverPosition: position))
                    }
                },
                alignment: arrowAlignment(for: step.position)
            )
            .position(position)
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateIn = true
                }
            }
            .onDisappear {
                animateIn = false
            }
        }
    }
    
    // MARK: - Position Calculations
    
    private func calculatePosition(for frame: CGRect, with position: PopoverPosition) -> CGPoint {
        let screenBounds = UIScreen.main.bounds
        let padding: CGFloat = 20
        let popoverHeight: CGFloat = 160 // Estimated height for the popover content
        let popoverWidth: CGFloat = min(240, screenBounds.width - 40) // Match the actual frame width
        
        var calculatedPosition: CGPoint
        
        switch position {
        case .automatic:
            // Determine best position based on available space
            let spaceAbove = frame.minY
            let spaceBelow = screenBounds.height - frame.maxY
            
            if spaceBelow > popoverHeight + padding {
                calculatedPosition = CGPoint(x: frame.midX, y: frame.maxY + popoverHeight/2 + padding)
            } else if spaceAbove > popoverHeight + padding {
                calculatedPosition = CGPoint(x: frame.midX, y: frame.minY - popoverHeight/2 - padding)
            } else {
                // Center on screen if not enough space
                calculatedPosition = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
            }
            
        case .above:
            // For above positioning, intelligently position to stay on screen
            let targetCenterX = frame.midX
            let preferredX = targetCenterX
            
            // Check if this is a tab bar item (near bottom of screen)
            let isTabBarItem = frame.minY > screenBounds.height - 100
            
            // Add extra padding based on element type
            let extraPadding: CGFloat
            if isTabBarItem {
                // Tab items need significant space to clear the entire tab
                extraPadding = 100
            } else {
                // Dashboard elements also need extra space to avoid overlap
                extraPadding = 60
            }
            
            // Position the popover's center above the target
            let yPosition = frame.minY - popoverHeight/2 - padding - extraPadding
            
            // Check if popover would go off the left edge
            if preferredX - popoverWidth/2 < padding {
                // Position from left edge with padding
                calculatedPosition = CGPoint(x: popoverWidth/2 + padding, y: yPosition)
            }
            // Check if popover would go off the right edge
            else if preferredX + popoverWidth/2 > screenBounds.width - padding {
                // Position from right edge with padding
                calculatedPosition = CGPoint(x: screenBounds.width - popoverWidth/2 - padding, y: yPosition)
            }
            else {
                // Center on target
                calculatedPosition = CGPoint(x: preferredX, y: yPosition)
            }
            
        case .below:
            // For below positioning, intelligently position to stay on screen
            let targetCenterX = frame.midX
            let preferredX = targetCenterX
            
            // Check if popover would go off the left edge
            if preferredX - popoverWidth/2 < padding {
                // Position from left edge with padding
                calculatedPosition = CGPoint(x: popoverWidth/2 + padding, y: frame.maxY + popoverHeight/2 + padding)
            }
            // Check if popover would go off the right edge
            else if preferredX + popoverWidth/2 > screenBounds.width - padding {
                // Position from right edge with padding
                calculatedPosition = CGPoint(x: screenBounds.width - popoverWidth/2 - padding, y: frame.maxY + popoverHeight/2 + padding)
            }
            else {
                // Center on target
                calculatedPosition = CGPoint(x: preferredX, y: frame.maxY + popoverHeight/2 + padding)
            }
            
        case .leading:
            calculatedPosition = CGPoint(x: frame.minX - popoverWidth/2 - padding, y: frame.midY)
            
        case .trailing:
            calculatedPosition = CGPoint(x: frame.maxX + popoverWidth/2 + padding, y: frame.midY)
            
        case .custom(let x, let y):
            calculatedPosition = CGPoint(x: x, y: y)
        }
        
        // Final bounds check for Y position to respect safe areas
        let safeAreaTop: CGFloat = 60 // Increased for notch/dynamic island
        let safeAreaBottom: CGFloat = 40
        let minY = popoverHeight/2 + safeAreaTop
        let maxY = screenBounds.height - popoverHeight/2 - safeAreaBottom
        
        calculatedPosition.y = max(minY, min(maxY, calculatedPosition.y))
        
        return calculatedPosition
    }
    
    private func arrowDirection(for position: PopoverPosition) -> ArrowDirection {
        switch position {
        case .automatic, .below:
            return .up
        case .above:
            return .down
        case .leading:
            return .right
        case .trailing:
            return .left
        case .custom:
            return .up
        }
    }
    
    private func arrowAlignment(for position: PopoverPosition) -> Alignment {
        switch position {
        case .automatic, .below:
            return .top
        case .above:
            return .bottom
        case .leading:
            return .trailing
        case .trailing:
            return .leading
        case .custom:
            return .top
        }
    }
    
    private func arrowOffset(for position: PopoverPosition, targetFrame: CGRect, popoverPosition: CGPoint) -> CGSize {
        switch position {
        case .automatic, .below:
            // Calculate horizontal offset to point to the target
            let targetCenterX = targetFrame.midX
            let xOffset = targetCenterX - popoverPosition.x
            // Clamp the offset to keep arrow within popover bounds
            let maxOffset: CGFloat = 100
            let clampedXOffset = max(-maxOffset, min(maxOffset, xOffset))
            return CGSize(width: clampedXOffset, height: -5)
        case .above:
            let targetCenterX = targetFrame.midX
            let xOffset = targetCenterX - popoverPosition.x
            // For tab bar items, reduce the max offset to keep arrow more centered
            let isTabBarItem = targetFrame.minY > UIScreen.main.bounds.height - 100
            let maxOffset: CGFloat = isTabBarItem ? 60 : 100
            let clampedXOffset = max(-maxOffset, min(maxOffset, xOffset))
            return CGSize(width: clampedXOffset, height: 5)
        case .leading:
            return CGSize(width: 5, height: 0)
        case .trailing:
            return CGSize(width: -5, height: 0)
        case .custom:
            return .zero
        }
    }
}

// MARK: - Arrow Shape

enum ArrowDirection {
    case up, down, left, right
}

struct ArrowShape: Shape {
    let direction: ArrowDirection
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch direction {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            
        case .down:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
            
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
            
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.closeSubpath()
        }
        
        return path
    }
}