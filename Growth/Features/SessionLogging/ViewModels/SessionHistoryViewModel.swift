import Foundation
import Combine
import FirebaseAuth // Required for Auth.auth().currentUser

class SessionHistoryViewModel: ObservableObject {
    @Published var sessionLogs: [SessionLog] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var growthProtocols: [String: Growth.TrainingProtocol] = [:] // To store fetched protocol details

    private var firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Listen for session log updates
        NotificationCenter.default.publisher(for: .sessionLogUpdated)
            .sink { [weak self] notification in
                if let updatedLog = notification.object as? SessionLog {
                    self?.updateSessionLogInList(updatedLog)
                }
            }
            .store(in: &cancellables)

        // Listen for session log deletions
        NotificationCenter.default.publisher(for: .sessionLogDeleted)
            .sink { [weak self] notification in
                if let deletedLogId = notification.object as? String {
                    self?.removeSessionLogFromList(deletedLogId)
                }
            }
            .store(in: &cancellables)
    }

    // Fetches all growth protocols and stores them for quick lookup
    func fetchAllGrowthProtocols() {
        firestoreService.getAllGrowthMethods { [weak self] (protocols, error) in
            if let error = error {
                self?.errorMessage = "Error fetching growth protocols: \(error.localizedDescription)"
                // Potentially handle this error more gracefully, maybe retry or use cached data
                return
            }
            var protocolsDict: [String: Growth.TrainingProtocol] = [:]
            for trainingProtocol in protocols {
                if let id = trainingProtocol.id {
                    protocolsDict[id] = trainingProtocol
                }
            }
            self?.growthProtocols = protocolsDict
            // After fetching protocols, fetch session logs as they might depend on protocol names
            self?.fetchSessionLogs()
        }
    }

    func fetchSessionLogs() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        FirestoreService.shared.getSessionLogsForUser(userId: userId) { [weak self] (logs, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error fetching session logs: \(error.localizedDescription)"
                } else {
                    self?.sessionLogs = logs
                    if logs.isEmpty {
                        // self?.errorMessage = "No sessions logged yet." // Or handle this in the View
                    }
                }
            }
        }
    }

    // Call this method when the view appears or needs to refresh data
    func loadData() {
        // Ensure growth protocols are loaded first, then session logs
        if growthProtocols.isEmpty {
            fetchAllGrowthProtocols()
        } else {
            fetchSessionLogs() // If protocols are already loaded, just fetch logs
        }
    }
    
    func getProtocolName(protocolId: String?) -> String {
        guard let id = protocolId else { return "Unknown Protocol" }

        // First check if we have it in our fetched protocols
        if let protocolTitle = growthProtocols[id]?.title {
            return protocolTitle
        }

        // Fallback to common protocol ID mappings
        switch id {
        case "angio_pumping": return "Angio Pumping"
        case "s2s_stretch": return "S2S Stretch"
        case "s2s_advanced": return "S2S Advanced"
        case "bfr_cyclic_bending": return "BFR Cyclic Bending"
        case "bfr_glans_pulsing": return "BFR Glans Pulsing"
        default: return "Protocol"
        }
    }
    
    private func updateSessionLogInList(_ updatedLog: SessionLog) {
        if let index = sessionLogs.firstIndex(where: { $0.id == updatedLog.id }) {
            sessionLogs[index] = updatedLog
        } else {
            // If the log wasn't in the list (e.g., new log not covered by current story, or list was empty),
            // or if a full refresh is preferred after any update, just reload all.
            // For now, this indicates an edge case or that a full refresh might be simpler.
            // loadData() // Consider if a full refresh is better
            Logger.debug("SessionHistoryViewModel: Received update for a log not currently in the list, or list needs full refresh.")
            // A more robust solution might be to insert if new and relevant, or just rely on next full loadData call.
            // For Story 4.4, we primarily expect updates to existing items.
        }
    }

    private func removeSessionLogFromList(_ deletedLogId: String) {
        sessionLogs.removeAll { $0.id == deletedLogId }
        // Optionally, if the list becomes empty, you might want to set a specific message
        // if sessionLogs.isEmpty {
        //     self.errorMessage = "No sessions logged yet."
        // }
    }
} 