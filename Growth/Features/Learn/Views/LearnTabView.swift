//
//  LearnTabView.swift
//  Growth
//
//  Created by Developer on 6/2/25.
//

import SwiftUI

struct LearnTabView: View {
    @State private var selectedSection: LearnSection = .resources
    @EnvironmentObject var authViewModel: AuthViewModel
    
    enum LearnSection: String, CaseIterable {
        case resources = "Resources"
        case coach = "AI Coach"
        
        var icon: String {
            switch self {
            case .resources:
                return "book.fill"
            case .coach:
                return "bubble.left.and.bubble.right.fill"
            }
        }
        
        var description: String {
            switch self {
            case .resources:
                return "Browse articles and guides to support your growth journey"
            case .coach:
                return "Get personalized guidance from your AI-powered growth coach"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticky header section
            VStack(spacing: 0) {
                // Welcome header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Learning Center")
                        .font(AppTheme.Typography.gravitySemibold(24))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Expand your knowledge and get personalized guidance")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 0)
                .padding(.bottom, 20)
                
                // Selection cards
                HStack(spacing: 12) {
                    ForEach(LearnSection.allCases, id: \.self) { section in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSection = section
                            }
                        }) {
                            VStack(spacing: 12) {
                                // Icon container
                                ZStack {
                                    Circle()
                                        .fill(selectedSection == section ? Color("GrowthGreen") : Color("PaleGreen"))
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: section.icon)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(selectedSection == section ? .white : Color("GrowthGreen"))
                                }
                                
                                Text(section.rawValue)
                                    .font(AppTheme.Typography.gravitySemibold(14))
                                    .foregroundColor(Color("TextColor"))
                                
                                Text(section.description)
                                    .font(AppTheme.Typography.gravityBook(11))
                                    .foregroundColor(Color("TextSecondaryColor"))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("BackgroundColor"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedSection == section ? Color("GrowthGreen") : Color("NeutralGray").opacity(0.2), lineWidth: selectedSection == section ? 2 : 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(selectedSection == section ? 0.08 : 0.04), radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .background(
                Color(.systemGroupedBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            )
            .zIndex(1) // Ensure header stays on top
            
            // Content area - fills remaining space
            ZStack {
                // Resources View
                if selectedSection == .resources {
                    EducationalResourcesListView()
                        .environmentObject(authViewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
                
                // AI Coach View
                if selectedSection == .coach {
                    CoachChatView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedSection)
        }
        .background(Color(.systemGroupedBackground))
        .customNavigationHeader(title: "Learn")
    }
}

#Preview {
    NavigationStack {
        LearnTabView()
            .environmentObject(AuthViewModel())
    }
}