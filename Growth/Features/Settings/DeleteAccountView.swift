//
//  DeleteAccountView.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI
import FirebaseAuth
import Firebase

struct DeleteAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var confirmationText = ""
    @State private var showFinalAlert = false
    @State private var isDeleting = false
    @State private var deletionError: String?
    @State private var showErrorAlert = false
    @State private var navigateToNotifications = false
    @State private var navigateToExport = false
    @State private var navigateToSupport = false
    @State private var showReauthAlert = false
    @State private var password = ""
    
    private let confirmationPhrase = "DELETE MY ACCOUNT"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top)
                
                // Title
                Text("Delete Your Account")
                    .font(AppTheme.Typography.gravitySemibold(24))
                    .foregroundColor(Color("TextColor"))
                
                // Warning Message
                VStack(spacing: 16) {
                    Text("This action is permanent and cannot be undone")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    Text("Deleting your account will:")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextColor"))
                }
                .padding(.horizontal)
                
                // What Will Be Deleted
                VStack(alignment: .leading, spacing: 12) {
                    DeletionItemRow(
                        icon: "ruler",
                        title: "All Measurements",
                        description: "Your entire gains tracking history"
                    )
                    
                    DeletionItemRow(
                        icon: "clock",
                        title: "Session History",
                        description: "All practice logs and progress data"
                    )
                    
                    DeletionItemRow(
                        icon: "list.bullet",
                        title: "Routines & Methods",
                        description: "Custom routines and saved preferences"
                    )
                    
                    DeletionItemRow(
                        icon: "person.crop.circle",
                        title: "Account Information",
                        description: "Profile, settings, and personal data"
                    )
                    
                    DeletionItemRow(
                        icon: "photo",
                        title: "Progress Photos",
                        description: "All uploaded images and media"
                    )
                    
                    DeletionItemRow(
                        icon: "icloud",
                        title: "Cloud Backups",
                        description: "All backup data stored in the cloud"
                    )
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Alternative Options
                VStack(spacing: 16) {
                    Text("Before you go...")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Consider these alternatives:")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    VStack(spacing: 12) {
                        AlternativeOptionCard(
                            icon: "moon.fill",
                            title: "Take a Break",
                            description: "Pause notifications and come back when ready",
                            action: {
                                navigateToNotifications = true
                            }
                        )
                        
                        AlternativeOptionCard(
                            icon: "square.and.arrow.up",
                            title: "Export Your Data",
                            description: "Download all your data before deleting",
                            action: {
                                navigateToExport = true
                            }
                        )
                        
                        AlternativeOptionCard(
                            icon: "envelope.fill",
                            title: "Contact Support",
                            description: "Let us help with any issues you're facing",
                            action: {
                                navigateToSupport = true
                            }
                        )
                    }
                }
                .padding()
                
                
                // Confirmation Section
                VStack(spacing: 16) {
                    Text("To confirm deletion, type:")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    Text(confirmationPhrase)
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                    
                    TextField("Type here to confirm", text: $confirmationText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .padding(.horizontal)
                    
                    Button(action: { showFinalAlert = true }) {
                        if isDeleting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Deleting...")
                                    .font(AppTheme.Typography.gravitySemibold(16))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        } else {
                            Text("Delete My Account")
                                .font(AppTheme.Typography.gravitySemibold(16))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(confirmationText == confirmationPhrase ? Color.red : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(confirmationText != confirmationPhrase || isDeleting)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Cancel Button
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(Color("GrowthGreen"))
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isDeleting)
        .alert("Final Confirmation", isPresented: $showFinalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Forever", role: .destructive) {
                checkAuthenticationAndDelete()
            }
        } message: {
            Text("This is your last chance. Your account and all data will be permanently deleted. This cannot be undone.")
        }
        .alert("Deletion Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(deletionError ?? "An error occurred while deleting your account.")
        }
        .sheet(isPresented: $showReauthAlert) {
            ReauthenticationView(
                password: $password,
                onCancel: {
                    showReauthAlert = false
                    password = ""
                },
                onConfirm: {
                    showReauthAlert = false
                    performReauthentication()
                }
            )
        }
        .navigationDestination(isPresented: $navigateToNotifications) {
            NotificationPreferencesView()
        }
        .navigationDestination(isPresented: $navigateToExport) {
            ExportDataView()
        }
        .navigationDestination(isPresented: $navigateToSupport) {
            ContactSupportView()
        }
    }
    
    private func checkAuthenticationAndDelete() {
        guard Auth.auth().currentUser != nil else {
            deletionError = "No user is currently signed in"
            showErrorAlert = true
            return
        }
        
        // For all users (including social login), proceed with deletion
        // The Firebase Auth SDK will handle reauthentication requirements
        performDeletion()
    }
    
    private func performDeletion() {
        isDeleting = true
        
        guard let userId = Auth.auth().currentUser?.uid else {
            isDeleting = false
            deletionError = "No user is currently signed in"
            showErrorAlert = true
            return
        }
        
        // Delete user data from Firestore and Auth account
        UserDataDeletionService.shared.deleteAllUserData(
            userId: userId,
            deleteAuthAccount: true
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    // Sign out and navigate to login
                    authViewModel.signOut()
                } else {
                    isDeleting = false
                    
                    // Check if reauthentication is required
                    if let error = error as NSError?,
                       error.domain == "UserDataDeletionService",
                       error.code == 1 {
                        // For social login users, show appropriate message
                        if let user = Auth.auth().currentUser,
                           user.providerData.contains(where: { $0.providerID == "google.com" || $0.providerID == "apple.com" }) {
                            let provider = user.providerData.first(where: { $0.providerID == "google.com" }) != nil ? "Google" : "Apple"
                            deletionError = "Your \(provider) session has expired. Please sign out completely from the app, then sign back in with \(provider) and try deleting your account again immediately after signing in."
                            showErrorAlert = true
                        } else {
                            // Show reauthentication alert for email/password users
                            self.showReauthAlert = true
                        }
                    } else {
                        deletionError = error?.localizedDescription ?? "Failed to delete account"
                        showErrorAlert = true
                    }
                }
            }
        }
    }
    
    private func performReauthentication() {
        guard let user = Auth.auth().currentUser else {
            deletionError = "Unable to reauthenticate. Please sign out and sign back in."
            showErrorAlert = true
            return
        }
        
        // Check the sign-in provider
        if user.providerData.contains(where: { $0.providerID == "google.com" }) {
            // Google sign-in user - try deletion directly as they should have recently authenticated
            self.performDeletion()
        } else if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            // Apple sign-in user - try deletion directly as they should have recently authenticated
            self.performDeletion()
        } else if let email = user.email {
            // Email/password user - reauthenticate with password
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            
            user.reauthenticate(with: credential) { _, error in
                if error != nil {
                    self.deletionError = "Incorrect password. Please try again."
                    self.showErrorAlert = true
                } else {
                    // Retry deletion after successful reauthentication
                    self.password = "" // Clear password
                    self.performDeletion()
                }
            }
        } else {
            deletionError = "Unable to verify identity. Please sign out and sign back in."
            showErrorAlert = true
        }
    }
}

// MARK: - Reauthentication View
struct ReauthenticationView: View {
    @Binding var password: String
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @FocusState private var isPasswordFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("GrowthGreen"))
                    .padding(.top, 40)
                
                // Title
                Text("Verify Your Identity")
                    .font(AppTheme.Typography.gravitySemibold(24))
                    .foregroundColor(Color("TextColor"))
                
                // Message
                Text("For security reasons, please enter your password to confirm account deletion.")
                    .font(AppTheme.Typography.gravityBook(16))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isPasswordFocused)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: onConfirm) {
                        Text("Confirm")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(password.isEmpty ? Color.gray : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(password.isEmpty)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .onAppear {
                isPasswordFocused = true
            }
        }
    }
}

// MARK: - Components
struct DeletionItemRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(AppTheme.Typography.title3Font())
                .foregroundColor(.red)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))
                Text(description)
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Spacer()
            
            Image(systemName: "xmark.circle.fill")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(.red.opacity(0.5))
        }
    }
}

struct AlternativeOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(Color("GrowthGreen"))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))
                    Text(description)
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
            .environmentObject(AuthViewModel())
    }
}