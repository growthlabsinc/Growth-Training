//
//  ChatMessage.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import Foundation

/// Sender type for chat messages
enum ChatSender: String, Codable {
    case user
    case ai
}

/// Model for representing a single chat message
struct ChatMessage: Identifiable, Codable, Equatable {
    /// Unique identifier for the message
    let id: UUID
    
    /// Content of the message
    let text: String
    
    /// Sender of the message (user or AI)
    let sender: ChatSender
    
    /// Timestamp when the message was created
    let timestamp: Date
    
    /// Optional list of knowledge sources referenced in AI response
    let sources: [KnowledgeSource]?
    
    /// Optional error message if AI response failed
    let error: String?
    
    /// Create a new chat message
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - text: Content of the message
    ///   - sender: Who sent the message
    ///   - timestamp: When the message was sent (defaults to now)
    ///   - sources: Optional knowledge sources referenced
    ///   - error: Optional error message
    init(
        id: UUID = UUID(),
        text: String,
        sender: ChatSender,
        timestamp: Date = Date(),
        sources: [KnowledgeSource]? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.sources = sources
        self.error = error
    }
    
    /// Create a user message
    /// - Parameter text: Message content
    /// - Returns: A new ChatMessage with user as sender
    static func userMessage(_ text: String) -> ChatMessage {
        ChatMessage(text: text, sender: .user)
    }
    
    /// Create an AI message
    /// - Parameter text: Message content
    /// - Returns: A new ChatMessage with AI as sender
    static func aiMessage(_ text: String, sources: [KnowledgeSource]? = nil) -> ChatMessage {
        ChatMessage(text: text, sender: .ai, sources: sources)
    }
    
    /// Create an error message from the AI
    /// - Parameter error: Error description
    /// - Returns: A new ChatMessage with AI as sender and error content
    static func aiErrorMessage(_ error: String) -> ChatMessage {
        ChatMessage(
            text: "I'm having trouble responding right now. Please try again later.",
            sender: .ai,
            error: error
        )
    }
    
    /// Create a loading message for the AI
    /// - Parameter text: Optional custom loading text (defaults to "...")
    /// - Returns: A new ChatMessage with AI as sender and loading text
    static func aiLoadingMessage(_ text: String = "...") -> ChatMessage {
        ChatMessage(
            id: UUID(),
            text: text,
            sender: .ai
        )
    }
}

/// Model for knowledge sources referenced in AI responses
struct KnowledgeSource: Identifiable, Codable, Equatable {
    /// Unique identifier for the source
    let id: UUID
    
    /// Title of the source
    let title: String
    
    /// Snippet of content from the source
    let snippet: String
    
    /// Confidence score for the source
    let confidence: Double
    
    /// Initialize a new knowledge source
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - title: Title of the source
    ///   - snippet: Content snippet
    ///   - confidence: Confidence score
    init(
        id: UUID = UUID(),
        title: String,
        snippet: String,
        confidence: Double
    ) {
        self.id = id
        self.title = title
        self.snippet = snippet
        self.confidence = confidence
    }
} 