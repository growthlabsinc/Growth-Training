//
//  PracticeOptionCardView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

struct PracticeOptionCardView: View {
    let option: PracticeOption
    let title: String
    let description: String
    let isEnabled: Bool
    var showHint: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and title
                HStack {
                    Image(systemName: option.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(isEnabled ? Color("GrowthGreen") : Color.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color("TextColor"))
                        
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextSecondaryColor"))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                // Action button
                Button(action: onTap) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        
                        Text(getButtonTitle())
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isEnabled ? Color("GrowthGreen") : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isEnabled)
                
                // Additional info if disabled or showing hint
                if (!isEnabled || showHint) && option == .guided {
                    HStack {
                        Image(systemName: showHint ? "arrow.right.circle" : "info.circle")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(showHint ? Color("GrowthGreen") : Color("TextSecondaryColor"))
                        
                        Text(showHint ? "Select a routine first" : "No routine selected or rest day")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(showHint ? Color("GrowthGreen") : Color("TextSecondaryColor"))
                    }
                }
            }
        }
    }
    
    private func getButtonTitle() -> String {
        switch option {
        case .guided:
            return isEnabled ? "Start Guided Session" : "No Session Available"
        case .quick:
            return "Start Quick Practice"
        case .freestyle:
            return "Start Freestyle Session"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PracticeOptionCardView(
            option: .guided,
            title: "Guided Practice",
            description: "Follow your routine with structured sessions",
            isEnabled: true,
            onTap: { print("Guided tapped") } // Release OK - Preview
        )
        
        PracticeOptionCardView(
            option: .quick,
            title: "Quick Practice",
            description: "Jump into any method for quick practice",
            isEnabled: true,
            onTap: { print("Quick tapped") } // Release OK - Preview
        )
        
        PracticeOptionCardView(
            option: .guided,
            title: "Guided Practice",
            description: "Follow your routine with structured sessions",
            isEnabled: false,
            onTap: { print("Disabled guided tapped") } // Release OK - Preview
        )
        
        PracticeOptionCardView(
            option: .freestyle,
            title: "Freestyle Practice",
            description: "Practice freely without time constraints",
            isEnabled: true,
            onTap: { print("Freestyle tapped") } // Release OK - Preview
        )
    }
    .padding()
}