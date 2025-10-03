import SwiftUI
import Combine

/// View model managing the app tour state and navigation
class AppTourViewModel: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var targetFrames: [String: CGRect] = [:]
    @Published var configuration: AppTourConfiguration
    
    private let tourService = AppTourService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var currentStep: AppTourStep? {
        guard currentStepIndex < configuration.steps.count else { return nil }
        return configuration.steps[currentStepIndex]
    }
    
    var currentTargetFrame: CGRect? {
        guard let step = currentStep else { 
            return nil 
        }
        let frame = targetFrames[step.targetViewId]
        return frame
    }
    
    var progressText: String {
        guard configuration.showProgress else { return "" }
        return "Step \(currentStepIndex + 1) of \(configuration.steps.count)"
    }
    
    var progressPercentage: Double {
        guard configuration.steps.count > 0 else { return 0 }
        return Double(currentStepIndex + 1) / Double(configuration.steps.count)
    }
    
    init() {
        self.configuration = tourService.getTourConfiguration()
        setupBindings()
    }
    
    private func setupBindings() {
        // Monitor for app becoming inactive to pause tour
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseTour()
            }
            .store(in: &cancellables)
    }
    
    /// Start the tour if it should be shown
    func startTourIfNeeded() {
        guard tourService.shouldShowTour() else { return }
        
        // Delay slightly to ensure all views are loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startTour()
        }
    }
    
    /// Start the tour
    func startTour() {
        currentStepIndex = 0
        isActive = true
        tourService.markTourStarted()
    }
    
    /// Move to the next step
    func nextStep() {
        guard currentStepIndex < configuration.steps.count - 1 else {
            completeTour()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStepIndex += 1
        }
    }
    
    /// Move to the previous step
    func previousStep() {
        guard currentStepIndex > 0 else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStepIndex -= 1
        }
    }
    
    /// Skip the entire tour
    func skipTour() {
        withAnimation(.easeOut(duration: 0.2)) {
            isActive = false
        }
        tourService.markTourSkipped()
    }
    
    /// Complete the tour
    func completeTour() {
        withAnimation(.easeOut(duration: 0.2)) {
            isActive = false
        }
        tourService.markTourCompleted()
    }
    
    /// Pause the tour (e.g., when app goes to background)
    private func pauseTour() {
        if isActive {
            isActive = false
        }
    }
    
    /// Update target frame for a view
    func updateTargetFrame(for viewId: String, frame: CGRect) {
        // Debounce frame updates to avoid multiple updates per frame
        DispatchQueue.main.async { [weak self] in
            self?.targetFrames[viewId] = frame
        }
    }
    
    /// Check if a specific view is currently highlighted
    func isHighlighted(viewId: String) -> Bool {
        guard isActive, let step = currentStep else { return false }
        return step.targetViewId == viewId
    }
}

/// View modifier to mark a view as a tour target
struct TourTarget: ViewModifier {
    let id: String
    @EnvironmentObject var tourViewModel: AppTourViewModel
    @State private var lastFrame: CGRect = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            let frame = geometry.frame(in: .global)
                            if frame != lastFrame {
                                lastFrame = frame
                                tourViewModel.updateTargetFrame(for: id, frame: frame)
                            }
                        }
                        .onChange(of: geometry.frame(in: .global)) { newFrame in
                            // Only update if frame actually changed
                            if newFrame != lastFrame {
                                lastFrame = newFrame
                                tourViewModel.updateTargetFrame(for: id, frame: newFrame)
                            }
                        }
                }
            )
    }
}

extension View {
    /// Mark this view as a tour target
    func tourTarget(_ id: String) -> some View {
        modifier(TourTarget(id: id))
    }
}