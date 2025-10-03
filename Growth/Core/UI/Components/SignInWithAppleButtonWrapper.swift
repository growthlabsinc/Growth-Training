import SwiftUI
import AuthenticationServices

/// A custom wrapper for ASAuthorizationAppleIDButton that properly handles SwiftUI layout constraints
struct SignInWithAppleButtonWrapper: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let onTap: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        
        // Remove autoresizing mask to prevent constraint conflicts
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set content hugging and compression resistance priorities
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }
    
    class Coordinator: NSObject {
        let onTap: () -> Void
        
        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }
        
        @objc func handleTap() {
            onTap()
        }
    }
}

/// A SwiftUI-friendly Sign in with Apple button that properly handles layout
struct AppleSignInButton: View {
    enum ButtonType {
        case signIn
        case signUp
        case `continue`
        
        var asAuthorizationType: ASAuthorizationAppleIDButton.ButtonType {
            switch self {
            case .signIn: return .signIn
            case .signUp: return .signUp
            case .continue: return .continue
            }
        }
    }
    
    let type: ButtonType
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var coordinator = SignInCoordinator()
    
    init(
        _ type: ButtonType = .signIn,
        onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
    ) {
        self.type = type
        self.onRequest = onRequest
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        SignInWithAppleButtonWrapper(
            type: type.asAuthorizationType,
            style: colorScheme == .dark ? .white : .black,
            onTap: handleSignInWithApple
        )
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .cornerRadius(26)
    }
    
    private func handleSignInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        onRequest(request)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        coordinator.onCompletion = onCompletion
        controller.delegate = coordinator
        controller.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate

private class SignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion?(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion?(.failure(error))
    }
}