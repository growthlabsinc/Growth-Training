import SwiftUI

/// Main overlay component for the app tour
struct AppTourOverlay: View {
    @ObservedObject var viewModel: AppTourViewModel
    @State private var animateOverlay = false
    
    var body: some View {
        if viewModel.isActive {
            GeometryReader { geometry in
                ZStack {
                    // Dimmed background with cutout
                    SpotlightOverlay(
                        targetFrame: viewModel.currentTargetFrame,
                        padding: viewModel.currentStep?.highlightPadding ?? 8
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    
                    // Coach mark
                    if let step = viewModel.currentStep, let targetFrame = viewModel.currentTargetFrame {
                        CoachMark(
                            step: step,
                            targetFrame: targetFrame,
                            onPrevious: viewModel.previousStep,
                            onNext: viewModel.nextStep,
                            onSkip: viewModel.skipTour,
                            showPrevious: viewModel.currentStepIndex > 0
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                            removal: .opacity
                        ))
                        
                    }
                    
                    // Progress indicator at top with proper safe area handling
                    VStack {
                        if viewModel.configuration.showProgress {
                            TourProgressIndicator(
                                currentStep: viewModel.currentStepIndex,
                                totalSteps: viewModel.configuration.steps.count,
                                progressText: viewModel.progressText
                            )
                            .padding(.top, geometry.safeAreaInsets.top + 20) // Respect safe area + additional padding
                        }
                        
                        Spacer()
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("AppTourOverlay")
            .opacity(animateOverlay ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    animateOverlay = true
                }
            }
            .onDisappear {
                animateOverlay = false
            }
        }
    }
}

/// Spotlight overlay with cutout for highlighted element
struct SpotlightOverlay: View {
    let targetFrame: CGRect?
    let padding: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            if let frame = targetFrame {
                Path { path in
                    // Add the entire screen
                    path.addRect(geometry.frame(in: .local))
                    
                    // Create cutout for highlighted area
                    let cutoutRect = frame.insetBy(dx: -padding, dy: -padding)
                    let cutoutPath = RoundedRectangle(cornerRadius: 12)
                        .path(in: cutoutRect)
                    
                    // Subtract the cutout from the full screen path
                    if #available(iOS 17.0, *) {
                        path = path.subtracting(Path(cutoutPath.cgPath))
                    } else {
                        // For iOS 16, use a simple cutout approach
                        // This won't be as smooth but will work
                        path = Path { p in
                            p.addRect(geometry.frame(in: .local))
                            p.addPath(cutoutPath, transform: .identity)
                        }
                    }
                }
                .fill(Color.black.opacity(0.5))
                .animation(.easeInOut(duration: 0.3), value: frame)
            } else {
                // No target, just dim the whole screen
                Color.black.opacity(0.5)
            }
        }
    }
}

// MARK: - Helper Extensions

extension View {
    /// Reverse mask modifier for creating cutouts
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            Rectangle()
                .overlay(
                    mask()
                        .blendMode(.destinationOut)
                )
        )
    }
}