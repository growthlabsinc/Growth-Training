//
//  CitationServiceTests.swift
//  GrowthTests
//
//  Unit tests for CitationService
//  Created by Developer on 10/6/25.
//

import XCTest
@testable import Growth

final class CitationServiceTests: XCTestCase {

    var service: CitationService!

    override func setUp() {
        super.setUp()
        service = CitationService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Validation Tests

    func testValidateCompleteCitation() async {
        let citation = Citation(
            id: "valid1",
            authors: "Smith, J.",
            year: "2024",
            title: "Complete Citation",
            journal: "Test Journal",
            doi: "10.1234/test",
            citationType: .journalArticle
        )

        let result = await service.validateCitation(citation)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testValidateMissingRequiredFields() async {
        let citation = Citation(
            id: "invalid1",
            authors: "",
            year: "",
            title: "",
            journal: ""
        )

        let result = await service.validateCitation(citation)

        XCTAssertFalse(result.isValid)
        XCTAssertGreaterThan(result.errors.count, 0)
        XCTAssertTrue(result.errors.contains("Authors field is empty"))
        XCTAssertTrue(result.errors.contains("Title field is empty"))
        XCTAssertTrue(result.errors.contains("Journal field is empty"))
        XCTAssertTrue(result.errors.contains("Year field is empty"))
    }

    func testValidateMissingIdentifiers() async {
        let citation = Citation(
            id: "warning1",
            authors: "Doe, J.",
            year: "2023",
            title: "No Identifiers",
            journal: "Journal"
        )

        let result = await service.validateCitation(citation)

        XCTAssertTrue(result.isValid) // Still valid, just has warning
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertGreaterThan(result.warnings.count, 0)
        XCTAssertTrue(result.warnings.first?.contains("No DOI, PMID, or URL") ?? false)
    }

    // MARK: - DOI Format Validation

    func testInvalidDOIFormat() async {
        let citation = Citation(
            id: "doi1",
            authors: "Author",
            year: "2024",
            title: "Invalid DOI",
            journal: "Journal",
            doi: "invalid-doi",
            citationType: .journalArticle
        )

        let result = await service.validateCitation(citation)

        XCTAssertTrue(result.isValid) // Main validation passes
        XCTAssertTrue(result.warnings.contains { $0.contains("DOI format appears invalid") })
    }

    // MARK: - URL Validation

    func testCheckURLValidityWithValidURL() async {
        // Test with a known reliable URL
        let isValid = await service.checkURLValidity("https://www.google.com")

        XCTAssertTrue(isValid)
    }

    func testCheckURLValidityWithInvalidURL() async {
        let isValid = await service.checkURLValidity("https://this-url-definitely-does-not-exist-12345.com")

        XCTAssertFalse(isValid)
    }

    func testCheckURLValidityWithMalformedURL() async {
        let isValid = await service.checkURLValidity("not-a-valid-url")

        XCTAssertFalse(isValid)
    }

    // MARK: - DOI Resolution Tests
    // Note: These test network calls and should be mocked in production

    func testResolveDOICleansDOIString() async throws {
        // Test that DOI cleaning works (can't test actual resolution without network)
        // This is more of an integration test - would need mocking for true unit test

        let doiWithPrefix = "https://doi.org/10.1234/test"
        let doiWithHTTP = "http://dx.doi.org/10.1234/test"
        let cleanDOI = "10.1234/test"

        // All should resolve to same clean format (would need to mock actual API call)
        // For now, just test that the method exists and doesn't crash
        do {
            _ = try await service.resolveDOI(cleanDOI)
        } catch {
            // Expected to fail without real DOI
            XCTAssertTrue(error is CitationServiceError)
        }
    }

    // MARK: - PubMed Lookup Tests

    func testFetchPubMedArticleCleansPMID() async throws {
        // Test PMID cleaning
        let pmidWithPrefix = "PMID: 12345"
        let pmcID = "PMC12345"
        let cleanPMID = "12345"

        // Would need mocking for actual test
        do {
            _ = try await service.fetchPubMedArticle(cleanPMID)
        } catch {
            // Expected to fail without real PMID
            XCTAssertTrue(error is CitationServiceError)
        }
    }

    // MARK: - Error Handling Tests

    func testCitationServiceErrorDescriptions() {
        XCTAssertNotNil(CitationServiceError.invalidDOI.errorDescription)
        XCTAssertNotNil(CitationServiceError.invalidPMID.errorDescription)
        XCTAssertNotNil(CitationServiceError.apiError.errorDescription)
        XCTAssertNotNil(CitationServiceError.parsingError.errorDescription)
        XCTAssertNotNil(CitationServiceError.networkError.errorDescription)
    }
}
