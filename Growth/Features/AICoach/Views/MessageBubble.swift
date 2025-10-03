//
//  MessageBubble.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import SwiftUI

/// A bubble view for displaying a chat message
struct MessageBubble: View {
    /// The message to display
    let message: ChatMessage
    
    /// Whether to show the knowledge sources
    @State private var showSources: Bool = false
    
    var body: some View {
        VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.sender == .user {
                    Spacer()
                }
                
                // Message content
                VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                    if message.error != nil {
                        // Error message
                        errorView
                    } else if message.text == "..." && message.sender == .ai {
                        // Loading indicator
                        loadingView
                    } else {
                        // Normal message
                        if message.sender == .ai {
                            // AI messages use FormattedTextView for markdown rendering
                            FormattedTextView(content: message.text, textColor: .black, spacing: 8)
                                .padding()
                                .background(Color.paleGreenColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        } else {
                            // User messages use plain text
                            Text(message.text)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.mintGreenColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                    
                    // Knowledge sources if available
                    if let sources = message.sources, !sources.isEmpty {
                        Button(action: {
                            showSources.toggle()
                        }) {
                            HStack {
                                Text(showSources ? "Hide Sources" : "Show Sources")
                                    .font(AppTheme.Typography.captionFont())
                                    .foregroundColor(.blue)
                                
                                Image(systemName: showSources ? "chevron.up" : "chevron.down")
                                    .font(AppTheme.Typography.captionFont())
                            }
                            .padding(.top, 4)
                            .padding(.leading, 8)
                        }
                        
                        if showSources {
                            sourcesView(sources: sources)
                        }
                    }
                }
                
                if message.sender == .ai {
                    Spacer()
                }
            }
            
            // Message timestamp
            Text(formattedTime)
                .font(AppTheme.Typography.captionFont())
                .foregroundColor(.gray)
                .padding(message.sender == .user ? .trailing : .leading, 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    /// View for displaying an error message
    private var errorView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.orange)
                
                Text("Using AI responses as medical advice is not recommended. Please consult a healthcare professional.")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.secondary)
            }
            .padding(6)
            .background(Color.paleGreenColor.opacity(0.3))
            .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(AppTheme.Typography.captionFont())
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text(message.error ?? "An unknown error occurred")
                    .font(AppTheme.Typography.captionFont())
                    .foregroundColor(.red)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paleGreenColor)
            .cornerRadius(8)
            .padding(.top, 4)
        }
    }
    
    /// View for displaying a loading indicator
    private var loadingView: some View {
        HStack(spacing: 4) {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(Color.mintGreenColor)
                .opacity(0.7)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.0), value: UUID()) // Using UUID() to force animation
            
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(Color.mintGreenColor)
                .opacity(0.7)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.2), value: UUID())
            
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(Color.mintGreenColor)
                .opacity(0.7)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.4), value: UUID())
        }
        .padding()
        .background(Color.paleGreenColor)
        .cornerRadius(16)
    }
    
    /// View for displaying knowledge sources
    private func sourcesView(sources: [KnowledgeSource]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sources) { source in
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.title)
                        .font(AppTheme.Typography.captionFont())
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(source.snippet)
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.gray)
                    
                    Text("Confidence: \(Int(source.confidence * 100))%")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.paleGreenColor.opacity(0.3))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 8)
        .transition(.opacity)
    }
    
    /// Formatted timestamp string
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}

// MARK: - Preview
struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageBubble(
                message: ChatMessage.userMessage("Hello, how can you help me with Growth Methods?")
            )
            
            MessageBubble(
                message: ChatMessage.aiMessage(
                    "I can help you understand Growth Methods and techniques. Would you like to learn about beginner methods or more advanced ones?",
                    sources: [
                        KnowledgeSource(
                            title: "Growth Methods Introduction",
                            snippet: "Growth Methods are specialized exercises designed to improve circulation...",
                            confidence: 0.92
                        )
                    ]
                )
            )
            
            MessageBubble(
                message: ChatMessage.aiLoadingMessage()
            )
            
            MessageBubble(
                message: ChatMessage.aiErrorMessage("Network connection error")
            )
        }
        .padding()
    }
} 