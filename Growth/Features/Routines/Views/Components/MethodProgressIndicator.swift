//
//  MethodProgressIndicator.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// Displays method progress and total session time remaining
struct MethodProgressIndicator: View {
    // MARK: - Properties
    
    let currentMethod: Int
    let totalMethods: Int
    let totalTimeRemaining: Int
    let sessionProgress: Double
    let isTimerRunning: Bool
    
    // MARK: - Environment
    
    @EnvironmentObject var navigationContext: NavigationContext
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            // Method progress text
            HStack {
                Text("Method \(currentMethod) of \(totalMethods)")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("TextColor"))
                
                Spacer()
                
                // Total time remaining
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                    Text(formatTime(totalTimeRemaining))
                        .font(AppTheme.Typography.gravityBook(14))
                }
                .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // Visual progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("GrowthGreen"))
                        .frame(width: geometry.size.width * sessionProgress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: sessionProgress)
                }
            }
            .frame(height: 8)
            
            // Method dots indicator
            HStack(spacing: 8) {
                ForEach(1...totalMethods, id: \.self) { methodNumber in
                    Circle()
                        .fill(methodNumber <= currentMethod ? Color("GrowthGreen") : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color("GrowthGreen"), lineWidth: methodNumber == currentMethod ? 2 : 0)
                                .frame(width: 12, height: 12)
                        )
                        .animation(.easeInOut(duration: 0.2), value: currentMethod)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("GrowthBackgroundLight"))
        )
        .appleIntelligenceGlow(
            isActive: isTimerRunning,
            cornerRadius: 12,
            intensity: 0.6
        )
        .onAppear {
            // Update navigation context
            navigationContext.updateMethodProgress(to: currentMethod)
        }
        .onChangeCompat(of: currentMethod) { newValue in
            // Update navigation context when method changes
            navigationContext.updateMethodProgress(to: newValue)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%dh %dm", hours, remainingMinutes)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        MethodProgressIndicator(
            currentMethod: 2,
            totalMethods: 3,
            totalTimeRemaining: 1320, // 22 minutes
            sessionProgress: 0.33,
            isTimerRunning: false
        )
        .environmentObject(NavigationContext())
        .padding()
        
        MethodProgressIndicator(
            currentMethod: 3,
            totalMethods: 5,
            totalTimeRemaining: 480, // 8 minutes
            sessionProgress: 0.6,
            isTimerRunning: true
        )
        .environmentObject(NavigationContext())
        .padding()
    }
}