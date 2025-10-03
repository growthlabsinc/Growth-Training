import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CommunityRoutineDetailView: View {
    let routine: Routine
    var routinesViewModel: RoutinesViewModel? = nil
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CommunityRoutineViewModel()
    
    // States
    @State private var showingReportSheet = false
    @State private var showingShareSheet = false
    @State private var showingCreatorProfile = false
    @State private var showingSaveConfirmation = false
    @State private var userRating: Int = 0
    @State private var hasRated = false
    @State private var isSaved = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with routine info
                VStack(alignment: .leading, spacing: 16) {
                    // Routine name and type
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name)
                                .font(AppTheme.Typography.title2Font())
                                .foregroundColor(AppTheme.Colors.text)
                            
                            HStack(spacing: 8) {
                                Label("\(routine.duration) days", systemImage: "calendar")
                                Label(routine.difficulty.rawValue.capitalized, systemImage: "chart.line.uptrend.xyaxis")
                            }
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Share button
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(Color("GrowthGreen"))
                        }
                    }
                    
                    // Description
                    if !routine.description.isEmpty {
                        Text(routine.description)
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                
                // Creator section
                creatorSection
                
                // Rating section
                ratingSection
                
                // Methods section
                methodsSection
                
                // Action buttons
                actionButtons
                
                // Stats section
                statsSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingReportSheet = true }) {
                        Label("Report", systemImage: "exclamationmark.triangle")
                    }
                    
                    if viewModel.currentUserId == routine.createdBy {
                        Button(role: .destructive, action: { viewModel.deleteRoutine() }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppTheme.Colors.text)
                }
            }
        }
        .onAppear {
            viewModel.routinesViewModel = routinesViewModel
            viewModel.loadRoutineDetails(routine)
            checkIfSaved()
            loadUserRating()
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportRoutineView(routine: routine)
        }
        .sheet(isPresented: $showingShareSheet) {
            CommunityShareSheet(items: [createShareURL()])
        }
        .sheet(isPresented: $showingCreatorProfile) {
            if let creator = viewModel.creator {
                NavigationView {
                    UserProfileView(user: creator)
                }
            }
        }
        .alert("Routine Saved!", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("This routine has been added to your saved routines.")
        }
        .alert("Change Routine?", isPresented: .constant(routinesViewModel?.showRoutineChangeConfirmation ?? false)) {
            Button("Cancel", role: .cancel) {
                routinesViewModel?.cancelRoutineChange()
            }
            Button("Change") {
                routinesViewModel?.confirmRoutineChange()
                dismiss()
            }
        } message: {
            if let routineName = routinesViewModel?.pendingRoutineName {
                Text("Are you sure you want to change to \"\(routineName)\"? Your progress on the current routine will be saved.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var creatorSection: some View {
        Button(action: { showingCreatorProfile = true }) {
            HStack(spacing: 12) {
                // Creator avatar
                ZStack {
                    Circle()
                        .fill(Color("GrowthGreen").opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text((viewModel.creator?.displayName ?? "?").prefix(1).uppercased())
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(Color("GrowthGreen"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created by")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    HStack(spacing: 4) {
                        Text("@\(viewModel.creator?.username ?? "unknown")")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(AppTheme.Colors.text)
                        
                        if viewModel.isVerifiedCreator {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color("GrowthGreen"))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var ratingSection: some View {
        VStack(spacing: 16) {
            // Average rating display
            HStack {
                starRatingDisplay
                
                Text(String(format: "%.1f", viewModel.averageRating))
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("(\(viewModel.totalRatings) ratings)")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
            
            // User rating
            if !hasRated {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate this routine")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rateRoutine(star) }) {
                                Image(systemName: star <= userRating ? "star.fill" : "star")
                                    .font(.system(size: 24))
                                    .foregroundColor(star <= userRating ? .yellow : Color.gray.opacity(0.3))
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("GrowthGreen").opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("GrowthGreen").opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private var methodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            methodsHeader
            methodsList
            additionalDaysIndicator
        }
    }
    
    private var methodsHeader: some View {
        Text("Methods")
            .font(AppTheme.Typography.headlineFont())
            .foregroundColor(AppTheme.Colors.text)
    }
    
    private var methodsList: some View {
        ForEach(routine.schedule.prefix(1), id: \.dayNumber) { day in
            ForEach(day.methods, id: \.methodId) { method in
                methodCard(for: method)
            }
        }
    }
    
    private func methodCard(for method: MethodSchedule) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(method.methodId)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(AppTheme.Colors.text)
                
                methodDetailsRow(for: method)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func methodDetailsRow(for method: MethodSchedule) -> some View {
        HStack(spacing: 8) {
            Label("\(method.duration) min", systemImage: "clock")
            Text("Order: \(method.order + 1)")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .font(AppTheme.Typography.captionFont())
        .foregroundColor(AppTheme.Colors.textSecondary)
    }
    
    @ViewBuilder
    private var additionalDaysIndicator: some View {
        if routine.schedule.count > 1 {
            Text("+ \(routine.schedule.count - 1) more days")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Save/Download button
            Button(action: saveRoutine) {
                HStack {
                    Image(systemName: isSaved ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                    Text(isSaved ? "Saved" : "Save Routine")
                }
                .font(AppTheme.Typography.gravitySemibold(16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSaved ? Color.gray : Color("GrowthGreen"))
                )
            }
            .disabled(isSaved)
            
            // Start button
            if isSaved {
                Button(action: startRoutine) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("GrowthGreen"))
                    )
                }
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 24) {
            StatItem(
                icon: "arrow.down.circle",
                value: viewModel.downloadCount.formatted(),
                label: "Downloads"
            )
            
            StatItem(
                icon: "person.2",
                value: viewModel.activeUsers.formatted(),
                label: "Active Users"
            )
            
            StatItem(
                icon: "calendar",
                value: routine.createdDate.formatted(date: .abbreviated, time: .omitted),
                label: "Created"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Helper Methods
    
    private func checkIfSaved() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let saved = await viewModel.checkIfRoutineSaved(routineId: routine.id, userId: userId)
            await MainActor.run {
                isSaved = saved
            }
        }
    }
    
    private func loadUserRating() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let rating = await viewModel.getUserRating(routineId: routine.id, userId: userId)
            await MainActor.run {
                if rating > 0 {
                    userRating = rating
                    hasRated = true
                }
            }
        }
    }
    
    private func rateRoutine(_ rating: Int) {
        userRating = rating
        hasRated = true
        
        Task {
            await viewModel.rateRoutine(routineId: routine.id, rating: rating)
        }
    }
    
    private func saveRoutine() {
        Task {
            let success = await viewModel.saveRoutine(routine)
            if success {
                await MainActor.run {
                    isSaved = true
                    showingSaveConfirmation = true
                }
            }
        }
    }
    
    private func startRoutine() {
        // Show confirmation dialog through the view model
        viewModel.routinesViewModel?.requestRoutineChange(routine.id, routineName: routine.name)
    }
    
    private func createShareURL() -> URL {
        // Create deep link URL for sharing
        URL(string: "growth://routine/\(routine.id)")!
    }
}

// MARK: - Helper Views

extension CommunityRoutineDetailView {
    private var starRatingDisplay: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= Int(viewModel.averageRating) ? "star.fill" : "star")
                    .font(.system(size: 16))
                    .foregroundColor(star <= Int(viewModel.averageRating) ? .yellow : Color.gray.opacity(0.3))
            }
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("GrowthGreen"))
            
            Text(value)
                .font(AppTheme.Typography.gravitySemibold(16))
                .foregroundColor(AppTheme.Colors.text)
            
            Text(label)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CommunityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Report View

struct ReportRoutineView: View {
    let routine: Routine
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Why are you reporting this routine?") {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reason.displayName)
                                    .font(AppTheme.Typography.bodyFont())
                                Text(reason.description)
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if selectedReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("GrowthGreen"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedReason = reason
                        }
                    }
                }
                
                Section("Additional Details (Optional)") {
                    TextEditor(text: $additionalDetails)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Report Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
        }
    }
    
    private func submitReport() {
        guard let reason = selectedReason else { return }
        isSubmitting = true
        
        Task {
            // Submit report through Firebase
            // TODO: Implementation would submit report with reason: \(reason.rawValue)
            // and additional details: \(additionalDetails)
            _ = reason // Suppress unused variable warning
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

struct CommunityRoutineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommunityRoutineDetailView(routine: Routine(
                id: "preview",
                name: "Sample Community Routine",
                description: "A sample routine for preview",
                difficulty: RoutineDifficulty.intermediate,
                duration: 14,
                focusAreas: ["Growth", "Wellness"],
                stages: [1, 2],
                createdDate: Date(),
                lastUpdated: Date(),
                schedule: [],
                isCustom: true,
                createdBy: "user123",
                shareWithCommunity: true,
                creatorUsername: "johndoe",
                creatorDisplayName: "John Doe"
            ))
        }
    }
}