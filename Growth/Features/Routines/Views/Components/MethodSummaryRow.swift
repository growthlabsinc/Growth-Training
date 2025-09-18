//
//  MethodSummaryRow.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// Compact row displaying method summary information
struct MethodSummaryRow: View {
    // MARK: - Properties
    
    let method: GrowthMethod
    let index: Int
    @State private var isHovered: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Method number indicator
            Text("\(index)")
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color("GrowthGreen").opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Method title
                Text(method.title)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))
                    .lineLimit(1)
                
                // Method description
                Text(method.methodDescription)
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Duration
                if let duration = method.estimatedDurationMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(duration) min")
                            .font(AppTheme.Typography.gravityBook(12))
                    }
                    .foregroundColor(Color("TextSecondaryColor"))
                }
                
                // Timer configuration indicator
                if let timerConfig = method.timerConfig {
                    TimerConfigBadge(config: timerConfig)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.gray.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Method \(index): \(method.title), \(method.estimatedDurationMinutes ?? 10) minutes")
    }
}

// MARK: - Supporting Views

struct TimerConfigBadge: View {
    let config: TimerConfiguration
    
    var body: some View {
        HStack(spacing: 4) {
            if config.isCountdown == true {
                Image(systemName: "timer")
                    .font(.system(size: 10))
            }
            
            if config.hasIntervals == true {
                Image(systemName: "repeat")
                    .font(.system(size: 10))
            }
            
            Text(timerTypeText)
                .font(AppTheme.Typography.gravityBook(10))
        }
        .foregroundColor(Color("GrowthGreen"))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color("GrowthGreen").opacity(0.1))
        )
    }
    
    private var timerTypeText: String {
        if config.hasIntervals == true {
            return "Interval"
        } else if config.isCountdown == true {
            return "Timer"
        } else {
            return "Stopwatch"
        }
    }
}

// MARK: - Expanded Method Row (Alternative Design)

struct ExpandedMethodRow: View {
    let method: GrowthMethod
    let index: Int
    @State private var showDetails: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                // Method number
                Text("\(index)")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color("GrowthGreen"))
                    )
                
                // Method info
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.title)
                        .font(AppTheme.Typography.gravitySemibold(15))
                        .foregroundColor(Color("TextColor"))
                    
                    if let duration = method.estimatedDurationMinutes {
                        Text("\(duration) minutes")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                }
                
                Spacer()
                
                // Expand button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDetails.toggle()
                    }
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color("GrowthGreen"))
                }
            }
            
            // Expanded details
            if showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text(method.methodDescription)
                        .font(AppTheme.Typography.gravityBook(13))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .padding(.leading, 44) // Align with content
                    
                    if let benefits = method.benefits, !benefits.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Benefits:")
                                .font(AppTheme.Typography.gravitySemibold(12))
                                .foregroundColor(Color("GrowthGreen"))
                            
                            ForEach(benefits.prefix(3), id: \.self) { benefit in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•")
                                    Text(benefit)
                                        .font(AppTheme.Typography.gravityBook(12))
                                }
                                .foregroundColor(Color("TextSecondaryColor"))
                            }
                        }
                        .padding(.leading, 44)
                        .padding(.top, 4)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Basic method rows
        VStack(spacing: 8) {
            Text("Method Summary Rows")
                .font(AppTheme.Typography.headlineFont())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            MethodSummaryRow(
                method: GrowthMethod(
                    id: "1",
                    stage: 1,
                    title: "Angion Method 1.0",
                    methodDescription: "Basic circular movements for vascular development",
                    instructionsText: "Instructions here",
                    estimatedDurationMinutes: 15,
                    timerConfig: TimerConfiguration(
                        recommendedDurationSeconds: 900,
                        isCountdown: true,
                        hasIntervals: false
                    )
                ),
                index: 1
            )
            
            MethodSummaryRow(
                method: GrowthMethod(
                    id: "2",
                    stage: 2,
                    title: "SABRE Method",
                    methodDescription: "Side-to-side stretching technique",
                    instructionsText: "Instructions here",
                    estimatedDurationMinutes: 10,
                    timerConfig: TimerConfiguration(
                        recommendedDurationSeconds: 600,
                        isCountdown: true,
                        hasIntervals: true,
                        intervals: [
                            MethodInterval(name: "Work", durationSeconds: 30),
                            MethodInterval(name: "Rest", durationSeconds: 10)
                        ]
                    )
                ),
                index: 2
            )
        }
        
        Divider()
        
        // Expanded method row
        VStack(spacing: 8) {
            Text("Expanded Method Row")
                .font(AppTheme.Typography.headlineFont())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ExpandedMethodRow(
                method: GrowthMethod(
                    id: "3",
                    stage: 2,
                    title: "Angion Method 2.0",
                    methodDescription: "Advanced circular movements with increased intensity",
                    instructionsText: "Instructions here",
                    estimatedDurationMinutes: 20,
                    benefits: [
                        "Improved circulation",
                        "Enhanced vascular health",
                        "Increased endurance"
                    ]
                ),
                index: 3
            )
        }
    }
    .padding()
}