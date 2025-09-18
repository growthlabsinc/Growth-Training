import SwiftUI
import AuthenticationServices

struct CreateAccountView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var username = ""
    @State private var usernameAvailable: Bool? = nil
    @State private var isCheckingUsername = false
    @State private var usernameError = ""
    @State private var agreedToTerms = false
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false
    @State private var isSecurePassword = true
    @State private var isSecurePasswordConfirmation = true
    
    @Binding var showCreateAccount: Bool?
    
    private let usernameDebouncer = Debouncer(delay: 0.5)
    
    init(showCreateAccount: Binding<Bool?> = .constant(nil)) {
        self._showCreateAccount = showCreateAccount
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                socialSignInSection
                dividerSection
                emailFormSection
                createAccountButton
                loginLink
            }
            .padding(.horizontal, 24)
        }
        .background(Color("GrowthBackgroundLight").ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
        .sheet(isPresented: $showTermsOfService) {
            NavigationStack {
                LegalDocumentView(documentId: "terms_of_use")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showTermsOfService = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                LegalDocumentView(documentId: "privacy_policy")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showPrivacyPolicy = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CREATE ACCOUNT")
                .font(AppTheme.Typography.footnoteFont())
                .foregroundColor(.gray)
                .padding(.top, 16)
            
            Text("Join Growth")
                .font(AppTheme.Typography.title1Font())
                .fontWeight(.bold)
            
            Text("Create your account to get started")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.gray)
                .padding(.bottom, 10)
        }
    }
    
    private var socialSignInSection: some View {
        VStack(spacing: 16) {
            googleSignInButton
            appleSignInButton
            
            if !viewModel.errorMessage.isEmpty && viewModel.email.isEmpty && viewModel.password.isEmpty {
                Text(viewModel.errorMessage)
                    .font(AppTheme.Typography.footnoteFont())
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private var googleSignInButton: some View {
        Button(action: { viewModel.signInWithGoogle() }) {
            HStack {
                Image("GoogleLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                
                Text("Sign up with Google")
                    .font(.system(size: 16))
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(26)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var appleSignInButton: some View {
        AppleSignInButton(
            .signUp,
            onRequest: { request in
                let nonceRequest = viewModel.startSignInWithAppleFlow()
                request.requestedScopes = nonceRequest.requestedScopes
                request.nonce = nonceRequest.nonce
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    viewModel.signInWithApple(authorization: authorization)
                case .failure(let error):
                    viewModel.errorMessage = "Apple sign-in failed: \(error.localizedDescription)"
                }
            }
        )
    }
    
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3))
            
            Text("OR")
                .font(AppTheme.Typography.footnoteFont())
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3))
        }
        .padding(.vertical, 8)
    }
    
    private var emailFormSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Sign up with email")
                .font(AppTheme.Typography.subheadlineFont())
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            usernameField
            emailField
            passwordField
            passwordConfirmationField
            termsCheckbox
        }
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .font(AppTheme.Typography.subheadlineFont())
                .fontWeight(.medium)
            
            HStack {
                TextField("Choose a unique username", text: $username)
                    .font(AppTheme.Typography.bodyFont())
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .onChangeCompat(of: username) { newValue in
                        validateUsername(newValue)
                    }
                
                if isCheckingUsername {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let available = usernameAvailable {
                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(available ? .green : .red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(!usernameError.isEmpty ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            if !usernameError.isEmpty {
                Text(usernameError)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.red)
            } else if username.isEmpty {
                Text("This will be your unique identifier for community features")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(AppTheme.Typography.subheadlineFont())
                .fontWeight(.medium)
            
            TextField("Enter your email address", text: $viewModel.email)
                .font(AppTheme.Typography.bodyFont())
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(!viewModel.emailError.isEmpty ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChangeCompat(of: viewModel.email) { _ in
                    if !viewModel.email.isEmpty {
                        _ = viewModel.validateEmail()
                    }
                }
            
            if !viewModel.emailError.isEmpty {
                Text(viewModel.emailError)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.red)
            }
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Password")
                    .font(AppTheme.Typography.subheadlineFont())
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: { isSecurePassword.toggle() }) {
                    Image(systemName: isSecurePassword ? "eye.slash" : "eye")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.gray)
                }
            }
            
            passwordTextFieldView(
                text: $viewModel.password,
                isSecure: isSecurePassword,
                placeholder: "Create a password",
                hasError: !viewModel.passwordError.isEmpty
            )
            
            if !viewModel.passwordError.isEmpty {
                Text(viewModel.passwordError)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.red)
            } else {
                passwordRequirementsView
            }
        }
    }
    
    private var passwordConfirmationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Confirm Password")
                    .font(AppTheme.Typography.subheadlineFont())
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: { isSecurePasswordConfirmation.toggle() }) {
                    Image(systemName: isSecurePasswordConfirmation ? "eye.slash" : "eye")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.gray)
                }
            }
            
            passwordTextFieldView(
                text: $viewModel.passwordConfirmation,
                isSecure: isSecurePasswordConfirmation,
                placeholder: "Confirm your password",
                hasError: !viewModel.passwordConfirmationError.isEmpty
            )
            
            if !viewModel.passwordConfirmationError.isEmpty {
                Text(viewModel.passwordConfirmationError)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder
    private func passwordTextFieldView(text: Binding<String>, isSecure: Bool, placeholder: String, hasError: Bool) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .font(AppTheme.Typography.bodyFont())
        .textContentType(.newPassword)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hasError ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .autocorrectionDisabled(true)
        .autocapitalization(.none)
    }
    
    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Password must contain:")
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(.gray)
            Group {
                passwordRequirementRow(text: "At least 8 characters", isMet: viewModel.password.count >= 8)
                passwordRequirementRow(text: "One uppercase letter", isMet: viewModel.password.contains(where: { $0.isUppercase }))
                passwordRequirementRow(text: "One lowercase letter", isMet: viewModel.password.contains(where: { $0.isLowercase }))
                passwordRequirementRow(text: "One number", isMet: viewModel.password.contains(where: { $0.isNumber }))
                passwordRequirementRow(text: "One special character", isMet: viewModel.password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }))
            }
        }
    }
    
    private func passwordRequirementRow(text: String, isMet: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isMet ? .green : .gray)
            Text(text)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(isMet ? .green : .gray)
        }
    }
    
    private var termsCheckbox: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { agreedToTerms.toggle() }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreedToTerms ? Color("GrowthGreen") : .gray)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("I agree to the ")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.gray)
                + Text("Terms of Service")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("GrowthGreen"))
                    .underline()
                + Text(" and ")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.gray)
                + Text("Privacy Policy")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("GrowthGreen"))
                    .underline()
            }
            .onTapGesture { showTermsOfService = true }
        }
    }
    
    private var createAccountButton: some View {
        Button(action: createAccount) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("GrowthGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                Text("Create Account")
                    .font(AppTheme.Typography.calloutFont())
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("GrowthGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .disabled(viewModel.isLoading)
    }
    
    private var loginLink: some View {
        HStack {
            Text("Already have an account?")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(.gray)
            
            Button("Sign In") {
                if showCreateAccount != nil {
                    showCreateAccount = false
                } else {
                    dismiss()
                }
            }
            .font(AppTheme.Typography.bodyFont())
            .fontWeight(.semibold)
            .foregroundColor(Color(AppColors.coreGreen))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 10)
    }
    
    private var backButton: some View {
        Button(action: {
            if showCreateAccount != nil {
                showCreateAccount = false
            } else {
                dismiss()
            }
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(Color.gray)
        }
    }
    
    // MARK: - Actions
    
    private func createAccount() {
        // Clear any previous errors
        viewModel.errorMessage = ""
        viewModel.emailError = ""
        viewModel.passwordError = ""
        viewModel.passwordConfirmationError = ""
        usernameError = ""
        
        // Validate all fields
        guard !username.isEmpty else {
            usernameError = "Username is required"
            return
        }
        
        guard usernameAvailable == true else {
            usernameError = "Username is not available"
            return
        }
        
        guard viewModel.validateEmail() else { return }
        guard viewModel.validatePassword() else { return }
        guard viewModel.validatePasswordsMatch() else { return }
        
        if !agreedToTerms {
            viewModel.errorMessage = "You must agree to the Terms of Service and Privacy Policy"
            return
        }
        
        // All validations passed, create account
        viewModel.createAccount(firstName: nil, username: username, displayName: username)
    }
    
    // MARK: - Username Validation
    
    private func validateUsername(_ username: String) {
        usernameError = ""
        usernameAvailable = nil
        
        guard !username.isEmpty else { return }
        
        // Validate format
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        
        if !usernamePredicate.evaluate(with: username) {
            usernameError = "Username must be 3-20 characters, letters, numbers, and underscores only"
            return
        }
        
        // Check availability with debouncing
        usernameDebouncer.debounce {
            Task {
                await checkUsernameAvailability(username)
            }
        }
    }
    
    private func checkUsernameAvailability(_ username: String) async {
        await MainActor.run {
            isCheckingUsername = true
        }
        
        do {
            let available = try await UserService.shared.checkUsernameAvailability(username)
            await MainActor.run {
                isCheckingUsername = false
                usernameAvailable = available
                if !available {
                    usernameError = "Username is already taken"
                }
            }
        } catch {
            await MainActor.run {
                isCheckingUsername = false
                usernameError = "Error checking username availability"
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateAccountView()
    }
} 