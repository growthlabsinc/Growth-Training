//
//  GrowthMethodFilter.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import Foundation

/// Model for filtering growth methods by various criteria
struct GrowthMethodFilter {
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
    
    /// Checks if a method matches the filter criteria
    /// - Parameter method: The method to check
    /// - Returns: True if the method matches all active filter criteria
    func matches(_ method: GrowthMethod) -> Bool {
        // If no filter is active, everything matches
        if !isActive {
            return true
        }
        
        // Apply search term filter
        if !searchTerm.isEmpty {
            let lowercasedTerm = searchTerm.lowercased()
            let matchesSearch = method.title.lowercased().contains(lowercasedTerm) ||
                               method.methodDescription.lowercased().contains(lowercasedTerm) ||
                               method.instructionsText.lowercased().contains(lowercasedTerm)
            
            if !matchesSearch {
                return false
            }
        }
        
        // Apply category filter
        if let category = selectedCategory, !method.categories.contains(category) {
            return false
        }
        
        // Apply stage filter
        if let stage = selectedStage, method.stage != stage {
            return false
        }
        
        // If we get here, the method matched all active filters
        return true
    }
    
    /// Creates a filter that matches methods containing the specified text
    /// - Parameter term: The search term
    /// - Returns: A new filter configured for text search
    static func search(_ term: String) -> GrowthMethodFilter {
        var filter = GrowthMethodFilter()
        filter.searchTerm = term
        return filter
    }
    
    /// Creates a filter that matches methods in the specified category
    /// - Parameter category: The category to filter by
    /// - Returns: A new filter configured for category filtering
    static func category(_ category: String) -> GrowthMethodFilter {
        var filter = GrowthMethodFilter()
        filter.selectedCategory = category
        return filter
    }
    
    /// Creates a filter that matches methods at the specified stage/level
    /// - Parameter stage: The stage number to filter by
    /// - Returns: A new filter configured for stage filtering
    static func stage(_ stage: Int) -> GrowthMethodFilter {
        var filter = GrowthMethodFilter()
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