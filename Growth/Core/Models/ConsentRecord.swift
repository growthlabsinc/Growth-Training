//
//  ConsentRecord.swift
//  Growth
//
//  Model for tracking user consent to legal documents
//

import Foundation

/// Record of user consent to a legal document
struct ConsentRecord: Codable {
    let documentId: String
    let documentVersion: String
    let acceptedAt: Date
    let ipAddress: String?
    
    init(documentId: String, documentVersion: String, acceptedAt: Date = Date(), ipAddress: String? = nil) {
        self.documentId = documentId
        self.documentVersion = documentVersion
        self.acceptedAt = acceptedAt
        self.ipAddress = ipAddress
    }
}