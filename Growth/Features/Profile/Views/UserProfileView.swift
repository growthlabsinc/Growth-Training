import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    let user: User
    
    @StateObject private var viewModel = UserProfileViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var showingBlockConfirmation = false
    @State private var isBlocked = false
    @State private var selectedRoutine: Routine?
    @State private var showingRoutineDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                profileHeader
                
                // Stats section
                statsSection
                
                // Bio section
                if let bio = viewModel.bio, !bio.isEmpty {
                    bioSection(bio)
                }
                
                // Shared routines
                sharedRoutinesSection
                
                // Action buttons
                if user.id != Auth.auth().currentUser?.uid {
                    actionButtons
                }
            }
            .padding()
        }
        .navigationTitle("Creator Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.loadUserProfile(user)
            checkBlockStatus()
        }
        .confirmationDialog(
            "Block @\(user.username ?? "user")?",
            isPresented: $showingBlockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                blockUser()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't see their routines anymore. You can unblock them anytime from Settings.")
        }
        .sheet(item: $selectedRoutine) { routine in
            NavigationView {
                CommunityRoutineDetailView(routine: routine)
            }
        }
    }
    
    // MARK: - View Components
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color("GrowthGreen"), Color("GrowthGreen").opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Text((user.displayName ?? user.firstName ?? "U").prefix(1).uppercased())
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Name and username
            VStack(spacing: 4) {
                Text(user.displayName ?? user.firstName ?? "User")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(AppTheme.Colors.text)
                
                HStack(spacing: 4) {
                    Text("@\(user.username ?? "unknown")")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    if viewModel.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
            }
            
            // Member since
            if let joinDate = viewModel.joinDate {
                Label(
                    "Member since \(joinDate.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: "calendar"
                )
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatView(
                value: "\(viewModel.sharedRoutinesCount)",
                label: "Routines",
                icon: "list.bullet"
            )
            
            Divider()
                .frame(height: 40)
            
            StatView(
                value: viewModel.totalDownloads.abbreviated,
                label: "Downloads",
                icon: "arrow.down.circle"
            )
            
            Divider()
                .frame(height: 40)
            
            StatView(
                value: String(format: "%.1f", viewModel.averageRating),
                label: "Avg Rating",
                icon: "star.fill"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About", systemImage: "person.fill")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(bio)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var sharedRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Shared Routines")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                if viewModel.sharedRoutines.count > 3 {
                    Button("See All") {
                        // Navigate to full list
                    }
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("GrowthGreen"))
                }
            }
            
            if viewModel.isLoadingRoutines {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if viewModel.sharedRoutines.isEmpty {
                Text("No shared routines yet")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            } else {
                ForEach(viewModel.sharedRoutines.prefix(3)) { routine in
                    RoutineCard(routine: routine) {
                        selectedRoutine = routine
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Follow button (future feature)
            Button(action: {}) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Follow")
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
            .disabled(true) // Coming soon
            
            // Block button
            Button(action: { showingBlockConfirmation = true }) {
                HStack {
                    Image(systemName: isBlocked ? "person.badge.minus.fill" : "person.badge.minus")
                    Text(isBlocked ? "Unblock" : "Block")
                }
                .font(AppTheme.Typography.gravitySemibold(16))
                .foregroundColor(isBlocked ? .white : .red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isBlocked ? Color.red : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkBlockStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let blocked = await viewModel.checkIfUserBlocked(
                userId: user.id,
                by: currentUserId
            )
            await MainActor.run {
                isBlocked = blocked
            }
        }
    }
    
    private func blockUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let success = await viewModel.toggleBlockUser(
                userId: user.id,
                blockerId: currentUserId,
                shouldBlock: !isBlocked
            )
            
            if success {
                await MainActor.run {
                    isBlocked.toggle()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatView: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color("GrowthGreen"))
            
            Text(value)
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(AppTheme.Colors.text)
            
            Text(label)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RoutineCard: View {
    let routine: Routine
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(routine.name)
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(AppTheme.Colors.text)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Label("\(routine.duration) days", systemImage: "calendar")
                        Label(routine.difficulty.rawValue.capitalized, systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    if let rating = routine.rating, rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", rating))
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Text("(\(routine.ratingCount))")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
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
}

// MARK: - Extension

extension Int {
    var abbreviated: String {
        if self >= 1_000_000 {
            return String(format: "%.1fM", Double(self) / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.1fK", Double(self) / 1_000)
        } else {
            return "\(self)"
        }
    }
}

// MARK: - Preview

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserProfileView(user: User(
                id: "123",
                firstName: "John",
                creationDate: Date(),
                lastLogin: Date(),
                settings: UserSettings(
                    notificationsEnabled: false,
                    reminderTime: nil,
                    privacyLevel: .medium
                ),
                username: "johndoe",
                displayName: "John Doe"
            ))
        }
    }
}