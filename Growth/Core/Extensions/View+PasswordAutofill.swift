import SwiftUI
import AuthenticationServices

extension View {
    /// Configure the view for password autofill with proper associated domains
    func configurePasswordAutofill() -> some View {
        self.onAppear {
            // The system automatically handles password autofill
            // when text fields have proper textContentType values
            // and associated domains are configured
        }
    }
}

/// A wrapper view that properly configures text fields for password autofill
struct AutofillTextField: View {
    let placeholder: String
    @Binding var text: String
    let contentType: UITextContentType
    let keyboardType: UIKeyboardType
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textContentType(contentType)
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .autocorrectionDisabled(true)
    }
}

/// A wrapper view that properly configures secure fields for password autofill
struct AutofillSecureField: View {
    let placeholder: String
    @Binding var text: String
    let contentType: UITextContentType
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .textContentType(contentType)
            .autocapitalization(.none)
            .autocorrectionDisabled(true)
    }
}