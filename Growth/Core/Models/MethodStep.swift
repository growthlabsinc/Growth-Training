//
//  MethodStep.swift
//  Growth
//
//  Created for multi-step method instructions
//

import Foundation

/// Represents a single step in a growth method's instructions
struct MethodStep: Codable, Identifiable {
    let id = UUID()
    var stepNumber: Int
    var title: String
    var description: String
    var duration: Int?
    var tips: [String]?
    var warnings: [String]?
    var intensity: String?
    
    enum CodingKeys: String, CodingKey {
        case stepNumber = "step_number"
        case title
        case description
        case duration
        case tips
        case warnings
        case intensity
    }
}