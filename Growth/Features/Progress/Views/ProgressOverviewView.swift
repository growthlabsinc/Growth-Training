//
//  ProgressOverviewView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// Main overview dashboard for the Progress tab
struct ProgressOverviewView: View {
    /// Progress view model containing overview data
    @ObservedObject var viewModel: ProgressViewModel
    
    /// Navigation actions
    let onViewCalendar: () -> Void
    let onViewStats: () -> Void
    let onViewGains: () -> Void
    
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Layout.spacingL) {
                // Subtitle text
                Text("Track your growth journey and celebrate your progress")
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Main content based on loading state
                if viewModel.overviewData.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.overviewData.errorMessage {
                    errorView(errorMessage)
                } else {
                    overviewContent
                }
            }
            .padding(.horizontal, AppTheme.Layout.spacingM)
            .padding(.vertical, AppTheme.Layout.spacingM)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await refreshData()
        }
        .onAppear {
            // Don't refresh here as ProgressTabView already calls fetchLoggedDates
        }
    }
    
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        VStack(spacing: AppTheme.Layout.spacingL) {
            // Contextual insights
            if !viewModel.overviewData.insights.isEmpty {
                insightsSection
            }
            
            // Today's routines
            TodayRoutinesCard(
                viewModel: viewModel
            )
            
            // Statistics highlights
            StatsHighlightView(
                statistics: viewModel.overviewData.statistics,
                onViewDetails: onViewStats
            )
            
            // Gains highlights
            GainsHighlightCard(
                onViewGains: onViewGains
            )
            
            // Motivational footer
            motivationalFooter
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(spacing: AppTheme.Layout.spacingM) {
            ForEach(viewModel.overviewData.insights.prefix(3)) { insight in
                InsightCardView(
                    insight: insight,
                    onDismiss: {
                        viewModel.dismissInsight(insight.id)
                    },
                    onAction: {
                        handleInsightAction(insight)
                    }
                )
                .transition(.asymmetric(
                    insertion: .slide,
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overviewData.insights)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppTheme.Layout.spacingL) {
            ProgressView()
                .scaleEffect(1.5)
                .frame(height: 100)
            
            Text("Loading your progress...")
                .font(AppTheme.Typography.gravityBook(16))
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        CardView {
            VStack(spacing: AppTheme.Layout.spacingM) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("ErrorColor"))
                
                Text("Unable to Load Progress")
                    .font(AppTheme.Typography.gravityBoldFont(16))
                    .foregroundColor(Color("TextColor"))
                
                Text(message)
                    .font(AppTheme.Typography.gravityBook(14))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
                
                Button("Try Again") {
                    viewModel.refreshOverviewData()
                }
                .font(AppTheme.Typography.gravitySemibold(14))
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Layout.spacingL)
                .padding(.vertical, AppTheme.Layout.spacingS)
                .background(Color("GrowthGreen"))
                .cornerRadius(AppTheme.Layout.cornerRadiusM)
            }
            .padding(AppTheme.Layout.spacingL)
        }
    }
    
    // MARK: - Motivational Footer
    
    private var motivationalFooter: some View {
        CardView(
            backgroundColor: Color("GrowthGreen").opacity(0.05),
            borderColor: Color("GrowthGreen").opacity(0.2)
        ) {
            HStack(spacing: AppTheme.Layout.spacingM) {
                Image(systemName: "heart.fill")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(Color("GrowthGreen"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(motivationalMessage)
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Keep up the great work!")
                        .font(AppTheme.Typography.gravityBook(12))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    
    /// Motivational message based on recent activity
    private var motivationalMessage: String {
        let stats = viewModel.overviewData.statistics
        let totalSessions = stats.first(where: { $0.title == "Total Sessions" })?.value ?? "0"
        
        if Int(totalSessions) ?? 0 > 0 {
            return "You're making excellent progress!"
        } else {
            return "Ready to start your growth journey?"
        }
    }
    
    // MARK: - Helper Methods
    
    
    /// Refresh data
    @MainActor
    private func refreshData() async {
        viewModel.fetchLoggedDates()
    }
    
    /// Handle action from insight card
    private func handleInsightAction(_ insight: ProgressInsight) {
        switch insight.type {
        case .trendNegative, .inactivityWarning:
            // Navigate to practice tab
            NotificationCenter.default.post(name: .switchToPracticeTab, object: nil)
        case .adherenceLow:
            // Navigate to routines tab
            NotificationCenter.default.post(name: .switchToRoutinesTab, object: nil)
        default:
            // For positive insights, might navigate to detailed stats
            onViewStats()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ProgressOverviewView(
            viewModel: ProgressViewModel(),
            onViewCalendar: { print("View calendar") }, // Release OK - Preview
            onViewStats: { print("View stats") }, // Release OK - Preview
            onViewGains: { print("View gains") } // Release OK - Preview
        )
    }
}