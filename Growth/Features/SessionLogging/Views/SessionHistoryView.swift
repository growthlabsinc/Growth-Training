import SwiftUI
// Removed FirebaseAuth and FirebaseFirestore imports as they are not directly used in the View if ViewModel handles all logic.
// Ensure ViewModel handles all Firebase interactions.

struct SessionHistoryView: View {
    @StateObject private var viewModel = SessionHistoryViewModel()
    #if DEBUG
    @State private var hasMockData = false
    #endif

    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Session History")
                .toolbar {
                     ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.loadData()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .onAppear {
                    viewModel.loadData()
                    #if DEBUG
                    checkForMockData()
                    #endif
                }
                .onReceive(NotificationCenter.default.publisher(for: .sessionLogDeleted)) { _ in
                    viewModel.loadData() // Refresh data when a log is deleted
                }
                #if DEBUG
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MockDataGenerated"))) { _ in
                    checkForMockData()
                    viewModel.loadData() // Refresh to show new mock data
                }
                #endif
        }
        .accentColor(AppTheme.Colors.primary)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            #if DEBUG
            // Show banner when mock data is active
            if hasMockData {
                mockDataBanner
            }
            #endif

            contentView
        }
    }

    #if DEBUG
    private var mockDataBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Mock data is active")
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            NavigationLink("Manage", destination: DebugMockDataView())
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
    #endif

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage)
        } else if viewModel.sessionLogs.isEmpty {
            emptyStateView
        } else {
            sessionListView
        }
    }

    private var loadingView: some View {
        SwiftUI.ProgressView("Loading History...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack {
            Text("Error")
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(AppTheme.Colors.errorColor)
            Text(message)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.errorColor)
                .multilineTextAlignment(.center)
                .padding()
            Button("Retry") {
                viewModel.loadData()
            }
            .padding()
            .background(AppTheme.Colors.primary)
            .foregroundColor(AppTheme.Colors.textOnPrimary)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack {
            Image(systemName: "list.bullet.clipboard")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.bottom)
            Text("No Sessions Logged Yet")
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(AppTheme.Colors.text)
            Text("Start a new session from the Methods tab to see your progress here.")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionListView: some View {
        List {
            ForEach(viewModel.sessionLogs) { log in
                NavigationLink(
                    destination: SessionDetailView(
                        sessionLog: log,
                        growthProtocol: log.methodId.flatMap { viewModel.growthProtocols[$0] }
                    )
                ) {
                    SessionLogRow(
                        log: log,
                        methodName: viewModel.getProtocolName(protocolId: log.methodId)
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    #if DEBUG
    private func checkForMockData() {
        DebugMockDataService.shared.hasMockData { exists in
            DispatchQueue.main.async {
                hasMockData = exists
            }
        }
    }
    #endif
}

struct SessionLogRow: View {
    let log: SessionLog
    let methodName: String

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(methodName)
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(AppTheme.Colors.text)
                Spacer()
                Text(formatMinutes(log.duration))
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            Text(dateFormatter.string(from: log.startTime))
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            if let notes = log.userNotes, !notes.isEmpty {
                Text(notes)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
    }
}

#if DEBUG
struct SessionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SessionHistoryView()
    }
}
#endif 