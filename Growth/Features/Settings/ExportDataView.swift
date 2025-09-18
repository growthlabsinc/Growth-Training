//
//  ExportDataView.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PDFKit
import UniformTypeIdentifiers

struct ExportDataView: View {
    @State private var selectedDataTypes: Set<DataType> = Set(DataType.allCases)
    @State private var exportFormat: ExportFormat = .json
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var exportProgress: Double = 0
    
    enum DataType: String, CaseIterable {
        case gains = "Growth Measurements"
        case sessions = "Practice Sessions"
        case routines = "Routines"
        case goals = "Goals"
        case notes = "Notes & Reflections"
        
        var icon: String {
            switch self {
            case .gains: return "ruler"
            case .sessions: return "clock"
            case .routines: return "list.bullet"
            case .goals: return "target"
            case .notes: return "note.text"
            }
        }
    }
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case pdf = "PDF"
        
        var fileExtension: String {
            return rawValue.lowercased()
        }
    }
    
    var body: some View {
        Form {
            // Data Selection Section
            Section(header: Text("Select Data to Export").font(AppTheme.Typography.gravitySemibold(13))) {
                ForEach(DataType.allCases, id: \.self) { dataType in
                    HStack {
                        Image(systemName: dataType.icon)
                            .foregroundColor(Color("GrowthGreen"))
                            .frame(width: 25)
                        
                        Text(dataType.rawValue)
                            .font(AppTheme.Typography.gravityBook(14))
                        
                        Spacer()
                        
                        if selectedDataTypes.contains(dataType) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("GrowthGreen"))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(Color("NeutralGray"))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedDataTypes.contains(dataType) {
                            selectedDataTypes.remove(dataType)
                        } else {
                            selectedDataTypes.insert(dataType)
                        }
                    }
                }
                
                Button(action: {
                    if selectedDataTypes.count == DataType.allCases.count {
                        selectedDataTypes.removeAll()
                    } else {
                        selectedDataTypes = Set(DataType.allCases)
                    }
                }) {
                    Text(selectedDataTypes.count == DataType.allCases.count ? "Deselect All" : "Select All")
                        .font(AppTheme.Typography.gravitySemibold(13))
                        .foregroundColor(Color("GrowthGreen"))
                }
            }
            
            // Export Format Section
            Section(header: Text("Export Format").font(AppTheme.Typography.gravitySemibold(13))) {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                formatDescriptionView
            }
            
            // Privacy Notice Section
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(AppTheme.Typography.title2Font())
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Privacy Matters")
                            .font(AppTheme.Typography.gravitySemibold(14))
                        Text("Exported data is stored locally on your device and only shared when you choose to")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Export Button Section
            Section {
                Button(action: startExport) {
                    if isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Exporting... \(Int(exportProgress * 100))%")
                                .font(AppTheme.Typography.gravitySemibold(16))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                                .font(AppTheme.Typography.gravitySemibold(16))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .foregroundColor(selectedDataTypes.isEmpty || isExporting ? Color("TextSecondaryColor") : Color("GrowthGreen"))
                .disabled(selectedDataTypes.isEmpty || isExporting)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var formatDescriptionView: some View {
        switch exportFormat {
        case .json:
            Text("Complete data structure, ideal for backups and technical analysis")
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
        case .csv:
            Text("Spreadsheet format, perfect for data analysis in Excel or Google Sheets")
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
        case .pdf:
            Text("Formatted report with charts and summaries, great for sharing or printing")
                .font(AppTheme.Typography.gravityBook(12))
                .foregroundColor(Color("TextSecondaryColor"))
        }
    }
    
    private func startExport() {
        isExporting = true
        exportProgress = 0
        
        Task {
            do {
                let exportData = try await createExportData()
                let fileName = "growth_export_\(formatDate(Date())).\(exportFormat.fileExtension)"
                let url = try await saveExportData(exportData, fileName: fileName)
                
                await MainActor.run {
                    exportedFileURL = url
                    isExporting = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func createExportData() async throws -> Any {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ExportError.noUser
        }
        
        var exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "userId": userId,
            "exportVersion": "1.0"
        ]
        
        // Update progress
        await updateProgress(0.1)
        
        // Fetch data based on selected types
        if selectedDataTypes.contains(.gains) {
            let gains = try await fetchGainsData(userId: userId)
            exportData["gains"] = gains
            await updateProgress(0.3)
        }
        
        if selectedDataTypes.contains(.sessions) {
            let sessions = try await fetchSessionsData(userId: userId)
            exportData["sessions"] = sessions
            await updateProgress(0.5)
        }
        
        if selectedDataTypes.contains(.routines) {
            let routines = try await fetchRoutinesData(userId: userId)
            exportData["routines"] = routines
            await updateProgress(0.7)
        }
        
        if selectedDataTypes.contains(.goals) {
            let goals = try await fetchGoalsData(userId: userId)
            exportData["goals"] = goals
            await updateProgress(0.8)
        }
        
        if selectedDataTypes.contains(.notes) {
            let notes = try await extractNotesFromAllData(userId: userId)
            exportData["notes"] = notes
            await updateProgress(0.9)
        }
        
        await updateProgress(1.0)
        return exportData
    }
    
    private func saveExportData(_ data: Any, fileName: String) async throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        switch exportFormat {
        case .json:
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: fileURL)
            
        case .csv:
            let csvString = try createCSVFromData(data as? [String: Any] ?? [:])
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
        case .pdf:
            let pdfData = try await createPDFFromData(data as? [String: Any] ?? [:])
            try pdfData.write(to: fileURL)
        }
        
        return fileURL
    }
    
    // MARK: - Data Fetching Methods
    
    private func fetchGainsData(userId: String) async throws -> [[String: Any]] {
        // Get entries from the last year
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        
        let entries = try await GainsService.shared.getEntries(userId: userId, from: startDate, to: endDate)
        
        return entries.map { entry in
            [
                "date": ISO8601DateFormatter().string(from: entry.timestamp),
                "length": entry.length,
                "girth": entry.girth,
                "erectionQuality": entry.erectionQuality,
                "volume": entry.volume,
                "measurementUnit": entry.measurementUnit.rawValue,
                "notes": entry.notes ?? ""
            ]
        }
    }
    
    private func fetchSessionsData(userId: String) async throws -> [[String: Any]] {
        return try await withCheckedThrowingContinuation { continuation in
            SessionService.shared.fetchSessionLogs(userId: userId, limit: 1000) { sessions, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let sessionData = sessions.map { session in
                        [
                            "date": ISO8601DateFormatter().string(from: session.startTime),
                            "startTime": ISO8601DateFormatter().string(from: session.startTime),
                            "endTime": ISO8601DateFormatter().string(from: session.endTime),
                            "methodId": session.methodId ?? "",
                            "duration": session.duration,
                            "userNotes": session.userNotes ?? "",
                            "moodBefore": session.moodBefore.rawValue,
                            "moodAfter": session.moodAfter.rawValue,
                            "intensity": session.intensity ?? 0,
                            "variation": session.variation ?? ""
                        ]
                    }
                    continuation.resume(returning: sessionData)
                }
            }
        }
    }
    
    private func fetchRoutinesData(userId: String) async throws -> [[String: Any]] {
        return try await withCheckedThrowingContinuation { continuation in
            let routineService = RoutineService.shared
            routineService.fetchUserCustomRoutines(userId: userId) { result in
                switch result {
                case .success(let routines):
                    let routineData = routines.map { routine in
                        var data: [String: Any] = [:]
                        data["id"] = routine.id
                        data["name"] = routine.name
                        data["description"] = routine.description
                        data["difficulty"] = routine.difficulty.rawValue
                        data["duration"] = routine.duration
                        data["focusAreas"] = routine.focusAreas
                        data["stages"] = routine.stages
                        data["isCustom"] = routine.isCustom ?? false
                        data["createdDate"] = ISO8601DateFormatter().string(from: routine.createdDate)
                        data["lastUpdated"] = ISO8601DateFormatter().string(from: routine.lastUpdated)
                        return data
                    }
                    continuation.resume(returning: routineData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchGoalsData(userId: String) async throws -> [[String: Any]] {
        return try await withCheckedThrowingContinuation { continuation in
            GoalService.shared.fetchGoalsForCurrentUser { goals, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let goalData = goals.map { goal in
                        [
                            "id": goal.id ?? "",
                            "title": goal.title,
                            "description": goal.description,
                            "targetValue": goal.targetValue,
                            "currentValue": goal.currentValue,
                            "valueType": goal.valueType.rawValue,
                            "timeframe": goal.timeframe.rawValue,
                            "associatedMethodIds": goal.associatedMethodIds,
                            "isArchived": goal.isArchived,
                            "deadline": goal.deadline != nil ? ISO8601DateFormatter().string(from: goal.deadline!) : "",
                            "createdAt": ISO8601DateFormatter().string(from: goal.createdAt),
                            "completedAt": goal.completedAt != nil ? ISO8601DateFormatter().string(from: goal.completedAt!) : ""
                        ]
                    }
                    continuation.resume(returning: goalData)
                }
            }
        }
    }
    
    private func extractNotesFromAllData(userId: String) async throws -> [[String: Any]] {
        var allNotes: [[String: Any]] = []
        
        // Get notes from sessions
        let sessions = try await fetchSessionsData(userId: userId)
        for session in sessions {
            if let notes = session["userNotes"] as? String, !notes.isEmpty {
                allNotes.append([
                    "type": "session",
                    "date": session["date"] as? String ?? "",
                    "content": notes,
                    "methodId": session["methodId"] as? String ?? ""
                ])
            }
        }
        
        // Get notes from gains
        let gains = try await fetchGainsData(userId: userId)
        for gain in gains {
            if let notes = gain["notes"] as? String, !notes.isEmpty {
                allNotes.append([
                    "type": "measurement",
                    "date": gain["date"] as? String ?? "",
                    "content": notes,
                    "length": gain["length"] as? Double ?? 0,
                    "girth": gain["girth"] as? Double ?? 0
                ])
            }
        }
        
        return allNotes
    }
    
    // MARK: - Export Format Methods
    
    private func createCSVFromData(_ data: [String: Any]) throws -> String {
        var csv = ""
        
        // Sessions CSV
        if let sessions = data["sessions"] as? [[String: Any]], !sessions.isEmpty {
            csv += "PRACTICE SESSIONS\n"
            csv += "Date,Method ID,Duration (min),Mood Before,Mood After,Intensity,Notes\n"
            for session in sessions {
                let date = formatDateString(session["date"] as? String ?? "")
                let methodId = session["methodId"] as? String ?? ""
                let duration = session["duration"] as? Int ?? 0
                let moodBefore = session["moodBefore"] as? String ?? ""
                let moodAfter = session["moodAfter"] as? String ?? ""
                let intensity = session["intensity"] as? Int ?? 0
                let notes = (session["userNotes"] as? String ?? "").replacingOccurrences(of: ",", with: ";")
                csv += "\(date),\(methodId),\(duration),\(moodBefore),\(moodAfter),\(intensity),\(notes)\n"
            }
            csv += "\n"
        }
        
        // Gains CSV
        if let gains = data["gains"] as? [[String: Any]], !gains.isEmpty {
            csv += "MEASUREMENTS\n"
            csv += "Date,Length,Girth,Erection Quality,Volume,Unit,Notes\n"
            for gain in gains {
                let date = formatDateString(gain["date"] as? String ?? "")
                let length = gain["length"] as? Double ?? 0
                let girth = gain["girth"] as? Double ?? 0
                let eq = gain["erectionQuality"] as? Int ?? 0
                let volume = gain["volume"] as? Double ?? 0
                let unit = gain["measurementUnit"] as? String ?? "imperial"
                let notes = (gain["notes"] as? String ?? "").replacingOccurrences(of: ",", with: ";")
                csv += "\(date),\(length),\(girth),\(eq),\(volume),\(unit),\(notes)\n"
            }
            csv += "\n"
        }
        
        // Goals CSV
        if let goals = data["goals"] as? [[String: Any]], !goals.isEmpty {
            csv += "GOALS\n"
            csv += "Title,Target,Current,Value Type,Timeframe,Archived,Deadline\n"
            for goal in goals {
                let title = goal["title"] as? String ?? ""
                let target = goal["targetValue"] as? Double ?? 0
                let current = goal["currentValue"] as? Double ?? 0
                let valueType = goal["valueType"] as? String ?? ""
                let timeframe = goal["timeframe"] as? String ?? ""
                let isArchived = goal["isArchived"] as? Bool ?? false
                let deadline = formatDateString(goal["deadline"] as? String ?? "")
                csv += "\(title),\(target),\(current),\(valueType),\(timeframe),\(isArchived),\(deadline)\n"
            }
        }
        
        return csv
    }
    
    private func createPDFFromData(_ data: [String: Any]) async throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Growth App",
            kCGPDFContextTitle: "Growth Progress Report",
            kCGPDFContextAuthor: Auth.auth().currentUser?.email ?? "User"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold)
            ]
            let smallAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            
            // Title
            "Growth Progress Report".draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
            
            // Date
            let dateStr = "Generated on \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))"
            dateStr.draw(at: CGPoint(x: 50, y: 90), withAttributes: smallAttributes)
            
            var yPosition: CGFloat = 140
            
            // Summary statistics
            if let sessions = data["sessions"] as? [[String: Any]] {
                let totalSessions = sessions.count
                let totalMinutes = sessions.reduce(0) { sum, session in
                    sum + (session["duration"] as? Int ?? 0)
                }
                
                "Summary".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                yPosition += 30
                
                "Total Sessions: \(totalSessions)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: smallAttributes)
                yPosition += 20
                "Total Practice Time: \(totalMinutes) minutes".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: smallAttributes)
                yPosition += 40
            }
            
            // Recent activity
            if let sessions = data["sessions"] as? [[String: Any]], !sessions.isEmpty {
                "Recent Sessions".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                yPosition += 30
                
                for session in sessions.prefix(5) {
                    let date = formatDateString(session["date"] as? String ?? "")
                    let methodId = session["methodId"] as? String ?? ""
                    let duration = session["duration"] as? Int ?? 0
                    
                    let sessionText = "\(date): Method \(methodId) - \(duration) minutes"
                    sessionText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: smallAttributes)
                    yPosition += 20
                    
                    if yPosition > 700 {
                        context.beginPage()
                        yPosition = 50
                    }
                }
            }
        }
        
        return data
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.exportProgress = progress
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: date)
    }
    
    private func formatDateString(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case noUser
    case dataFetchFailed(String)
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No authenticated user found"
        case .dataFetchFailed(let message):
            return "Failed to fetch data: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

// ShareSheet is defined in HelpArticleDetailView.swift

#Preview {
    NavigationStack {
        ExportDataView()
    }
}