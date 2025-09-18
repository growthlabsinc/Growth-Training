//
//  SessionType.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

public enum SessionType: String, Codable {
    case single = "single"
    case multiMethod = "multi"
    case quickPractice = "quick"
    case freestyle = "freestyle"
    case restDay = "rest"
    
    var displayName: String {
        switch self {
        case .single:
            return "Single Method"
        case .multiMethod:
            return "Multi-Method Session"
        case .quickPractice:
            return "Quick Practice"
        case .freestyle:
            return "Freestyle Session"
        case .restDay:
            return "Rest Day"
        }
    }
}