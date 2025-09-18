//
//  PendingConsents.swift
//  Growth
//
//  Manages pending consent records before user account creation
//

import Foundation

/// Singleton class to manage pending consents before user authentication
class PendingConsents {
    static let shared = PendingConsents()
    
    private init() {}
    
    // Disclaimer consent
    var disclaimerAccepted: Bool = false
    var disclaimerVersion: String?
    var disclaimerAcceptedTimestamp: Date?
    
    // Consent records for legal documents
    var consentRecords: [ConsentRecord] = []
    
    /// Add a consent record
    func addConsentRecord(_ record: ConsentRecord) {
        consentRecords.append(record)
    }
    
    /// Set disclaimer acceptance
    func setDisclaimerAccepted(version: String) {
        disclaimerAccepted = true
        disclaimerVersion = version
        disclaimerAcceptedTimestamp = Date()
    }
    
    /// Record privacy and terms acceptance
    func recordPrivacyTermsAcceptance(privacyVersion: String, termsVersion: String) {
        // Add privacy policy consent
        let privacyConsent = ConsentRecord(
            documentId: "privacy_policy",
            documentVersion: privacyVersion,
            acceptedAt: Date(),
            ipAddress: nil
        )
        addConsentRecord(privacyConsent)
        
        // Add terms of use consent
        let termsConsent = ConsentRecord(
            documentId: "terms_of_use",
            documentVersion: termsVersion,
            acceptedAt: Date(),
            ipAddress: nil
        )
        addConsentRecord(termsConsent)
    }
    
    /// Convenience method matching the old API
    func recordDisclaimerAcceptance(version: String) {
        setDisclaimerAccepted(version: version)
    }
    
    /// Clear all pending consents (after saving to user document)
    func clear() {
        disclaimerAccepted = false
        disclaimerVersion = nil
        disclaimerAcceptedTimestamp = nil
        consentRecords.removeAll()
    }
}