//
//  CitationManager.swift
//  Growth
//
//  Centralized manager for medical citations with caching and easy access
//

import Foundation
import SwiftUI
import CryptoKit

/// Centralized manager for medical citations
@MainActor
class CitationManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CitationManager()
    
    // MARK: - Properties
    
    @Published private(set) var citations: [String: [MedicalCitation]] = [:]
    @Published private(set) var isLoading = false
    
    private var citationCache: [String: MedicalCitation] = [:]
    private var categoryCache: [String: [MedicalCitation]] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadCitations()
    }
    
    // MARK: - Public Methods
    
    /// Load all citations into memory
    func loadCitations() {
        isLoading = true
        
        // Load from MedicalCitations static data
        citations = MedicalCitations.allCitations
        
        // Build cache for quick lookup
        buildCache()
        
        isLoading = false
    }
    
    /// Get a citation by its ID
    func citation(byId id: String) -> MedicalCitation? {
        return citationCache[id]
    }
    
    /// Get citations for a specific category
    func citations(for category: String) -> [MedicalCitation] {
        return categoryCache[category] ?? []
    }
    
    /// Get all citations as a flat list
    var allCitations: [MedicalCitation] {
        return citations.values.flatMap { $0 }
    }
    
    /// Search citations by keyword
    func search(keyword: String) -> [MedicalCitation] {
        let lowercased = keyword.lowercased()
        return allCitations.filter { citation in
            citation.title.lowercased().contains(lowercased) ||
            citation.authors.joined().lowercased().contains(lowercased) ||
            citation.journal.lowercased().contains(lowercased)
        }
    }
    
    /// Get citations by year range
    func citations(from startYear: Int, to endYear: Int) -> [MedicalCitation] {
        return allCitations.filter { citation in
            citation.year >= startYear && citation.year <= endYear
        }
    }
    
    /// Get the most recent citations (last 5 years)
    func recentCitations() -> [MedicalCitation] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return citations(from: currentYear - 5, to: currentYear)
    }
    
    /// Get citations related to a specific topic
    func citationsRelated(to topic: String) -> [MedicalCitation] {
        // First check if it's an exact category match
        if let categoryCitations = categoryCache[topic] {
            return categoryCitations
        }
        
        // Otherwise search for related citations
        return search(keyword: topic)
    }
    
    /// Get citation count for a category
    func citationCount(for category: String) -> Int {
        return categoryCache[category]?.count ?? 0
    }
    
    /// Get total citation count
    var totalCitationCount: Int {
        return allCitations.count
    }
    
    /// Get categories sorted alphabetically
    var sortedCategories: [String] {
        return Array(citations.keys).sorted()
    }
    
    /// Check if citations support a claim
    func hasCitationsFor(claim: String) -> Bool {
        // Check if we have citations related to the claim
        let relatedCitations = search(keyword: claim)
        return !relatedCitations.isEmpty
    }
    
    /// Get a formatted citation string for display
    func formattedCitation(for id: String) -> String? {
        return citation(byId: id)?.formattedCitation
    }
    
    /// Get a short citation reference for inline use
    func shortCitation(for id: String) -> String? {
        return citation(byId: id)?.shortCitation
    }
    
    // MARK: - Private Methods
    
    private func buildCache() {
        // Clear existing cache
        citationCache.removeAll()
        categoryCache.removeAll()
        
        // Build citation ID cache
        for (category, citationList) in citations {
            for citation in citationList {
                citationCache[citation.id] = citation
            }
            categoryCache[category] = citationList
        }
    }
}

// MARK: - SwiftUI Environment

struct CitationManagerKey: EnvironmentKey {
    @MainActor
    static var defaultValue: CitationManager {
        CitationManager.shared
    }
}

extension EnvironmentValues {
    var citationManager: CitationManager {
        get { self[CitationManagerKey.self] }
        set { self[CitationManagerKey.self] = newValue }
    }
}

// MARK: - View Modifiers

extension View {
    /// Inject the citation manager into the environment
    @MainActor
    func withCitationManager() -> some View {
        self.environmentObject(CitationManager.shared)
    }
}

// MARK: - Citation Reference Helper

/// Helper struct for creating inline citation references
struct CitationReference {
    let id: String
    let number: Int
    private let _citation: MedicalCitation?
    
    init(id: String, number: Int, citation: MedicalCitation? = nil) {
        self.id = id
        self.number = number
        self._citation = citation
    }
    
    var citation: MedicalCitation? {
        _citation
    }
    
    var formattedReference: String {
        "[\(number)]"
    }
    
    var superscriptReference: AttributedString {
        var attributed = AttributedString(String(number))
        attributed.baselineOffset = 6
        attributed.font = .caption
        return attributed
    }
}

// MARK: - Citation Collection Helper

/// Helper for managing citations in a specific context
struct CitationCollection {
    private var references: [CitationReference] = []
    private var usedIds: Set<String> = []
    private var citationCache: [String: MedicalCitation] = [:]
    
    mutating func add(_ citation: MedicalCitation) -> CitationReference {
        if !usedIds.contains(citation.id) {
            usedIds.insert(citation.id)
            citationCache[citation.id] = citation
            let reference = CitationReference(
                id: citation.id,
                number: references.count + 1,
                citation: citation
            )
            references.append(reference)
            return reference
        } else {
            // Return existing reference
            return references.first { $0.id == citation.id }!
        }
    }
    
    var allReferences: [CitationReference] {
        references
    }
    
    var citationList: [MedicalCitation] {
        references.compactMap { $0.citation }
    }
    
    mutating func reset() {
        references.removeAll()
        usedIds.removeAll()
        citationCache.removeAll()
    }
}