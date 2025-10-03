//
//  GrowthMethodDetailViewModel.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import Foundation
import Combine

/// View model for Growth Method detail view
class GrowthMethodDetailViewModel: ObservableObject {
    /// The growth method to display
    @Published var method: GrowthMethod?
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Error message if fetch fails
    @Published var errorMessage: String? = nil
    
    /// Snapshot of progression readiness
    @Published var progressionSnapshot: ProgressionSnapshot?
    
    /// List of progression events (history)
    @Published var progressionEvents: [ProgressionEvent] = []
    
    /// Reference to the Growth Method service
    private let methodService = GrowthMethodService.shared
    
    /// Store for cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Method ID
    private var methodId: String?
    
    /// Initialize with a method ID to load
    /// - Parameter methodId: The ID of the method to display
    init(methodId: String? = nil) {
        self.methodId = methodId
        if let id = methodId {
            loadMethod(id: id)
        }
    }
    
    /// Initialize with a pre-loaded method
    /// - Parameter method: The method to display
    init(method: GrowthMethod) {
        self.method = method
        self.methodId = method.id
        self.evaluateReadiness()
        self.loadHistory()
    }
    
    /// Loads the method from the service
    /// - Parameters:
    ///   - id: The ID of the method to load
    ///   - forceRefresh: If true, bypasses cache and fetches fresh data
    func loadMethod(id: String, forceRefresh: Bool = false) {
        methodId = id
        isLoading = true
        errorMessage = nil
        
        methodService.fetchMethod(withId: id, forceRefresh: forceRefresh) { [weak self] (result: Result<GrowthMethod, Error>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let method):
                    self.method = method
                    self.evaluateReadiness()
                    self.loadHistory()
                case .failure(let error):
                    self.errorMessage = "Failed to load method: \(error.localizedDescription)"
                    Logger.debug("GrowthMethodDetailViewModel: Error loading method \(id) - \(error)")
                }
            }
        }
    }
    
    /// Reloads the current method
    /// - Parameter forceRefresh: If true, bypasses cache and fetches fresh data
    func reload(forceRefresh: Bool = true) {
        guard let methodId = methodId else { return }
        loadMethod(id: methodId, forceRefresh: forceRefresh)
    }
    
    /// Returns true if the method has equipment requirements
    var hasEquipment: Bool {
        return method?.equipmentNeeded.isEmpty == false
    }
    
    /// Returns true if the method has categories
    var hasCategories: Bool {
        return method?.categories.isEmpty == false
    }
    
    /// Returns the method stage as a formatted string
    var stageFormatted: String {
        guard let stage = method?.stage else { return "Unknown Stage" }
        switch stage {
        case 1: return "Beginner (Stage 1)"
        case 2: return "Intermediate (Stage 2)"
        case 3: return "Advanced (Stage 3)"
        default: return "Stage \(stage)"
        }
    }
    
    // MARK: - Progression / Readiness
    private func evaluateReadiness() {
        guard let method = method else { return }
        ProgressionService.shared.evaluateReadiness(for: method) { [weak self] snapshot in
            DispatchQueue.main.async {
                self?.progressionSnapshot = snapshot
            }
        }
    }
    
    /// Progress user to next stage
    func progressToNextStage() {
        guard let method = method else { return }
        ProgressionService.shared.progressUser(for: method, latestSnapshot: progressionSnapshot) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Refresh readiness and update method stage
                    self?.reload(forceRefresh: true)
                } else if let error = error {
                    Logger.debug("Progression failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - History
    private func loadHistory() {
        guard let method = method else { return }
        ProgressionService.shared.fetchHistory(for: method) { [weak self] events in
            DispatchQueue.main.async {
                self?.progressionEvents = events
            }
        }
    }
    
    // MARK: - Exposed properties for UI
    var classification: String? {
        method?.classification
    }
    var progressionCriteriaText: String? {
        method?.progressionCriteriaText
    }
    var progressionCriteria: ProgressionCriteria? {
        method?.progressionCriteria
    }
    var safetyNotes: String? {
        method?.safetyNotes
    }
    var benefits: [String]? {
        method?.benefits
    }
    var relatedMethods: [String]? {
        method?.relatedMethods
    }
    var hasSafetyNotes: Bool {
        (method?.safetyNotes?.isEmpty == false)
    }
    var formattedProgressionCriteria: String {
        if let text = method?.progressionCriteriaText, !text.isEmpty {
            return text
        } else if method?.progressionCriteria != nil {
            // You can add custom formatting for structured criteria here
            return "See progression criteria details."
        } else {
            return "No progression criteria specified."
        }
    }
    var formattedSafetyNotes: String {
        method?.safetyNotes ?? "No specific safety notes."
    }
} 