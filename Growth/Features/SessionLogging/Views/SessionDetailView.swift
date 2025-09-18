import SwiftUI
import Foundation  // For Logger

struct SessionDetailView: View {
    @StateObject private var viewModel: SessionDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel

    init(sessionLog: SessionLog, growthMethod: GrowthMethod?) {
        _viewModel = StateObject(wrappedValue: SessionDetailViewModel(sessionLog: sessionLog, growthMethod: growthMethod))
    }

    var body: some View {
        List {
            Section(header: Text("Method Details").font(AppTheme.Typography.headlineFont())) {
                HStack {
                    Text("Method:")
                        .font(AppTheme.Typography.bodyFont())
                    Spacer()
                    Text(viewModel.growthMethod?.title ?? "Unknown Method")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            Section(header: Text("Session Information").font(AppTheme.Typography.headlineFont())) {
                DetailRow(label: "Date:", value: formatDate(viewModel.sessionLog.startTime))
                DetailRow(label: "Time:", value: formatTime(viewModel.sessionLog.startTime))
                DetailRow(label: "Duration:", value: formatMinutes(viewModel.sessionLog.duration))
            }

            if let notes = viewModel.sessionLog.userNotes, !notes.isEmpty {
                Section(header: Text("My Notes").font(AppTheme.Typography.headlineFont())) {
                    Text(notes)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.vertical, AppTheme.Layout.spacingS)
                }
            }

            Section(header: Text("Mood Reflection").font(AppTheme.Typography.headlineFont())) {
                DetailRow(label: "Mood Before:", value: viewModel.sessionLog.moodBefore.displayName)
                DetailRow(label: "Mood After:", value: viewModel.sessionLog.moodAfter.displayName)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(viewModel.growthMethod?.title ?? "Session Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if viewModel.isLoading {
                        SwiftUI.ProgressView()
                    } else {
                        Button {
                            viewModel.showEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .disabled(viewModel.isLoading)

                        Button {
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(AppTheme.Colors.errorColor)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            LogSessionView(
                sessionLogToEdit: viewModel.sessionLog,
                method: viewModel.growthMethod ?? GrowthMethod(id: "unknown", stage: 0, title: "Unknown Method", methodDescription: "", instructionsText: "")
            )
            .environmentObject(authViewModel)
        }
        .alert(isPresented: $viewModel.showDeleteConfirmation) {
            Alert(
                title: Text("Delete Session Log"),
                message: Text("Are you sure you want to delete this session log? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteSession()
                },
                secondaryButton: .cancel()
            )
        }
        .onReceive(viewModel.$errorMessage) { errorMessage in
            if errorMessage != nil {
                Logger.error("Error: \(errorMessage!)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionLogDeleted)) { notification in
            if let deletedLogId = notification.object as? String, deletedLogId == viewModel.sessionLog.id {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionLogUpdated)) { notification in
            if let updatedLog = notification.object as? SessionLog, updatedLog.id == viewModel.sessionLog.id {
                viewModel.sessionLog = updatedLog
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.bodyFont())
            Spacer()
            Text(value)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

#if DEBUG
struct SessionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockLog = SessionLog(
            id: "previewLog1",
            userId: "previewUser",
            duration: 30,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            userNotes: "This was a good session. Felt focused and energized afterwards. I think I am getting the hang of the main exercise.",
            methodId: "previewMethod1",
            sessionIndex: nil,
            moodBefore: .neutral,
            moodAfter: .positive
        )
        
        let mockMethod = GrowthMethod(
            id: "previewMethod1",
            stage: 1,
            title: "Angion Method 1.0",
            methodDescription: "A foundational method for beginners to improve vascular health through specific manual exercises.",
            instructionsText: "1. Preparation: Ensure you're in a comfortable, private setting. Have a towel and lubricant ready.\n2. Warm-up: Perform a 5-minute gentle massage to increase blood flow to the area.\n3. Main Exercise: Apply light to moderate pressure using circular motions along the targeted vessels for 10 minutes. Focus on consistent rhythm and pressure.\n4. Cool Down: Perform gentle stretching for 2-3 minutes to relax the area.",
            visualPlaceholderUrl: nil, // No image for preview
            equipmentNeeded: ["Towel", "Lubricant"],
            estimatedDurationMinutes: 20,
            categories: ["Vascular Health", "Beginner"],
            isFeatured: true,
            progressionCriteriaText: "Complete 15 sessions, maintaining consistency and comfort.",
            createdAt: Date(), 
            updatedAt: Date()
        )

        NavigationView {
            SessionDetailView(sessionLog: mockLog, growthMethod: mockMethod)
        }
        .environmentObject(AuthViewModel()) // If your SessionDetailViewModel or subviews need it
    }
}
#endif 