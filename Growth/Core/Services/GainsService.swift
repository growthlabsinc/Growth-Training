//
//  GainsService.swift
//  Growth
//
//  Created by Developer on 6/2/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// Service for managing gains measurement data
class GainsService: ObservableObject {
    static let shared = GainsService()
    
    private let db = Firestore.firestore()
    private let collection = "gains_entries"
    
    @Published var entries: [GainsEntry] = []
    @Published var statistics: GainsStatistics?
    @Published var isLoading = false
    @Published var error: String?
    
    // User preferences
    @Published var preferredUnit: MeasurementUnit = .imperial {
        didSet {
            UserDefaults.standard.set(preferredUnit.rawValue, forKey: "preferred_measurement_unit")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        // Load preferred unit from UserDefaults
        if let savedUnit = UserDefaults.standard.string(forKey: "preferred_measurement_unit"),
           let unit = MeasurementUnit(rawValue: savedUnit) {
            self.preferredUnit = unit
        }
    }
    
    // MARK: - Public Methods
    
    /// Start listening to gains entries for a user
    func startListening(userId: String) {
        stopListening()
        
        isLoading = true
        listenerRegistration = db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.entries = []
                    return
                }
                
                self.entries = documents.compactMap { doc in
                    try? doc.data(as: GainsEntry.self)
                }
                
                self.calculateStatistics()
            }
    }
    
    /// Stop listening to changes
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    /// Add a new gains entry
    func addEntry(_ entry: GainsEntry) async throws {
        let data = try Firestore.Encoder().encode(entry)
        try await db.collection(collection).addDocument(data: data)
    }
    
    /// Update an existing entry
    func updateEntry(_ entry: GainsEntry) async throws {
        guard let id = entry.id else { return }
        
        // Create a new entry with updated timestamp
        let updatedEntry = GainsEntry(
            id: entry.id,
            userId: entry.userId,
            timestamp: entry.timestamp,
            length: entry.length,
            girth: entry.girth,
            erectionQuality: entry.erectionQuality,
            notes: entry.notes,
            sessionId: entry.sessionId,
            measurementUnit: entry.measurementUnit
        )
        
        let data = try Firestore.Encoder().encode(updatedEntry)
        try await db.collection(collection).document(id).setData(data)
    }
    
    /// Delete an entry
    func deleteEntry(_ entryId: String) async throws {
        try await db.collection(collection).document(entryId).delete()
    }
    
    /// Get the latest entry for a user
    func getLatestEntry(userId: String) async throws -> GainsEntry? {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: GainsEntry.self)
    }
    
    /// Get baseline entry (first entry) for a user
    func getBaselineEntry(userId: String) async throws -> GainsEntry? {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: false)
            .limit(to: 1)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: GainsEntry.self)
    }
    
    /// Get entries for a specific date range
    func getEntries(userId: String, from startDate: Date, to endDate: Date) async throws -> [GainsEntry] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
            .whereField("timestamp", isLessThanOrEqualTo: endDate)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: GainsEntry.self)
        }
    }
    
    // MARK: - Statistics Calculation
    
    private func calculateStatistics() {
        guard !entries.isEmpty else {
            statistics = nil
            return
        }
        
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        let baseline = sortedEntries.first
        let latest = sortedEntries.last
        
        // Find best measurements
        let bestLength = sortedEntries.max { $0.length < $1.length }
        let bestGirth = sortedEntries.max { $0.girth < $1.girth }
        let bestEQ = sortedEntries.max { $0.erectionQuality < $1.erectionQuality }
        
        // Create a "best" entry combining all best measurements
        let best = bestLength.map { length in
            GainsEntry(
                userId: length.userId,
                timestamp: length.timestamp,
                length: length.length,
                girth: bestGirth?.girth ?? length.girth,
                erectionQuality: bestEQ?.erectionQuality ?? length.erectionQuality,
                measurementUnit: length.measurementUnit
            )
        }
        
        // Calculate averages
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        
        let weekEntries = entries.filter { $0.timestamp >= weekAgo }
        let monthEntries = entries.filter { $0.timestamp >= monthAgo }
        
        statistics = GainsStatistics(
            baseline: baseline,
            latest: latest,
            best: best,
            weekAverage: calculateAverages(for: weekEntries, days: 7),
            monthAverage: calculateAverages(for: monthEntries, days: 30),
            allTimeAverage: calculateAverages(for: entries, days: daysBetween(baseline?.timestamp ?? now, now))
        )
    }
    
    private func calculateAverages(for entries: [GainsEntry], days: Int) -> GainsAverages? {
        guard !entries.isEmpty else { return nil }
        
        let totalLength = entries.reduce(0) { $0 + $1.length }
        let totalGirth = entries.reduce(0) { $0 + $1.girth }
        let totalVolume = entries.reduce(0) { $0 + $1.volume }
        let totalEQ = entries.reduce(0) { $0 + Double($1.erectionQuality) }
        
        let count = Double(entries.count)
        
        return GainsAverages(
            length: totalLength / count,
            girth: totalGirth / count,
            volume: totalVolume / count,
            erectionQuality: totalEQ / count,
            entryCount: entries.count,
            periodDays: days
        )
    }
    
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(1, components.day ?? 1)
    }
    
    // MARK: - Validation
    
    /// Validate measurement values
    static func validateMeasurements(length: Double, girth: Double, unit: MeasurementUnit) -> (isValid: Bool, error: String?) {
        // Convert to inches for validation
        let lengthInches = unit == .metric ? length / 2.54 : length
        let girthInches = unit == .metric ? girth / 2.54 : girth
        
        // Reasonable bounds (in inches)
        let minLength: Double = 1.0
        let maxLength: Double = 12.0
        let minGirth: Double = 1.0
        let maxGirth: Double = 8.0
        
        if lengthInches < minLength || lengthInches > maxLength {
            return (false, "Length must be between \(formatMeasurement(minLength, unit)) and \(formatMeasurement(maxLength, unit))")
        }
        
        if girthInches < minGirth || girthInches > maxGirth {
            return (false, "Girth must be between \(formatMeasurement(minGirth, unit)) and \(formatMeasurement(maxGirth, unit))")
        }
        
        return (true, nil)
    }
    
    private static func formatMeasurement(_ inches: Double, _ unit: MeasurementUnit) -> String {
        switch unit {
        case .imperial:
            return String(format: "%.1f\"", inches)
        case .metric:
            return String(format: "%.1fcm", inches * 2.54)
        }
    }
}

