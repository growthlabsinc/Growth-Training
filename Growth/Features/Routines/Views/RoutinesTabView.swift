//
//  RoutinesTabView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

struct RoutinesTabView: View {
    @ObservedObject var routinesViewModel: RoutinesViewModel
    @State private var selectedSection: RoutineSection = .current
    @State private var showRoutineSelection = false
    
    enum RoutineSection: String, CaseIterable {
        case current = "Current"
        case browse = "Browse"
        case guide = "Guide"
        case history = "History"
    }
    
    init(routinesViewModel: RoutinesViewModel) {
        self.routinesViewModel = routinesViewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom pill navigation
            CustomRoutineNavigation(selectedSection: $selectedSection)
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 8)
            
            // Content based on selected section
            TabView(selection: $selectedSection) {
                CurrentRoutineView(
                    routinesViewModel: routinesViewModel,
                    showRoutineSelection: $showRoutineSelection
                )
                    .tag(RoutineSection.current)
                
                BrowseRoutinesView(routinesViewModel: routinesViewModel)
                    .tag(RoutineSection.browse)
                
                MethodsGuideView()
                    .tag(RoutineSection.guide)
                
                RoutineHistoryView(routinesViewModel: routinesViewModel)
                    .tag(RoutineSection.history)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .background(Color(.systemGroupedBackground))
        .customNavigationHeader(title: "Routines")
        .navigationDestination(isPresented: $showRoutineSelection) {
            RoutinesListView(viewModel: routinesViewModel)
        }
    }
}

// MARK: - Custom Navigation Component

struct CustomRoutineNavigation: View {
    @Binding var selectedSection: RoutinesTabView.RoutineSection
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(RoutinesTabView.RoutineSection.allCases, id: \.self) { section in
                RoutinePillNavigationItem(
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

struct RoutinePillNavigationItem: View {
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
                                .matchedGeometryEffect(id: "selectedRoutinePill", in: namespace)
                                .shadow(color: Color("GrowthGreen").opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                )
                .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        RoutinesTabView(routinesViewModel: RoutinesViewModel(userId: "preview"))
    }
}