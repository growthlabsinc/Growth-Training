import SwiftUI
import FirebaseAuth

struct CreateUsernameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    @State private var displayName = ""
    @State private var isCheckingUsername = false
    @State private var usernameError: String?
    @State private var isValid = false
    @State private var hasAcceptedGuidelines = false
    @State private var showingGuidelines = false
    
    let onComplete: (String, String) -> Void
    
    private let userService = UserService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color("GrowthGreen").opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color("GrowthGreen"))
                        }
                        
                        Text("Create Your Creator Profile")
                            .font(AppTheme.Typography.title2Font())
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Text("Choose a unique username to share routines with the community")
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    VStack(spacing: 20) {
                        // Username input
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Username", systemImage: "at")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            HStack {
                                TextField("username", text: $username)
                                    .font(AppTheme.Typography.bodyFont())
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .onChangeCompat(of: username) { _ in
                                        validateUsername()
                                    }
                                
                                if isCheckingUsername {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if isValid && !username.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("GrowthGreen"))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(usernameError != nil ? Color.red : Color.clear, lineWidth: 1)
                                    )
                            )
                            
                            if let error = usernameError {
                                Text(error)
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(.red)
                            } else {
                                Text("3-20 characters, letters, numbers, and underscores only")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                        
                        // Display name input
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Display Name", systemImage: "person")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            TextField("Your Name", text: $displayName)
                                .font(AppTheme.Typography.bodyFont())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            
                            Text("How your name appears on shared routines")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        // Community guidelines acceptance
                        VStack(spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Toggle("", isOn: $hasAcceptedGuidelines)
                                    .toggleStyle(CheckboxToggleStyle())
                                    .tint(Color("GrowthGreen"))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("I agree to follow the Community Guidelines")
                                        .font(AppTheme.Typography.bodyFont())
                                        .foregroundColor(AppTheme.Colors.text)
                                    
                                    Button("View Guidelines") {
                                        showingGuidelines = true
                                    }
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(Color("GrowthGreen"))
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Create button
                    Button(action: createProfile) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Create Profile")
                        }
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("GrowthGreen"))
                                .opacity(canCreateProfile ? 1 : 0.5)
                        )
                    }
                    .disabled(!canCreateProfile)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGuidelines) {
                CommunityGuidelinesView()
            }
        }
    }
    
    private var canCreateProfile: Bool {
        isValid && 
        !username.isEmpty && 
        !displayName.isEmpty && 
        hasAcceptedGuidelines && 
        !isCheckingUsername
    }
    
    private func validateUsername() {
        // Reset error
        usernameError = nil
        isValid = false
        
        // Check length
        guard username.count >= 3 else {
            if !username.isEmpty {
                usernameError = "Username must be at least 3 characters"
            }
            return
        }
        
        guard username.count <= 20 else {
            usernameError = "Username must be 20 characters or less"
            return
        }
        
        // Check characters
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        guard username.range(of: usernameRegex, options: .regularExpression) != nil else {
            usernameError = "Only letters, numbers, and underscores allowed"
            return
        }
        
        // Check availability
        checkUsernameAvailability()
    }
    
    private func checkUsernameAvailability() {
        isCheckingUsername = true
        
        Task {
            do {
                let isAvailable = try await userService.checkUsernameAvailability(username)
                
                await MainActor.run {
                    isCheckingUsername = false
                    if isAvailable {
                        isValid = true
                        usernameError = nil
                    } else {
                        isValid = false
                        usernameError = "Username is already taken"
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingUsername = false
                    usernameError = "Error checking username"
                }
            }
        }
    }
    
    private func createProfile() {
        guard canCreateProfile else { return }
        
        Task {
            do {
                try await userService.updateUsername(username, displayName: displayName)
                
                await MainActor.run {
                    onComplete(username, displayName)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    usernameError = "Failed to create profile. Please try again."
                }
            }
        }
    }
}

// Custom checkbox style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .font(.system(size: 20))
                .foregroundColor(configuration.isOn ? Color("GrowthGreen") : Color.gray)
        }
    }
}

struct CreateUsernameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateUsernameView { _, _ in }
    }
}