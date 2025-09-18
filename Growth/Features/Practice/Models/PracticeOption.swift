//
//  PracticeOption.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

enum PracticeOption: String, CaseIterable {
    case guided = "guided"
    case quick = "quick"
    case freestyle = "freestyle"
    
    var iconName: String {
        switch self {
        case .guided:
            return "map.fill"
        case .quick:
            return "bolt.fill"
        case .freestyle:
            return "sparkles"
        }
    }
    
    var title: String {
        switch self {
        case .guided:
            return "Guided Practice"
        case .quick:
            return "Quick Practice"
        case .freestyle:
            return "Freestyle Practice"
        }
    }
    
    var description: String {
        switch self {
        case .guided:
            return "Follow your routine with structured sessions"
        case .quick:
            return "Jump into any method for quick practice"
        case .freestyle:
            return "Practice freely without time constraints"
        }
    }
}