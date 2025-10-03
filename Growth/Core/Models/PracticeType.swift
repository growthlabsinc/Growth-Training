//
//  PracticeType.swift
//  Growth
//
//  Created by Developer on 6/5/25.
//

import Foundation

enum PracticeType {
    case heavy
    case moderate
    case light
    case rest
    
    var accessibilityLabel: String {
        switch self {
        case .heavy:
            return "Heavy training day"
        case .moderate:
            return "Moderate training day"
        case .light:
            return "Light training day"
        case .rest:
            return "Rest day"
        }
    }
}