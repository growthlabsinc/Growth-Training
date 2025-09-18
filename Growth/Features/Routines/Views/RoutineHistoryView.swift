//
//  RoutineHistoryView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI
import FirebaseAuth

struct RoutineHistoryView: View {
    @ObservedObject var routinesViewModel: RoutinesViewModel
    @StateObject private var sessionHistoryVM = SessionHistoryViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingSessionDetail: SessionLog? = nil
    
    init(routinesViewModel: RoutinesViewModel) {
        self.routinesViewModel = routinesViewModel
    }
    
    var filteredSessions: [SessionLog] {
        sessionHistoryVM.sessionLogs
            .filter { $0.startTime >= selectedTimeRange.startDate }
            .sorted { $0.startTime > $1.startTime }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color("GrowthBackgroundLight")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Time range selector
                timeRangeSelector
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                
                // Content
                if sessionHistoryVM.isLoading {
                    loadingView
                } else if let error = sessionHistoryVM.errorMessage {
                    errorView(message: error)
                } else if filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
        }
        .onAppear {
            sessionHistoryVM.loadData()
        }
        .sheet(item: $showingSessionDetail) { session in
            NavigationView {
                SessionDetailView(
                    sessionLog: session,
                    growthMethod: session.methodId != nil ? sessionHistoryVM.growthMethods[session.methodId!] : nil
                )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Session History")
                .font(AppTheme.Typography.gravitySemibold(24))
                .foregroundColor(AppTheme.Colors.text)
            
            Text("\(filteredSessions.count) sessions logged")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding()
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTimeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(selectedTimeRange == range ? .white : AppTheme.Colors.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeRange == range ? Color("GrowthGreen") : Color("BackgroundColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedTimeRange == range ? Color.clear : Color("GrowthNeutralGray").opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredSessions) { session in
                    SessionHistoryCard(
                        session: session,
                        methodName: sessionHistoryVM.getMethodName(methodId: session.methodId),
                        action: {
                            showingSessionDetail = session
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color("GrowthGreen"))
            
            Text("Loading session history...")
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("ErrorColor"))
            
            Text("Unable to load sessions")
                .font(AppTheme.Typography.gravitySemibold(18))
                .foregroundColor(AppTheme.Colors.text)
            
            Text(message)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                sessionHistoryVM.loadData()
            } label: {
                Text("Try Again")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color("GrowthGreen"))
                    .cornerRadius(12)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(Color("GrowthGreen").opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Sessions Yet")
                    .font(AppTheme.Typography.gravitySemibold(20))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text(selectedTimeRange == .all ? 
                     "Start practicing to see your history here" :
                     "No sessions found for \(selectedTimeRange.rawValue.lowercased())")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if selectedTimeRange != .all {
                Button {
                    selectedTimeRange = .all
                } label: {
                    Text("View All Sessions")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(Color("GrowthGreen"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("GrowthGreen"), lineWidth: 1.5)
                        )
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Session History Card

struct SessionHistoryCard: View {
    let session: SessionLog
    let methodName: String
    let action: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d" // e.g., "Mon, Jan 1"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Date indicator
                VStack(spacing: 4) {
                    Text(session.startTime.formatted(.dateTime.weekday(.abbreviated)))
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text(session.startTime.formatted(.dateTime.day()))
                        .font(AppTheme.Typography.gravitySemibold(20))
                        .foregroundColor(Color("GrowthGreen"))
                    
                    Text(session.startTime.formatted(.dateTime.month(.abbreviated)))
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(width: 50)
                .padding(.vertical, 8)
                .background(Color("GrowthGreen").opacity(0.1))
                .cornerRadius(8)
                
                // Session details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(methodName)
                            .font(AppTheme.Typography.gravitySemibold(16))
                            .foregroundColor(AppTheme.Colors.text)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(session.duration) min")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(Color("GrowthGreen"))
                    }
                    
                    HStack(spacing: 16) {
                        Label(timeFormatter.string(from: session.startTime), 
                              systemImage: "clock.fill")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if let intensity = session.intensity {
                            Label("Intensity: \(intensity)/10", systemImage: "flame.fill")
                                .font(AppTheme.Typography.captionFont())
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        // Mood indicator
                        moodIcon(for: session.moodAfter)
                            .font(AppTheme.Typography.bodyFont())
                    }
                    
                    if let notes = session.userNotes, !notes.isEmpty {
                        Text(notes)
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
            .background(Color("BackgroundColor"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func moodIcon(for mood: Mood) -> some View {
        switch mood {
        case .veryPositive:
            return Image(systemName: "face.smiling.fill")
                .foregroundColor(.green)
        case .positive:
            return Image(systemName: "face.smiling")
                .foregroundColor(.green.opacity(0.8))
        case .neutral:
            return Image(systemName: "face.dashed")
                .foregroundColor(.gray)
        case .negative:
            return Image(systemName: "face.frowning")
                .foregroundColor(.orange)
        case .veryNegative:
            return Image(systemName: "face.frowning.fill")
                .foregroundColor(.red)
        }
    }
}

#Preview {
    RoutineHistoryView(routinesViewModel: RoutinesViewModel(userId: "preview"))
}