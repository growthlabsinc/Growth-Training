import SwiftUI
import Firebase
import FirebaseFirestore
import Foundation  // For Logger

/// Account settings view
struct AccountView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showLogoutConfirmation = false
    @State private var isEditingFirstName = false
    @State private var isEditingUsername = false
    @State private var firstName: String = ""
    @State private var username: String = ""
    @State private var currentUsername: String = ""
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool? = nil
    @State private var usernameError = ""
    @State private var userData: User?
    @State private var isLoadingUser = false
    @State private var saveError: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section(header: Text("Profile Information")) {
                if let user = authViewModel.user {
                    // First Name row with edit capability
                    HStack {
                        Text("First Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        if isEditingFirstName {
                            TextField("Enter first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 200)
                        } else {
                            Text((userData?.firstName?.isEmpty ?? true) ? "Not set" : (userData?.firstName ?? "Not set"))
                                .foregroundColor(.primary)
                        }
                        Button(action: {
                            if isEditingFirstName {
                                // Save first name
                                saveFirstName()
                            } else {
                                // Initialize firstName with current value when starting to edit
                                firstName = userData?.firstName ?? ""
                                isEditingFirstName = true
                            }
                        }) {
                            Text(isEditingFirstName ? "Save" : "Edit")
                                .foregroundColor(Color("GrowthGreen"))
                        }
                    }
                    
                    // Username row with edit capability
                    HStack {
                        Text("Username")
                            .foregroundColor(.secondary)
                        Spacer()
                        if isEditingUsername {
                            HStack {
                                TextField("Enter username", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 200)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .onChangeCompat(of: username) { newValue in
                                        validateUsername(newValue)
                                    }
                                
                                if isCheckingUsername {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if username != currentUsername && !username.isEmpty {
                                    if let available = usernameAvailable {
                                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(available ? .green : .red)
                                    }
                                }
                            }
                        } else {
                            Text("@\((userData?.username?.isEmpty ?? true) ? "Not set" : (userData?.username ?? "Not set"))")
                                .foregroundColor(.primary)
                        }
                        Button(action: {
                            if isEditingUsername {
                                // Save username
                                saveUsername()
                            } else {
                                // Initialize username with current value when starting to edit
                                username = userData?.username ?? ""
                                currentUsername = userData?.username ?? ""
                                isEditingUsername = true
                            }
                        }) {
                            Text(isEditingUsername ? "Save" : "Edit")
                                .foregroundColor(Color("GrowthGreen"))
                        }
                        .disabled(isEditingUsername && (isCheckingUsername || usernameAvailable == false || !usernameError.isEmpty))
                    }
                    
                    if isEditingUsername && !usernameError.isEmpty {
                        Text(usernameError)
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    infoRow(title: "Email", value: user.email)
                    infoRow(title: "Account Created", value: formatDate(user.createdAt.dateValue()))
                    if user.onboardingCompleted {
                        infoRow(title: "Onboarding", value: "Completed")
                    } else {
                        infoRow(title: "Onboarding", value: "Not Completed")
                    }
                } else {
                    Text("User information not available")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Account Actions")) {
                Button(action: {
                    showLogoutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Text("Log Out")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Account")
        .onAppear {
            loadUserData()
        }
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authViewModel.signOut()
                // Return to main view after logout
                dismiss()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .overlay {
            if authViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 15) {
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Logging out...")
                            .font(AppTheme.Typography.headlineFont())
                            .foregroundColor(.white)
                    }
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.7))
                    )
                }
            }
        }
    }
    
    /// Format a date to a readable string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Create an info row with title and value
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
    
    /// Load user data from Firestore
    private func loadUserData() {
        guard let userId = authViewModel.user?.id else { 
            Logger.debug("AccountView: No user ID available")
            return 
        }
        
        Logger.debug("AccountView: Loading user data for userId: \(userId)")
        isLoadingUser = true
        UserService.shared.fetchUser(userId: userId) { result in
            DispatchQueue.main.async {
                isLoadingUser = false
                switch result {
                case .success(let user):
                    Logger.info("AccountView: Successfully loaded user data")
                    Logger.debug("AccountView: User firstName: \(user.firstName ?? "nil")")
                    Logger.debug("AccountView: User username: \(user.username ?? "nil")")
                    self.userData = user
                    self.firstName = user.firstName ?? ""
                    self.username = user.username ?? ""
                    self.currentUsername = user.username ?? ""
                case .failure(let error):
                    Logger.error("AccountView: Failed to load user data: \(error.localizedDescription)")
                    self.saveError = "Failed to load user data"
                }
            }
        }
    }
    
    /// Save the first name
    private func saveFirstName() {
        guard let userId = authViewModel.user?.id else { 
            Logger.debug("AccountView: No user ID for saving")
            return 
        }
        
        // Trim whitespace from firstName
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.debug("AccountView: Saving firstName '\(trimmedFirstName)' for userId: \(userId)")
        
        UserService.shared.updateFirstName(userId: userId, firstName: trimmedFirstName) { error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.error("AccountView: Error saving firstName: \(error.localizedDescription)")
                    self.saveError = error.localizedDescription
                } else {
                    Logger.info("AccountView: Successfully saved firstName")
                    // Update the userData with the new first name
                    if var updatedUser = self.userData {
                        updatedUser.firstName = trimmedFirstName.isEmpty ? nil : trimmedFirstName
                        self.userData = updatedUser
                    }
                    // Post notification that user data was updated
                    NotificationCenter.default.post(name: Notification.Name("UserDataUpdated"), object: nil)
                    self.isEditingFirstName = false
                    
                    // Force a refresh by reloading the user data
                    self.loadUserData()
                    
                    // Post notification to update other views
                    NotificationCenter.default.post(name: Notification.Name("UserDataUpdated"), object: nil)
                }
            }
        }
    }
    
    // MARK: - Username Methods
    
    private func validateUsername(_ username: String) {
        // Reset state
        usernameError = ""
        usernameAvailable = nil
        
        // Skip if username hasn't changed
        if username == currentUsername {
            return
        }
        
        // Skip if empty
        if username.isEmpty {
            return
        }
        
        // Validate format
        if username.count < 3 {
            usernameError = "Username must be at least 3 characters"
            usernameAvailable = false
            return
        }
        
        if username.count > 20 {
            usernameError = "Username must be 20 characters or less"
            usernameAvailable = false
            return
        }
        
        // Check for valid characters (alphanumeric and underscore only)
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        if !usernamePredicate.evaluate(with: username) {
            usernameError = "Username can only contain letters, numbers, and underscores"
            usernameAvailable = false
            return
        }
        
        // Check availability
        isCheckingUsername = true
        checkUsernameAvailability(username)
    }
    
    private func checkUsernameAvailability(_ username: String) {
        let db = Firestore.firestore()
        
        db.collection("users")
            .whereField("username", isEqualTo: username.lowercased())
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isCheckingUsername = false
                    
                    if let error = error {
                        self.usernameError = "Error checking username availability"
                        self.usernameAvailable = false
                        Logger.error("Error checking username: \(error)")
                    } else {
                        let isAvailable = snapshot?.documents.isEmpty ?? true
                        self.usernameAvailable = isAvailable
                        
                        if !isAvailable {
                            self.usernameError = "Username is already taken"
                        }
                    }
                }
            }
    }
    
    private func saveUsername() {
        guard let userId = authViewModel.user?.id else {
            Logger.debug("AccountView: No user ID for saving username")
            return
        }
        
        // Validate username before saving
        if usernameAvailable == false || !usernameError.isEmpty {
            return
        }
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        Logger.debug("AccountView: Saving username '\(trimmedUsername)' for userId: \(userId)")
        
        UserService.shared.updateUserFields(userId: userId, fields: ["username": trimmedUsername]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.error("AccountView: Error saving username: \(error.localizedDescription)")
                    self.saveError = error.localizedDescription
                } else {
                    Logger.info("AccountView: Successfully saved username")
                    // Update the userData with the new username
                    if var updatedUser = self.userData {
                        updatedUser.username = trimmedUsername
                        self.userData = updatedUser
                    }
                    self.currentUsername = trimmedUsername
                    self.isEditingUsername = false
                    
                    // Force a refresh by reloading the user data
                    self.loadUserData()
                    
                    // Post notification to update other views
                    NotificationCenter.default.post(name: Notification.Name("UserDataUpdated"), object: nil)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AccountView(authViewModel: AuthViewModel())
    }
} 