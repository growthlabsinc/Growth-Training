//
//  BiometricSettingsView.swift
//  Growth
//
//  View for managing biometric authentication settings
//

import SwiftUI
import LocalAuthentication
import FirebaseAuth

struct BiometricSettingsView: View {
    @StateObject private var biometricService = BiometricAuthService.shared
    @State private var showDisableConfirmation = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false
    @State private var showCredentialPrompt = false
    @State private var email = ""
    @State private var password = ""
    
    private let keychainService = KeychainService.shared
    
    var body: some View {
        Form {
            // Biometric Status Section
            Section {
                HStack {
                    Image(systemName: biometricService.biometryIcon)
                        .font(.system(size: 40))
                        .foregroundColor(Color("GrowthGreen"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(biometricService.biometryName)
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(Color("TextColor"))
                        
                        Text(biometricService.canUseBiometrics() ? "Available" : "Not Available")
                            .font(AppTheme.Typography.gravityBook(13))
                            .foregroundColor(biometricService.canUseBiometrics() ? .green : Color("TextSecondaryColor"))
                    }
                    .padding(.leading, 12)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Settings Section
            if biometricService.canUseBiometrics() {
                Section(header: Text("Login").font(AppTheme.Typography.gravitySemibold(13)),
                        footer: loginFooterText) {
                    Toggle(isOn: $biometricService.biometricLoginEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Use \(biometricService.biometryName) to Login")
                                    .font(AppTheme.Typography.gravityBook(15))
                                
                                Text("Sign in quickly without entering your password")
                                    .font(AppTheme.Typography.gravityBook(12))
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                        }
                    }
                    .onChangeCompat(of: biometricService.biometricLoginEnabled) { newValue in
                        handleBiometricLoginToggle(newValue: newValue)
                    }
                    
                    // Show stored credentials status
                    if biometricService.biometricLoginEnabled {
                        HStack {
                            Image(systemName: keychainService.retrieveCredentials() != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(keychainService.retrieveCredentials() != nil ? .green : .red)
                            
                            Text(keychainService.retrieveCredentials() != nil ? "Credentials saved" : "No credentials saved")
                                .font(AppTheme.Typography.gravityBook(14))
                                .foregroundColor(Color("TextSecondaryColor"))
                        }
                    }
                }
                
                Section(header: Text("App Security").font(AppTheme.Typography.gravitySemibold(13)),
                        footer: appSecurityFooterText) {
                    Toggle(isOn: $biometricService.requireBiometricOnLaunch) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.app.dashed")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Require \(biometricService.biometryName) to Open App")
                                    .font(AppTheme.Typography.gravityBook(15))
                                
                                Text("Add an extra layer of security")
                                    .font(AppTheme.Typography.gravityBook(12))
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                        }
                    }
                    .onChangeCompat(of: biometricService.requireBiometricOnLaunch) { newValue in
                        handleAppLockToggle(newValue: newValue)
                    }
                }
                
                // Clear Credentials Section
                if biometricService.biometricLoginEnabled && keychainService.retrieveCredentials() != nil {
                    Section {
                        Button(action: {
                            showDisableConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Clear Saved Credentials")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            } else {
                // Biometrics not available
                Section(footer: Text("Biometric authentication is not available on this device or has not been set up. Please configure \(biometricService.biometryName) in Settings app.")) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.yellow)
                        Text("\(biometricService.biometryName) Not Available")
                            .font(AppTheme.Typography.gravityBook(15))
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Error message
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(AppTheme.Typography.gravityBook(13))
                }
            }
        }
        .navigationTitle("Face ID & Passcode")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear Credentials", isPresented: $showDisableConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCredentials()
            }
        } message: {
            Text("This will remove your saved login credentials. You'll need to enter your email and password next time you sign in.")
        }
        .sheet(isPresented: $showCredentialPrompt) {
            SaveCredentialsView(
                email: $email,
                password: $password,
                onSave: handleCredentialsSave,
                onCancel: {
                    showCredentialPrompt = false
                    email = ""
                    password = ""
                }
            )
        }
        .onAppear {
            Task {
                // Small delay to avoid SwiftUI publishing issues
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                biometricService.checkBiometryAvailability()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var loginFooterText: some View {
        Group {
            if biometricService.biometricLoginEnabled && keychainService.retrieveCredentials() == nil {
                Text("Enable 'Remember me' when you sign in to save your credentials for \(biometricService.biometryName) login.")
                    .font(AppTheme.Typography.gravityBook(12))
            } else if biometricService.biometricLoginEnabled {
                Text("Your credentials are securely stored and can only be accessed with \(biometricService.biometryName).")
                    .font(AppTheme.Typography.gravityBook(12))
            } else {
                Text("When enabled, you can sign in using \(biometricService.biometryName) instead of entering your password.")
                    .font(AppTheme.Typography.gravityBook(12))
            }
        }
    }
    
    private var appSecurityFooterText: some View {
        Text("When enabled, you'll need to authenticate with \(biometricService.biometryName) every time you open the app.")
            .font(AppTheme.Typography.gravityBook(12))
    }
    
    // MARK: - Helper Methods
    
    private func handleBiometricLoginToggle(newValue: Bool) {
        if newValue {
            // Enabling biometric login
            Task {
                // First check if we have saved credentials
                if keychainService.retrieveCredentials() == nil {
                    // No credentials saved - need to prompt for them
                    // Pre-fill email if user is logged in
                    if let currentUser = Auth.auth().currentUser {
                        email = currentUser.email ?? ""
                    }
                    showCredentialPrompt = true
                    // Temporarily disable until credentials are saved
                    biometricService.biometricLoginEnabled = false
                } else {
                    // Credentials exist - just authenticate to enable
                    let authenticated = await authenticateUser(reason: "Authenticate to enable \(biometricService.biometryName) login")
                    if !authenticated {
                        // Revert the toggle if authentication failed
                        biometricService.biometricLoginEnabled = false
                    }
                }
            }
        } else {
            // Disabling - show confirmation
            showDisableConfirmation = true
        }
    }
    
    private func handleAppLockToggle(newValue: Bool) {
        if newValue {
            // Enabling app lock
            Task {
                let authenticated = await authenticateUser(reason: "Authenticate to require \(biometricService.biometryName) for app access")
                if !authenticated {
                    // Revert the toggle if authentication failed
                    biometricService.requireBiometricOnLaunch = false
                }
            }
        }
    }
    
    private func authenticateUser(reason: String) async -> Bool {
        errorMessage = ""
        return await biometricService.authenticate(reason: reason)
    }
    
    private func clearCredentials() {
        keychainService.removeCredentials()
        biometricService.biometricLoginEnabled = false
        errorMessage = ""
    }
    
    private func handleCredentialsSave() {
        // Validate credentials
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }
        
        // Save credentials
        if keychainService.storeCredentials(email: email, password: password) {
            // Success - enable biometric login
            biometricService.biometricLoginEnabled = true
            showCredentialPrompt = false
            email = ""
            password = ""
            errorMessage = ""
        } else {
            errorMessage = "Failed to save credentials"
        }
    }
}

// MARK: - Save Credentials View

struct SaveCredentialsView: View {
    @Binding var email: String
    @Binding var password: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: BiometricAuthService.shared.biometryIcon)
                        .font(.system(size: 50))
                        .foregroundColor(Color("GrowthGreen"))
                    
                    Text("Save Login Credentials")
                        .font(AppTheme.Typography.gravitySemibold(24))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Enter your login credentials to enable \(BiometricAuthService.shared.biometryName) sign in")
                        .font(AppTheme.Typography.gravityBook(15))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)
                
                // Form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(Color("TextColor"))
                        
                        TextField("your@email.com", text: $email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(Color("TextColor"))
                        
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(AppTheme.Typography.gravityBook(13))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Security note
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextSecondaryColor"))
                    Text("Your credentials will be securely stored in the iOS Keychain")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        Text("Save Credentials")
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("GrowthGreen"))
                            .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    
                    Button(action: {
                        onCancel()
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(AppTheme.Typography.gravityBook(16))
                            .foregroundColor(Color("TextColor"))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    NavigationStack {
        BiometricSettingsView()
    }
}