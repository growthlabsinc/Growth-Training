//
//  AchievementHighlightView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// Achievement showcase component for the progress overview
struct AchievementHighlightView: View {
    /// Achievements to display
    let achievements: [AchievementHighlight]
    
    /// Action to perform when user taps to view all achievements
    let onViewAchievements: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.spacingM) {
                // Header
                headerSection
                
                // Achievements content
                if achievements.isEmpty {
                    emptyStateView
                } else {
                    achievementsContent
                }
                
                // View all achievements button
                viewAllButton
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievements")
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(Color("TextColor"))
                
                Text("Your progress milestones")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            Spacer()
            
            Image(systemName: "trophy.fill")
                .font(AppTheme.Typography.title2Font())
                .foregroundColor(Color("GrowthGreen"))
        }
    }
    
    // MARK: - Achievements Content
    
    private var achievementsContent: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            ForEach(achievements.prefix(3)) { achievement in
                AchievementRowView(achievement: achievement)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle")
                .font(.system(size: 40))
                .foregroundColor(Color("GrowthNeutralGray"))
            
            Text("Start practicing to unlock achievements!")
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Layout.spacingL)
    }
    
    // MARK: - View All Button
    
    private var viewAllButton: some View {
        Button(action: onViewAchievements) {
            HStack {
                Text("View All Achievements")
                    .font(AppTheme.Typography.gravitySemibold(14))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(AppTheme.Typography.captionFont())
            }
            .foregroundColor(Color("GrowthGreen"))
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Achievement Row View

/// Individual achievement display row
private struct AchievementRowView: View {
    let achievement: AchievementHighlight
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacingM) {
            // Achievement icon
            achievementIcon
            
            // Achievement details
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(AppTheme.Typography.gravitySemibold(14))
                    .foregroundColor(Color("TextColor"))
                
                Text(achievement.description)
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .lineLimit(2)
                
                // Progress bar for unearned achievements
                if !achievement.isEarned, let progress = achievement.progress {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(achievement.colorTheme)))
                        .frame(height: 4)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Status indicator
            statusIndicator
        }
        .padding(AppTheme.Layout.spacingM)
        .background(achievementBackground)
        .cornerRadius(AppTheme.Layout.cornerRadiusM)
    }
    
    // MARK: - Achievement Icon
    
    private var achievementIcon: some View {
        Image(systemName: achievement.iconName)
            .font(AppTheme.Typography.title2Font())
            .foregroundColor(Color(achievement.colorTheme))
            .frame(width: 32, height: 32)
            .background(Color(achievement.colorTheme).opacity(0.1))
            .cornerRadius(8)
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        Group {
            if achievement.isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .font(AppTheme.Typography.title3Font())
                    .foregroundColor(Color(achievement.colorTheme))
            } else if let progress = achievement.progress {
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(AppTheme.Typography.gravityBoldFont(12))
                        .foregroundColor(Color(achievement.colorTheme))
                }
            }
        }
    }
    
    // MARK: - Achievement Background
    
    private var achievementBackground: Color {
        if achievement.isEarned {
            return Color(achievement.colorTheme).opacity(0.05)
        } else {
            return Color("GrowthNeutralGray").opacity(0.05)
        }
    }
}

// MARK: - Preview

#Preview {
    let mockAchievements = [
        AchievementHighlight(
            title: "Consistent Practitioner",
            description: "Completed 7+ sessions this month",
            iconName: "star.fill",
            isEarned: true,
            earnedDate: Date(),
            colorTheme: "GrowthGreen"
        ),
        AchievementHighlight(
            title: "Time Master",
            description: "4/5 hours completed this month",
            iconName: "clock.badge.checkmark",
            isEarned: false,
            progress: 0.8,
            colorTheme: "BrightTeal"
        ),
        AchievementHighlight(
            title: "Streak Builder",
            description: "2/7 day streak achieved",
            iconName: "flame",
            isEarned: false,
            progress: 0.28,
            colorTheme: "ErrorColor"
        )
    ]
    
    AchievementHighlightView(
        achievements: mockAchievements,
        onViewAchievements: { print("View achievements") } // Release OK - Preview
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}