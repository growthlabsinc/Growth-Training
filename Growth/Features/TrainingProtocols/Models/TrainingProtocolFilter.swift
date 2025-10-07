//
//  TrainingProtocolFilter.swift
//  Growth
//
//  Renamed from GrowthMethodFilter.swift for Epic 5 Story 5.3
//

import Foundation

/// Model for filtering training protocols by various criteria
struct TrainingProtocolFilter {
    /// The search term for filtering by text
    var searchTerm: String = ""

    /// The category to filter by
    var selectedCategory: String?

    /// The stage/level to filter by
    var selectedStage: Int?

    /// Whether the filter has active criteria
    var isActive: Bool {
        !searchTerm.isEmpty || selectedCategory != nil || selectedStage != nil
    }

    /// Checks if a protocol matches the filter criteria
    /// - Parameter protocol: The protocol to check
    /// - Returns: True if the protocol matches all active filter criteria
    func matches(_ protocol: TrainingProtocol) -> Bool {
        // If no filter is active, everything matches
        if !isActive {
            return true
        }

        // Apply search term filter
        if !searchTerm.isEmpty {
            let lowercasedTerm = searchTerm.lowercased()
            let matchesSearch = `protocol`.title.lowercased().contains(lowercasedTerm) ||
                               `protocol`.protocolDescription.lowercased().contains(lowercasedTerm) ||
                               `protocol`.instructionsText.lowercased().contains(lowercasedTerm)

            if !matchesSearch {
                return false
            }
        }

        // Apply category filter
        if let category = selectedCategory, !`protocol`.categories.contains(category) {
            return false
        }

        // Apply stage filter
        if let stage = selectedStage, `protocol`.stage != stage {
            return false
        }

        // If we get here, the protocol matched all active filters
        return true
    }

    /// Creates a filter that matches protocols containing the specified text
    /// - Parameter term: The search term
    /// - Returns: A new filter configured for text search
    static func search(_ term: String) -> TrainingProtocolFilter {
        var filter = TrainingProtocolFilter()
        filter.searchTerm = term
        return filter
    }

    /// Creates a filter that matches protocols in the specified category
    /// - Parameter category: The category to filter by
    /// - Returns: A new filter configured for category filtering
    static func category(_ category: String) -> TrainingProtocolFilter {
        var filter = TrainingProtocolFilter()
        filter.selectedCategory = category
        return filter
    }

    /// Creates a filter that matches protocols at the specified stage/level
    /// - Parameter stage: The stage number to filter by
    /// - Returns: A new filter configured for stage filtering
    static func stage(_ stage: Int) -> TrainingProtocolFilter {
        var filter = TrainingProtocolFilter()
        filter.selectedStage = stage
        return filter
    }

    /// Resets all filter criteria to their default values
    mutating func reset() {
        searchTerm = ""
        selectedCategory = nil
        selectedStage = nil
    }
}
