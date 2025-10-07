//
//  CitationService.swift
//  Growth
//
//  Created by Developer on 10/6/25.
//

import Foundation

/// Result of citation validation
struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
}

/// Service for managing citations: resolution, validation, and linking
class CitationService {

    static let shared = CitationService()

    private init() {}

    // MARK: - DOI Resolution

    /// Resolves a DOI to retrieve full citation metadata
    /// Uses CrossRef API (free, no API key required)
    func resolveDOI(_ doi: String) async throws -> Citation? {
        // Clean DOI (remove https://doi.org/ prefix if present)
        let cleanDOI = doi.replacingOccurrences(of: "https://doi.org/", with: "")
            .replacingOccurrences(of: "http://dx.doi.org/", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard !cleanDOI.isEmpty else {
            return nil
        }

        // CrossRef API endpoint
        let urlString = "https://api.crossref.org/works/\(cleanDOI)"
        guard let url = URL(string: urlString) else {
            throw CitationServiceError.invalidDOI
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CitationServiceError.apiError
        }

        // Parse CrossRef response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any] else {
            throw CitationServiceError.parsingError
        }

        return parseCrossRefResponse(message, doi: cleanDOI)
    }

    private func parseCrossRefResponse(_ data: [String: Any], doi: String) -> Citation? {
        // Extract required fields
        guard let titleArray = data["title"] as? [String],
              let title = titleArray.first else {
            return nil
        }

        // Extract authors
        let authorsArray = data["author"] as? [[String: Any]] ?? []
        let authorNames = authorsArray.compactMap { author -> String? in
            let family = author["family"] as? String ?? ""
            let given = author["given"] as? String ?? ""
            return family.isEmpty ? nil : "\(family), \(given.prefix(1))."
        }
        let authors = authorNames.joined(separator: ", ")

        // Extract publication info
        let year: String
        if let publishedDate = data["published-print"] as? [String: Any] ?? data["published-online"] as? [String: Any],
           let dateParts = publishedDate["date-parts"] as? [[Int]],
           let firstDate = dateParts.first,
           let yearInt = firstDate.first {
            year = String(yearInt)
        } else {
            year = "n.d."
        }

        // Extract journal
        let containerTitles = data["container-title"] as? [String] ?? []
        let journal = containerTitles.first ?? "Unknown Journal"

        // Extract volume, issue, pages
        let volume = data["volume"] as? String
        let issue = data["issue"] as? String
        let page = data["page"] as? String

        // Generate unique ID from DOI
        let id = "doi_\(doi.replacingOccurrences(of: "/", with: "_"))"

        return Citation(
            id: id,
            authors: authors.isEmpty ? "Unknown" : authors,
            year: year,
            title: title,
            journal: journal,
            volume: volume,
            issue: issue,
            pages: page,
            doi: doi,
            pmid: nil,
            url: "https://doi.org/\(doi)",
            accessDate: Date(),
            citationType: .journalArticle
        )
    }

    // MARK: - PubMed Lookup

    /// Fetches citation from PubMed using PMID
    /// Uses NCBI E-utilities API (free, no API key required for low volume)
    func fetchPubMedArticle(_ pmid: String) async throws -> Citation? {
        let cleanPMID = pmid.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "PMID:", with: "")
            .replacingOccurrences(of: "PMC", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard !cleanPMID.isEmpty else {
            return nil
        }

        // NCBI E-utilities efetch endpoint for PubMed
        let urlString = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=\(cleanPMID)&retmode=xml"
        guard let url = URL(string: urlString) else {
            throw CitationServiceError.invalidPMID
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CitationServiceError.apiError
        }

        // Parse PubMed XML response
        return parsePubMedXML(data, pmid: cleanPMID)
    }

    private func parsePubMedXML(_ data: Data, pmid: String) -> Citation? {
        // Simple XML parsing using XMLDocument (available in Foundation)
        guard let xmlString = String(data: data, encoding: .utf8) else {
            return nil
        }

        // Extract basic fields using string parsing (simple approach)
        // In production, use proper XML parser

        let title = extractXMLValue(xmlString, tag: "ArticleTitle") ?? "Unknown Title"
        let journal = extractXMLValue(xmlString, tag: "Title") ?? "Unknown Journal"
        let year = extractXMLValue(xmlString, tag: "Year") ?? "n.d."
        let volume = extractXMLValue(xmlString, tag: "Volume")
        let issue = extractXMLValue(xmlString, tag: "Issue")
        let pages = extractXMLValue(xmlString, tag: "MedlinePgn")

        // Extract DOI if available
        let doi = extractXMLValue(xmlString, tag: "ELocationID", attribute: "EIdType", value: "doi")

        // Extract authors (simplified - just get LastName)
        let authors = extractAuthors(from: xmlString)

        let id = "pmid_\(pmid)"

        return Citation(
            id: id,
            authors: authors,
            year: year,
            title: title,
            journal: journal,
            volume: volume,
            issue: issue,
            pages: pages,
            doi: doi,
            pmid: pmid,
            url: "https://pubmed.ncbi.nlm.nih.gov/\(pmid)/",
            accessDate: Date(),
            citationType: .journalArticle
        )
    }

    private func extractXMLValue(_ xml: String, tag: String, attribute: String? = nil, value: String? = nil) -> String? {
        if let attr = attribute, let val = value {
            // Extract value with specific attribute
            let pattern = "<\(tag)[^>]*\(attr)=\"\(val)\"[^>]*>([^<]*)</\(tag)>"
            if let range = xml.range(of: pattern, options: .regularExpression) {
                let match = String(xml[range])
                return match.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            }
        } else {
            // Simple tag extraction
            let pattern = "<\(tag)>([^<]*)</\(tag)>"
            if let range = xml.range(of: pattern, options: .regularExpression) {
                let match = String(xml[range])
                return match.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            }
        }
        return nil
    }

    private func extractAuthors(from xml: String) -> String {
        // Simple extraction of author last names
        let pattern = "<LastName>([^<]*)</LastName>"
        var authors: [String] = []

        var searchRange = xml.startIndex..<xml.endIndex
        while let range = xml.range(of: pattern, options: .regularExpression, range: searchRange) {
            let match = String(xml[range])
            if let name = match.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).split(separator: ">").last {
                authors.append(String(name))
            }
            searchRange = range.upperBound..<xml.endIndex
        }

        if authors.isEmpty {
            return "Unknown"
        } else if authors.count == 1 {
            return authors[0]
        } else {
            return "\(authors[0]) et al."
        }
    }

    // MARK: - Validation

    /// Validates a citation's completeness and checks for broken links
    func validateCitation(_ citation: Citation) async -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        // Check required fields
        if citation.authors.isEmpty {
            errors.append("Authors field is empty")
        }
        if citation.title.isEmpty {
            errors.append("Title field is empty")
        }
        if citation.journal.isEmpty {
            errors.append("Journal field is empty")
        }
        if citation.year.isEmpty {
            errors.append("Year field is empty")
        }

        // Check for at least one identifier
        if citation.doi == nil && citation.pmid == nil && citation.url == nil {
            warnings.append("No DOI, PMID, or URL provided - citation may be difficult to verify")
        }

        // Check URL if present
        if let urlString = citation.url, !urlString.isEmpty {
            let isValid = await checkURLValidity(urlString)
            if !isValid {
                warnings.append("URL appears to be broken or inaccessible: \(urlString)")
            }
        }

        // Check DOI format if present
        if let doi = citation.doi, !doi.isEmpty {
            if !isValidDOIFormat(doi) {
                warnings.append("DOI format appears invalid: \(doi)")
            }
        }

        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }

    // MARK: - Link Checking

    /// Checks if a URL is accessible
    func checkURLValidity(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // Use HEAD to avoid downloading content
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...399).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }

    private func isValidDOIFormat(_ doi: String) -> Bool {
        // DOI format: 10.XXXX/... (starts with 10. followed by registrant code and suffix)
        let pattern = "^10\\.\\d{4,}/[\\S]+$"
        return doi.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Errors

enum CitationServiceError: LocalizedError {
    case invalidDOI
    case invalidPMID
    case apiError
    case parsingError
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidDOI:
            return "Invalid DOI format"
        case .invalidPMID:
            return "Invalid PubMed ID format"
        case .apiError:
            return "API request failed"
        case .parsingError:
            return "Failed to parse API response"
        case .networkError:
            return "Network connection error"
        }
    }
}
