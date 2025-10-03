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
@MainActor
class QuickPracticeTimerService: ObservableObject {
    static let shared = QuickPracticeTimerService()
    
    /// The underlying timer service instance
    private var _timerService: TimerService?
    
    var timerService: TimerService {
        if let service = _timerService {
            return service
        }
        
        let service = TimerService(skipStateRestore: true, isQuickPractice: true)
        _timerService = service
        setupBindings(for: service)
        return service
    }
    
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
        // timerService will be created lazily when first accessed
        // This ensures proper MainActor isolation
    }
    
    private func setupBindings(for service: TimerService) {
        // Set up subscriptions to mirror timer service state
        service.$elapsedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                Task { @MainActor in
                    self?.elapsedTime = time
                }
            }
            .store(in: &cancellables)

        service.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                Task { @MainActor in
                    self?.remainingTime = time
                }
            }
            .store(in: &cancellables)

        service.$timerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                Task { @MainActor in
                    self?.timerState = state
                }
            }
            .store(in: &cancellables)

        service.$overallProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                Task { @MainActor in
                    self?.overallProgress = progress
                }
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
    
    func startWithTrialCheck(completion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            let result = await startAsync()
            completion(result)
        }
    }

    private func startAsync() async -> Bool {
        print("QuickPracticeTimerService: Starting timer")
        print("  - Current state: \(timerService.state)")
        print("  - Timer mode: \(timerService.timerMode)")
        print("  - Target duration: \(timerService.targetDurationValue)")

        // Check trial limits before starting
        let (allowed, reason) = await timerService.canStartSessionWithTrialLimits(
            duration: timerService.timerMode == .countdown ? timerService.targetDurationValue : nil,
            timerMode: timerService.timerMode
        )

        print("📊 [QuickTimer] Trial check result:")
        print("  - Allowed: \(allowed)")
        print("  - Reason: \(reason ?? "none")")

        if !allowed {
            // Show alert with reason
            if let reason = reason {
                NotificationCenter.default.post(
                    name: Notification.Name("showTrialLimitAlert"),
                    object: nil,
                    userInfo: ["message": reason]
                )
            }
            return false
        }

        // If allowed but has a warning message, show it
        if let reason = reason {
            NotificationCenter.default.post(
                name: Notification.Name("showTrialLimitWarning"),
                object: nil,
                userInfo: ["message": reason]
            )
        }

        timerService.start()

        // TimerService will notify TimerCoordinator with type "quick" since isQuickPractice=true

        print("  - State after start: \(timerService.state)")
        return true
    }

    // Legacy method for backward compatibility - bypasses trial checks
    func start() {
        print("⚠️ QuickPracticeTimerService: Using legacy start() without trial checks")
        timerService.start()
    }
    
    func pause() {
        timerService.pause()
    }
    
    func resume() {
        timerService.resume()
    }
    
    func stop() {
        timerService.stop()
        
        // TimerService will notify TimerCoordinator with type "quick" since isQuickPractice=true
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