import SwiftUI

struct ForgotPasswordView: View {
    /// Authentication view model (passed from parent view)
    @ObservedObject var viewModel: AuthViewModel
    
    /// Environment value to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("FORGOT PASSWORD")
                        .font(AppTheme.Typography.footnoteFont())
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                    
                    // Title
                    Text("Reset Password")
                        .font(AppTheme.Typography.title1Font())
                        .fontWeight(.bold)
                    
                    // Subtitle
                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    
                    // Form
                    VStack(alignment: .leading, spacing: 24) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(AppTheme.Typography.subheadlineFont())
                                .fontWeight(.medium)
                            
                            TextField("Enter your email address", text: $viewModel.email)
                                .font(AppTheme.Typography.bodyFont())
                                .keyboardType(.emailAddress)
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
                        
                        // Error message
                        if !viewModel.passwordResetError.isEmpty {
                            Text(viewModel.passwordResetError)
                                .font(AppTheme.Typography.footnoteFont())
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                        
                        // Success message
                        if viewModel.passwordResetSent {
                            VStack(alignment: .center, spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 36))
                                
                                Text("Password reset email sent!")
                                    .font(AppTheme.Typography.headlineFont())
                                    .foregroundColor(.green)
                                
                                Text("Please check your inbox and follow the instructions to reset your password.")
                                    .font(AppTheme.Typography.bodyFont())
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.1))
                            )
                            .padding(.vertical)
                        }
                        
                        // Send reset link button
                        Button(action: {
                            viewModel.sendPasswordReset()
                        }) {
                            if viewModel.isLoading {
                                SwiftUI.ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(AppColors.mintGreen))
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            } else {
                                Text("Send Reset Link")
                                    .font(AppTheme.Typography.calloutFont())
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(AppColors.mintGreen))
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(viewModel.isLoading || viewModel.passwordResetSent)
                        .padding(.top, 10)
                        
                        // Back to login button
                        if viewModel.passwordResetSent {
                            Button("Back to Login") {
                                dismiss()
                            }
                            .font(AppTheme.Typography.calloutFont())
                            .foregroundColor(Color(AppColors.coreGreen))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView(viewModel: AuthViewModel())
} 