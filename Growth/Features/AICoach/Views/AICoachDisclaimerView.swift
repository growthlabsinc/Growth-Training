//
//  AICoachDisclaimerView.swift
//  Growth
//
//  Created by Developer on <CURRENT_DATE>.
//

import SwiftUI

struct AICoachDisclaimerView: View {
    @Environment(\.dismiss) var dismiss
    let onAccept: (() -> Void)?
    let onDecline: (() -> Void)?
    
    init(onAccept: (() -> Void)? = nil, onDecline: (() -> Void)? = nil) {
        self.onAccept = onAccept
        self.onDecline = onDecline
    }

    var body: some View {
        VStack(spacing: AppTheme.Layout.spacingL) {
            Text("Medical Disclaimer")
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(AppTheme.Colors.text)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Important Information")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("""
                    The Growth Coach AI assistant is designed to provide information and guidance about the Growth Method app and related educational content.
                    
                    **Not Medical Advice:** The AI Coach cannot and does not provide medical advice, diagnosis, or treatment recommendations. The information provided is for educational purposes only.
                    
                    **Consult Healthcare Professionals:** For any medical concerns, symptoms, or health-related questions, please consult with qualified healthcare professionals.
                    
                    **Use at Your Own Risk:** By using the AI Coach, you acknowledge that you understand these limitations and agree to use the service responsibly.
                    
                    Do you understand and accept these terms?
                    """)
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineSpacing(6)
                }
                .padding(.horizontal, 4)
            }

            HStack(spacing: 16) {
                Button("Decline") {
                    if let onDecline = onDecline {
                        onDecline()
                    } else {
                        dismiss()
                    }
                }
                .font(AppTheme.Typography.gravitySemibold(14))
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.clear)
                .foregroundColor(Color("TextColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusM)
                        .stroke(Color("NeutralGray"), lineWidth: 1)
                )
                
                Button("I Understand & Accept") {
                    if let onAccept = onAccept {
                        onAccept()
                    } else {
                        dismiss()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, AppTheme.Layout.spacingXL)
        }
        .padding(AppTheme.Layout.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.Layout.cornerRadiusL)
        .shadow(radius: AppTheme.Layout.shadowRadius)
        .padding(AppTheme.Layout.spacingM)
        .presentationDetents([.medium, .large])
    }
}

#if DEBUG
struct AICoachDisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        AICoachDisclaimerView()
            .previewLayout(.sizeThatFits)
    }
}
#endif 