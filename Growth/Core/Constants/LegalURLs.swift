/**
 * LegalURLs.swift
 * Growth App Legal Document URLs
 *
 * Central location for all legal document URLs used in the app
 */

import Foundation

enum LegalURLs {
    /// Base website URL
    static let websiteBase = "https://www.growthlabs.coach"
    
    /// Terms of Service / EULA URL
    static let termsOfService = "\(websiteBase)/terms"
    
    /// Privacy Policy URL
    static let privacyPolicy = "\(websiteBase)/privacy-policy"
    
    /// Support Email
    static let supportEmail = "support@growthlabs.coach"
    
    /// Apple's Standard EULA (as fallback)
    static let appleStandardEULA = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    
    /// Get URL for a specific document type
    static func url(for documentType: LegalDocumentType) -> URL? {
        switch documentType {
        case .termsOfService:
            return URL(string: termsOfService)
        case .privacyPolicy:
            return URL(string: privacyPolicy)
        }
    }
}

enum LegalDocumentType {
    case termsOfService
    case privacyPolicy
    
    var title: String {
        switch self {
        case .termsOfService:
            return "Terms of Service"
        case .privacyPolicy:
            return "Privacy Policy"
        }
    }
}