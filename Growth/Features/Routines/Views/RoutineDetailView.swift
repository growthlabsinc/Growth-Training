import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation  // For Logger

// Notification for routine updates
extension Notification.Name {
    static let routineDeleted = Notification.Name("routineDeleted")
    static let routineUpdated = Notification.Name("routineUpdated")
}

struct RoutineDetailView: View {
    @StateObject private var viewModel = RoutineDetailViewModel()
    let routineId: String
    @State private var expandedDays: Set<Int> = []
    @State private var methodsCache: [String: GrowthMethod] = [:]
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingShareToggle = false
    @State private var showingEditView = false
    @State private var showingReportAlert = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var selectedReportReason: ReportReason?
    
    private let growthMethodService = GrowthMethodService.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color("GrowthGreen").opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error: error)
            } else if let routine = viewModel.routine {
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        heroSection(routine: routine)
                            .padding(.top, 16)
                        
                        // Weekly Schedule Section
                        weeklyScheduleSection(routine: routine)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Routine Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
            
            // Show menu for custom routines
            if let routine = viewModel.routine, routine.isCustom == true {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if let currentUserId = Auth.auth().currentUser?.uid {
                            if routine.createdBy == currentUserId {
                                // Owner actions
                                Button {
                                    showingEditView = true
                                } label: {
                                    Label("Edit Routine", systemImage: "pencil")
                                }
                                
                                Button {
                                    showingShareToggle.toggle()
                                } label: {
                                    Label(
                                        routine.shareWithCommunity == true ? "Unshare from Community" : "Share with Community",
                                        systemImage: routine.shareWithCommunity == true ? "person.2.slash" : "person.2"
                                    )
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Routine", systemImage: "trash")
                                }
                            } else if routine.shareWithCommunity == true {
                                // Community routine by another user
                                Button {
                                    showingReportAlert = true
                                } label: {
                                    Label("Report Routine", systemImage: "exclamationmark.triangle")
                                }
                                
                                if let creatorId = routine.createdBy {
                                    Button {
                                        blockUser(creatorId)
                                    } label: {
                                        Label("Block User", systemImage: "person.fill.xmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadRoutine(by: routineId)
        }
        .alert("Delete Routine", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRoutine()
            }
        } message: {
            Text("Are you sure you want to delete this routine? This action cannot be undone.")
        }
        .alert("Share with Community", isPresented: $showingShareToggle) {
            Button("Cancel", role: .cancel) { }
            Button("Share") {
                toggleCommunitySharing()
            }
        } message: {
            if viewModel.routine?.shareWithCommunity == true {
                Text("Stop sharing this routine with the community? Other users will no longer be able to see or use this routine.")
            } else {
                Text("Share this routine with the community? Other users will be able to see and use your routine after moderation approval.")
            }
        }
        .alert("Error", isPresented: .constant(deleteError != nil)) {
            Button("OK") {
                deleteError = nil
            }
        } message: {
            Text(deleteError ?? "An error occurred")
        }
        .fullScreenCover(isPresented: $showingEditView) {
            if let routine = viewModel.routine {
                NavigationView {
                    RoutineEditView(routine: routine)
                }
                .onDisappear {
                    // Reload routine to show updated data
                    viewModel.loadRoutine(by: routineId)
                }
            }
        }
        .confirmationDialog("Report Routine", isPresented: $showingReportAlert, titleVisibility: .visible) {
            Button("Inappropriate Content") {
                selectedReportReason = .inappropriate
                reportRoutine()
            }
            
            Button("Spam or Misleading") {
                selectedReportReason = .spam
                reportRoutine()
            }
            
            Button("Copyright Violation") {
                selectedReportReason = .copyright
                reportRoutine()
            }
            
            Button("Harmful or Dangerous") {
                selectedReportReason = .harmful
                reportRoutine()
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please select a reason for reporting this routine")
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading routine...")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppTheme.Typography.gravityBoldFont(48))
                .foregroundColor(Color("ErrorColor"))
            
            Text("Unable to load routine")
                .font(AppTheme.Typography.headlineFont())
                .foregroundColor(.primary)
            
            Text(error)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                viewModel.loadRoutine(by: routineId)
            } label: {
                Text("Try Again")
                    .font(AppTheme.Typography.subheadlineFont())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color("GrowthGreen"))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Hero Section
    
    private func heroSection(routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Gradient background with routine info
            VStack(alignment: .leading, spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GrowthGreen"),
                        Color("BrightTeal")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    VStack(alignment: .leading, spacing: 12) {
                        Text(routine.name)
                            .font(AppTheme.Typography.gravityBoldFont(22))
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.8)
                        
                        Text(routine.description)
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Difficulty Badge
                        HStack {
                            Image(systemName: difficultyIcon(for: routine.difficultyLevel))
                                .font(AppTheme.Typography.captionFont())
                            Text(routine.difficultyLevel)
                                .font(AppTheme.Typography.captionFont())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                        
                        Spacer(minLength: 8)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
                .frame(minHeight: 240)
            }
            .cornerRadius(16)
            .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Weekly Schedule Section
    
    private func weeklyScheduleSection(routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "calendar")
                    .font(AppTheme.Typography.gravityBoldFont(20))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("Weekly Schedule")
                    .font(AppTheme.Typography.gravityBoldFont(22))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(routine.schedule.count) days")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Day Cards
            VStack(spacing: 12) {
                ForEach(routine.schedule.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                    dayCard(day: day, routine: routine, isExpanded: expandedDays.contains(day.dayNumber))
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Day Card
    
    private func dayCard(day: DaySchedule, routine: Routine, isExpanded: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Always visible header section
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    // Day indicator circle
                    ZStack {
                        Circle()
                            .fill(day.isRestDay ? Color("PaleGreen").opacity(0.2) : Color("GrowthGreen").opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Text("\(day.dayNumber)")
                            .font(AppTheme.Typography.gravityBoldFont(20))
                            .foregroundColor(day.isRestDay ? Color.primary : Color("GrowthGreen"))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.dayName)
                            .font(AppTheme.Typography.gravitySemibold(17))
                            .foregroundColor(.primary)
                        
                        if !isExpanded {
                            // Show method count and total duration when collapsed
                            HStack(spacing: 8) {
                                if day.methods.count > 0 {
                                    Text("\(day.methods.count) method\(day.methods.count == 1 ? "" : "s")")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    // Calculate total duration for this day
                                    let totalMinutes = day.methods.reduce(0) { $0 + $1.duration }
                                    Text("\(totalMinutes) min")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(.secondary)
                                } else if day.isRestDay {
                                    Text("Rest Day")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(Color("BrightTeal"))
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Expand/Collapse button
                    Button {
                        withAnimation(.spring()) {
                            if expandedDays.contains(day.dayNumber) {
                                expandedDays.remove(day.dayNumber)
                            } else {
                                expandedDays.insert(day.dayNumber)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.spring(), value: isExpanded)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                }
                .padding(16)
                .padding(.bottom, isExpanded ? 0 : 0)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    if expandedDays.contains(day.dayNumber) {
                        expandedDays.remove(day.dayNumber)
                    } else {
                        expandedDays.insert(day.dayNumber)
                    }
                }
            }
            
            // Expandable Content (appears beneath title)
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Type badge moved to expanded section
                    HStack(spacing: 8) {
                        Label(
                            day.isRestDay ? "Rest Day" : "Training Day",
                            systemImage: day.isRestDay ? "moon.fill" : "figure.strengthtraining.traditional"
                        )
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(day.isRestDay ? Color("BrightTeal") : Color("GrowthGreen"))
                        
                        if let methodCount = day.methodIds?.count, methodCount > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(methodCount) methods")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.secondary)
                        
                        Text(day.description)
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    
                    // Additional Notes
                    if let notes = day.additionalNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Notes")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.secondary)
                            
                            Text(notes)
                                .font(AppTheme.Typography.calloutFont())
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(12)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Scheduled methods when expanded
                    if !day.methods.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scheduled Methods")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 8) {
                                ForEach(day.methods.sorted(by: { $0.order < $1.order })) { methodSchedule in
                                    methodRow(methodSchedule: methodSchedule)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func methodRow(methodSchedule: MethodSchedule) -> some View {
        HStack(spacing: 12) {
            // Method number circle
            ZStack {
                Circle()
                    .fill(Color("GrowthGreen").opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Text("\(methodSchedule.order + 1)")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let method = methodsCache[methodSchedule.methodId] {
                    Text(method.title)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label("\(methodSchedule.duration) min", systemImage: "clock")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Stage \(method.stage)")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Loading...")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.secondary)
                        .onAppear {
                            loadMethod(methodId: methodSchedule.methodId)
                        }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    private func loadMethod(methodId: String) {
        guard methodsCache[methodId] == nil else { return }
        
        growthMethodService.fetchMethod(withId: methodId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let method):
                    self.methodsCache[methodId] = method
                case .failure(let error):
                    Logger.error("Failed to load method \(methodId): \(error)")
                }
            }
        }
    }
    
    private func difficultyIcon(for level: String) -> String {
        switch level.lowercased() {
        case "beginner":
            return "leaf.fill"
        case "intermediate":
            return "flame.fill"
        case "advanced":
            return "bolt.fill"
        default:
            return "star.fill"
        }
    }
    
    // MARK: - Helper Functions
    
    private func deleteRoutine() {
        guard let routine = viewModel.routine else { return }
        
        isDeleting = true
        
        Task {
            do {
                // Get current user
                guard let userId = Auth.auth().currentUser?.uid else {
                    deleteError = "You must be logged in to delete routines"
                    return
                }
                
                // Verify this is the user's routine
                guard routine.createdBy == userId else {
                    deleteError = "You can only delete your own routines"
                    return
                }
                
                // Delete from user's custom routines collection
                try await RoutineService.shared.deleteCustomRoutine(routineId: routine.id, userId: userId)
                
                await MainActor.run {
                    isDeleting = false
                    // Post notification to refresh routines list
                    NotificationCenter.default.post(name: .routineDeleted, object: routine.id)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    deleteError = error.localizedDescription
                }
            }
        }
    }
    
    private func toggleCommunitySharing() {
        guard let routine = viewModel.routine else { return }
        
        Task {
            do {
                // Get current user
                guard let userId = Auth.auth().currentUser?.uid else {
                    deleteError = "You must be logged in to share routines"
                    return
                }
                
                // Verify this is the user's routine
                guard routine.createdBy == userId else {
                    deleteError = "You can only share or unshare your own routines"
                    return
                }
                
                // Get user data for username
                let userDoc = try await Firestore.firestore().collection("users").document(userId).getDocument()
                
                // Get raw data to check what fields exist
                let rawData = userDoc.data()
                Logger.debug("User document data: \(rawData ?? [:])")
                
                // Extract fields directly from raw data instead of trying to decode entire User model
                let username = rawData?["username"] as? String
                let displayName = rawData?["displayName"] as? String
                let firstName = rawData?["firstName"] as? String
                
                if routine.shareWithCommunity != true {
                    // Share with community
                    guard let validUsername = username else {
                        deleteError = "Please set a username in Settings > Account before sharing routines"
                        return
                    }
                    
                    guard let validDisplayName = displayName ?? firstName else {
                        deleteError = "Please set your name in Settings > Account before sharing routines"
                        return
                    }
                    
                    try await RoutineService.shared.shareRoutineWithCommunity(
                        routine,
                        username: validUsername,
                        displayName: validDisplayName
                    )
                } else {
                    // Unshare from community
                    try await RoutineService.shared.unshareRoutineFromCommunity(routine.id)
                }
                
                // Reload routine to get updated state
                await MainActor.run {
                    viewModel.loadRoutine(by: routineId)
                    // Post notification to refresh routines list
                    NotificationCenter.default.post(name: .routineUpdated, object: routine.id)
                }
            } catch {
                await MainActor.run {
                    deleteError = error.localizedDescription
                }
            }
        }
    }
    
    private func reportRoutine() {
        guard let routine = viewModel.routine,
              let reason = selectedReportReason else { return }
        
        Task {
            do {
                try await RoutineService.shared.reportRoutine(
                    routine.id,
                    reason: reason,
                    details: nil
                )
                
                await MainActor.run {
                    deleteError = "Thank you for your report. We'll review it shortly."
                }
            } catch {
                await MainActor.run {
                    deleteError = error.localizedDescription
                }
            }
        }
    }
    
    private func blockUser(_ userId: String) {
        Task {
            do {
                // Get current user
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    deleteError = "You must be logged in to block users"
                    return
                }
                
                // Add to blocked users list
                try await UserService.shared.blockUser(userId: userId, blockedBy: currentUserId)
                
                await MainActor.run {
                    deleteError = "User blocked. You won't see their content anymore."
                    // Refresh the view or navigate away
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    deleteError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview

struct RoutineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RoutineDetailView(routineId: "standard_growth_routine")
        }
    }
} 