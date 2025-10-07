//
//  MethodCardView.swift
//  Growth
//
//  Created by Developer on 6/11/25.
//

import SwiftUI

struct MethodCardView: View {
    let method: TrainingProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with stage indicator
            HStack {
                Text(method.title)
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("TextColor"))
                    .lineLimit(2)
                
                Spacer()
                
                // Stage indicator
                Text("S\(method.stage)")
                    .font(AppTheme.Typography.captionFont())
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stageColor(for: method.stage))
                    .cornerRadius(6)
            }
            
            // Description
            Text(method.protocolDescription)
                .font(AppTheme.Typography.subheadlineFont())
                .foregroundColor(Color("TextSecondaryColor"))
                .lineLimit(3)
            
            // Bottom info
            HStack {
                // Duration
                if let duration = method.estimatedDurationMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(AppTheme.Typography.captionFont())
                        Text("\(duration) min")
                            .font(AppTheme.Typography.captionFont())
                    }
                    .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
                
                // Categories
                if !method.categories.isEmpty {
                    Text(method.categories.first ?? "")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(Color("GrowthGreen"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("GrowthGreen").opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color("BackgroundColor"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func stageColor(for stage: Int) -> Color {
        switch stage {
        case 1: return Color("GrowthGreen")
        case 2: return Color("BrightTeal")
        case 3: return .orange
        case 4: return .red
        default: return .purple
        }
    }
}

#Preview {
    MethodCardView(method: TrainingProtocol(
        id: "preview1",
        stage: 1,
        title: "Basic Manual Stretch",
        protocolDescription: "The fundamental length exercise for tissue elongation",
        instructionsText: "Follow the instructions...",
        estimatedDurationMinutes: 10,
        categories: ["Length"]
    ))
    .padding()
}