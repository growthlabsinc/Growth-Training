//
//  ProgressTabView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI
import FirebaseAuth

struct ProgressTabView: View {
    @State private var selectedSection: ProgressSection = .overview
    @StateObject private var progressViewModel = ProgressViewModel()
    @State private var selectedDate: Date? = nil
    @State private var showQuickPracticeTimer = false
    @State private var detailDate: DrillDownDate? = nil
    
    enum ProgressSection: String, CaseIterable {
        case overview = "Overview"
        case calendar = "Calendar"
        case stats = "Stats"
        case gains = "Gains"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick Session Button
            quickSessionButton
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            // Custom pill navigation
            CustomProgressNavigation(selectedSection: $selectedSection)
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 8)
            
            // Content based on selected section
            TabView(selection: $selectedSection) {
                ProgressOverviewView(
                    viewModel: progressViewModel,
                    onViewCalendar: { selectedSection = .calendar },
                    onViewStats: { selectedSection = .stats },
                    onViewGains: { selectedSection = .gains }
                )
                .tag(ProgressSection.overview)
                
                PremiumCalendarProgressView(viewModel: progressViewModel, selectedDate: $selectedDate)
                    .padding(.top, 40)
                    .tag(ProgressSection.calendar)
                
                DetailedProgressStatsView(viewModel: progressViewModel)
                    .tag(ProgressSection.stats)
                
                GainsProgressView()
                    .tag(ProgressSection.gains)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .background(Color(.systemGroupedBackground))
        .customNavigationHeader(title: "Progress")
        .onAppear {
            // Refresh progress data when tab appears
            progressViewModel.fetchLoggedDates()
        }
        .fullScreenCover(isPresented: $showQuickPracticeTimer) {
            NavigationStack {
                QuickPracticeTimerView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToProgressCalendar"))) { _ in
            selectedSection = .calendar
        }
        .onChangeCompat(of: selectedDate) { newValue in
            if let date = newValue {
                detailDate = DrillDownDate(date: date)
            }
        }
        .sheet(item: $detailDate) { wrapper in
            DailyDrillDownView(date: wrapper.date, sessions: progressViewModel.sessions(on: wrapper.date))
                .onDisappear {
                    selectedDate = nil
                }
        }
    }
    
    // MARK: - Quick Session Button
    private var quickSessionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showQuickPracticeTimer = true
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color("GrowthGreen").opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color("GrowthGreen"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Session")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.label))
                    
                    Text("Start a standalone practice")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.separator).opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(showQuickPracticeTimer ? 0.98 : 1.0)
    }
}

// MARK: - Custom Navigation Component

struct CustomProgressNavigation: View {
    @Binding var selectedSection: ProgressTabView.ProgressSection
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(ProgressTabView.ProgressSection.allCases, id: \.self) { section in
                PillNavigationItem(
                    title: section.rawValue,
                    isSelected: selectedSection == section,
                    namespace: namespace,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSection = section
                        }
                    }
                )
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct PillNavigationItem: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.gravitySemibold(13))
                .foregroundColor(isSelected ? .white : Color("TextSecondaryColor"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(Color("GrowthGreen"))
                                .matchedGeometryEffect(id: "selectedProgressPill", in: namespace)
                                .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                )
                .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Color extension removed - using the one from ColorExtensions.swift

#Preview {
    NavigationStack {
        ProgressTabView()
    }
}