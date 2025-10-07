//
//  CitationTests.swift
//  GrowthTests
//
//  Unit tests for Citation model
//  Created by Developer on 10/6/25.
//

import XCTest
@testable import Growth

final class CitationTests: XCTestCase {

    // MARK: - Model Initialization Tests

    func testCitationInitialization() {
        let citation = Citation(
            id: "test1",
            authors: "Smith, J. & Jones, A.",
            year: "2024",
            title: "Test Article",
            journal: "Test Journal",
            volume: "10",
            issue: "2",
            pages: "123-145",
            doi: "10.1234/test",
            pmid: "12345678",
            url: "https://example.com",
            accessDate: Date(),
            citationType: .journalArticle
        )

        XCTAssertEqual(citation.id, "test1")
        XCTAssertEqual(citation.authors, "Smith, J. & Jones, A.")
        XCTAssertEqual(citation.year, "2024")
        XCTAssertEqual(citation.title, "Test Article")
        XCTAssertEqual(citation.journal, "Test Journal")
        XCTAssertEqual(citation.volume, "10")
        XCTAssertEqual(citation.issue, "2")
        XCTAssertEqual(citation.pages, "123-145")
        XCTAssertEqual(citation.doi, "10.1234/test")
        XCTAssertEqual(citation.pmid, "12345678")
        XCTAssertEqual(citation.url, "https://example.com")
        XCTAssertNotNil(citation.accessDate)
        XCTAssertEqual(citation.citationType, .journalArticle)
    }

    func testCitationWithDefaults() {
        let citation = Citation(
            id: "test2",
            authors: "Doe, J.",
            year: "2023",
            title: "Minimal Citation",
            journal: "Journal"
        )

        XCTAssertEqual(citation.id, "test2")
        XCTAssertNil(citation.volume)
        XCTAssertNil(citation.issue)
        XCTAssertNil(citation.pages)
        XCTAssertNil(citation.doi)
        XCTAssertNil(citation.pmid)
        XCTAssertNil(citation.url)
        XCTAssertNil(citation.accessDate)
        XCTAssertEqual(citation.citationType, .journalArticle) // Default
    }

    // MARK: - Codable Tests

    func testCitationEncodingDecoding() throws {
        let original = Citation(
            id: "test3",
            authors: "Brown, A. et al.",
            year: "2022",
            title: "Encoding Test",
            journal: "Codable Journal",
            volume: "5",
            issue: "1",
            pages: "10-20",
            doi: "10.5678/encode",
            pmid: "87654321",
            url: "https://test.com",
            accessDate: Date(),
            citationType: .book
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Citation.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.authors, original.authors)
        XCTAssertEqual(decoded.year, original.year)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.journal, original.journal)
        XCTAssertEqual(decoded.volume, original.volume)
        XCTAssertEqual(decoded.issue, original.issue)
        XCTAssertEqual(decoded.pages, original.pages)
        XCTAssertEqual(decoded.doi, original.doi)
        XCTAssertEqual(decoded.pmid, original.pmid)
        XCTAssertEqual(decoded.url, original.url)
        XCTAssertEqual(decoded.citationType, original.citationType)
    }

    // MARK: - APA Formatting Tests

    func testFormattedAPAWithDOI() {
        let citation = Citation(
            id: "test4",
            authors: "Johnson, M.",
            year: "2021",
            title: "APA Test",
            journal: "Format Journal",
            volume: "3",
            issue: "4",
            pages: "50-60",
            doi: "10.1111/apa",
            citationType: .journalArticle
        )

        let formatted = citation.formattedAPA
        XCTAssertTrue(formatted.contains("Johnson, M."))
        XCTAssertTrue(formatted.contains("(2021)"))
        XCTAssertTrue(formatted.contains("APA Test"))
        XCTAssertTrue(formatted.contains("Format Journal"))
        XCTAssertTrue(formatted.contains("*3*(4)"))
        XCTAssertTrue(formatted.contains("50-60"))
        XCTAssertTrue(formatted.contains("https://doi.org/10.1111/apa"))
    }

    func testFormattedAPAWithPMID() {
        let citation = Citation(
            id: "test5",
            authors: "Williams, S. et al.",
            year: "2020",
            title: "PMID Test",
            journal: "Medical Journal",
            volume: "15",
            pages: "100-110",
            pmid: "99887766",
            citationType: .journalArticle
        )

        let formatted = citation.formattedAPA
        XCTAssertTrue(formatted.contains("Williams, S. et al."))
        XCTAssertTrue(formatted.contains("(2020)"))
        XCTAssertTrue(formatted.contains("PMID: 99887766"))
        XCTAssertFalse(formatted.contains("https://doi.org"))
    }

    func testFormattedAPAWithURL() {
        let citation = Citation(
            id: "test6",
            authors: "Davis, R.",
            year: "2019",
            title: "URL Test",
            journal: "Web Journal",
            url: "https://example.org/article",
            citationType: .journalArticle
        )

        let formatted = citation.formattedAPA
        XCTAssertTrue(formatted.contains("Davis, R."))
        XCTAssertTrue(formatted.contains("https://example.org/article"))
        XCTAssertFalse(formatted.contains("DOI"))
        XCTAssertFalse(formatted.contains("PMID"))
    }

    // MARK: - Firestore Conversion Tests

    func testToFirestoreData() {
        let citation = Citation(
            id: "test7",
            authors: "Miller, T.",
            year: "2018",
            title: "Firestore Test",
            journal: "Database Journal",
            volume: "7",
            issue: "3",
            doi: "10.2222/firestore",
            pmid: "11223344",
            citationType: .report
        )

        let firestoreData = citation.toFirestoreData()

        XCTAssertEqual(firestoreData["id"] as? String, "test7")
        XCTAssertEqual(firestoreData["authors"] as? String, "Miller, T.")
        XCTAssertEqual(firestoreData["year"] as? String, "2018")
        XCTAssertEqual(firestoreData["title"] as? String, "Firestore Test")
        XCTAssertEqual(firestoreData["journal"] as? String, "Database Journal")
        XCTAssertEqual(firestoreData["volume"] as? String, "7")
        XCTAssertEqual(firestoreData["issue"] as? String, "3")
        XCTAssertEqual(firestoreData["doi"] as? String, "10.2222/firestore")
        XCTAssertEqual(firestoreData["pmid"] as? String, "11223344")
        XCTAssertEqual(firestoreData["citation_type"] as? String, "report")
    }

    // MARK: - Citation Type Tests

    func testCitationTypeEnum() {
        XCTAssertEqual(CitationType.journalArticle.rawValue, "journalArticle")
        XCTAssertEqual(CitationType.book.rawValue, "book")
        XCTAssertEqual(CitationType.bookChapter.rawValue, "bookChapter")
        XCTAssertEqual(CitationType.report.rawValue, "report")
        XCTAssertEqual(CitationType.thesis.rawValue, "thesis")
        XCTAssertEqual(CitationType.conference.rawValue, "conference")

        XCTAssertEqual(CitationType.allCases.count, 6)
    }

    // MARK: - Hashable Tests

    func testCitationHashable() {
        let citation1 = Citation(
            id: "test8",
            authors: "Author A",
            year: "2024",
            title: "Title",
            journal: "Journal"
        )

        let citation2 = Citation(
            id: "test8",
            authors: "Author A",
            year: "2024",
            title: "Title",
            journal: "Journal"
        )

        XCTAssertEqual(citation1, citation2)
        XCTAssertEqual(citation1.hashValue, citation2.hashValue)
    }

    func testCitationNotEqual() {
        let citation1 = Citation(
            id: "test9",
            authors: "Author A",
            year: "2024",
            title: "Title",
            journal: "Journal"
        )

        let citation2 = Citation(
            id: "test10",
            authors: "Author B",
            year: "2023",
            title: "Different Title",
            journal: "Other Journal"
        )

        XCTAssertNotEqual(citation1, citation2)
    }
}
