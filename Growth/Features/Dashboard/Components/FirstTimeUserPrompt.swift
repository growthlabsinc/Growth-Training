//
//  FirstTimeUserPrompt.swift
//  Growth
//
//  Created by Developer on 6/7/25.
//

import SwiftUI
import FirebaseAuth

/// A prompt shown to first-time users on the dashboard with personalized next action
struct FirstTimeUserPrompt: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingPrompt = true
    
    let user: User
    let onDismiss: () -> Void
    let onActionTap: () -> Void
    
    // Computed properties for personalized content
    private var promptTitle: String {
        if let practiceMode = user.preferredPracticeMode, 
           practiceMode == "routine",
           user.selectedRoutineId != nil {
            return "Ready to Start Your Routine?"
        } else if let practiceMode = user.preferredPracticeMode,
                  practiceMode == "routine" {
            return "Select Your First Routine"
        } else {
            return "Ready for Your First Session?"
        }
    }
    
    private var promptMessage: String {
        if let practiceMode = user.preferredPracticeMode,
           practiceMode == "routine",
           user.selectedRoutineId == nil {
            return "Choose a structured routine to guide your practice journey"
        } else if let initialMethod = user.initialMethodId {
            switch initialMethod {
            case "angio_pumping":
                return "Begin with Angio Pumping - a gentle starting point for your vascular health journey"
            case , "am1":
                return "Start with Angion Method 1.0 - the foundation of your growth journey"
            default:
                return "Your personalized starting point is ready"
            }
        } else if user.preferredPracticeMode == "routine" {
            return "Explore beginner-friendly routines to structure your practice"
        } else {
            return "Choose any method to begin your first practice session"
        }
    }
    
    private var actionButtonTitle: String {
        if let practiceMode = user.preferredPracticeMode, 
           practiceMode == "routine",
           user.selectedRoutineId == nil {
            return "Browse Routines"
        } else if let practiceMode = user.preferredPracticeMode, 
                  practiceMode == "routine" {
            return "View My Routine"
        } else if let initialMethod = user.initialMethodId {
            switch initialMethod {
            case "angio_pumping":
                return "Start Angio Pumping"
            case "s2s_stretch":
                return "Start S2S Stretches"
            default:
                return "Start Practice"
            }
        } else {
            return "Explore Methods"
        }
    }
    
    private var iconName: String {
        if user.preferredPracticeMode == "routine" {
            return "calendar.badge.clock"
        } else {
            return "play.circle.fill"
        }
    }
    
    var body: some View {
        if showingPrompt {
            VStack(spacing: 0) {
                // Card Content
                VStack(spacing: AppTheme.Layout.spacingL) {
                    // Header with dismiss button
                    HStack {
                        // Icon and Title
                        HStack(spacing: AppTheme.Layout.spacingM) {
                            Image(systemName: iconName)
                                .font(.system(size: 28))
                                .foregroundColor(Color("GrowthGreen"))
                            
                            Text(promptTitle)
                                .font(AppTheme.Typography.gravitySemibold(18))
                                .foregroundColor(AppTheme.Colors.text)
                        }
                        
                        Spacer()
                        
                        // Dismiss button
                        Button {
                            dismissPrompt()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color("GrowthNeutralGray").opacity(0.5))
                        }
                    }
                    
                    // Message
                    Text(promptMessage)
                        .font(AppTheme.Typography.bodyFont())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Action Button
                    Button {
                        handleActionTap()
                    } label: {
                        HStack {
                            Text(actionButtonTitle)
                                .font(AppTheme.Typography.gravitySemibold(16))
                            Image(systemName: "arrow.right")
                                .font(AppTheme.Typography.bodyFont())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("GrowthGreen"))
                        )
                    }
                    
                    // Achievement teaser
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(Color("GrowthGreen"))
                        
                        Text("Complete this session to earn your first achievement!")
                            .font(AppTheme.Typography.captionFont())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.top, AppTheme.Layout.spacingS)
                }
                .padding(AppTheme.Layout.spacingL)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("BackgroundColor"))
                        .shadow(
                            color: Color.black.opacity(0.08),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("GrowthGreen").opacity(0.15), lineWidth: 1)
                )
            }
            .padding(.horizontal, AppTheme.Layout.spacingM)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Private Methods
    
    private func dismissPrompt() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingPrompt = false
        }
        
        onDismiss()
    }
    
    private func handleActionTap() {
        // Haptic feedback
        if themeManager.hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        dismissPrompt()
        onActionTap()
    }
}

// MARK: - Preview

#if DEBUG
struct FirstTimeUserPrompt_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Routine user
            FirstTimeUserPrompt(
                user: User(
                    id: "test",
                    firstName: "Test",
                    creationDate: Date(),
                    lastLogin: Date(),
                    settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium),
                    preferredPracticeMode: "routine"
                ),
                onDismiss: {},
                onActionTap: {}
            )
            
            Spacer()
            
            // Angio Pumping user
            FirstTimeUserPrompt(
                user: User(
                    id: "test2",
                    firstName: "Test",
                    creationDate: Date(),
                    lastLogin: Date(),
                    settings: UserSettings(notificationsEnabled: false, reminderTime: nil, privacyLevel: .medium),
                    initialMethodId: "angio_pumping"
                ),
                onDismiss: {},
                onActionTap: {}
            )
        }
        .padding()
        .background(Color("GrowthBackgroundLight"))
    }
}
#endif