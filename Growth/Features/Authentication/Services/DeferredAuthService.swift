//
//  DeferredAuthService.swift
//  Growth
//
//  Wrapper for AuthService that defers initialization until Firebase is configured
//

import Foundation
import Combine
import Firebase
import UIKit
import AuthenticationServices

/// A wrapper around AuthService that defers its initialization until Firebase is configured
class DeferredAuthService: AuthServiceProtocol {
    private var _authService: AuthService?
    private var authService: AuthService {
        if _authService == nil {
            _authService = AuthService()
        }
        return _authService!
    }
    
    var currentUser: AuthUser? {
        // Check if Firebase is configured before accessing
        guard FirebaseApp.app() != nil else {
            return nil
        }
        return authService.currentUser
    }
    
    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        // Return an empty publisher if Firebase isn't configured yet
        guard FirebaseApp.app() != nil else {
            return Empty<AuthUser?, Never>().eraseToAnyPublisher()
        }
        return authService.authStatePublisher
    }
    
    func createUser(email: String, password: String, firstName: String?, username: String?, displayName: String?, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard FirebaseApp.app() != nil else {
            completion(.failure(NSError(domain: "DeferredAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])))
            return
        }
        authService.createUser(email: email, password: password, firstName: firstName, username: username, displayName: displayName, completion: completion)
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard FirebaseApp.app() != nil else {
            completion(.failure(NSError(domain: "DeferredAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])))
            return
        }
        authService.signIn(email: email, password: password, completion: completion)
    }
    
    func signInAnonymously(completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard FirebaseApp.app() != nil else {
            completion(.failure(NSError(domain: "DeferredAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])))
            return
        }
        authService.signInAnonymously(completion: completion)
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        guard FirebaseApp.app() != nil else {
            completion(NSError(domain: "DeferredAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"]))
            return
        }
        authService.sendPasswordReset(email: email, completion: completion)
    }
    
    func signOut(completion: @escaping (Error?) -> Void) {
        guard FirebaseApp.app() != nil else {
            completion(NSError(domain: "DeferredAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"]))
            return
        }
        authService.signOut(completion: completion)
    }
    
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard FirebaseApp.app() != nil else {
            completion(.failure(NSError(domain: "DeferredAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])))
            return
        }
        authService.signInWithGoogle(presentingViewController: presentingViewController, completion: completion)
    }
    
    func signInWithApple(authorization: ASAuthorization, nonce: String, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard FirebaseApp.app() != nil else {
            completion(.failure(NSError(domain: "DeferredAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])))
            return
        }
        authService.signInWithApple(authorization: authorization, nonce: nonce, completion: completion)
    }
}