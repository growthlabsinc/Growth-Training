import SwiftUI

struct PrivacyTermsConsentView: View {
    @State private var isChecked = false
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    @State private var privacyDocument: LegalDocument? = nil
    @State private var termsDocument: LegalDocument? = nil
    
    var onNext: (() -> Void)?
    var onBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your Privacy is Our Priority.")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color("GrowthGreen"))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            
            // Privacy summary with links
            VStack(alignment: .leading, spacing: 16) {
                Text("We are committed to protecting your privacy and data:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color("GrowthGreen"))
                            .frame(width: 20)
                        Text("End-to-end encryption for all your health data")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.Colors.text)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color("GrowthGreen"))
                            .frame(width: 20)
                        Text("We never share your personal logs or health information")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.Colors.text)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color("GrowthGreen"))
                            .frame(width: 20)
                        Text("You have full control over your data at all times")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.Colors.text)
                    }
                }
                .padding(.vertical, 8)
                
                // Links to full documents
                HStack(spacing: 20) {
                    Button(action: { showPrivacyPolicy = true }) {
                        Text("Read Full Privacy Policy")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color("GrowthGreen"))
                            .underline()
                    }
                    
                    Button(action: { showTermsOfUse = true }) {
                        Text("Read Terms of Use")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color("GrowthGreen"))
                            .underline()
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color(UIColor.label).opacity(0.08), radius: 8, y: 2)
            )
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Consent checkbox with animation
            HStack(alignment: .center, spacing: 12) {
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isChecked.toggle()
                    }
                    if ThemeManager.shared.hapticFeedback {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }) {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(isChecked ? Color("GrowthGreen") : Color("GrowthNeutralGray"))
                        .scaleEffect(isChecked ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChecked)
                }
                .accessibilityLabel("Agree to privacy and terms")
                
                Text("I agree to the Privacy Policy and Terms of Use.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            
            if let error = errorMessage {
                Text(error)
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.red)
            }
            
            // Navigation buttons
            HStack(spacing: 16) {
                Button(action: {
                    if ThemeManager.shared.hapticFeedback {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                    onBack?()
                }) {
                    Text("Back")
                        .font(AppTheme.Typography.gravitySemibold(17))
                        .foregroundColor(Color("GrowthGreen"))
                        .frame(width: 100, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                                .stroke(Color("GrowthGreen"), lineWidth: 1.5)
                        )
                }
                
                if isChecked {
                    AnimatedPrimaryButton(
                        title: isSubmitting ? "Submitting..." : "Continue",
                        action: submitConsent
                    )
                    .disabled(isSubmitting)
                } else {
                    Button(action: {}) {
                        Text("Continue")
                            .font(AppTheme.Typography.gravitySemibold(17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, GrowthUITheme.ComponentSize.primaryButtonHeight / 3)
                            .background(
                                RoundedRectangle(cornerRadius: GrowthUITheme.ComponentSize.primaryButtonCornerRadius)
                                    .fill(Color("GrowthNeutralGray").opacity(0.4))
                            )
                    }
                    .disabled(true)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .onAppear {
            loadDocuments()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            if let document = privacyDocument {
                LegalDocumentModalView(document: document)
            }
        }
        .sheet(isPresented: $showTermsOfUse) {
            if let document = termsDocument {
                LegalDocumentModalView(document: document)
            }
        }
    }
    
    private func loadDocuments() {
        // Load privacy policy
        LegalDocumentService.shared.fetchDocument(withId: "privacy_policy") { document in
            self.privacyDocument = document
        }
        
        // Load terms of use
        LegalDocumentService.shared.fetchDocument(withId: "terms_of_use") { document in
            self.termsDocument = document
        }
    }
    
    private func submitConsent() {
        // Store consent temporarily until user creates account
        let privacyVersion = privacyDocument?.version ?? "1.0.0"
        let termsVersion = termsDocument?.version ?? "1.0.0"
        
        PendingConsents.shared.recordPrivacyTermsAcceptance(
            privacyVersion: privacyVersion,
            termsVersion: termsVersion
        )
        
        onNext?()
    }
    
    private func recordConsent(for document: LegalDocument) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            LegalDocumentService.shared.recordConsentWithProfile(for: document) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

// MARK: - Legal Document Modal View
struct LegalDocumentModalView: View {
    let document: LegalDocument
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(document.content)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.text)
                        .padding()
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("GrowthGreen"))
                }
            }
        }
    }
}

#Preview {
    PrivacyTermsConsentView()
}