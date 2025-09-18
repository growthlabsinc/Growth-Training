//
//  ProfileSetupView.swift
//  Growth
//
//  Created by Developer on 6/7/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation  // For Logger

/// Optional profile setup screen during onboarding
struct ProfileSetupView: View {
    var onNext: () -> Void
    var onBack: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingContent = false
    
    // Profile fields
    @State private var firstName = ""
    @State private var username = ""
    @State private var currentUsername = ""
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool? = nil
    @State private var usernameError = ""
    @State private var reminderTime = Date()
    @State private var enableReminders = false
    @State private var privacyLevel: PrivacyLevel = .medium
    @State private var isSocialSignIn = false
    
    // UI State
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var isSaveButtonPressed = false
    
    // Focus state
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isUsernameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppTheme.Layout.spacingXL) {
                    // Icon
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(Color("GrowthGreen"))
                        .padding(.top, AppTheme.Layout.spacingXL)
                        .scaleEffect(showingContent ? 1.0 : 0.8)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Title
                    Text("Personalize Your Experience")
                        .font(AppTheme.Typography.title1Font())
                        .foregroundColor(AppTheme.Colors.text)
                        .multilineTextAlignment(.center)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Description
                    Text("Add a few details to customize your journey (you can update these anytime)")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, AppTheme.Layout.spacingL)
                        .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Form Fields
                    VStack(spacing: AppTheme.Layout.spacingL) {
                        // First Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name (Optional)")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            TextField("Your first name", text: $firstName)
                                .font(AppTheme.Typography.bodyFont())
                                .foregroundColor(AppTheme.Colors.text)
                                .tint(Color("GrowthGreen"))
                                .autocorrectionDisabled()
                                .textContentType(.givenName)
                                .focused($isNameFieldFocused)
                                .padding(AppTheme.Layout.spacingM)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("BackgroundColor"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isNameFieldFocused ? Color("GrowthGreen") : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Username Field (only for social sign-in users)
                        if isSocialSignIn {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                HStack {
                                    TextField("Choose your username", text: $username)
                                        .font(AppTheme.Typography.bodyFont())
                                        .foregroundColor(AppTheme.Colors.text)
                                        .tint(Color("GrowthGreen"))
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .focused($isUsernameFieldFocused)
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
                                .padding(AppTheme.Layout.spacingM)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("BackgroundColor"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isUsernameFieldFocused ? Color("GrowthGreen") : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                                        )
                                )
                                
                                if !usernameError.isEmpty {
                                    Text(usernameError)
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(.red)
                                } else if username.isEmpty {
                                    Text("You can customize your username now or keep the one we generated")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }
                        
                        // Reminder Settings
                        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                            Text("Daily Reminders")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            // Enable Reminders Toggle
                            Toggle(isOn: $enableReminders) {
                                HStack(spacing: AppTheme.Layout.spacingM) {
                                    Image(systemName: "bell.badge")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color("GrowthGreen"))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Enable Practice Reminders")
                                            .font(AppTheme.Typography.bodyFont())
                                            .foregroundColor(AppTheme.Colors.text)
                                        
                                        Text("Get gentle nudges to maintain your routine")
                                            .font(AppTheme.Typography.captionFont())
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }
                                }
                            }
                            .tint(Color("GrowthGreen"))
                            
                            // Time Picker (shown when reminders are enabled)
                            if enableReminders {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Reminder Time")
                                        .font(AppTheme.Typography.captionFont())
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    
                                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .tint(Color("GrowthGreen"))
                                        .padding(.horizontal, AppTheme.Layout.spacingM)
                                        .padding(.vertical, AppTheme.Layout.spacingS)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color("BackgroundColor"))
                                        )
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                            }
                        }
                        
                        // Privacy Settings
                        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                            Text("Privacy Preference")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            VStack(spacing: 0) {
                                ForEach([PrivacyLevel.high, PrivacyLevel.medium, PrivacyLevel.low], id: \.self) { level in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            privacyLevel = level
                                        }
                                        
                                        if themeManager.hapticFeedback {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(privacyLevelTitle(for: level))
                                                    .font(AppTheme.Typography.bodyFont())
                                                    .foregroundColor(AppTheme.Colors.text)
                                                
                                                Text(privacyLevelDescription(for: level))
                                                    .font(AppTheme.Typography.captionFont())
                                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: privacyLevel == level ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(privacyLevel == level ? Color("GrowthGreen") : Color("GrowthNeutralGray"))
                                        }
                                        .padding(AppTheme.Layout.spacingM)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(privacyLevel == level ? Color("GrowthGreen").opacity(0.1) : Color.clear)
                                        )
                                    }
                                    
                                    if level != PrivacyLevel.low {
                                        Divider()
                                            .padding(.horizontal, AppTheme.Layout.spacingM)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("BackgroundColor"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Layout.spacingL)
                    .opacity(showingContent ? 1.0 : 0.0)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Layout.spacingL)
                    }
                    
                    // Button Stack
                    VStack(spacing: AppTheme.Layout.spacingM) {
                        // Save and Continue Button
                        Button {
                            handleSaveProfile()
                        } label: {
                            HStack {
                                if isUpdating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(firstName.isEmpty && !enableReminders ? "Continue" : "Save & Continue")
                                        .font(AppTheme.Typography.gravitySemibold(17))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, GrowthUITheme.ComponentSize.primaryButtonHeight / 3)
                            .background(
                                RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                                    .fill(Color("GrowthGreen"))
                                    .shadow(
                                        color: Color("GrowthGreen").opacity(0.25),
                                        radius: isSaveButtonPressed ? 2 : AppTheme.Layout.shadowRadius,
                                        x: 0,
                                        y: isSaveButtonPressed ? 1 : 2
                                    )
                            )
                        }
                        .scaleEffect(isSaveButtonPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isSaveButtonPressed)
                        .disabled(isUpdating)
                        
                        // Skip for now
                        Button {
                            handleSkip()
                        } label: {
                            Text("Skip for now")
                                .font(AppTheme.Typography.bodyFont())
                                .foregroundColor(AppTheme.Colors.text)
                                .padding(.vertical, AppTheme.Layout.spacingS)
                        }
                        .opacity(showingContent ? 0.7 : 0.0)
                        .disabled(isUpdating)
                    }
                    .padding(.horizontal, AppTheme.Layout.spacingL)
                    .padding(.top, AppTheme.Layout.spacingL)
                    .opacity(showingContent ? 1.0 : 0.0)
                }
                .padding(.bottom, AppTheme.Layout.spacingXL)
            }
        }
        .background(Color("GrowthBackgroundLight").ignoresSafeArea())
        .onAppear {
            loadExistingProfile()
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showingContent = true
            }
        }
        .onTapGesture {
            isNameFieldFocused = false
            isUsernameFieldFocused = false
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func privacyLevelTitle(for level: PrivacyLevel) -> String {
        switch level {
        case .high:
            return "Maximum Privacy"
        case .medium:
            return "Balanced (Recommended)"
        case .low:
            return "Enhanced Features"
        }
    }
    
    private func privacyLevelDescription(for level: PrivacyLevel) -> String {
        switch level {
        case .high:
            return "Minimal data collection, limited features"
        case .medium:
            return "Standard features with privacy protection"
        case .low:
            return "All features enabled, more data shared"
        }
    }
    
    private func loadExistingProfile() {
        // Load any existing user data
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Check if user signed in with social provider
        if let currentUser = Auth.auth().currentUser {
            // Check provider data
            for userInfo in currentUser.providerData {
                if userInfo.providerID == "google.com" || userInfo.providerID == "apple.com" {
                    isSocialSignIn = true
                    break
                }
            }
        }
        
        UserService.shared.fetchUser(userId: userId) { result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    if let existingName = user.firstName {
                        self.firstName = existingName
                    }
                    
                    // Load username for social sign-in users
                    if self.isSocialSignIn, let existingUsername = user.username {
                        self.username = existingUsername
                        self.currentUsername = existingUsername
                    }
                    
                    self.privacyLevel = user.settings.privacyLevel
                    self.enableReminders = user.settings.notificationsEnabled
                    
                    if let existingReminderTime = user.settings.reminderTime {
                        self.reminderTime = existingReminderTime
                    }
                }
            case .failure:
                // Ignore errors, use defaults
                break
            }
        }
    }
    
    private func handleSaveProfile() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        // Animate button press
        withAnimation(.easeInOut(duration: 0.1)) {
            isSaveButtonPressed = true
        }
        
        // Skip if no changes made
        if firstName.isEmpty && !enableReminders && (username == currentUsername || username.isEmpty) {
            resetButtonAndAdvance()
            return
        }
        
        // Validate username if changed
        if isSocialSignIn && username != currentUsername && !username.isEmpty {
            if usernameAvailable == false || !usernameError.isEmpty {
                errorMessage = "Please choose a valid, available username"
                resetButton()
                return
            }
        }
        
        // Save profile updates
        isUpdating = true
        errorMessage = nil
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            isUpdating = false
            return
        }
        
        // Prepare update data
        var updateData: [String: Any] = [:]
        
        // Update settings as a nested object
        var settingsUpdate: [String: Any] = [
            "privacyLevel": privacyLevel.rawValue,
            "notificationsEnabled": enableReminders
        ]
        
        if enableReminders {
            settingsUpdate["reminderTime"] = Timestamp(date: reminderTime)
        }
        
        updateData["settings"] = settingsUpdate
        
        if !firstName.isEmpty {
            updateData["firstName"] = firstName
        }
        
        // Update username if changed
        if isSocialSignIn && username != currentUsername && !username.isEmpty {
            updateData["username"] = username.lowercased()
        }
        
        // Update user profile
        UserService.shared.updateUserFields(userId: userId, fields: updateData) { error in
            DispatchQueue.main.async {
                self.isUpdating = false
                
                if let error = error {
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.resetButton()
                } else {
                    // Successfully saved profile
                    // Note: Actual reminder scheduling will be handled by the app's notification service
                    self.resetButtonAndAdvance()
                }
            }
        }
    }
    
    private func handleSkip() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        onNext()
    }
    
    private func resetButton() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isSaveButtonPressed = false
        }
    }
    
    private func resetButtonAndAdvance() {
        resetButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.onNext()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView(onNext: {}, onBack: {})
            .preferredColorScheme(.light)
        
        ProfileSetupView(onNext: {}, onBack: {})
            .preferredColorScheme(.dark)
    }
}
#endif