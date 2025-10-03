//
//  GainsEntry.swift
//  Growth
//
//  Created by Developer on 6/2/25.
//

import Foundation
import FirebaseFirestore

/// Represents a single gains measurement entry
struct GainsEntry: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userId: String
    let timestamp: Date
    
    // Measurements
    let length: Double // Always stored in inches internally
    let girth: Double  // Always stored in inches internally
    let erectionQuality: Int // 1-10 scale
    
    // Calculated field
    var volume: Double {
        // Volume = π × (girth/2π)² × length
        // Simplified: Volume = (girth²/4π) × length
        let radius = girth / (2 * Double.pi)
        return Double.pi * radius * radius * length
    }
    
    // Optional metadata
    let notes: String?
    let sessionId: String? // Link to practice session if applicable
    let measurementUnit: MeasurementUnit // User's preference at time of entry
    
    // Timestamps
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: String? = nil,
        userId: String,
        timestamp: Date = Date(),
        length: Double,
        girth: Double,
        erectionQuality: Int,
        notes: String? = nil,
        sessionId: String? = nil,
        measurementUnit: MeasurementUnit = .imperial
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.length = length
        self.girth = girth
        self.erectionQuality = min(max(erectionQuality, 1), 10) // Clamp between 1-10
        self.notes = notes
        self.sessionId = sessionId
        self.measurementUnit = measurementUnit
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Computed properties for display
    func displayLength(in unit: MeasurementUnit) -> Double {
        switch unit {
        case .imperial:
            return length
        case .metric:
            return length * 2.54 // inches to cm
        }
    }
    
    func displayGirth(in unit: MeasurementUnit) -> Double {
        switch unit {
        case .imperial:
            return girth
        case .metric:
            return girth * 2.54 // inches to cm
        }
    }
    
    func displayVolume(in unit: MeasurementUnit) -> Double {
        switch unit {
        case .imperial:
            return volume // cubic inches
        case .metric:
            return volume * 16.387 // cubic inches to cubic cm
        }
    }
}

/// Unit system for measurements
enum MeasurementUnit: String, Codable, CaseIterable {
    case imperial = "imperial"
    case metric = "metric"
    
    var lengthSymbol: String {
        switch self {
        case .imperial: return "in"
        case .metric: return "cm"
        }
    }
    
    var volumeSymbol: String {
        switch self {
        case .imperial: return "in³"
        case .metric: return "cm³"
        }
    }
    
    var displayName: String {
        switch self {
        case .imperial: return "inch"
        case .metric: return "cm"
        }
    }
}

/// Statistics for gains tracking
struct GainsStatistics: Codable {
    let baseline: GainsEntry?
    let latest: GainsEntry?
    let best: GainsEntry?
    
    // Averages over different periods
    let weekAverage: GainsAverages?
    let monthAverage: GainsAverages?
    let allTimeAverage: GainsAverages?
    
    // Gains from baseline
    var lengthGain: Double? {
        guard let baseline = baseline, let latest = latest else { return nil }
        return latest.length - baseline.length
    }
    
    var girthGain: Double? {
        guard let baseline = baseline, let latest = latest else { return nil }
        return latest.girth - baseline.girth
    }
    
    var volumeGain: Double? {
        guard let baseline = baseline, let latest = latest else { return nil }
        return latest.volume - baseline.volume
    }
    
    var erectionQualityGain: Int? {
        guard let baseline = baseline, let latest = latest else { return nil }
        return latest.erectionQuality - baseline.erectionQuality
    }
    
    // Percentage gains
    var lengthGainPercentage: Double? {
        guard let baseline = baseline, baseline.length > 0, let gain = lengthGain else { return nil }
        return (gain / baseline.length) * 100
    }
    
    var girthGainPercentage: Double? {
        guard let baseline = baseline, baseline.girth > 0, let gain = girthGain else { return nil }
        return (gain / baseline.girth) * 100
    }
    
    var volumeGainPercentage: Double? {
        guard let baseline = baseline, baseline.volume > 0, let gain = volumeGain else { return nil }
        return (gain / baseline.volume) * 100
    }
}

/// Average measurements over a period
struct GainsAverages: Codable {
    let length: Double
    let girth: Double
    let volume: Double
    let erectionQuality: Double
    let entryCount: Int
    let periodDays: Int
}

// MARK: - Default Values
extension GainsEntry {
    /// Default baseline measurements (average male)
    static let defaultBaseline = GainsEntry(
        userId: "",
        timestamp: Date(),
        length: 5.0, // 5 inches
        girth: 4.0,  // 4 inches
        erectionQuality: 7,
        notes: "Baseline measurement",
        measurementUnit: .imperial
    )
    
    /// Create a sample entry for previews
    static func sample(
        length: Double = 5.5,
        girth: Double = 4.25,
        erectionQuality: Int = 8
    ) -> GainsEntry {
        GainsEntry(
            userId: "sample",
            timestamp: Date(),
            length: length,
            girth: girth,
            erectionQuality: erectionQuality,
            measurementUnit: .imperial
        )
    }
}