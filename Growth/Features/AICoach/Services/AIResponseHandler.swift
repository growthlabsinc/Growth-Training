//
//  AIResponseHandler.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import Foundation

/// Handler for processing AI responses
class AIResponseHandler {
    /// Maximum length for an AI response before truncation
    private let maxResponseLength = 2000
    
    /// Shared instance for singleton access
    static let shared = AIResponseHandler()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Process and format an AI response text
    /// - Parameter text: Raw response text from AI
    /// - Returns: Formatted response text
    func processResponseText(_ text: String) -> String {
        var processedText = text
        
        // Trim any leading/trailing whitespace
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Truncate response if too long
        if processedText.count > maxResponseLength {
            let endIndex = processedText.index(processedText.startIndex, offsetBy: maxResponseLength)
            processedText = String(processedText[..<endIndex]) + "..."
        }
        
        // Replace multiple consecutive newlines with just two
        processedText = processedText.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )
        
        // Ensure response ends with proper punctuation
        if !processedText.isEmpty && !".!?".contains(processedText.last!) {
            processedText += "."
        }
        
        return processedText
    }
    
    /// Extract sources from AI response if mentioned in text
    /// - Parameter text: Response text to parse
    /// - Returns: Array of source titles if found
    func extractSourceReferences(from text: String) -> [String] {
        // This is a simple implementation that looks for "Source:" or "Reference:" patterns
        // A more sophisticated implementation could use regex or other patterns
        
        var sources: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.starts(with: "Source:") || trimmedLine.starts(with: "Reference:") {
                let sourceText = trimmedLine.replacingOccurrences(of: "Source:", with: "")
                    .replacingOccurrences(of: "Reference:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !sourceText.isEmpty {
                    sources.append(sourceText)
                }
            }
        }
        
        return sources
    }
    
    /// Check if a response contains disclaimers about medical advice
    /// - Parameter text: Response text to check
    /// - Returns: True if medical disclaimers are present
    func containsMedicalDisclaimer(_ text: String) -> Bool {
        let lowerText = text.lowercased()
        
        let disclaimerPhrases = [
            "not medical advice",
            "consult a healthcare professional",
            "consult your doctor",
            "speak with a medical professional",
            "not a substitute for professional medical advice"
        ]
        
        return disclaimerPhrases.contains { lowerText.contains($0) }
    }
} 