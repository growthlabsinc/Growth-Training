import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct LoginView: View {
    /// Authentication view model
    @StateObject private var viewModel = AuthViewModel()
    
    /// Flag to control showing the forgot password sheet
    @State private var showingForgotPassword = false
    
    /// Biometric service
    @StateObject private var biometricService = BiometricAuthService.shared
    
    /// Focus state for text fields
    @FocusState private var focusedField: Field?
    
    /// Color scheme environment
    @Environment(\.colorScheme) var colorScheme
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                // App Logo (centered, no text)
                AppLogo(size: 64, showText: false)
                    .padding(.bottom, 16)
                
                // Title and subtitle
                VStack(spacing: 8) {
                    Text("Welcome back")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("Sign in to access your Growth account")
                        .font(.system(size: 16))
                        .foregroundColor(Color("GrowthNeutralGray"))
                }
                .padding(.bottom, 16)
                
                // Card-like form with lighter shadow and more rounded corners
                VStack(spacing: 24) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(AppTheme.Typography.subheadlineFont())
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        ZStack(alignment: .leading) {
                            if viewModel.email.isEmpty {
                                Text("your@email.com")
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(Color("GrowthNeutralGray"))
                                    .padding(.horizontal, 16)
                            }
                            
                            TextField("", text: $viewModel.email)
                                .font(AppTheme.Typography.bodyFont())
                                .foregroundColor(AppTheme.Colors.text)
                                .tint(Color("GrowthGreen"))
                                .keyboardType(.emailAddress)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .autocorrectionDisabled(true)
                                .submitLabel(.next)
                                .padding(16)
                                .focused($focusedField, equals: .email)
                                .onSubmit {
                                    focusedField = .password
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(!viewModel.emailError.isEmpty ? Color.red : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                        )
                            .onChangeCompat(of: viewModel.email) { _ in
                                if !viewModel.email.isEmpty {
                                    _ = viewModel.validateEmail()
                                } else {
                                    viewModel.emailError = ""
                                }
                            }
                        
                        if !viewModel.emailError.isEmpty {
                            Text(viewModel.emailError)
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Password field with forgot password
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Password")
                                .font(AppTheme.Typography.subheadlineFont())
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Spacer()
                            
                            Button("Forgot password?") {
                                viewModel.clearPasswordResetState()
                                showingForgotPassword = true
                            }
                            .font(.system(size: 15))
                            .foregroundColor(Color("GrowthGreen"))
                        }
                        
                        SecureField("Enter your password", text: $viewModel.password)
                            .font(AppTheme.Typography.bodyFont())
                            .foregroundColor(AppTheme.Colors.text)
                            .tint(Color("GrowthGreen"))
                            .textContentType(.password)
                            .autocorrectionDisabled(true)
                            .autocapitalization(.none)
                            .submitLabel(.go)
                            .padding(16)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                viewModel.signIn()
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(!viewModel.passwordError.isEmpty ? Color.red : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                            )
                            .onChangeCompat(of: viewModel.password) { _ in
                                if !viewModel.password.isEmpty {
                                    _ = viewModel.validatePassword()
                                } else {
                                    viewModel.passwordError = ""
                                }
                            }
                        
                        if !viewModel.passwordError.isEmpty {
                            Text(viewModel.passwordError)
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Remember me checkbox with Face ID option
                    HStack {
                        Button(action: { viewModel.rememberMe.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.rememberMe ? "checkmark.square" : "square")
                                    .foregroundColor(viewModel.rememberMe ? Color("GrowthGreen") : Color("GrowthNeutralGray"))
                                    .font(.system(size: 15))
                                
                                Text("Remember me")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.Colors.text)
                            }
                        }
                        
                        Spacer()
                        
                        // Show Face ID button if biometric login is enabled and credentials are saved
                        if biometricService.biometricLoginEnabled && viewModel.biometricsAvailable {
                            Button(action: {
                                Task {
                                    await viewModel.signInWithBiometrics()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: biometricService.biometryIcon)
                                        .font(.system(size: 18))
                                    Text("Use \(biometricService.biometryName)")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(Color("GrowthGreen"))
                            }
                        }
                    }
                    .padding(.top, -8)
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(.red)
                            .padding(.top, -8)
                    }
                }
                .padding(20)
                .background(Color("BackgroundColor"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                .padding(.horizontal, 16)
                
                // Log in button outside the card
                Button(action: { viewModel.signIn() }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            SwiftUI.ProgressView()
                                .tint(Color.white)
                        } else {
                            Text("Log In")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(Color("GrowthGreen"))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .opacity(viewModel.isLoading ? 0.4 : 1.0)
                .disabled(viewModel.isLoading)
                
                // Face ID quick login button (if credentials are saved)
                if biometricService.biometricLoginEnabled && viewModel.biometricsAvailable && KeychainService.shared.retrieveCredentials() != nil {
                    VStack(spacing: 8) {
                        // Face ID specific warning (Apple's recommendation)
                        if biometricService.biometryType == .faceID {
                            Text("Tapping the button will immediately start Face ID scanning")
                                .font(.system(size: 12))
                                .foregroundColor(Color("TextSecondaryColor").opacity(0.8))
                                .multilineTextAlignment(.center)
                                .italic()
                                .padding(.horizontal, 16)
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.signInWithBiometrics()
                            }
                        }) {
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: biometricService.biometryIcon)
                                    .font(.system(size: 20))
                                Text("Sign in with \(biometricService.biometryName)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(Color("GrowthGreen"))
                            Spacer()
                        }
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("GrowthGreen"), lineWidth: 1.5)
                        )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .disabled(viewModel.isLoading)
                    }
                }
                
                // Divider with 'or continue with'
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color("GrowthNeutralGray"))
                        .opacity(0.3)
                    
                    Text("or continue with")
                        .font(.system(size: 15))
                        .foregroundColor(Color("GrowthNeutralGray"))
                        .padding(.horizontal, 8)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color("GrowthNeutralGray"))
                        .opacity(0.3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Social login buttons
                VStack(spacing: 12) {
                    // Custom Google Sign-In Button
                    Button(action: { viewModel.signInWithGoogle() }) {
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                if UIImage(named: "GoogleLogo") != nil {
                                    Image("GoogleLogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                } else {
                                    // Fallback to text "G" if icon not found
                                    Text("G")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.red)
                                        .frame(width: 20, height: 20)
                                }
                                
                                Text("Sign in with Google")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            Spacer()
                        }
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(26)
                    }
                    
                    // Apple Sign-In Button
                    AppleSignInButton(
                        .signIn,
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
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Sign up link at bottom
                HStack {
                    Text("Don't have an account?")
                        .font(.system(size: 15))
                        .foregroundColor(Color("GrowthNeutralGray"))
                    
                    NavigationLink(destination: CreateAccountView()) {
                        Text("Sign Up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color("GrowthBackgroundLight").ignoresSafeArea())
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
            .configurePasswordAutofill()
            .onAppear {
                // Request password autofill credentials when the view appears
                if #available(iOS 14.0, *) {
                    // This helps trigger the password autofill UI
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // The system will automatically show available credentials
                        // when it detects username and password fields with proper content types
                    }
                }
            }
        }
    }
}


#Preview {
    LoginView()
} 