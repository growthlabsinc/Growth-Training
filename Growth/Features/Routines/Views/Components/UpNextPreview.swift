//
//  UpNextPreview.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// Displays a preview of the next method in the session
struct UpNextPreview: View {
    // MARK: - Properties
    
    let nextMethod: GrowthMethod
    @State private var isVisible: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("GrowthGreen"))
                
                Text("Up Next")
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("GrowthGreen"))
                
                Spacer()
                
                // Duration
                if let duration = nextMethod.estimatedDurationMinutes {
                    Text("\(duration) min")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
            }
            
            // Method info
            VStack(alignment: .leading, spacing: 4) {
                Text(nextMethod.title)
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("TextColor"))
                    .lineLimit(1)
                
                Text(nextMethod.methodDescription)
                    .font(AppTheme.Typography.gravityBook(13))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("GrowthBackgroundLight"))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1 : 0.95)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            // Pulse animation for attention
            withAnimation(.easeInOut(duration: 0.8).repeatCount(2, autoreverses: true)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        UpNextPreview(
            nextMethod: GrowthMethod(
                id: "preview1",
                stage: 2,
                classification: "Intermediate",
                title: "Angion Method 2.0",
                methodDescription: "Intermediate circular movements for enhanced circulation",
                instructionsText: "Sample instructions",
                estimatedDurationMinutes: 15,
                categories: ["intermediate"],
                safetyNotes: "Sample safety notes"
            )
        )
        .padding()
    }
}