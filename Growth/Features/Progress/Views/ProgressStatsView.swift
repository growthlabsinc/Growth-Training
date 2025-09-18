//
//  ProgressStatsView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

struct ProgressStatsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Stats Icon
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("GrowthGreen"))
                .padding(.bottom, 20)
            
            // Title
            Text("Progress Statistics")
                .font(AppTheme.Typography.largeTitleFont())
                .fontWeight(.bold)
                .foregroundColor(Color("TextColor"))
            
            // Subtitle
            Text("View detailed analytics and insights about your practice")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Coming Soon Badge
            Text("Coming Soon")
                .font(AppTheme.Typography.captionFont())
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("GrowthGreen"))
                .cornerRadius(16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("GrowthBackgroundLight"))
    }
}

#Preview {
    ProgressStatsView()
}