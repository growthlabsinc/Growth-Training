import SwiftUI

/// Text field types for authentication screens
enum AuthTextFieldType {
    case email
    case password
    case confirmPassword
    
    /// Get the placeholder text based on field type
    var placeholder: String {
        switch self {
        case .email:
            return "Email"
        case .password:
            return "Password"
        case .confirmPassword:
            return "Confirm Password"
        }
    }
    
    /// Get the keyboard type based on field type
    var keyboardType: UIKeyboardType {
        switch self {
        case .email:
            return .emailAddress
        case .password, .confirmPassword:
            return .default
        }
    }
    
    /// Get the SF Symbol name based on field type
    var iconName: String {
        switch self {
        case .email:
            return "envelope"
        case .password, .confirmPassword:
            return "lock"
        }
    }
}

/// A custom text field component for authentication screens
struct AuthTextField: View {
    /// Type of the auth text field
    let type: AuthTextFieldType
    
    /// Binding to text value
    @Binding var text: String
    
    /// Optional error message to display
    var errorMessage: String?
    
    /// Binding to indicate when the field's content changed
    var onEditingChanged: ((Bool) -> Void)?
    
    /// Whether the field is in secure entry mode
    @State private var isSecure: Bool = true
    
    /// Whether the field is currently focused
    @State private var isFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                // Field icon
                Image(systemName: type.iconName)
                    .foregroundColor(errorMessage != nil ? .red : (isFocused ? .blue : .gray))
                
                // Text field with secure entry support
                if type == .password || type == .confirmPassword {
                    if isSecure {
                        SecureField(type.placeholder, text: $text)
                            .keyboardType(type.keyboardType)
                            .autocapitalization(.none)
                            .autocorrectionDisabled(true)
                            .onChangeCompat(of: text) { _ in
                                onEditingChanged?(true)
                            }
                            .onTapGesture {
                                isFocused = true
                            }
                    } else {
                        TextField(type.placeholder, text: $text)
                            .keyboardType(type.keyboardType)
                            .autocapitalization(.none)
                            .autocorrectionDisabled(true)
                            .onChangeCompat(of: text) { _ in
                                onEditingChanged?(true)
                            }
                            .onTapGesture {
                                isFocused = true
                            }
                    }
                    
                    // Toggle secure entry button
                    Button(action: {
                        isSecure.toggle()
                    }) {
                        Image(systemName: isSecure ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    }
                } else {
                    // Standard text field for non-password types
                    TextField(type.placeholder, text: $text)
                        .keyboardType(type.keyboardType)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                        .onChangeCompat(of: text) { _ in
                            onEditingChanged?(true)
                        }
                        .onTapGesture {
                            isFocused = true
                        }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(errorMessage != nil ? Color.red : (isFocused ? Color.blue : Color.gray.opacity(0.5)), lineWidth: 1)
            )
            
            // Display error message if present
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AuthTextField(type: .email, text: .constant("user@example.com"))
        
        AuthTextField(type: .email, text: .constant("invalid_email"), errorMessage: "Please enter a valid email address")
        
        AuthTextField(type: .password, text: .constant("password123"))
        
        AuthTextField(type: .confirmPassword, text: .constant("password123"), errorMessage: "Passwords do not match")
    }
    .padding()
} 