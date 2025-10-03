//
//  BiometricLockView.swift
//  Growth
//
//  View shown when app requires biometric authentication on launch
//

import SwiftUI
import LocalAuthentication

struct BiometricLockView: View {
    @StateObject private var biometricService = BiometricAuthService.shared
    @State private var isUnlocked = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var onUnlock: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color("GrowthBackgroundLight")
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo
                AppLogo(size: 80, showText: false)
                
                // Lock Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("GrowthGreen"))
                    .padding(.bottom, 20)
                
                // Title
                Text("Growth is Locked")
                    .font(AppTheme.Typography.gravitySemibold(28))
                    .foregroundColor(Color("TextColor"))
                
                // Subtitle with Face ID warning
                VStack(spacing: 8) {
                    Text("Authenticate to access your data")
                        .font(AppTheme.Typography.gravityBook(16))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.center)
                    
                    // Face ID specific warning (Apple's recommendation)
                    if biometricService.biometryType == .faceID {
                        Text("Tapping the button will immediately start Face ID scanning")
                            .font(AppTheme.Typography.gravityBook(14))
                            .foregroundColor(Color("TextSecondaryColor").opacity(0.8))
                            .multilineTextAlignment(.center)
                            .italic()
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Authenticate Button
                Button(action: authenticate) {
                    HStack {
                        Image(systemName: biometricService.biometryIcon)
                            .font(.system(size: 24))
                        Text("Unlock with \(biometricService.biometryName)")
                            .font(AppTheme.Typography.gravitySemibold(18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("GrowthGreen"), Color("BrightTeal")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .alert("Authentication Failed", isPresented: $showError) {
            Button("Try Again") {
                authenticate()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Automatically attempt authentication on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        Task {
            // Check biometry availability first
            biometricService.checkBiometryAvailability()
            
            guard biometricService.canUseBiometrics() else {
                errorMessage = getUnavailabilityMessage()
                showError = true
                return
            }
            
            let authenticated = await biometricService.authenticateForAppAccess()
            
            if authenticated {
                withAnimation(.easeOut(duration: 0.3)) {
                    isUnlocked = true
                }
                // Small delay for animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onUnlock()
                }
            } else {
                // Use enhanced error messaging from the service
                if let error = biometricService.lastError {
                    errorMessage = biometricService.getErrorMessage(from: error)
                } else {
                    errorMessage = "Authentication failed. Please try again."
                }
                showError = true
            }
        }
    }
    
    private func getUnavailabilityMessage() -> String {
        if biometricService.isTemporarilyLocked {
            return "Biometric authentication is temporarily locked. Please wait \(Int(biometricService.lockoutDuration)) seconds."
        } else if !biometricService.isBiometryAvailable() {
            return "\(biometricService.biometryName) is not available on this device."
        } else {
            return "\(biometricService.biometryName) is not available. Please try again later."
        }
    }
}

#Preview {
    BiometricLockView {
        Logger.error("Unlocked!")
    }
}