import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ReportManagementView: View {
    @State private var reports: [Report] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedStatus: ReportStatus = .pending
    @State private var selectedReport: Report?
    @State private var showingActionSheet = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                // Status filter
                Picker("Status", selection: $selectedStatus) {
                    ForEach(ReportStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChangeCompat(of: selectedStatus) { _ in
                    loadReports()
                }
                
                if isLoading {
                    ProgressView("Loading reports...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reports.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("No Reports")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("No reports with status: \(selectedStatus.displayName)")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(reports) { report in
                        ReportRowView(report: report) {
                            selectedReport = report
                            showingActionSheet = true
                        }
                    }
                }
            }
            .navigationTitle("Report Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadReports()
                    }
                }
            }
            .onAppear {
                loadReports()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .confirmationDialog("Take Action", isPresented: $showingActionSheet) {
                if let report = selectedReport {
                    Button("Remove Content") {
                        takeAction(on: report, action: .contentRemoved)
                    }
                    
                    Button("Warn User") {
                        takeAction(on: report, action: .userWarned)
                    }
                    
                    Button("Suspend User") {
                        takeAction(on: report, action: .userSuspended)
                    }
                    
                    Button("Ban User", role: .destructive) {
                        takeAction(on: report, action: .userBanned)
                    }
                    
                    Button("Dismiss Report") {
                        takeAction(on: report, action: .noAction)
                    }
                    
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
    }
    
    private func loadReports() {
        isLoading = true
        
        db.collection("reports")
            .whereField("status", isEqualTo: selectedStatus.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                reports = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Report.self)
                } ?? []
            }
    }
    
    private func takeAction(on report: Report, action: ModeratorAction) {
        guard let reportId = report.id,
              let moderatorId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                // Update report status
                try await db.collection("reports").document(reportId).updateData([
                    "status": ReportStatus.resolved.rawValue,
                    "moderatorId": moderatorId,
                    "moderatorAction": action.rawValue,
                    "resolutionDate": Timestamp(date: Date()),
                    "resolutionNotes": "Action taken: \(action.displayName)"
                ])
                
                // Take action based on the type
                switch action {
                case .contentRemoved:
                    if report.contentType == .routine {
                        try await removeRoutine(report.contentId)
                    }
                    
                case .userBanned:
                    try await banUser(report.creatorId)
                    
                case .userSuspended:
                    try await suspendUser(report.creatorId)
                    
                case .userWarned:
                    try await warnUser(report.creatorId)
                    
                default:
                    break
                }
                
                await MainActor.run {
                    loadReports() // Refresh list
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func removeRoutine(_ routineId: String) async throws {
        // Remove from main collection
        try await db.collection("routines").document(routineId).updateData([
            "shareWithCommunity": false,
            "moderationStatus": "removed",
            "removedDate": Timestamp(date: Date())
        ])
    }
    
    private func banUser(_ userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "isBanned": true,
            "bannedDate": Timestamp(date: Date()),
            "banReason": "Community guidelines violation"
        ])
    }
    
    private func suspendUser(_ userId: String) async throws {
        let suspendedUntil = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        try await db.collection("users").document(userId).updateData([
            "isSuspended": true,
            "suspendedUntil": Timestamp(date: suspendedUntil),
            "suspensionReason": "Community guidelines violation"
        ])
    }
    
    private func warnUser(_ userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "warnings": FieldValue.increment(Int64(1)),
            "lastWarningDate": Timestamp(date: Date())
        ])
    }
}

struct ReportRowView: View {
    let report: Report
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(report.contentType.displayName, systemImage: iconForContentType(report.contentType))
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(report.timeSinceReport)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.secondary)
                }
                
                Text(report.reason.displayName)
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(.primary)
                
                if let details = report.details, !details.isEmpty {
                    Text(details)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("ID: \(report.contentId)")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if report.status == .escalated {
                        Label("Escalated", systemImage: "exclamationmark.triangle.fill")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForContentType(_ type: ContentType) -> String {
        switch type {
        case .routine: return "list.bullet"
        case .user: return "person.circle"
        case .comment: return "bubble.left"
        case .review: return "star"
        }
    }
}

// MARK: - Preview
struct ReportManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ReportManagementView()
    }
}