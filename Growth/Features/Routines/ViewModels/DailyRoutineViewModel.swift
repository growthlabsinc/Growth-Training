import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

/// ViewModel that loads the GrowthMethods for a DaySchedule and tracks routine timer state.
@MainActor
class DailyRoutineViewModel: ObservableObject {
    @Published var methods: [GrowthMethod] = []
    @Published var isTimerRunning: Bool = false
    @Published var remainingSeconds: Int = 0
    
    // Track if timer has been started at least once
    private var timerStarted: Bool = false
    @Published var isCompleted: Bool = false
    @Published var isPaused: Bool = false

    // Track current method position for Previous/Next
    @Published var currentMethodIndex: Int = 0
    
    // Computed property to get the actual current method based on elapsed time
    var calculatedMethodIndex: Int {
        guard !methods.isEmpty && totalDurationMinutes > 0 else { return 0 }
        
        let elapsedSeconds = (totalDurationMinutes * 60) - remainingSeconds
        var accumulatedSeconds = 0
        
        for (index, method) in methods.enumerated() {
            let methodDuration = (method.estimatedDurationMinutes ?? 0) * 60
            accumulatedSeconds += methodDuration
            
            if elapsedSeconds < accumulatedSeconds {
                return index
            }
        }
        
        return methods.count - 1
    }

    private var schedule: DaySchedule
    private var cancellables = Set<AnyCancellable>()

    init(schedule: DaySchedule) {
        self.schedule = schedule
        loadMethods()
    }

    var totalDurationMinutes: Int {
        methods.compactMap { $0.estimatedDurationMinutes }.reduce(0, +)
    }

    // MARK: - Public Actions
    func startTimer() {
        guard !isTimerRunning else { return }
        if !timerStarted {
            remainingSeconds = totalDurationMinutes * 60
            timerStarted = true
        }
        isPaused = false
        isTimerRunning = true
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isPaused { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    // Update current method index based on elapsed time
                    self.currentMethodIndex = self.calculatedMethodIndex
                } else {
                    self.isTimerRunning = false
                    self.isCompleted = true
                }
            }
            .store(in: &cancellables)
    }

    func endTimer() {
        isTimerRunning = false
        cancellables.removeAll()
    }
    
    func resetTimer() {
        endTimer()
        remainingSeconds = totalDurationMinutes * 60
        currentMethodIndex = 0
        isCompleted = false
        isPaused = false
        timerStarted = false
    }

    func togglePause() {
        guard isTimerRunning else { return }
        isPaused.toggle()
    }

    // MARK: - Method Navigation
    func nextMethod() {
        guard currentMethodIndex + 1 < methods.count else { return }
        
        // Calculate the time at the start of the next method
        var timeToNextMethod = 0
        for i in 0...currentMethodIndex {
            timeToNextMethod += (methods[i].estimatedDurationMinutes ?? 0) * 60
        }
        
        // Update remaining seconds to jump to the start of the next method
        remainingSeconds = (totalDurationMinutes * 60) - timeToNextMethod
        currentMethodIndex = calculatedMethodIndex
    }

    func previousMethod() {
        guard currentMethodIndex > 0 else { return }
        
        // Calculate the time at the start of the previous method
        var timeToPreviousMethod = 0
        for i in 0..<currentMethodIndex {
            timeToPreviousMethod += (methods[i].estimatedDurationMinutes ?? 0) * 60
        }
        
        // Update remaining seconds to jump to the start of the previous method
        remainingSeconds = (totalDurationMinutes * 60) - timeToPreviousMethod
        currentMethodIndex = calculatedMethodIndex
    }

    // MARK: - Logging
    func logSessionCompletion() {
        let secondsSpent = (totalDurationMinutes * 60) - remainingSeconds
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let log: [String: Any] = [
            "userId": userId,
            "scheduleId": schedule.id,
            "secondsSpent": secondsSpent,
            "completedAt": Timestamp(date: Date())
        ]
        Firestore.firestore()
            .collection("sessionLogs")
            .addDocument(data: log) { error in
                if let error = error {
                    Logger.debug("Failed to log session: \(error)")
                } else {
                    Logger.debug("Session logged successfully")
                }
            }
    }

    // MARK: - Private Helpers
    private func loadMethods() {
        guard let ids = schedule.methodIds, !ids.isEmpty else { return }
        var loadedMethods: [GrowthMethod] = []
        let dispatchGroup = DispatchGroup()
        
        for id in ids {
            dispatchGroup.enter()
            GrowthMethodService.shared.fetchMethod(withId: id) { result in
                switch result {
                case .success(let method):
                    loadedMethods.append(method)
                case .failure(let error):
                    Logger.debug("DailyRoutineViewModel: Failed to load method \(id): \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.methods = loadedMethods.sorted { method1, method2 in
                guard let index1 = ids.firstIndex(of: method1.id ?? ""),
                      let index2 = ids.firstIndex(of: method2.id ?? "") else { return false }
                return index1 < index2
            }
            // Initialize remaining seconds to total duration when methods are loaded
            if !self.timerStarted {
                self.remainingSeconds = self.totalDurationMinutes * 60
            }
        }
    }
} 