import SwiftUI

struct DisclaimerView: View {
    @State private var isChecked = false
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showingCitations = false
    @Environment(\.presentationMode) var presentationMode
    let disclaimer = DisclaimerVersion.current
    var onAccepted: (() -> Void)?
    var onBack: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Important: Your Safety Comes First.")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color("GrowthGreen"))
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(disclaimer.content)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.Colors.text)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .shadow(color: Color(UIColor.label).opacity(0.08), radius: 8, y: 2)
                            )
                        
                        // Citation reference section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "text.book.closed.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.secondary)
                                Text("Scientific References")
                                    .font(AppTheme.Typography.gravitySemibold(14))
                                    .foregroundColor(AppTheme.Colors.text)
                            }
                            
                            Button(action: { showingCitations = true }) {
                                HStack {
                                    Text("View all 20+ peer-reviewed citations")
                                        .font(AppTheme.Typography.gravityBook(13))
                                        .foregroundColor(AppTheme.Colors.secondary)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.Colors.secondary)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppTheme.Colors.secondary.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .frame(maxHeight: 380)
                
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
                    .accessibilityLabel("Acknowledge disclaimer")
                    Text("I have read and agree to the Safety & Medical Disclaimer.")
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
                
                if isChecked {
                    AnimatedPrimaryButton(
                        title: isSubmitting ? "Submitting..." : "Continue",
                        action: submitAcceptance
                    )
                    .disabled(isSubmitting)
                    .padding(.horizontal)
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
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        if let onBack = onBack {
                            onBack()
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color("GrowthGreen"))
                        Text("Back")
                            .foregroundColor(Color("GrowthGreen"))
                    }
                }
            }
            .sheet(isPresented: $showingCitations) {
                NavigationStack {
                    AllCitationsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingCitations = false
                                }
                                .font(AppTheme.Typography.gravitySemibold(16))
                                .foregroundColor(AppTheme.Colors.secondary)
                            }
                        }
                }
            }
        }
    }
    
    private func submitAcceptance() {
        // Store consent temporarily until user creates account
        PendingConsents.shared.recordDisclaimerAcceptance(version: disclaimer.version)
        onAccepted?()
    }
}

#Preview {
    DisclaimerView()
} 