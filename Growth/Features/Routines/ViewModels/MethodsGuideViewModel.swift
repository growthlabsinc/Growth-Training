//
//  MethodsGuideViewModel.swift
//  Growth
//
//  Created for Methods Guide feature
//

import Foundation
import Combine
import SwiftUI

class MethodsGuideViewModel: ObservableObject {
    @Published var methods: [TrainingProtocol] = []
    @Published var categories: [String] = ["All"]
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let growthMethodService = TrainingProtocolService.shared
    
    init() {
        loadMethods()
    }
    
    func loadMethods() {
        isLoading = true
        error = nil

        // Use fetchActionableProtocols to exclude Level 0 educational protocols
        // Level 0 protocols are educational content meant for the Learning Center
        growthMethodService.fetchActionableProtocols { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let fetchedMethods):
                    self?.methods = fetchedMethods.sorted { $0.stage < $1.stage }
                    self?.extractCategories()
                case .failure(let error):
                    self?.error = error.localizedDescription
                    Logger.debug("Error loading methods: \(error)")
                }
            }
        }
    }
    
    private func extractCategories() {
        // Extract unique categories from all methods
        var uniqueCategories = Set<String>()
        
        for method in methods {
            for category in method.categories {
                uniqueCategories.insert(category)
            }
        }
        
        // Sort categories and add "All" at the beginning
        categories = ["All"] + uniqueCategories.sorted()
    }
    
    func methodsForCategory(_ category: String) -> [TrainingProtocol] {
        if category == "All" {
            return methods
        }
        return methods.filter { $0.categories.contains(category) }
    }
    
    func searchMethods(query: String) -> [TrainingProtocol] {
        guard !query.isEmpty else { return methods }
        
        return methods.filter { method in
            method.title.localizedCaseInsensitiveContains(query) ||
            method.protocolDescription.localizedCaseInsensitiveContains(query) ||
            method.instructionsText.localizedCaseInsensitiveContains(query)
        }
    }
}