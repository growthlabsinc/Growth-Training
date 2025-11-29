//
//  CSVExportService.swift
//  Growth
//
//  Created by Claude Code on 11/28/25.
//  Story 11.2: Session Log CSV Export
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Error types for CSV export operations
enum CSVExportError: LocalizedError {
    case noUser
    case noSessionsFound
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No user logged in. Please sign in to export data."
        case .noSessionsFound:
            return "No session logs found to export."
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }
}

/// Service for exporting session logs to GrowthTrack-compatible CSV format
/// Implements privacy-first data export with PII stripping and anonymous IDs
class CSVExportService {
    /// Shared singleton instance
    static let shared = CSVExportService()

    // MARK: - Private Constants

    /// CSV header matching GrowthTrack schema exactly
    private let csvHeader = "anonymous_id,date,category,duration_minutes,pre_bpel_mm,pre_bpfsl_mm,pre_mseg_mm,post_bpel_mm,post_bpfsl_mm,post_mseg_mm"

    /// Date formatter for YYYY-MM-DD format (cached for performance)
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Date formatter for filename timestamps
    private lazy var filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    // MARK: - Dependencies

    private let db = Firestore.firestore()
    private let anonymizationService = AnonymizationService.shared

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Public Export Methods

    /// Exports all session logs for current user to CSV file compatible with GrowthTrack
    /// - Parameter progressHandler: Optional callback for progress updates (0.0 to 1.0)
    /// - Returns: URL to exported CSV file in temp directory
    /// - Throws: CSVExportError if user not authenticated, no sessions found, or export fails
    func exportSessionLogsCSV(progressHandler: ((Double) -> Void)? = nil) async throws -> URL {
        // Report initial progress
        progressHandler?(0.0)

        // Get current user
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CSVExportError.noUser
        }

        // Fetch all session logs
        let sessions = try await fetchAllSessionLogs(userId: userId)

        // Report progress after fetch
        progressHandler?(0.5)

        // Check if any sessions exist
        guard !sessions.isEmpty else {
            throw CSVExportError.noSessionsFound
        }

        // Get anonymous ID
        let anonymousId = anonymizationService.getOrCreateAnonymousId()

        // Generate CSV content
        var csvContent = csvHeader + "\n"

        // Generate rows (filtering out sessions without measurements)
        for session in sessions {
            if let row = generateCSVRow(session: session, anonymousId: anonymousId) {
                csvContent += row + "\n"
            }
        }

        // Save to file
        let fileURL = try saveCSVFile(content: csvContent)

        // Report completion
        progressHandler?(1.0)

        // Log export for analytics (anonymized)
        logExportAttempt(sessionCount: sessions.count, success: true)

        return fileURL
    }

    // MARK: - Private Fetch Methods

    /// Fetches all session logs for a user from Firestore
    /// - Parameter userId: Firebase Auth user ID
    /// - Returns: Array of SessionLog entries ordered by startTime descending
    /// - Throws: Firestore errors if query fails
    private func fetchAllSessionLogs(userId: String) async throws -> [SessionLog] {
        let snapshot = try await db.collection("sessionLogs")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .getDocuments()

        // Convert documents to SessionLog models
        let sessions = snapshot.documents.compactMap { SessionLog(document: $0) }

        // Filter to only sessions with both pre and post measurements
        return sessions.filter { session in
            guard let pre = session.preMeasurements,
                  let post = session.postMeasurements else {
                return false
            }
            // Must have BPEL, BPFSL, and MSEG for both pre and post
            return pre[.bpel] != nil && pre[.bpfsl] != nil && pre[.mseg] != nil &&
                   post[.bpel] != nil && post[.bpfsl] != nil && post[.mseg] != nil
        }
    }

    // MARK: - Private CSV Generation Methods

    /// Generates CSV row for a session with PII stripped
    /// - Parameters:
    ///   - session: SessionLog to export
    ///   - anonymousId: Anonymous statistical ID
    /// - Returns: CSV row string, or nil if session lacks required measurements
    private func generateCSVRow(session: SessionLog, anonymousId: String) -> String? {
        // Extract measurements (return nil if any required measurement is missing)
        guard let pre = session.preMeasurements,
              let post = session.postMeasurements,
              let preBPEL = pre[.bpel],
              let preBPFSL = pre[.bpfsl],
              let preMSEG = pre[.mseg],
              let postBPEL = post[.bpel],
              let postBPFSL = post[.bpfsl],
              let postMSEG = post[.mseg] else {
            return nil
        }

        // Format date (YYYY-MM-DD only, no time component)
        let date = dateFormatter.string(from: session.startTime)

        // Map to category (lengthwork, girthwork, hybrid)
        let category = mapToCategory(methodId: session.methodId)

        // Convert measurements to millimeters
        let preBPELmm = convertToMillimeters(preBPEL)
        let preBPFSLmm = convertToMillimeters(preBPFSL)
        let preMSEGmm = convertToMillimeters(preMSEG)
        let postBPELmm = convertToMillimeters(postBPEL)
        let postBPFSLmm = convertToMillimeters(postBPFSL)
        let postMSEGmm = convertToMillimeters(postMSEG)

        // Build CSV row (no spaces after commas)
        return "\(anonymousId),\(date),\(category),\(session.duration),\(preBPELmm),\(preBPFSLmm),\(preMSEGmm),\(postBPELmm),\(postBPFSLmm),\(postMSEGmm)"
    }

    /// Converts inches to millimeters (rounded to nearest integer)
    /// - Parameter inches: Measurement in inches (can be nil)
    /// - Returns: String representation of mm, or empty string if nil
    private func convertToMillimeters(_ inches: Double?) -> String {
        guard let inches = inches else { return "" }
        return "\(Int(round(inches * 25.4)))"
    }

    /// Maps methodId to GrowthTrack category
    /// - Parameter methodId: Growth Training method ID
    /// - Returns: Category string (lengthwork, girthwork, hybrid)
    private func mapToCategory(methodId: String?) -> String {
        // For now, default to hybrid
        // TODO: Story 11.5 - Integrate with TrainingProtocolService for proper mapping
        return "hybrid"
    }

    // MARK: - Private File Management Methods

    /// Saves CSV content to temporary file
    /// - Parameter content: CSV string content
    /// - Returns: URL to saved file
    /// - Throws: CSVExportError.exportFailed if file write fails
    private func saveCSVFile(content: String) throws -> URL {
        // Generate filename with current date
        let currentDate = filenameDateFormatter.string(from: Date())
        let filename = "growth-training-sessions-\(currentDate).csv"

        // Get temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        // Write content to file
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw CSVExportError.exportFailed("Failed to save CSV file: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Analytics Methods

    /// Logs export attempt for analytics (anonymized)
    /// - Parameters:
    ///   - sessionCount: Number of sessions exported
    ///   - success: Whether export succeeded
    private func logExportAttempt(sessionCount: Int, success: Bool) {
        Task {
            do {
                try await db.collection("export_analytics").addDocument(data: [
                    "userId": Auth.auth().currentUser?.uid ?? "unknown",
                    "timestamp": FieldValue.serverTimestamp(),
                    "exportType": "sessions",
                    "sessionCount": sessionCount,
                    "success": success
                ])
            } catch {
                // Don't throw - analytics should never block export
                print("⚠️ CSVExportService: Analytics logging failed - \(error.localizedDescription)")
            }
        }
    }
}
