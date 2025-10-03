//
//  TextInputField.swift
//  Growth
//
//  Created by Developer on 5/8/25.
//

import SwiftUI

/// A styled text input field component
struct TextInputField: View {
    // MARK: - Properties
    
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var disableAutocorrection: Bool = false
    var icon: String? = nil
    var errorMessage: String? = nil
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacingXS) {
            // Input label
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.systemGray)
            
            // Text field with optional secure entry
            HStack {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .foregroundColor(AppTheme.Colors.systemGray)
                        .frame(width: 24, height: 24)
                }
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .disableAutocorrection(disableAutocorrection)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .disableAutocorrection(disableAutocorrection)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(AppTheme.Layout.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                    .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 1)
            )
            
            // Error message if present
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Standard text field
        TextInputField(
            title: "Name",
            placeholder: "Enter your name",
            text: .constant("")
        )
        
        // Email field with icon
        TextInputField(
            title: "Email",
            placeholder: "example@email.com",
            text: .constant("user@example.com"),
            keyboardType: .emailAddress,
            autocapitalization: .never,
            disableAutocorrection: true,
            icon: "envelope"
        )
        
        // Password field
        TextInputField(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant("password123"),
            isSecure: true,
            autocapitalization: .never,
            disableAutocorrection: true,
            icon: "lock"
        )
        
        // Field with error
        TextInputField(
            title: "Username",
            placeholder: "Choose a username",
            text: .constant(""),
            autocapitalization: .never,
            icon: "person",
            errorMessage: "Username is required"
        )
    }
    .padding()
    .background(Color(UIColor.systemBackground))
} 