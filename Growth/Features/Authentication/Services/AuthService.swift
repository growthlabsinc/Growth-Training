import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine
import GoogleSignIn
import AuthenticationServices
import CryptoKit

// MARK: - Note on FirebaseFirestoreSwift
// This service interacts with the AuthUser model which ideally should use @DocumentID
// property wrapper for the id field. However, this requires the FirebaseFirestoreSwift pod.
// The Podfile has been updated to include this dependency, but installation is required.

/// Protocol for authentication operations
protocol AuthServiceProtocol {
    /// The currently authenticated user
    var currentUser: AuthUser? { get }
    
    /// Publisher for authentication state changes
    var authStatePublisher: AnyPublisher<AuthUser?, Never> { get }
    
    /// Create a new user account with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - firstName: User's first name (optional)
    ///   - username: User's unique username (optional)
    ///   - displayName: User's display name (optional)
    ///   - completion: Completion handler with result
    func createUser(email: String, password: String, firstName: String?, username: String?, displayName: String?, completion: @escaping (Result<AuthUser, Error>) -> Void)
    
    /// Sign in with existing email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - completion: Completion handler with result
    func signIn(email: String, password: String, completion: @escaping (Result<AuthUser, Error>) -> Void)
    
    /// Sign in anonymously for basic app functionality
    /// - Parameter completion: Completion handler with result
    func signInAnonymously(completion: @escaping (Result<AuthUser, Error>) -> Void)
    
    /// Send password reset email
    /// - Parameters:
    ///   - email: User's email address
    ///   - completion: Completion handler with optional error
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void)
    
    /// Sign out the current user
    /// - Parameter completion: Completion handler with optional error
    func signOut(completion: @escaping (Error?) -> Void)
    
    /// Sign in with Google
    /// - Parameters:
    ///   - presentingViewController: The view controller presenting the sign-in flow
    ///   - completion: Completion handler with result
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<AuthUser, Error>) -> Void)
    
    /// Sign in with Apple
    /// - Parameters:
    ///   - authorization: The Apple ID credential authorization
    ///   - nonce: The nonce used for validation
    ///   - completion: Completion handler with result
    func signInWithApple(authorization: ASAuthorization, nonce: String, completion: @escaping (Result<AuthUser, Error>) -> Void)
}

/// Firebase implementation of AuthServiceProtocol
class AuthService: AuthServiceProtocol {
    /// Firestore collection path for user data
    private let usersCollection = "users"
    
    /// Current authenticated user
    private var _currentUser: AuthUser?
    
    /// Subject for publishing authentication state changes
    private let authStateSubject = PassthroughSubject<AuthUser?, Never>()
    
    /// Publisher for authentication state changes
    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        return authStateSubject.eraseToAnyPublisher()
    }
    
    /// The currently authenticated user
    var currentUser: AuthUser? {
        return _currentUser
    }
    
    /// Firebase Auth instance - lazy to ensure Firebase is configured first
    private var auth: Auth {
        return Auth.auth()
    }
    
    /// Firebase Firestore instance - lazy to ensure Firebase is configured first
    private var db: Firestore {
        return Firestore.firestore()
    }
    
    /// Authentication state listener handle
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    /// Initialize the AuthService and set up the authentication state listener
    init() {
        // Ensure Firebase is configured before setting up auth listener
        if FirebaseApp.app() == nil {
            Logger.error("⚠️ AuthService: Firebase not yet configured, deferring auth state listener")
            // Defer the setup slightly to allow Firebase to initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.setupAuthStateListener()
            }
        } else {
            setupAuthStateListener()
        }
    }
    
    /// Set up the Firebase authentication state listener
    private func setupAuthStateListener() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let user = user {
                // Fetch the user document from Firestore
                self.fetchUserDocument(uid: user.uid) { result in
                    switch result {
                    case .success(let userData):
                        self._currentUser = userData
                        self.authStateSubject.send(userData)
                    case .failure(let error):
                        // Only log if it's not a "document doesn't exist" error
                        if !error.localizedDescription.contains("missing") && !error.localizedDescription.contains("No document") {
                            Logger.error("Error fetching user data: \(error.localizedDescription)")
                        }
                        // Create a minimal user object with just the UID and email
                        let minimalUser = AuthUser(id: user.uid, email: user.email ?? "")
                        self._currentUser = minimalUser
                        self.authStateSubject.send(minimalUser)
                    }
                }
            } else {
                // User is signed out
                self._currentUser = nil
                self.authStateSubject.send(nil)
            }
        }
    }
    
    /// Create a new user account with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - firstName: User's first name (optional)
    ///   - completion: Completion handler with result
    func createUser(email: String, password: String, firstName: String?, username: String? = nil, displayName: String? = nil, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authResult = authResult, let email = authResult.user.email else {
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create user account."])))
                return
            }
            
            // Update the user's display name in Firebase Auth with just the first name
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
            changeRequest.commitChanges { error in
                if let error = error {
                    Logger.error("AuthService: Failed to update displayName: \(error.localizedDescription)")
                }
                // Continue with creating user document regardless
                // Always use createUserDocument to handle pending consents
                self.createUserDocument(uid: authResult.user.uid, email: email, firstName: firstName ?? "", username: username, displayName: displayName, completion: completion)
            }
        }
    }
    
    /// Sign in with existing email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - completion: Completion handler with result
    func signIn(email: String, password: String, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authResult = authResult else {
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign in."])))
                return
            }
            
            // Fetch the user document from Firestore
            self.fetchUserDocument(uid: authResult.user.uid) { result in
                // If we successfully fetched user data, update the Firebase Auth display name
                if case .success(_) = result {
                    // Get the firstName from the User model in Firestore
                    self.db.collection(self.usersCollection).document(authResult.user.uid).getDocument { snapshot, error in
                        if let data = snapshot?.data(),
                           let firstName = data["firstName"] as? String,
                           !firstName.isEmpty {
                            // Update Firebase Auth display name to match Firestore firstName
                            let changeRequest = authResult.user.createProfileChangeRequest()
                            changeRequest.displayName = firstName
                            changeRequest.commitChanges { _ in
                                Logger.error("AuthService: Updated displayName to match Firestore firstName")
                            }
                        }
                    }
                }
                completion(result)
            }
        }
    }
    
    /// Sign in anonymously for basic app functionality
    /// - Parameter completion: Completion handler with result
    func signInAnonymously(completion: @escaping (Result<AuthUser, Error>) -> Void) {
        auth.signInAnonymously { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authResult = authResult else {
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign in anonymously."])))
                return
            }
            
            // Create a minimal user object for anonymous users
            let anonymousUser = AuthUser(id: authResult.user.uid, email: "anonymous@local")
            
            // Don't save anonymous users to Firestore, just return the user object
            completion(.success(anonymousUser))
        }
    }
    
    /// Send password reset email
    /// - Parameters:
    ///   - email: User's email address
    ///   - completion: Completion handler with optional error
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        auth.sendPasswordReset(withEmail: email) { error in
            completion(error)
        }
    }
    
    /// Sign out the current user
    /// - Parameter completion: Completion handler with optional error
    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try auth.signOut()
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    /// Save user data to Firestore
    /// - Parameters:
    ///   - user: The user model to save
    ///   - completion: Completion handler with result
    private func saveUserToFirestore(user: AuthUser, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard let uid = user.id else {
            completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID is missing."])))
            return
        }
        
        do {
            try db.collection(usersCollection).document(uid).setData(from: user) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(user))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Fetch user document from Firestore
    /// - Parameters:
    ///   - uid: User ID to fetch
    ///   - completion: Completion handler with result
    private func fetchUserDocument(uid: String, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        db.collection(usersCollection).document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User document not found."])))
                return
            }
            
            do {
                let user = try snapshot.data(as: AuthUser.self)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Update specific fields for a user
    /// - Parameters:
    ///   - fields: Dictionary of fields to update
    ///   - completion: Completion handler with result
    func updateUser(fields: [String: Any], completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard let uid = currentUser?.id else {
            completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user is signed in."])))
            return
        }
        
        // Always update the updatedAt timestamp
        var updateFields = fields
        updateFields["updatedAt"] = Timestamp()
        
        db.collection(usersCollection).document(uid).updateData(updateFields) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Fetch the updated user document
            self.fetchUserDocument(uid: uid, completion: completion)
        }
    }
    
    /// Generate a unique username from email or name
    /// - Parameters:
    ///   - email: User's email address
    ///   - firstName: User's first name (optional)
    ///   - completion: Completion handler with the generated username
    private func generateUniqueUsername(from email: String, firstName: String? = nil, completion: @escaping (String) -> Void) {
        // Start with email prefix or first name
        var baseUsername = ""
        
        if let firstName = firstName, !firstName.isEmpty {
            // Use first name as base, remove spaces and special characters
            baseUsername = firstName.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        } else if !email.isEmpty {
            // Use email prefix as base
            baseUsername = email.components(separatedBy: "@").first ?? "user"
            baseUsername = baseUsername.lowercased()
                .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        }
        
        // Ensure minimum length
        if baseUsername.isEmpty || baseUsername.count < 3 {
            baseUsername = "user"
        }
        
        // Check if username is available
        checkUsernameAvailability(baseUsername) { available in
            if available {
                completion(baseUsername)
            } else {
                // Add random numbers until we find an available username
                self.findAvailableUsername(baseUsername: baseUsername, completion: completion)
            }
        }
    }
    
    /// Find an available username by appending numbers
    private func findAvailableUsername(baseUsername: String, attempt: Int = 1, completion: @escaping (String) -> Void) {
        let candidateUsername = "\(baseUsername)\(Int.random(in: 100...9999))"
        
        checkUsernameAvailability(candidateUsername) { available in
            if available {
                completion(candidateUsername)
            } else if attempt < 10 {
                // Try again with a different number
                self.findAvailableUsername(baseUsername: baseUsername, attempt: attempt + 1, completion: completion)
            } else {
                // Fallback to timestamp-based username
                completion("\(baseUsername)\(Int(Date().timeIntervalSince1970))")
            }
        }
    }
    
    /// Check if a username is available
    private func checkUsernameAvailability(_ username: String, completion: @escaping (Bool) -> Void) {
        db.collection(usersCollection)
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                if let error = error {
                    Logger.error("Error checking username availability: \(error)")
                    completion(false)
                } else {
                    completion(snapshot?.documents.isEmpty ?? true)
                }
            }
    }
    
    /// Create a full user document in Firestore with firstName
    /// - Parameters:
    ///   - uid: User ID
    ///   - email: User's email
    ///   - firstName: User's first name
    ///   - username: User's unique username (optional)
    ///   - displayName: User's display name (optional)
    ///   - completion: Completion handler with result
    private func createUserDocument(uid: String, email: String, firstName: String, username: String? = nil, displayName: String? = nil, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        // Create User model with firstName
        var userData: [String: Any] = [
            "userId": uid,
            "firstName": firstName,
            "creationDate": Timestamp(),
            "lastLogin": Timestamp(),
            "settings": [
                "notificationsEnabled": false,
                "privacyLevel": "medium"
            ],
            "streak": 0,
            "earnedBadges": []
        ]
        
        // Add username and displayName if provided
        if let username = username {
            userData["username"] = username
        }
        if let displayName = displayName {
            userData["displayName"] = displayName
        }
        
        // Add pending consents if any
        let pendingConsents = PendingConsents.shared
        if pendingConsents.disclaimerAccepted {
            userData["disclaimerAccepted"] = true
            userData["disclaimerVersion"] = pendingConsents.disclaimerVersion
            userData["disclaimerAcceptedTimestamp"] = Timestamp(date: pendingConsents.disclaimerAcceptedTimestamp ?? Date())
        }
        
        // Add consent records
        if !pendingConsents.consentRecords.isEmpty {
            userData["consentRecords"] = pendingConsents.consentRecords.map { record in
                var recordData: [String: Any] = [
                    "documentId": record.documentId,
                    "documentVersion": record.documentVersion,
                    "acceptedAt": Timestamp(date: record.acceptedAt)
                ]
                if let ipAddress = record.ipAddress {
                    recordData["ipAddress"] = ipAddress
                }
                return recordData
            }
        }
        
        db.collection(usersCollection).document(uid).setData(userData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Clear pending consents after successful save
                pendingConsents.clear()
                
                // Return AuthUser for consistency
                let authUser = AuthUser(id: uid, email: email)
                completion(.success(authUser))
            }
        }
    }
    
    /// Sign in with Google
    /// - Parameters:
    ///   - presentingViewController: The view controller presenting the sign-in flow
    ///   - completion: Completion handler with result
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase client ID not found."])))
            return
        }
        
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Sign in
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get Google sign-in result."])))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            // Sign in with Firebase
            self.auth.signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let authResult = authResult else {
                    completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign in with Google."])))
                    return
                }
                
                // Check if this is a new user
                let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
                
                if isNewUser {
                    // Create user document for new Google users
                    let firstName = user.profile?.givenName ?? ""
                    let fullName = user.profile?.name ?? ""
                    let email = user.profile?.email ?? authResult.user.email ?? ""
                    
                    // Generate unique username from Google profile
                    self.generateUniqueUsername(from: email, firstName: firstName) { generatedUsername in
                        self.createUserDocument(
                            uid: authResult.user.uid,
                            email: email,
                            firstName: firstName,
                            username: generatedUsername,
                            displayName: fullName.isEmpty ? generatedUsername : fullName,
                            completion: completion
                        )
                    }
                } else {
                    // Fetch existing user document
                    self.fetchUserDocument(uid: authResult.user.uid, completion: completion)
                }
            }
        }
    }
    
    /// Sign in with Apple
    /// - Parameters:
    ///   - authorization: The Apple ID credential authorization
    ///   - nonce: The nonce used for validation
    ///   - completion: Completion handler with result
    func signInWithApple(authorization: ASAuthorization, nonce: String, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get Apple ID credential."])))
            return
        }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get identity token."])))
            return
        }
        
        // Create Firebase credential
        let credential = OAuthProvider.appleCredential(withIDToken: identityToken,
                                                      rawNonce: nonce,
                                                      fullName: appleIDCredential.fullName)
        
        // Sign in with Firebase
        auth.signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authResult = authResult else {
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign in with Apple."])))
                return
            }
            
            // Check if this is a new user
            let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
            
            if isNewUser {
                // Extract name components
                var firstName = ""
                var fullName = ""
                if let appleFullName = appleIDCredential.fullName {
                    let nameComponents = [appleFullName.givenName, appleFullName.familyName]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                    
                    if !nameComponents.isEmpty {
                        firstName = nameComponents[0]
                        fullName = nameComponents.joined(separator: " ")
                    }
                }
                
                // Use email from credential or from Firebase auth
                let email = appleIDCredential.email ?? authResult.user.email ?? ""
                
                // Generate unique username from Apple profile
                self.generateUniqueUsername(from: email, firstName: firstName) { generatedUsername in
                    self.createUserDocument(
                        uid: authResult.user.uid,
                        email: email,
                        firstName: firstName,
                        username: generatedUsername,
                        displayName: fullName.isEmpty ? generatedUsername : fullName,
                        completion: completion
                    )
                }
            } else {
                // Fetch existing user document
                self.fetchUserDocument(uid: authResult.user.uid, completion: completion)
            }
        }
    }
    
    /// Clean up resources when the service is no longer needed
    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
} 