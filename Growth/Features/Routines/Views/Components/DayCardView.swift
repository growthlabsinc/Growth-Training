//
//  DayCardView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI
import Foundation  // For Logger

/// A card view representing a single day in a routine schedule
struct DayCardView: View {
    // MARK: - Properties
    
    let daySchedule: DaySchedule
    @Binding var isExpanded: Bool
    let isToday: Bool
    @State private var methods: [GrowthMethod] = []
    @State private var isLoading: Bool = false
    
    private let growthMethodService = GrowthMethodService.shared
    
    // MARK: - Computed Properties
    
    /// Determine the practice type based on day name
    private var practiceType: PracticeType {
        let dayNameLower = daySchedule.dayName.lowercased()
        
        if daySchedule.isRestDay {
            return .rest
        } else if dayNameLower.contains("heavy") {
            return .heavy
        } else if dayNameLower.contains("moderate") {
            return .moderate
        } else if dayNameLower.contains("light") {
            return .light
        } else {
            // Default based on method count
            let methodCount = daySchedule.methodIds?.count ?? 0
            if methodCount >= 3 {
                return .heavy
            } else if methodCount == 2 {
                return .moderate
            } else {
                return .light
            }
        }
    }
    
    /// Color for the day card based on practice type
    private var cardColor: Color {
        switch practiceType {
        case .heavy:
            return Color("GrowthGreen")
        case .moderate:
            return Color("BrightTeal")
        case .light:
            return Color("MintGreen")
        case .rest:
            return Color("PaleGreen")
        }
    }
    
    /// Text color for day number to ensure visibility
    private var dayNumberTextColor: Color {
        // Always use white text for better contrast
        return .white
    }
    
    /// Background color for the day number circle
    private var dayNumberBackgroundColor: Color {
        switch practiceType {
        case .heavy:
            return .green
        case .moderate:
            return .teal
        case .light:
            return .mint
        case .rest:
            return .orange
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            cardHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardBackground)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            
            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(daySchedule.dayName), \(practiceType.accessibilityLabel)")
        .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")
        .onAppear {
            if !daySchedule.isRestDay {
                loadMethods()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var cardHeader: some View {
        HStack(spacing: 12) {
            // Day number - smaller to give more space to content
            Text("\(daySchedule.dayNumber)")
                .font(AppTheme.Typography.gravityBoldFont(20))
                .foregroundColor(dayNumberTextColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(dayNumberBackgroundColor)
                )
            
            // Content area with flexible space
            VStack(alignment: .leading, spacing: 4) {
                // Day name with Today indicator if applicable
                HStack(spacing: 6) {
                    Text(daySchedule.dayName)
                        .font(AppTheme.Typography.gravitySemibold(15))
                        .foregroundColor(Color("TextColor"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8) // Allow text to scale down if needed
                    
                    if isToday {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color("GrowthGreen"))
                                .frame(width: 5, height: 5)
                            Text("Today")
                                .font(AppTheme.Typography.gravitySemibold(10))
                                .foregroundColor(Color("GrowthGreen"))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color("GrowthGreen").opacity(0.15))
                        )
                    }
                    
                    Spacer()
                }
                
                // Show method count and duration summary
                HStack(spacing: 8) {
                    if daySchedule.methods.count > 0 {
                        Text("\(daySchedule.methods.count) method\(daySchedule.methods.count == 1 ? "" : "s")")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                        
                        Text("•")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                        
                        // Calculate total duration for this day
                        let totalMinutes = daySchedule.methods.reduce(0) { $0 + $1.duration }
                        Text("\(totalMinutes) min")
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                    } else {
                        Text(daySchedule.description)
                            .font(AppTheme.Typography.gravityBook(12))
                            .foregroundColor(Color("TextSecondaryColor"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side content - more compact
            HStack(spacing: 8) {
                VStack(spacing: 6) {
                    // Method count badge or rest indicator
                    if daySchedule.isRestDay {
                        RestDayBadge()
                    } else if let methodCount = daySchedule.methodIds?.count {
                        MethodCountBadge(count: methodCount)
                    }
                    
                    // Intensity indicator
                    IntensityIndicator(practiceType: practiceType)
                }
                
                // Chevron indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color("GrowthBackgroundLight"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isExpanded ? cardColor : Color.clear, lineWidth: 2)
            )
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal)
            
            if daySchedule.isRestDay {
                RestDayContent(daySchedule: daySchedule)
                    .padding()
            } else {
                methodsList
                    .padding()
            }
        }
        .background(Color("GrowthBackgroundLight").opacity(0.5))
    }
    
    private var methodsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading methods...")
                        .font(AppTheme.Typography.gravityBook(13))
                        .foregroundColor(Color("TextSecondaryColor"))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if methods.isEmpty {
                Text("No methods scheduled")
                    .font(AppTheme.Typography.gravityBook(13))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .padding()
            } else {
                // Show individual methods with names and durations
                VStack(spacing: 8) {
                    ForEach(daySchedule.methods.sorted(by: { $0.order < $1.order })) { methodSchedule in
                        HStack(spacing: 12) {
                            // Method number circle
                            ZStack {
                                Circle()
                                    .fill(Color("GrowthGreen").opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Text("\(methodSchedule.order + 1)")
                                    .font(AppTheme.Typography.gravitySemibold(14))
                                    .foregroundColor(Color("GrowthGreen"))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if let method = methods.first(where: { $0.id == methodSchedule.methodId }) {
                                    Text(method.title)
                                        .font(AppTheme.Typography.bodyFont())
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 8) {
                                        Label("\(methodSchedule.duration) min", systemImage: "clock")
                                            .font(AppTheme.Typography.captionFont())
                                            .foregroundColor(.secondary)
                                        
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        
                                        Text("Stage \(method.stage)")
                                            .font(AppTheme.Typography.captionFont())
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("Loading...")
                                        .font(AppTheme.Typography.bodyFont())
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
            }
            
            if let notes = daySchedule.additionalNotes {
                Text(notes)
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadMethods() {
        guard !daySchedule.methods.isEmpty else { return }
        
        isLoading = true
        
        Task {
            var loadedMethods: [GrowthMethod] = []
            
            for methodSchedule in daySchedule.methods {
                do {
                    let method = try await withCheckedThrowingContinuation { continuation in
                        growthMethodService.fetchMethod(withId: methodSchedule.methodId) { result in
                            continuation.resume(with: result)
                        }
                    }
                    loadedMethods.append(method)
                } catch {
                    Logger.error("Failed to load method \(methodSchedule.methodId): \(error)")
                }
            }
            
            await MainActor.run {
                self.methods = loadedMethods
                self.isLoading = false
            }
        }
    }
}

// MARK: - Supporting Types

// MARK: - Supporting Views

struct MethodCountBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "list.bullet")
                .font(.system(size: 10))
            Text("\(count)")
                .font(AppTheme.Typography.gravitySemibold(12))
        }
        .foregroundColor(Color("GrowthGreen"))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color("GrowthGreen").opacity(0.15))
        )
    }
}

struct RestDayBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "leaf")
                .font(.system(size: 10))
            Text("Rest")
                .font(AppTheme.Typography.gravitySemibold(12))
        }
        .foregroundColor(Color("PaleGreen"))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color("PaleGreen").opacity(0.15))
        )
    }
}

struct RestDayContent: View {
    let daySchedule: DaySchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .font(AppTheme.Typography.title2Font())
                    .foregroundColor(Color("PaleGreen"))
                Text("Recovery Day")
                    .font(AppTheme.Typography.gravitySemibold(16))
                    .foregroundColor(Color("TextColor"))
            }
            
            Text(daySchedule.description)
                .font(AppTheme.Typography.gravityBook(14))
                .foregroundColor(Color("TextSecondaryColor"))
            
            if let notes = daySchedule.additionalNotes {
                Text(notes)
                    .font(AppTheme.Typography.gravityBook(13))
                    .foregroundColor(Color("TextSecondaryColor"))
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DayCardView(
            daySchedule: DaySchedule(
                id: "d1",
                dayNumber: 1,
                dayName: "Day 1: Heavy Training",
                description: "Intense session with multiple methods",
                methodIds: ["m1", "m2", "m3"],
                isRestDay: false,
                additionalNotes: nil
            ),
            isExpanded: .constant(false),
            isToday: false
        )
        
        DayCardView(
            daySchedule: DaySchedule(
                id: "d4",
                dayNumber: 4,
                dayName: "Day 4: Rest & Recovery",
                description: "Focus on recovery and light stretching",
                methodIds: nil,
                isRestDay: true,
                additionalNotes: "Stay hydrated and get plenty of sleep"
            ),
            isExpanded: .constant(true),
            isToday: true
        )
    }
    .padding()
}