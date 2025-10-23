//
//  GainsEntry.swift
//  Growth
//
//  Created by Developer on 6/2/25.
//

import Foundation
import FirebaseFirestore

/// Measurement type taxonomy based on Reddit PE community standards
enum MeasurementType: String, Codable, CaseIterable {
    // Primary Length Measurements (Erect)
    case bpel = "bpel" // Bone Pressed Erect Length - Most common
    case nbpel = "nbpel" // Non-Bone Pressed Erect Length

    // Secondary Length Measurements (Flaccid/Stretched)
    case bpfsl = "bpfsl" // Bone Pressed Flaccid Stretched Length
    case nbpfsl = "nbpfsl" // Non-Bone Pressed Flaccid Stretched Length
    case fl = "fl" // Flaccid Length
    case bpfl = "bpfl" // Bone Pressed Flaccid Length

    // Primary Girth Measurements (Erect)
    case mseg = "mseg" // Mid-Shaft Erect Girth - Most common
    case beg = "beg" // Base Erect Girth
    case heg = "heg" // Head Erect Girth (Glans)
    case eg = "eg" // General Erect Girth

    // Secondary Girth Measurements (Flaccid)
    case msfg = "msfg" // Mid-Shaft Flaccid Girth
    case bfg = "bfg" // Base Flaccid Girth
    case fg = "fg" // General Flaccid Girth

    var displayName: String {
        switch self {
        // Length measurements
        case .bpel: return "BPEL"
        case .nbpel: return "NBPEL"
        case .bpfsl: return "BPFSL"
        case .nbpfsl: return "NBPFSL"
        case .fl: return "FL"
        case .bpfl: return "BPFL"
        // Girth measurements
        case .mseg: return "MSEG"
        case .beg: return "BEG"
        case .heg: return "HEG"
        case .eg: return "EG"
        case .msfg: return "MSFG"
        case .bfg: return "BFG"
        case .fg: return "FG"
        }
    }

    var fullName: String {
        switch self {
        // Length measurements
        case .bpel: return "Bone Pressed Erect Length"
        case .nbpel: return "Non-Bone Pressed Erect Length"
        case .bpfsl: return "Bone Pressed Flaccid Stretched Length"
        case .nbpfsl: return "Non-Bone Pressed Flaccid Stretched Length"
        case .fl: return "Flaccid Length"
        case .bpfl: return "Bone Pressed Flaccid Length"
        // Girth measurements
        case .mseg: return "Mid-Shaft Erect Girth"
        case .beg: return "Base Erect Girth"
        case .heg: return "Head Erect Girth"
        case .eg: return "Erect Girth"
        case .msfg: return "Mid-Shaft Flaccid Girth"
        case .bfg: return "Base Flaccid Girth"
        case .fg: return "Flaccid Girth"
        }
    }

    var isLength: Bool {
        switch self {
        case .bpel, .nbpel, .bpfsl, .nbpfsl, .fl, .bpfl:
            return true
        case .mseg, .beg, .heg, .eg, .msfg, .bfg, .fg:
            return false
        }
    }

    var icon: String {
        isLength ? "ruler" : "circle"
    }

    /// Primary measurements recommended for tracking (based on Reddit frequency analysis)
    static var primaryMeasurements: [MeasurementType] {
        [.bpel, .mseg]
    }

    /// Secondary measurements for advanced tracking
    static var secondaryMeasurements: [MeasurementType] {
        [.nbpel, .bpfsl, .beg]
    }

    /// All length measurements
    static var lengthMeasurements: [MeasurementType] {
        allCases.filter { $0.isLength }
    }

    /// All girth measurements
    static var girthMeasurements: [MeasurementType] {
        allCases.filter { !$0.isLength }
    }
}

/// Represents a single gains measurement entry
struct GainsEntry: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userId: String
    let timestamp: Date

    // Measurements - New detailed structure
    var measurements: [MeasurementType: Double] // Stored in inches internally
    let erectionQuality: Int // 1-10 scale

    // Legacy fields for backwards compatibility
    let length: Double? // Deprecated - use measurements[.bpel] instead
    let girth: Double? // Deprecated - use measurements[.mseg] instead
    
    // Calculated field - uses primary measurements (BPEL x MSEG)
    var volume: Double {
        let length = measurements[.bpel] ?? self.length ?? 0
        let girth = measurements[.mseg] ?? self.girth ?? 0

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

    // New initializer with detailed measurements
    init(
        id: String? = nil,
        userId: String,
        timestamp: Date = Date(),
        measurements: [MeasurementType: Double],
        erectionQuality: Int,
        notes: String? = nil,
        sessionId: String? = nil,
        measurementUnit: MeasurementUnit = .imperial
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.measurements = measurements
        self.erectionQuality = min(max(erectionQuality, 1), 10) // Clamp between 1-10
        self.notes = notes
        self.sessionId = sessionId
        self.measurementUnit = measurementUnit
        self.createdAt = Date()
        self.updatedAt = Date()

        // Populate legacy fields for backwards compatibility
        self.length = measurements[.bpel]
        self.girth = measurements[.mseg]
    }

    // Legacy initializer for backwards compatibility
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
        // Convert legacy measurements to new structure
        self.measurements = [
            .bpel: length,
            .mseg: girth
        ]
        self.erectionQuality = min(max(erectionQuality, 1), 10) // Clamp between 1-10
        self.notes = notes
        self.sessionId = sessionId
        self.measurementUnit = measurementUnit
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Display Methods

    /// Get measurement value in preferred unit
    func displayMeasurement(_ type: MeasurementType, in unit: MeasurementUnit) -> Double? {
        guard let valueInches = measurements[type] else { return nil }

        switch unit {
        case .imperial:
            return valueInches
        case .metric:
            return valueInches * 2.54 // inches to cm
        }
    }

    // Computed properties for display (backwards compatible)
    func displayLength(in unit: MeasurementUnit) -> Double {
        let value = measurements[.bpel] ?? length ?? 0
        switch unit {
        case .imperial:
            return value
        case .metric:
            return value * 2.54 // inches to cm
        }
    }

    func displayGirth(in unit: MeasurementUnit) -> Double {
        let value = measurements[.mseg] ?? girth ?? 0
        switch unit {
        case .imperial:
            return value
        case .metric:
            return value * 2.54 // inches to cm
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
    /// Default baseline measurements (average male according to studies)
    static let defaultBaseline = GainsEntry(
        userId: "",
        timestamp: Date(),
        measurements: [
            .bpel: 5.16,  // Average BPEL from studies
            .nbpel: 4.59, // Average NBPEL from studies
            .mseg: 4.59,  // Average girth from studies
            .beg: 4.75,   // Slightly larger at base
        ],
        erectionQuality: 7,
        notes: "Baseline measurement",
        measurementUnit: .imperial
    )

    /// Create a sample entry for previews
    static func sample(
        bpel: Double = 5.5,
        mseg: Double = 4.5,
        erectionQuality: Int = 8
    ) -> GainsEntry {
        GainsEntry(
            userId: "sample",
            timestamp: Date(),
            measurements: [
                .bpel: bpel,
                .nbpel: bpel - 0.5, // NBPEL typically 0.5" less
                .mseg: mseg,
                .bpfsl: bpel - 0.2  // BPFSL typically close to BPEL
            ],
            erectionQuality: erectionQuality,
            measurementUnit: .imperial
        )
    }

    /// Legacy sample for backwards compatibility
    static func legacySample(
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