//
//  RoutineGoalSelectionView.swift
//  Growth
//
//  Created by Developer on [Date]
//

import SwiftUI
import FirebaseAuth
import Foundation  // For Logger

struct RoutineGoalSelectionView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showRoutineBrowser = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var selectedOption: SelectionOption?
    @State private var routinesViewModel: RoutinesViewModel?
    
    enum SelectionOption {
        case guidedRoutine
        case quickPractice
        case skip
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Choose Your Path")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color("TextColor"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                        .padding(.horizontal)
                    
                    // Subtitle
                    Text("Select how you'd like to practice")
                        .font(.system(size: 18))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    
                    // Option Cards
                    VStack(spacing: 16) {
                        // Guided Routine Card (Recommended)
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedOption = .guidedRoutine
                                handleGuidedRoutineSelection()
                            }
                        }) {
                            CardView(
                                hasShadow: true,
                                backgroundColor: selectedOption == .guidedRoutine ? Color("PaleGreen").opacity(0.2) : Color("BackgroundColor"),
                                borderColor: selectedOption == .guidedRoutine ? Color("GrowthGreen") : nil,
                                borderWidth: selectedOption == .guidedRoutine ? 2 : 1
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Start a Guided Routine")
                                                    .font(AppTheme.Typography.headlineFont())
                                                    .foregroundColor(Color("TextColor"))
                                                
                                                // Recommended badge
                                                Text("RECOMMENDED")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color("GrowthGreen"))
                                                    .cornerRadius(4)
                                            }
                                            
                                            Text("Follow a structured weekly program for consistent progress")
                                                .font(AppTheme.Typography.subheadlineFont())
                                                .foregroundColor(Color("TextSecondaryColor"))
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color("GrowthGreen"))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Quick Practice Card
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedOption = .quickPractice
                                handleQuickPracticeSelection()
                            }
                        }) {
                            CardView(
                                hasShadow: true,
                                backgroundColor: selectedOption == .quickPractice ? Color("PaleGreen").opacity(0.2) : Color("BackgroundColor"),
                                borderColor: selectedOption == .quickPractice ? Color("GrowthGreen") : nil,
                                borderWidth: selectedOption == .quickPractice ? 2 : 1
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("I prefer Quick Practice")
                                                .font(AppTheme.Typography.headlineFont())
                                                .foregroundColor(Color("TextColor"))
                                            
                                            Text("Practice any method, any time, at your own pace")
                                                .font(AppTheme.Typography.subheadlineFont())
                                                .foregroundColor(Color("TextSecondaryColor"))
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "timer")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color("GrowthGreen"))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Skip for now button
                    Button(action: {
                        selectedOption = .skip
                        handleSkipSelection()
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 16))
                            .foregroundColor(Color("TextSecondaryColor"))
                            .opacity(0.7)
                    }
                    .padding(.top, 24)
                    
                    // Back Button
                    Button(action: {
                        viewModel.regress()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                            Text("Back")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Color("TextSecondaryColor"))
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(AppTheme.Typography.footnoteFont())
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            
            // Loading overlay
            if isProcessing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    )
            }
        }
        .background(Color("GrowthBackgroundLight").ignoresSafeArea())
        .fullScreenCover(isPresented: $showRoutineBrowser, onDismiss: {
            // Check if a routine was actually selected
            checkRoutineSelectionAndProceed()
        }) {
            // Navigate to routine browser for beginners
            NavigationStack {
                if let userId = Auth.auth().currentUser?.uid {
                    let routinesVM = RoutinesViewModel(userId: userId)
                    RoutinesListView(viewModel: routinesVM, isOnboarding: true)
                        .navigationTitle("Select Your Routine")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    // Only allow dismissal if a routine was selected
                                    if routinesVM.selectedRoutineId != nil {
                                        showRoutineBrowser = false
                                    } else {
                                        // Show error or prompt to select
                                        errorMessage = "Please select a routine to continue"
                                    }
                                }
                            }
                        }
                        .onAppear {
                            // Store reference to check selection later
                            routinesViewModel = routinesVM
                        }
                        .onDisappear {
                            // Log the selected routine when dismissing
                            if let selectedId = routinesVM.selectedRoutineId {
                                Logger.debug("RoutineGoalSelection: Routine selected: \(selectedId)")
                            }
                        }
                }
            }
        }
    }
    
    private func handleGuidedRoutineSelection() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save preference
        savePracticePreference(mode: "routine") { success in
            if success {
                // Navigate to routine browser
                showRoutineBrowser = true
            }
        }
    }
    
    private func handleQuickPracticeSelection() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save preference and advance
        savePracticePreference(mode: "adhoc") { success in
            if success {
                viewModel.advance()
            }
        }
    }
    
    private func handleSkipSelection() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Save as adhoc preference and advance
        savePracticePreference(mode: "adhoc") { success in
            if success {
                viewModel.advance()
            }
        }
    }
    
    private func savePracticePreference(mode: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            completion(false)
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        UserService.shared.updatePracticePreference(userId: userId, practiceMode: mode) { error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.errorMessage = "Failed to save preference: \(error.localizedDescription)"
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    private func checkRoutineSelectionAndProceed() {
        // Check if a routine was selected
        if let routinesVM = routinesViewModel, routinesVM.selectedRoutineId != nil {
            // Routine was selected, advance to next step
            viewModel.advance()
        } else {
            // No routine selected, show error
            errorMessage = "Please select a routine before continuing"
            
            // Optionally reopen the routine browser
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showRoutineBrowser = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        RoutineGoalSelectionView()
            .environmentObject(OnboardingViewModel())
    }
}