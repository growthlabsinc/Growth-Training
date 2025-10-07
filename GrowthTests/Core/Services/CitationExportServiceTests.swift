//
//  CitationExportServiceTests.swift
//  GrowthTests
//
//  Unit tests for CitationExportService
//  Created by Developer on 10/6/25.
//

import XCTest
@testable import Growth

final class CitationExportServiceTests: XCTestCase {

    var service: CitationExportService!
    var testCitation: Citation!

    override func setUp() {
        super.setUp()
        service = CitationExportService.shared

        testCitation = Citation(
            id: "test1",
            authors: "Smith, J. & Jones, A.",
            year: "2024",
            title: "Test Article Title",
            journal: "Journal of Testing",
            volume: "10",
            issue: "2",
            pages: "123-145",
            doi: "10.1234/test2024",
            pmid: "12345678",
            url: "https://example.com/article",
            citationType: .journalArticle
        )
    }

    override func tearDown() {
        service = nil
        testCitation = nil
        super.tearDown()
    }

    // MARK: - BibTeX Export Tests

    func testExportToBibTeXSingleCitation() {
        let result = service.exportToBibTeX([testCitation])

        XCTAssertTrue(result.contains("@article"))
        XCTAssertTrue(result.contains("author = {Smith, J. & Jones, A.}"))
        XCTAssertTrue(result.contains("title = {Test Article Title}"))
        XCTAssertTrue(result.contains("journal = {Journal of Testing}"))
        XCTAssertTrue(result.contains("year = {2024}"))
        XCTAssertTrue(result.contains("volume = {10}"))
        XCTAssertTrue(result.contains("number = {2}"))
        XCTAssertTrue(result.contains("pages = {123-145}"))
        XCTAssertTrue(result.contains("doi = {10.1234/test2024}"))
    }

    func testExportToBibTeXMultipleCitations() {
        let citation2 = Citation(
            id: "test2",
            authors: "Brown, M.",
            year: "2023",
            title: "Another Article",
            journal: "Another Journal",
            citationType: .book
        )

        let result = service.exportToBibTeX([testCitation, citation2])

        // Should contain both citations
        XCTAssertTrue(result.contains("@article"))
        XCTAssertTrue(result.contains("@book"))
        XCTAssertTrue(result.contains("Test Article Title"))
        XCTAssertTrue(result.contains("Another Article"))
    }

    func testBibTeXEscapesSpecialCharacters() {
        let citationWithSpecialChars = Citation(
            id: "special",
            authors: "Author & Co.",
            year: "2024",
            title: "Title with $pecial & Ch@racters #1",
            journal: "Journal",
            citationType: .journalArticle
        )

        let result = service.exportToBibTeX([citationWithSpecialChars])

        XCTAssertTrue(result.contains("\\&")) // Escaped ampersand
        XCTAssertTrue(result.contains("\\$")) // Escaped dollar
        XCTAssertTrue(result.contains("\\#")) // Escaped hash
    }

    func testBibTeXCitationType() {
        let book = Citation(id: "b1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .book)
        let chapter = Citation(id: "c1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .bookChapter)
        let report = Citation(id: "r1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .report)
        let thesis = Citation(id: "t1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .thesis)
        let conf = Citation(id: "co1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .conference)

        XCTAssertTrue(service.exportToBibTeX([book]).contains("@book"))
        XCTAssertTrue(service.exportToBibTeX([chapter]).contains("@inbook"))
        XCTAssertTrue(service.exportToBibTeX([report]).contains("@techreport"))
        XCTAssertTrue(service.exportToBibTeX([thesis]).contains("@phdthesis"))
        XCTAssertTrue(service.exportToBibTeX([conf]).contains("@inproceedings"))
    }

    // MARK: - RIS Export Tests

    func testExportToRISSingleCitation() {
        let result = service.exportToRIS([testCitation])

        XCTAssertTrue(result.contains("TY  - JOUR"))
        XCTAssertTrue(result.contains("AU  - Smith"))
        XCTAssertTrue(result.contains("TI  - Test Article Title"))
        XCTAssertTrue(result.contains("JO  - Journal of Testing"))
        XCTAssertTrue(result.contains("PY  - 2024"))
        XCTAssertTrue(result.contains("VL  - 10"))
        XCTAssertTrue(result.contains("IS  - 2"))
        XCTAssertTrue(result.contains("DO  - 10.1234/test2024"))
        XCTAssertTrue(result.contains("N1  - PMID: 12345678"))
        XCTAssertTrue(result.contains("ER  -"))
    }

    func testRISPageRangeSplitting() {
        let result = service.exportToRIS([testCitation])

        // Pages "123-145" should be split into SP and EP
        XCTAssertTrue(result.contains("SP  - 123"))
        XCTAssertTrue(result.contains("EP  - 145"))
    }

    func testRISCitationType() {
        let book = Citation(id: "b1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .book)
        let chapter = Citation(id: "c1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .bookChapter)
        let report = Citation(id: "r1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .report)
        let thesis = Citation(id: "t1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .thesis)
        let conf = Citation(id: "co1", authors: "A", year: "2024", title: "T", journal: "J", citationType: .conference)

        XCTAssertTrue(service.exportToRIS([book]).contains("TY  - BOOK"))
        XCTAssertTrue(service.exportToRIS([chapter]).contains("TY  - CHAP"))
        XCTAssertTrue(service.exportToRIS([report]).contains("TY  - RPRT"))
        XCTAssertTrue(service.exportToRIS([thesis]).contains("TY  - THES"))
        XCTAssertTrue(service.exportToRIS([conf]).contains("TY  - CONF"))
    }

    // MARK: - Plain Text Export Tests

    func testExportToPlainText() {
        let result = service.exportToPlainText([testCitation])

        // Should use APA formatted output
        XCTAssertTrue(result.contains("Smith, J. & Jones, A."))
        XCTAssertTrue(result.contains("(2024)"))
        XCTAssertTrue(result.contains("Test Article Title"))
    }

    // MARK: - Format Citation for Copy Tests

    func testFormatCitationForCopyAPA() {
        let result = service.formatCitationForCopy(testCitation, format: .apa)

        XCTAssertTrue(result.contains("Smith, J. & Jones, A."))
        XCTAssertTrue(result.contains("(2024)"))
    }

    func testFormatCitationForCopyBibTeX() {
        let result = service.formatCitationForCopy(testCitation, format: .bibtex)

        XCTAssertTrue(result.contains("@article"))
        XCTAssertTrue(result.contains("author = {"))
    }

    func testFormatCitationForCopyRIS() {
        let result = service.formatCitationForCopy(testCitation, format: .ris)

        XCTAssertTrue(result.contains("TY  - JOUR"))
        XCTAssertTrue(result.contains("ER  -"))
    }

    // MARK: - Export Format Tests

    func testExportFormatProperties() {
        XCTAssertEqual(ExportFormat.apa.fileExtension, "txt")
        XCTAssertEqual(ExportFormat.bibtex.fileExtension, "bib")
        XCTAssertEqual(ExportFormat.ris.fileExtension, "ris")

        XCTAssertEqual(ExportFormat.apa.mimeType, "text/plain")
        XCTAssertEqual(ExportFormat.bibtex.mimeType, "application/x-bibtex")
        XCTAssertEqual(ExportFormat.ris.mimeType, "application/x-research-info-systems")

        XCTAssertEqual(ExportFormat.allCases.count, 3)
    }

    // MARK: - Empty Input Tests

    func testExportEmptyArray() {
        let bibtexResult = service.exportToBibTeX([])
        let risResult = service.exportToRIS([])
        let plainResult = service.exportToPlainText([])

        XCTAssertTrue(bibtexResult.isEmpty)
        XCTAssertTrue(risResult.isEmpty)
        XCTAssertTrue(plainResult.isEmpty)
    }
}
