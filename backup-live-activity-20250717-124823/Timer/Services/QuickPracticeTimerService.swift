//
//  QuickPracticeTimerService.swift
//  Growth
//
//  Singleton service for quick practice timer to maintain state across navigation
//

import Foundation
import Combine

/// Singleton timer service specifically for quick practice sessions
/// This ensures timer state persists when navigating away from and back to the quick practice view
class QuickPracticeTimerService: ObservableObject {
    static let shared = QuickPracticeTimerService()
    
    /// The underlying timer service instance
    private(set) var timerService: TimerService
    
    /// Published properties that mirror the timer service for proper UI updates
    @Published var elapsedTime: TimeInterval = 0
    @Published var remainingTime: TimeInterval = 0
    @Published var timerState: TimerState = .stopped
    @Published var overallProgress: Double = 0
    
    /// Publisher for timer state changes
    var timerStatePublisher: AnyPublisher<TimerState, Never> {
        $timerState.eraseToAnyPublisher()
    }
    
    /// Current timer state
    var state: TimerState {
        timerState
    }
    
    /// Timer mode
    var timerMode: TimerMode {
        timerService.timerMode
    }
    
    /// Target duration value
    var targetDurationValue: TimeInterval {
        timerService.targetDurationValue
    }
    
    /// Cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Current method ID
    var currentMethodId: String? {
        get { timerService.currentMethodId }
        set { timerService.currentMethodId = newValue }
    }
    
    /// Current method name
    var currentMethodName: String? {
        get { timerService.currentMethodName }
        set { timerService.currentMethodName = newValue }
    }
    
    private init() {
        // Create a dedicated timer service instance for quick practice
        // skipStateRestore: true - we handle restoration manually
        // isQuickPractice: true - marks this as a quick practice timer
        self.timerService = TimerService(skipStateRestore: true, isQuickPractice: true)
        
        // Set up subscriptions to mirror timer service state
        timerService.$elapsedTime
            .sink { [weak self] time in
                self?.elapsedTime = time
            }
            .store(in: &cancellables)
        
        timerService.$remainingTime
            .sink { [weak self] time in
                self?.remainingTime = time
            }
            .store(in: &cancellables)
        
        timerService.$timerState
            .sink { [weak self] state in
                self?.timerState = state
            }
            .store(in: &cancellables)
        
        timerService.$overallProgress
            .sink { [weak self] progress in
                self?.overallProgress = progress
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Timer Control Methods
    
    func configure(with configuration: TimerConfiguration) {
        print("QuickPracticeTimerService: Configuring timer")
        print("  - Recommended duration: \(configuration.recommendedDurationSeconds ?? 0)s")
        print("  - Is countdown: \(configuration.isCountdown ?? false)")
        print("  - Has intervals: \(configuration.hasIntervals ?? false)")
        timerService.configure(with: configuration)
        print("  - Timer mode after config: \(timerService.timerMode)")
        print("  - Target duration after config: \(timerService.targetDurationValue)")
    }
    
    func start() {
        print("QuickPracticeTimerService: Starting timer")
        print("  - Current state: \(timerService.state)")
        print("  - Timer mode: \(timerService.timerMode)")
        print("  - Target duration: \(timerService.targetDurationValue)")
        timerService.start()
        print("  - State after start: \(timerService.state)")
    }
    
    func pause() {
        timerService.pause()
    }
    
    func resume() {
        timerService.resume()
    }
    
    func stop() {
        timerService.stop()
    }
    
    func restoreFromBackground(isQuickPractice: Bool = true) {
        timerService.restoreFromBackground(isQuickPractice: isQuickPractice)
    }
    
    func hasActiveBackgroundTimer() -> Bool {
        return timerService.hasActiveBackgroundTimer()
    }
    
    /// Reset the timer service to a fresh state
    /// This should be called when starting a new quick practice session
    func reset() {
        timerService.stop()
        timerService.currentMethodId = nil
        timerService.currentMethodName = nil
    }
}