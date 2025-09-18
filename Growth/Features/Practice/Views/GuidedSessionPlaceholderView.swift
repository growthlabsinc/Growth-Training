//
//  GuidedSessionPlaceholderView.swift
//  Growth
//
//  Created for Practice tab guided session placeholder
//

import SwiftUI

struct GuidedSessionPlaceholderView: View {
    @EnvironmentObject var navigationContext: NavigationContext
    @State private var showQuickPracticeTimer = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                heroSection
                
                // Action Cards
                VStack(spacing: 16) {
                    // Quick Session Card
                    quickSessionCard
                    
                    // Select Routine Card
                    selectRoutineCard
                }
                .padding(.horizontal)
                
                // Info Section
                infoSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showQuickPracticeTimer) {
            QuickPracticeTimerView()
        }
    }
    
    // MARK: - Subviews
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color("PaleGreen").opacity(0.3))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50))
                    .foregroundColor(Color("GrowthGreen"))
            }
            
            // Title and subtitle
            VStack(spacing: 12) {
                Text("No Active Routine")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextColor"))
                
                Text("Start with a quick session or select a routine to unlock guided practice")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(Color("TextSecondaryColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 40)
    }
    
    private var quickSessionCard: some View {
        Button(action: {
            showQuickPracticeTimer = true
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("GrowthGreen").opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "bolt.fill")
                        .font(AppTheme.Typography.title2Font())
                        .foregroundColor(Color("GrowthGreen"))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Practice")
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Start a standalone session")
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var selectRoutineCard: some View {
        Button(action: {
            // Switch to Routines tab
            NotificationCenter.default.post(name: .switchToRoutinesTab, object: nil)
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("BrightTeal").opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "list.bullet.rectangle")
                        .font(AppTheme.Typography.title2Font())
                        .foregroundColor(Color("BrightTeal"))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Browse Routines")
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Select a structured program")
                        .font(AppTheme.Typography.subheadlineFont())
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.bodyFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var infoSection: some View {
        VStack(spacing: 24) {
            // Divider
            Rectangle()
                .fill(Color("TextSecondaryColor").opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 40)
            
            // Benefits
            VStack(spacing: 16) {
                Text("Why Choose a Routine?")
                    .font(AppTheme.Typography.headlineFont())
                    .foregroundColor(Color("TextColor"))
                
                VStack(alignment: .leading, spacing: 12) {
                    benefitRow(icon: "chart.line.uptrend.xyaxis", 
                              text: "Progressive overload for consistent gains")
                    
                    benefitRow(icon: "calendar", 
                              text: "Structured schedule with rest days")
                    
                    benefitRow(icon: "sparkles", 
                              text: "Personalized guidance based on your level")
                    
                    benefitRow(icon: "trophy", 
                              text: "Track progress and earn achievements")
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.top, 24)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(AppTheme.Typography.bodyFont())
                .foregroundColor(Color("GrowthGreen"))
                .frame(width: 24)
            
            Text(text)
                .font(AppTheme.Typography.subheadlineFont())
                .foregroundColor(Color("TextSecondaryColor"))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// Quick Session Menu Sheet
struct QuickSessionMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationContext: NavigationContext
    @State private var selectedMethod: GrowthMethod?
    @State private var showTimer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Method")
                        .font(AppTheme.Typography.headlineFont())
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("GrowthGreen"))
                }
                .padding()
                
                // Method List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sampleMethods) { method in
                            methodRow(method)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedMethod) { method in
            NavigationView {
                TimerView(growthMethod: method)
            }
            .navigationViewStyle(.stack)
        }
    }
    
    private func methodRow(_ method: GrowthMethod) -> some View {
        Button(action: {
            navigationContext.setupQuickPracticeContext()
            selectedMethod = method
            dismiss()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(AppTheme.Typography.headlineFont())
                        .foregroundColor(Color("TextColor"))
                    
                    if let duration = method.estimatedDurationMinutes {
                        Text("\(duration) minutes")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(Color("TextSecondaryColor"))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Sample methods for quick practice
    private var sampleMethods: [GrowthMethod] {
        return [
            GrowthMethod(
                id: "quick1",
                stage: 1,
                classification: "Beginner",
                title: "Angion Method 1.0",
                methodDescription: "Basic blood flow enhancement",
                instructionsText: "Start with basic movements",
                estimatedDurationMinutes: 20,
                categories: ["Vascular"]
            ),
            GrowthMethod(
                id: "quick2",
                stage: 1,
                classification: "Intermediate",
                title: "Soft Clamping",
                methodDescription: "Girth focused exercise",
                instructionsText: "Focus on expansion",
                estimatedDurationMinutes: 15,
                categories: ["Girth"]
            ),
            GrowthMethod(
                id: "quick3",
                stage: 1,
                classification: "Beginner",
                title: "Stretching Routine",
                methodDescription: "Length focused stretches",
                instructionsText: "Gentle stretching routine",
                estimatedDurationMinutes: 10,
                categories: ["Length"]
            )
        ]
    }
}

#Preview {
    NavigationStack {
        GuidedSessionPlaceholderView()
    }
    .environmentObject(NavigationContext())
}

