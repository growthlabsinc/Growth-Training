//
//  BreadcrumbView.swift
//  Growth
//
//  Created by Developer on 5/30/25.
//

import SwiftUI

/// A view that displays breadcrumb navigation context
struct BreadcrumbView: View {
    // MARK: - Environment
    @EnvironmentObject var navigationContext: NavigationContext
    
    // MARK: - State
    @State private var isVisible: Bool = false
    
    // MARK: - Properties
    let style: BreadcrumbStyle
    
    // MARK: - Types
    enum BreadcrumbStyle {
        case practice
        case routine
        case progress
        
        var backgroundColor: Color {
            switch self {
            case .practice:
                return Color("GrowthGreen").opacity(0.1)
            case .routine:
                return Color("BrightTeal").opacity(0.1)
            case .progress:
                return Color("MintGreen").opacity(0.1)
            }
        }
        
        var textColor: Color {
            switch self {
            case .practice:
                return Color("GrowthGreen")
            case .routine:
                return Color("BrightTeal")
            case .progress:
                return Color("MintGreen")
            }
        }
    }
    
    // MARK: - Initialization
    init(style: BreadcrumbStyle = .practice) {
        self.style = style
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if navigationContext.showBreadcrumb,
               let breadcrumbText = navigationContext.breadcrumbText {
                HStack(spacing: 8) {
                    // Icon
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(style.textColor)
                    
                    // Breadcrumb text
                    Text(breadcrumbText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(style.backgroundColor)
                )
                .padding(.horizontal)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isVisible)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current position: \(breadcrumbText)")
                .onAppear {
                    withAnimation {
                        isVisible = true
                    }
                }
                .onChangeCompat(of: breadcrumbText) { newValue in
                    // Animate changes
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isVisible = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isVisible = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var iconName: String {
        switch style {
        case .practice:
            return "figure.strengthtraining.traditional"
        case .routine:
            return "calendar.day.timeline.left"
        case .progress:
            return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - View Extension
extension View {
    /// Adds a breadcrumb view to the top of the view
    func breadcrumb(style: BreadcrumbView.BreadcrumbStyle = .practice) -> some View {
        VStack(spacing: 0) {
            BreadcrumbView(style: style)
                .padding(.top, 8)
            
            self
        }
    }
}

// MARK: - Preview
#Preview("Practice Breadcrumb") {
    let context = NavigationContext()
    context.setupRoutineContext(
        dayNumber: 5,
        dayName: "Day 5: Heavy Training",
        totalMethods: 3,
        routineId: "routine123"
    )
    
    return VStack {
        BreadcrumbView(style: .practice)
            .environmentObject(context)
        
        Spacer()
    }
}

#Preview("Routine Breadcrumb") {
    let context = NavigationContext()
    context.setupRoutineContext(
        dayNumber: 2,
        dayName: "Day 2",
        totalMethods: 1,
        routineId: "routine123"
    )
    
    return VStack {
        BreadcrumbView(style: .routine)
            .environmentObject(context)
        
        Spacer()
    }
}