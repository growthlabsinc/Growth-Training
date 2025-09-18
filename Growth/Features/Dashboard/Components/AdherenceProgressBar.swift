//
//  AdherenceProgressBar.swift
//  Growth
//
//  Created by Developer on 5/31/25.
//

import SwiftUI

/// Reusable progress bar component for visualizing adherence
struct AdherenceProgressBar: View {
    /// The adherence percentage (0-100)
    let percentage: Double
    
    /// Whether to show the percentage label
    let showLabel: Bool
    
    /// Height of the progress bar
    let height: CGFloat
    
    /// Animation namespace for smooth transitions
    @Namespace private var animation
    
    /// Current color based on percentage
    private var progressColor: Color {
        if percentage >= 80 {
            return Color("GrowthGreen")
        } else if percentage >= 60 {
            return Color.orange
        } else {
            return Color("ErrorColor")
        }
    }
    
    // MARK: - Initialization
    
    init(percentage: Double, showLabel: Bool = true, height: CGFloat = 8) {
        self.percentage = min(max(percentage, 0), 100) // Clamp between 0-100
        self.showLabel = showLabel
        self.height = height
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: height)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: height)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentage)
                }
            }
            .frame(height: height)
            
            // Label
            if showLabel {
                HStack {
                    Text("\(Int(percentage))%")
                        .font(AppTheme.Typography.gravityBoldFont(14))
                        .foregroundColor(progressColor)
                    
                    Spacer()
                    
                    Text(getAdherenceLabel())
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getAdherenceLabel() -> String {
        if percentage >= 80 {
            return "Excellent"
        } else if percentage >= 60 {
            return "Good"
        } else if percentage > 0 {
            return "Needs Improvement"
        } else {
            return "No Data"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Excellent Adherence")
                .font(AppTheme.Typography.headlineFont())
            AdherenceProgressBar(percentage: 95)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Good Adherence")
                .font(AppTheme.Typography.headlineFont())
            AdherenceProgressBar(percentage: 75)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Needs Improvement")
                .font(AppTheme.Typography.headlineFont())
            AdherenceProgressBar(percentage: 45)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Without Label")
                .font(AppTheme.Typography.headlineFont())
            AdherenceProgressBar(percentage: 85, showLabel: false)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}