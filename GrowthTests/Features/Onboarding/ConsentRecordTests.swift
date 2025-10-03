import XCTest
@testable import Growth

class ConsentRecordTests: XCTestCase {
    
    func testConsentRecordInitialization() {
        let documentId = "privacy_policy"
        let documentVersion = "1.0.0"
        let acceptedAt = Date()
        let ipAddress = "192.168.1.1"
        
        let consentRecord = ConsentRecord(
            documentId: documentId,
            documentVersion: documentVersion,
            acceptedAt: acceptedAt,
            ipAddress: ipAddress
        )
        
        XCTAssertEqual(consentRecord.documentId, documentId)
        XCTAssertEqual(consentRecord.documentVersion, documentVersion)
        XCTAssertEqual(consentRecord.acceptedAt, acceptedAt)
        XCTAssertEqual(consentRecord.ipAddress, ipAddress)
    }
    
    func testConsentRecordInitializationWithoutIP() {
        let documentId = "terms_of_use"
        let documentVersion = "2.0.0"
        let acceptedAt = Date()
        
        let consentRecord = ConsentRecord(
            documentId: documentId,
            documentVersion: documentVersion,
            acceptedAt: acceptedAt
        )
        
        XCTAssertEqual(consentRecord.documentId, documentId)
        XCTAssertEqual(consentRecord.documentVersion, documentVersion)
        XCTAssertEqual(consentRecord.acceptedAt, acceptedAt)
        XCTAssertNil(consentRecord.ipAddress)
    }
    
    func testConsentRecordCodable() throws {
        let consentRecord = ConsentRecord(
            documentId: "medical_disclaimer",
            documentVersion: "1.2.0",
            acceptedAt: Date(),
            ipAddress: "10.0.0.1"
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(consentRecord)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedRecord = try decoder.decode(ConsentRecord.self, from: data)
        
        XCTAssertEqual(consentRecord.documentId, decodedRecord.documentId)
        XCTAssertEqual(consentRecord.documentVersion, decodedRecord.documentVersion)
        XCTAssertEqual(consentRecord.acceptedAt.timeIntervalSince1970, 
                      decodedRecord.acceptedAt.timeIntervalSince1970, 
                      accuracy: 0.001)
        XCTAssertEqual(consentRecord.ipAddress, decodedRecord.ipAddress)
    }
    
    func testConsentRecordCodableWithoutIP() throws {
        let consentRecord = ConsentRecord(
            documentId: "privacy_policy",
            documentVersion: "3.0.0",
            acceptedAt: Date()
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(consentRecord)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedRecord = try decoder.decode(ConsentRecord.self, from: data)
        
        XCTAssertEqual(consentRecord.documentId, decodedRecord.documentId)
        XCTAssertEqual(consentRecord.documentVersion, decodedRecord.documentVersion)
        XCTAssertEqual(consentRecord.acceptedAt.timeIntervalSince1970, 
                      decodedRecord.acceptedAt.timeIntervalSince1970, 
                      accuracy: 0.001)
        XCTAssertNil(decodedRecord.ipAddress)
    }
}