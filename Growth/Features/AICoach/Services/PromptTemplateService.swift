//
//  PromptTemplateService.swift
//  Growth
//
//  Created by Developer on <CURRENT_DATE>. Copyright © 2024 Growth. All rights reserved.
//

import Foundation

// Enum to define different query categories
enum AIQueryCategory {
    case growthMethodGuidance
    case appNavigation
    case generalWellnessInScope
    case progressTracking // Future
    case outOfScope // Includes medical advice or truly irrelevant topics
    case unknown // Default or fallback
}

// Struct to hold a specific prompt template and its components
struct AIPromptTemplate {
    let name: String
    let category: AIQueryCategory
    let systemMessage: String // Base system prompt or specific intro
    let userMessageTemplate: String // Template for the user part, expecting placeholders like {{user_query}}, {{context}}
    // Potentially add few-shot examples here if they are static per template
}

class PromptTemplateService {

    // MARK: - Properties

    // In a real app, these would be loaded from a configuration file (e.g., JSON bundled with app)
    // or potentially fetched from a remote config. For now, defined inline.
    private let baseSystemPrompt = """
    You are the Growth Coach, an AI assistant for the Growth app. Your goal is to help users understand and utilize the app's Growth Methods, navigate its features, and find information on related wellness topics covered within the app's content.
    You are supportive, encouraging, and provide clear, concise information.

    **IMPORTANT RULES:**
    1.  **Knowledge Base First:** Prioritize information directly from the provided knowledge base (Growth Methods, Educational Articles). When using this information, clearly indicate it (e.g., "According to the [Method Name] method..."). The knowledge base context will be provided to you.
    2.  **Angion Method Medical Information:** You CAN provide information about the Angion Method as it pertains to erectile function, vascular health, and related sexual wellness topics, as this information is specifically included in your knowledge base. However, you MUST include this disclaimer: "⚠️ This information is for educational purposes only. While based on the Angion Method knowledge base, you should consult with a healthcare professional before starting any new practice, especially if you have existing health conditions or concerns about erectile function."
    3.  **General Medical Advice Restrictions:** For medical questions unrelated to the Angion Method or not covered in your knowledge base, you CANNOT provide medical advice. Politely decline and suggest consulting a healthcare professional. Example: "I can't provide medical advice on that topic, but I recommend speaking with a healthcare professional."
    4.  **Stay In Scope:** If a question is unrelated to the Growth app's content, Growth Methods, or general wellness topics covered by the app, politely state that you cannot answer. Example: "I can help with questions about the Growth app and its methods. For other topics, you might need to consult a different resource."
    5.  **Be Clear and Concise:** Provide direct answers and avoid overly long responses.
    6.  **Encourage Exploration:** Where appropriate, suggest related methods or articles within the app.
    """

    private lazy var templates: [AIQueryCategory: AIPromptTemplate] = [
        .growthMethodGuidance: AIPromptTemplate(
            name: "GrowthMethodGuidanceQuery",
            category: .growthMethodGuidance,
            systemMessage: baseSystemPrompt, // Or a more specific intro if base is handled separately
            userMessageTemplate: """
            Context from Knowledge Base (Growth Method: {{method_name}}):
            {{retrieved_method_details}}

            User Query: {{user_query}}

            Based *only* on the provided context for Growth Method '{{method_name}}', answer the user's query.
            - If the query asks for steps, list them clearly.
            - If the query asks for benefits, summarize them.
            - If the context does not contain the answer, state that the information isn't available for this specific method in the knowledge base.
            """
        ),
        .appNavigation: AIPromptTemplate(
            name: "AppNavigationQuery",
            category: .appNavigation,
            systemMessage: baseSystemPrompt,
            userMessageTemplate: """
            Context from Knowledge Base (App Features/Navigation):
            {{retrieved_app_navigation_info}}

            User Query: {{user_query}}

            Based on the app's known features and your understanding of common app navigation, provide clear instructions to help the user with their query: "{{user_query}}".
            If the feature is not known, suggest they explore the main sections of the app like 'Learn', 'Methods', or 'Progress'.
            """
        ),
        .generalWellnessInScope: AIPromptTemplate(
            name: "GeneralWellnessQuery",
            category: .generalWellnessInScope,
            systemMessage: baseSystemPrompt,
            userMessageTemplate: """
            Context from Knowledge Base (Educational Resource: {{resource_topic}}):
            {{retrieved_educational_article_content}}

            User Query: {{user_query}}

            Based *only* on the provided educational content on '{{resource_topic}}', answer the user's query.
            - Provide a concise summary of the relevant information.
            - If the context doesn't directly answer the query, state that specific information isn't available in the current resources but you can offer general information from the article if it's related.
            """
        ),
        .outOfScope: AIPromptTemplate(
            name: "OutOfScopeQueryHandling",
            category: .outOfScope,
            systemMessage: baseSystemPrompt, // The base prompt contains the rules, this template just reinforces the query context
            userMessageTemplate: """
            User Query: {{user_query}}

            The user's query is: "{{user_query}}".
            This query has been identified as potentially seeking medical advice or being outside the scope of the Growth app.
            Respond according to the rules for out-of-scope questions or medical advice requests defined in your primary instructions (system message).
            Do not attempt to answer the query directly.
            """
        ),
        // Fallback/Unknown - could just use baseSystemPrompt and append user query directly
        .unknown: AIPromptTemplate(
            name: "UnknownOrFallbackQuery",
            category: .unknown,
            systemMessage: baseSystemPrompt,
            userMessageTemplate: "User Query: {{user_query}}\n\nAnswer the user query based on your general knowledge and the rules provided in the system message, prioritizing information from the Growth app if applicable."
        )
    ]

    // MARK: - Initialization

    init() {
        // In the future, load templates from a configuration file
        // For now, they are hardcoded.
        // Consider validating templates on init.
        Logger.info("PromptTemplateService initialized with \(templates.count) templates.")
    }

    // MARK: - Public Methods

    func getSystemPrompt(for category: AIQueryCategory) -> String {
        return templates[category]?.systemMessage ?? baseSystemPrompt // Fallback to base
    }

    func buildUserMessage(for category: AIQueryCategory, userQuery: String, context: [String: String] = [:]) -> String {
        guard let template = templates[category] else {
            // Fallback for unknown category: simply use the user query with no special formatting.
            // The base system prompt will still apply.
            return userQuery 
        }

        var populatedTemplate = template.userMessageTemplate
        populatedTemplate = populatedTemplate.replacingOccurrences(of: "{{user_query}}", with: userQuery)

        // Populate context-specific placeholders
        for (key, value) in context {
            populatedTemplate = populatedTemplate.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        
        // Ensure any un-filled placeholders are removed or handled gracefully
        // This regex matches {{placeholder_name}}
        let placeholderRegex = try! NSRegularExpression(pattern: "\\{\\{(.*?)\\}\\}")
        let range = NSRange(location: 0, length: populatedTemplate.utf16.count)
        populatedTemplate = placeholderRegex.stringByReplacingMatches(in: populatedTemplate, options: [], range: range, withTemplate: "[Context for $1 not provided]") // Or remove them: ""

        return populatedTemplate
    }
    
    /**
     Determines the AIQueryCategory for a given user input string.
     This is a placeholder and would need a more sophisticated implementation
     (e.g., keyword matching, simple NLP, or a lightweight model).
    */
    func categorizeQuery(_ query: String) -> AIQueryCategory {
        let lowercasedQuery = query.lowercased()

        // General medical advice should be out of scope
        if lowercasedQuery.contains("medical") || lowercasedQuery.contains("doctor") || lowercasedQuery.contains("diagnose") || lowercasedQuery.contains("symptom") {
            return .outOfScope
        }
        
        if lowercasedQuery.contains("how to") || lowercasedQuery.contains("method") || lowercasedQuery.contains("technique") {
             // Check for specific method names if possible
            if lowercasedQuery.contains("p.a.d.") || lowercasedQuery.contains("jelqing") { // Example method names
                 return .growthMethodGuidance
            }
            // Could be a general wellness question or app navigation
        }
        if lowercasedQuery.contains("find") || lowercasedQuery.contains("where is") || lowercasedQuery.contains("navigate") {
            return .appNavigation
        }
        if lowercasedQuery.contains("benefit") || lowercasedQuery.contains("learn about") || lowercasedQuery.contains("what is") {
            // Could be general wellness, or a specific method query
            // Needs more refinement
            return .generalWellnessInScope // Defaulting for now
        }

        return .unknown // Default if no specific category matches
    }
}

// Example Usage (for testing purposes)
/*
func testPromptService() {
    let service = PromptTemplateService()

    let query1 = "How do I perform the P.A.D. Method?"
    let category1 = service.categorizeQuery(query1)
    let system1 = service.getSystemPrompt(for: category1)
    let userMessage1 = service.buildUserMessage(
        for: category1, 
        userQuery: query1, 
        context: [
            "method_name": "P.A.D. Method",
            "retrieved_method_details": "The P.A.D. Method involves Preparation, Action, and Diligence. Step 1..."
        ]
    )
    Logger.info("--- Query 1 (Growth Method) ---")
    Logger.info("Category: \(category1)")
    // print( // Release OK"System: \(system1)") // System prompt is long
    Logger.info("User Message: \(userMessage1)")

    let query2 = "Where can I find my saved articles?"
    let category2 = service.categorizeQuery(query2)
    let system2 = service.getSystemPrompt(for: category2)
    let userMessage2 = service.buildUserMessage(
        for: category2, 
        userQuery: query2, 
        context: ["retrieved_app_navigation_info": "Saved articles are in the Learn tab, under 'My Library' section."]
    )
    Logger.info("\n--- Query 2 (App Navigation) ---")
    Logger.info("Category: \(category2)")
    Logger.info("User Message: \(userMessage2)")

    let query3 = "I have a headache, what should I do?"
    let category3 = service.categorizeQuery(query3)
    let system3 = service.getSystemPrompt(for: category3)
    let userMessage3 = service.buildUserMessage(for: category3, userQuery: query3)
    Logger.info("\n--- Query 3 (Medical/OutOfScope) ---")
    Logger.info("Category: \(category3)")
    Logger.info("User Message: \(userMessage3)")
    
    let query4 = "Tell me about the weather."
    let category4 = service.categorizeQuery(query4)
    let system4 = service.getSystemPrompt(for: category4)
    let userMessage4 = service.buildUserMessage(for: category4, userQuery: query4)
    Logger.info("\n--- Query 4 (Unknown/OutOfScope) ---")
    Logger.info("Category: \(category4)")
    Logger.info("User Message: \(userMessage4)")
}

// testPromptService()
*/ 