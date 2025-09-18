//
//  CoachChatView.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import SwiftUI

/// Main view for the AI Coach chat interface
struct CoachChatView: View {
    /// View model for chat functionality
    @StateObject private var viewModel = CoachChatViewModel()
    
    /// Scroll view reader for scrolling to bottom
    @Namespace private var bottomID
    
    /// Flag for showing the network reset confirmation dialog
    @State private var showingNetworkResetConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Network status indicator
            if !viewModel.isNetworkAvailable {
                networkStatusBanner
            }
            
            // Chat history
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Chat messages
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Invisible view at bottom for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                    .padding(.vertical, 8)
                }
                .onChangeCompat(of: viewModel.messages.count) { _ in
                    // Scroll to bottom when messages change
                    withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            
            // Input area
            inputView
        }
        .storeKit2FeatureGated("aiCoach")
        // Navigation title removed as this view will be embedded in LearnTabView
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        viewModel.clearChat()
                    }) {
                        Label("Clear Chat", systemImage: "trash")
                    }
                    
                    Button(action: {
                        viewModel.showDisclaimerDetails()
                    }) {
                        Label("Show Disclaimer", systemImage: "info.circle")
                    }
                    
                    Button(action: {
                        showingNetworkResetConfirmation = true
                    }) {
                        Label("Reset Connection", systemImage: "network")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingDisclaimerSheet) {
            AICoachDisclaimerView(onAccept: {
                viewModel.markDisclaimerAsAccepted()
            }, onDecline: {
                // If declined, just close the sheet without marking as accepted
                viewModel.showingDisclaimerSheet = false
            })
        }
        .onAppear {
            // Check and show disclaimer only if needed and not already showing
            viewModel.checkAndShowDisclaimerIfNeeded()
        }
        .alert("Reset Network Connection?", isPresented: $showingNetworkResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset") {
                Task {
                    await viewModel.resetNetworkConnections()
                }
            }
        } message: {
            Text("This may help resolve connection issues with the AI Coach service.")
        }
    }
    
    /// Network status banner view
    private var networkStatusBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("No internet connection")
            Spacer()
            Button(action: {
                showingNetworkResetConfirmation = true
            }) {
                Text("Reset")
                    .font(AppTheme.Typography.gravityBook(11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondaryButtonBackground)
                    .foregroundColor(Color("TextColor"))
                    .cornerRadius(12)
            }
        }
        .font(AppTheme.Typography.gravityBook(13))
        .padding(10)
        .background(Color.red.opacity(0.2))
        .foregroundColor(.red)
    }
    
    /// View for the input field and send button
    private var inputView: some View {
        VStack(spacing: 0) {
            // Error message if present
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Text(errorMessage)
                        .font(AppTheme.Typography.gravityBook(11))
                        .foregroundColor(.red)
                    
                    if errorMessage.contains("network") || errorMessage.contains("connection") {
                        Button(action: {
                            showingNetworkResetConfirmation = true
                        }) {
                            Text("Reset Connection")
                                .font(AppTheme.Typography.gravityBook(11))
                                .underline()
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            
            HStack {
                // Text input field
                TextField("Ask Growth Coach...", text: $viewModel.currentInput)
                    .padding()
                    .background(Color.backgroundLightColor)
                    .cornerRadius(24)
                    .disabled(viewModel.isProcessing || !viewModel.isNetworkAvailable)
                    .onSubmit {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                
                // Send button
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(AppTheme.Typography.title1Font())
                        .foregroundColor(
                            viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                            viewModel.isProcessing || 
                            !viewModel.isNetworkAvailable
                            ? Color("NeutralGray")
                            : Color.mintGreenColor
                        )
                }
                .disabled(
                    viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                    viewModel.isProcessing ||
                    !viewModel.isNetworkAvailable
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color("BackgroundColor"))
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: -1)
        }
    }
}

// MARK: - Preview
struct CoachChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CoachChatView()
        }
    }
} 