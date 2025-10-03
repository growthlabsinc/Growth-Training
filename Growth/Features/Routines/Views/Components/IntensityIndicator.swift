//
//  IntensityIndicator.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// Visual indicator for practice intensity
struct IntensityIndicator: View {
    // MARK: - Properties
    
    let practiceType: PracticeType
    @State private var isAnimating: Bool = false
    
    // MARK: - Computed Properties
    
    private var indicatorColor: Color {
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
    
    private var fillLevel: Int {
        switch practiceType {
        case .heavy:
            return 3
        case .moderate:
            return 2
        case .light:
            return 1
        case .rest:
            return 0
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < fillLevel ? indicatorColor : Color.gray.opacity(0.2))
                    .frame(width: 4, height: 12 + CGFloat(index * 4))
                    .scaleEffect(isAnimating && index < fillLevel ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.3)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(practiceType) intensity")
    }
}

// MARK: - Alternative Circular Design

struct CircularIntensityIndicator: View {
    let practiceType: PracticeType
    @State private var animationProgress: CGFloat = 0
    
    private var indicatorColor: Color {
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
    
    private var progress: CGFloat {
        switch practiceType {
        case .heavy:
            return 1.0
        case .moderate:
            return 0.66
        case .light:
            return 0.33
        case .rest:
            return 0.1
        }
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                .frame(width: 24, height: 24)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animationProgress)
                .stroke(indicatorColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
            
            // Center icon
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(indicatorColor)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = progress
            }
        }
    }
    
    private var iconName: String {
        switch practiceType {
        case .heavy:
            return "flame.fill"
        case .moderate:
            return "bolt.fill"
        case .light:
            return "sparkle"
        case .rest:
            return "leaf.fill"
        }
    }
}

// MARK: - Dot Intensity Indicator

struct DotIntensityIndicator: View {
    let practiceType: PracticeType
    @State private var isAnimating: Bool = false
    
    private var indicatorColor: Color {
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
    
    private var activeDots: Int {
        switch practiceType {
        case .heavy:
            return 3
        case .moderate:
            return 2
        case .light:
            return 1
        case .rest:
            return 0
        }
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < activeDots ? indicatorColor : Color.gray.opacity(0.2))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating && index < activeDots ? 1.2 : 1.0)
                    .animation(
                        Animation.spring(response: 0.3, dampingFraction: 0.6)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Bar indicators
        VStack(spacing: 10) {
            Text("Bar Indicators")
                .font(AppTheme.Typography.headlineFont())
            
            HStack(spacing: 20) {
                VStack {
                    IntensityIndicator(practiceType: PracticeType.heavy)
                    Text("Heavy").font(AppTheme.Typography.captionFont())
                }
                VStack {
                    IntensityIndicator(practiceType: PracticeType.moderate)
                    Text("Moderate").font(AppTheme.Typography.captionFont())
                }
                VStack {
                    IntensityIndicator(practiceType: PracticeType.light)
                    Text("Light").font(AppTheme.Typography.captionFont())
                }
                VStack {
                    IntensityIndicator(practiceType: PracticeType.rest)
                    Text("Rest").font(AppTheme.Typography.captionFont())
                }
            }
        }
        
        Divider()
        
        // Circular indicators
        VStack(spacing: 10) {
            Text("Circular Indicators")
                .font(AppTheme.Typography.headlineFont())
            
            HStack(spacing: 20) {
                CircularIntensityIndicator(practiceType: PracticeType.heavy)
                CircularIntensityIndicator(practiceType: PracticeType.moderate)
                CircularIntensityIndicator(practiceType: PracticeType.light)
                CircularIntensityIndicator(practiceType: PracticeType.rest)
            }
        }
        
        Divider()
        
        // Dot indicators
        VStack(spacing: 10) {
            Text("Dot Indicators")
                .font(AppTheme.Typography.headlineFont())
            
            HStack(spacing: 20) {
                DotIntensityIndicator(practiceType: PracticeType.heavy)
                DotIntensityIndicator(practiceType: PracticeType.moderate)
                DotIntensityIndicator(practiceType: PracticeType.light)
                DotIntensityIndicator(practiceType: PracticeType.rest)
            }
        }
    }
    .padding()
}