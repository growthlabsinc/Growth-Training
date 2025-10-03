//
//  ContextualQuickActionsView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

struct ContextualQuickActionsView: View {
    @ObservedObject var viewModel: TodayViewViewModel
    let onStartRoutine: () -> Void
    let onQuickPractice: () -> Void
    let onLogSession: () -> Void
    let onViewProgress: () -> Void
    let onBrowseRoutines: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Quick Actions")
                    .font(AppTheme.Typography.gravityBoldFont(18))
                    .foregroundColor(Color("TextColor"))
                
                if viewModel.shouldShowQuickActions() {
                    actionsGrid
                } else {
                    loadingView
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading actions...")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(Color("TextSecondaryColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions Grid
    private var actionsGrid: some View {
        VStack(spacing: 12) {
            // Primary action (contextual)
            primaryActionButton
            
            // Secondary actions row
            HStack(spacing: 12) {
                secondaryActionButton(
                    title: "Log Session",
                    icon: "plus.circle.fill",
                    action: onLogSession
                )
                
                secondaryActionButton(
                    title: "View Progress", 
                    icon: "chart.line.uptrend.xyaxis",
                    action: onViewProgress
                )
                
                if viewModel.todayFocusState == .noRoutine {
                    secondaryActionButton(
                        title: "Browse Routines",
                        icon: "list.bullet.rectangle",
                        action: onBrowseRoutines
                    )
                }
            }
        }
    }
    
    // MARK: - Primary Action Button
    private var primaryActionButton: some View {
        Button(action: onQuickPractice) {
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .font(AppTheme.Typography.title2Font())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Session")
                        .font(AppTheme.Typography.gravitySemibold(16))
                    
                    Text("Start a standalone timer session")
                        .font(AppTheme.Typography.gravityBook(12))
                        .opacity(0.9)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(AppTheme.Typography.title2Font())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color("GrowthGreen"), Color("BrightTeal")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - Secondary Action Button
    private func secondaryActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.title3Font())
                    .foregroundColor(Color("GrowthGreen"))
                
                Text(title)
                    .font(AppTheme.Typography.gravitySemibold(12))
                    .foregroundColor(Color("TextColor"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color("GrowthGreen").opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("GrowthGreen").opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Computed Properties
    private var primaryActionIcon: String {
        switch viewModel.todayFocusState {
        case .routineDay(_):
            return "play.circle.fill"
        case .quickPractice, .noRoutine:
            return "bolt.circle.fill"
        case .restDay(_):
            return "checkmark.circle.fill"
        case .completed:
            return "plus.circle.fill"
        case .loading:
            return "clock.fill"
        }
    }
    
    private var primaryActionSubtitle: String {
        switch viewModel.todayFocusState {
        case .routineDay(let schedule):
            let methodCount = schedule.methodIds?.count ?? 0
            return "\(methodCount) method\(methodCount == 1 ? "" : "s") planned"
        case .quickPractice:
            return "Start a standalone timer session"
        case .noRoutine:
            return "Start a quick practice session"
        case .restDay(_):
            return "Track your recovery activities"
        case .completed:
            return "Add extra practice to your day"
        case .loading:
            return "Please wait..."
        }
    }
    
    private var primaryActionBackground: some View {
        switch viewModel.todayFocusState {
        case .routineDay(_):
            return LinearGradient(
                colors: [Color("GrowthGreen"), Color("BrightTeal")],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .restDay(_):
            return LinearGradient(
                colors: [Color("PaleGreen"), Color("MintGreen")],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [Color("GrowthGreen"), Color("GrowthGreen")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private func primaryAction() {
        switch viewModel.todayFocusState {
        case .routineDay(_):
            onStartRoutine()
        case .quickPractice, .noRoutine, .completed:
            onQuickPractice()
        case .restDay(_):
            onLogSession() // Log rest day as a session
        case .loading:
            break // Do nothing while loading
        }
    }
}

#Preview {
    let mockRoutinesVM = RoutinesViewModel(userId: "mock")
    let mockProgressVM = ProgressViewModel()
    let mockTodayVM = TodayViewViewModel(routinesViewModel: mockRoutinesVM, progressViewModel: mockProgressVM)
    
    return ContextualQuickActionsView(
        viewModel: mockTodayVM,
        onStartRoutine: { print("Start routine") }, // Release OK - Preview
        onQuickPractice: { print("Quick practice") }, // Release OK - Preview
        onLogSession: { print("Log session") }, // Release OK - Preview
        onViewProgress: { print("View progress") }, // Release OK - Preview
        onBrowseRoutines: { print("Browse routines") } // Release OK - Preview
    )
    .padding()
}