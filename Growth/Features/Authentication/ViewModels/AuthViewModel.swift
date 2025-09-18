import Foundation
import Combine
import Firebase
import FirebaseAuth
import UIKit
import AuthenticationServices
import CryptoKit

/// View model for handling authentication operations and state
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Services
    
    /// Authentication service
    private let authService: AuthServiceProtocol
    
    // MARK: - Published Properties
    
    /// Email entered by the user
    @Published var email: String = ""
    
    /// Password entered by the user
    @Published var password: String = ""
    
    /// Password confirmation entered by the user
    @Published var passwordConfirmation: String = ""
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Authentication error message
    @Published var errorMessage: String = ""
    
    /// Email validation error
    @Published var emailError: String = ""
    
    /// Password validation error
    @Published var passwordError: String = ""
    
    /// Password confirmation validation error
    @Published var passwordConfirmationError: String = ""
    
    /// User authentication state
    @Published var isAuthenticated: Bool = false
    
    /// User model (when authenticated)
    @Published var user: AuthUser?
    
    /// Password reset success state
    @Published var passwordResetSent: Bool = false
    
    /// Password reset specific error message
    @Published var passwordResetError: String = ""
    
    /// Whether the disclaimer needs to be shown
    @Published var needsDisclaimer: Bool = false
    
    /// Whether to remember the user for future logins
    @Published var rememberMe: Bool = false
    
    /// Whether biometric authentication is available
    @Published var biometricsAvailable: Bool = false
    
    /// The type of biometric authentication available
    @Published var biometryType: String = ""
    
    // MARK: - Private Properties
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Biometric authentication service
    private let biometricService = BiometricAuthService.shared
    
    /// Keychain service for secure storage
    private let keychainService = KeychainService.shared
    
    // MARK: - Initialization
    
    /// Initialize the view model with the auth service
    /// - Parameter authService: The authentication service to use
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
        
        // Ensure Firebase is configured before subscribing to auth state
        guard FirebaseApp.app() != nil else {
            Logger.error("⚠️ AuthViewModel: Firebase not yet configured, deferring setup")
            // Defer the setup slightly to allow Firebase to initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.setupAuthSubscription()
            }
            return
        }
        
        setupAuthSubscription()
    }
    
    private func setupAuthSubscription() {
        // Subscribe to auth state changes
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                self.user = user
                self.isAuthenticated = user != nil
                self.checkDisclaimerState(for: user)
            }
            .store(in: &cancellables)
        
        // Check biometric availability after a small delay to avoid SwiftUI publishing issues
        Task { @MainActor in
            // Small delay to ensure we're not in a view update cycle
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            updateBiometricAvailability()
        }
    }
    
    // MARK: - Validation
    
    /// Validate the email format
    /// - Returns: True if the email is valid
    func validateEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValid = emailPredicate.evaluate(with: email)
        
        emailError = isValid ? "" : "Please enter a valid email address"
        
        return isValid
    }
    
    /// Validate the password strength
    /// - Returns: True if the password is valid
    func validatePassword() -> Bool {
        guard password.count >= 8 else {
            passwordError = "Password should be at least 8 characters"
            return false
        }
        
        let hasLetters = password.rangeOfCharacter(from: .letters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        guard hasLetters && hasNumbers else {
            passwordError = "Password should include letters and numbers"
            return false
        }
        
        passwordError = ""
        return true
    }
    
    /// Validate that password and confirmation match
    /// - Returns: True if the passwords match
    func validatePasswordsMatch() -> Bool {
        let doMatch = password == passwordConfirmation
        
        passwordConfirmationError = doMatch ? "" : "Passwords do not match"
        
        return doMatch
    }
    
    /// Validate all fields for account creation
    /// - Returns: True if all validations pass
    func validateCreateAccountFields() -> Bool {
        let isEmailValid = validateEmail()
        let isPasswordValid = validatePassword()
        let doPasswordsMatch = validatePasswordsMatch()
        
        return isEmailValid && isPasswordValid && doPasswordsMatch
    }
    
    /// Validate required fields for sign in
    /// - Returns: True if all validations pass
    func validateSignInFields() -> Bool {
        // Less strict validation for sign in
        let isEmailValid = !email.isEmpty
        let isPasswordValid = !password.isEmpty
        
        emailError = isEmailValid ? "" : "Please enter your email"
        passwordError = isPasswordValid ? "" : "Please enter your password"
        
        return isEmailValid && isPasswordValid
    }
    
    // MARK: - Auth Operations
    
    /// Create a new user account
    func createAccount(firstName: String? = nil, username: String? = nil, displayName: String? = nil) {
        // Clear any previous errors
        errorMessage = ""
        
        // Validate all fields
        guard validateCreateAccountFields() else {
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Call auth service
        authService.createUser(email: email, password: password, firstName: firstName, username: username, displayName: displayName) { [weak self] result in
            guard let self = self else { return }
            
            // Always stop loading
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    // Account created successfully
                    self.user = user
                    self.checkDisclaimerState(for: user)
                    
                case .failure(let error):
                    // Handle Firebase Auth errors
                    let nsError = error as NSError
                    
                    // Extract error code directly from NSError
                    if let authError = AuthErrorCode(rawValue: nsError.code) {
                        // Update error message based on error code
                        switch authError {
                        case .emailAlreadyInUse:
                            self.errorMessage = "An account with this email already exists"
                        case .weakPassword:
                            self.errorMessage = "Please use a stronger password"
                        case .networkError:
                            self.errorMessage = "Unable to connect to server. Please check your internet connection"
                        default:
                            self.errorMessage = "Failed to create account: \(error.localizedDescription)"
                        }
                    } else {
                        self.errorMessage = "Failed to create account: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    /// Sign in with email and password
    func signIn() {
        // Clear any previous errors
        errorMessage = ""
        
        // Validate required fields
        guard validateSignInFields() else {
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Call auth service
        authService.signIn(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            // Always stop loading
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    // Sign in successful
                    self.user = user
                    self.checkDisclaimerState(for: user)
                    
                    // Store credentials if remember me is enabled
                    if self.rememberMe {
                        _ = self.keychainService.storeCredentials(email: self.email, password: self.password)
                        // Enable biometric login if biometrics are available
                        if self.biometricsAvailable {
                            self.biometricService.biometricLoginEnabled = true
                        }
                    }
                    
                case .failure(let error):
                    // Handle Firebase Auth errors
                    let nsError = error as NSError
                    
                    // Extract error code directly from NSError
                    if let authError = AuthErrorCode(rawValue: nsError.code) {
                        // Update error message based on error code
                        switch authError {
                        case .wrongPassword:
                            self.errorMessage = "Incorrect password"
                        case .userNotFound:
                            self.errorMessage = "Account not found. Please check your email or create a new account"
                        case .userDisabled:
                            self.errorMessage = "This account has been disabled"
                        case .networkError:
                            self.errorMessage = "Unable to connect to server. Please check your internet connection"
                        default:
                            self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                        }
                    } else {
                        self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    /// Sign in with biometric authentication
    @MainActor
    func signInWithBiometrics() async {
        // Clear any previous errors
        errorMessage = ""
        
        // Check if we have stored credentials
        guard let credentials = keychainService.retrieveCredentials() else {
            errorMessage = "No saved credentials found. Please sign in with your email and password first."
            return
        }
        
        // Authenticate with biometrics
        let authenticated = await biometricService.authenticateForLogin()
        
        if authenticated {
            // Set loading state
            isLoading = true
            
            // Use stored credentials to sign in
            email = credentials.email
            password = credentials.password
            
            // Call auth service
            authService.signIn(email: credentials.email, password: credentials.password) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let user):
                        // Sign in successful
                        self.user = user
                        self.checkDisclaimerState(for: user)
                        // Clear password from view model for security
                        self.password = ""
                        
                    case .failure(let error):
                        // Handle errors
                        self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                        // Clear stored credentials if sign in fails
                        self.keychainService.removeCredentials()
                        self.biometricService.biometricLoginEnabled = false
                    }
                }
            }
        } else {
            // Biometric authentication failed or was cancelled
            errorMessage = "Biometric authentication failed or was cancelled"
        }
    }
    
    /// Update biometric availability status
    func updateBiometricAvailability() {
        biometricService.checkBiometryAvailability()
        biometricsAvailable = biometricService.canUseBiometrics()
        biometryType = biometricService.biometryName
    }
    
    /// Sign out the current user
    func signOut() {
        isLoading = true
        
        authService.signOut { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                }
                
                // Clear keychain data
                self.keychainService.removeAll()
                
                // Even if there's an error, we clear the user data from the view model
                self.clearUserData()
            }
        }
    }
    
    /// Clear all user input and error messages
    func clearUserData() {
        email = ""
        password = ""
        passwordConfirmation = ""
        errorMessage = ""
        emailError = ""
        passwordError = ""
        passwordConfirmationError = ""
    }
    
    /// Send password reset email
    func sendPasswordReset() {
        // Clear any previous messages
        passwordResetError = ""
        passwordResetSent = false
        
        // Validate email
        guard validateEmail() else {
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Call auth service
        authService.sendPasswordReset(email: email) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    // Handle Firebase Auth errors
                    let nsError = error as NSError
                    
                    if let authError = AuthErrorCode(rawValue: nsError.code) {
                        switch authError {
                        case .userNotFound:
                            self.passwordResetError = "No account found with this email address"
                        case .invalidEmail:
                            self.passwordResetError = "Please enter a valid email address"
                        case .networkError:
                            self.passwordResetError = "Unable to connect to server. Please check your internet connection"
                        default:
                            self.passwordResetError = "Failed to send password reset email: \(error.localizedDescription)"
                        }
                    } else {
                        self.passwordResetError = "Failed to send password reset email: \(error.localizedDescription)"
                    }
                } else {
                    // Password reset email sent successfully
                    self.passwordResetSent = true
                }
            }
        }
    }
    
    /// Clear password reset state
    func clearPasswordResetState() {
        passwordResetSent = false
        passwordResetError = ""
    }
    
    // After successful login or account creation, check disclaimer state
    private func checkDisclaimerState(for user: AuthUser?) {
        // This is no longer used - onboarding state is checked in MainView via OnboardingViewModel
        needsDisclaimer = false
    }
    
    /// Delete all user data (and optionally Firebase auth account)
    func deleteUserData(deleteAccount: Bool) {
        guard let uid = user?.id else {
            self.errorMessage = "User not authenticated"
            return
        }
        isLoading = true
        UserDataDeletionService.shared.deleteAllUserData(userId: uid, deleteAuthAccount: deleteAccount) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Deletion failed: \(error.localizedDescription)"
                } else {
                    // Clear local user state regardless
                    self?.clearUserData()
                    self?.user = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    /// Sign in with Google
    func signInWithGoogle() {
        // Clear any previous errors
        errorMessage = ""
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find root view controller"
            return
        }
        
        // Find the topmost view controller
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        // Set loading state
        isLoading = true
        
        // Call auth service
        authService.signInWithGoogle(presentingViewController: topViewController) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    // Sign in successful
                    self.user = user
                    self.checkDisclaimerState(for: user)
                    
                case .failure(let error):
                    // Handle errors
                    self.errorMessage = "Google sign-in failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In
    
    /// Current nonce for Apple Sign-In
    private var currentNonce: String?
    
    /// Generate a random nonce for Apple Sign-In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    /// Generate SHA256 hash of the nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    /// Start Apple Sign-In flow
    func startSignInWithAppleFlow() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        return request
    }
    
    /// Handle Apple Sign-In completion
    func signInWithApple(authorization: ASAuthorization) {
        // Clear any previous errors
        errorMessage = ""
        
        guard let nonce = currentNonce else {
            errorMessage = "Invalid state: A login callback was received, but no login request was sent."
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Call auth service
        authService.signInWithApple(authorization: authorization, nonce: nonce) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.currentNonce = nil
                
                switch result {
                case .success(let user):
                    // Sign in successful
                    self.user = user
                    self.checkDisclaimerState(for: user)
                    
                case .failure(let error):
                    // Handle errors
                    self.errorMessage = "Apple sign-in failed: \(error.localizedDescription)"
                }
            }
        }
    }
} 