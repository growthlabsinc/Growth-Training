//
//  SourceDatabaseConverter.swift
//  Growth
//
//  Created by Developer on 10/6/25.
//
//  Utility to convert source-database.json to Citation models

import Foundation

/// Converts Story 7.2 source database JSON to Citation models
class SourceDatabaseConverter {

    struct SourceDatabase: Codable {
        let metadata: Metadata
        let sources: [Source]

        struct Metadata: Codable {
            let collectionDate: String
            let totalSources: Int
            let researchMethodology: String
            let topicsCovered: Int
            let qualityCriteria: String

            enum CodingKeys: String, CodingKey {
                case collectionDate = "collection_date"
                case totalSources = "total_sources"
                case researchMethodology = "research_methodology"
                case topicsCovered = "topics_covered"
                case qualityCriteria = "quality_criteria"
            }
        }

        struct Source: Codable {
            let id: String
            let category: String
            let title: String
            let authors: [String]
            let year: Int
            let journal: String
            let url: String
            let doi: String?
            let pubmedId: String?
            let openAccess: Bool
            let researchType: String
            let relevanceScore: Int
            let impactFactor: String
            let peerReviewed: Bool
            let keyFindings: String

            enum CodingKeys: String, CodingKey {
                case id, category, title, authors, year, journal, url, doi
                case pubmedId = "pubmed_id"
                case openAccess = "open_access"
                case researchType = "research_type"
                case relevanceScore = "relevance_score"
                case impactFactor = "impact_factor"
                case peerReviewed = "peer_reviewed"
                case keyFindings = "key_findings"
            }
        }
    }

    /// Converts source database JSON file to array of Citation models
    static func convertSourceDatabase(from jsonURL: URL) throws -> [Citation] {
        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        let database = try decoder.decode(SourceDatabase.self, from: data)

        return database.sources.map { convertSourceToCitation($0) }
    }

    /// Converts a single Source to Citation model
    static func convertSourceToCitation(_ source: SourceDatabase.Source) -> Citation {
        // Format authors as APA string
        let authors = formatAuthorsAPA(source.authors)

        // Clean DOI (remove "Available via PMC" text)
        let cleanDOI: String?
        if let doi = source.doi, !doi.isEmpty, doi != "Available via PMC", doi != "null" {
            cleanDOI = doi
        } else {
            cleanDOI = nil
        }

        // Clean PMID (handle PMC IDs and PMID format)
        let cleanPMID: String?
        if let pmid = source.pubmedId, !pmid.isEmpty {
            // Extract numeric ID from strings like "PMC10936890" or "PMID: 12345"
            let numericPMID = pmid.replacingOccurrences(of: "PMC", with: "")
                .replacingOccurrences(of: "PMID:", with: "")
                .replacingOccurrences(of: " ", with: "")
            cleanPMID = numericPMID.isEmpty ? nil : numericPMID
        } else {
            cleanPMID = nil
        }

        // Map research_type to CitationType
        let citationType = mapResearchTypeToCitationType(source.researchType)

        // Use source ID as citation ID
        let citationId = source.id

        return Citation(
            id: citationId,
            authors: authors,
            year: String(source.year),
            title: source.title,
            journal: source.journal,
            volume: nil, // Not provided in source database
            issue: nil,  // Not provided in source database
            pages: nil,  // Not provided in source database
            doi: cleanDOI,
            pmid: cleanPMID,
            url: source.url,
            accessDate: Date(), // Current date as access date
            citationType: citationType
        )
    }

    /// Formats author array to APA citation format
    private static func formatAuthorsAPA(_ authors: [String]) -> String {
        if authors.isEmpty {
            return "Unknown"
        }

        // For "Multiple authors", use that string
        if authors.count == 1 && authors[0].contains("Multiple") {
            return authors[0]
        }

        // For single author organization names
        if authors.count == 1 {
            return authors[0]
        }

        // For multiple authors
        if authors.count <= 2 {
            return authors.joined(separator: " & ")
        } else {
            // More than 2 authors: "First et al."
            return "\(authors[0]) et al."
        }
    }

    /// Maps research type string to CitationType enum
    private static func mapResearchTypeToCitationType(_ researchType: String) -> CitationType {
        let lowercased = researchType.lowercased()

        if lowercased.contains("review") || lowercased.contains("study") || lowercased.contains("research") {
            return .journalArticle
        } else if lowercased.contains("guideline") || lowercased.contains("reference") {
            return .report
        } else if lowercased.contains("book") {
            return .book
        } else if lowercased.contains("conference") {
            return .conference
        } else if lowercased.contains("thesis") {
            return .thesis
        } else {
            return .journalArticle // Default
        }
    }

    /// Convenience method to convert from file path string
    static func convertSourceDatabase(fromPath path: String) throws -> [Citation] {
        let url = URL(fileURLWithPath: path)
        return try convertSourceDatabase(from: url)
    }

    /// Export citations to Swift code for inclusion in app
    static func exportAsSwiftCode(_ citations: [Citation]) -> String {
        var code = "// Generated Citation Models from Source Database\n"
        code += "// Total: \(citations.count) citations\n\n"
        code += "let sourceDatabaseCitations: [Citation] = [\n"

        for citation in citations {
            code += "    Citation(\n"
            code += "        id: \"\(citation.id)\",\n"
            code += "        authors: \"\(escapeSwiftString(citation.authors))\",\n"
            code += "        year: \"\(citation.year)\",\n"
            code += "        title: \"\(escapeSwiftString(citation.title))\",\n"
            code += "        journal: \"\(escapeSwiftString(citation.journal))\",\n"
            code += "        doi: \(citation.doi.map { "\"\($0)\"" } ?? "nil"),\n"
            code += "        pmid: \(citation.pmid.map { "\"\($0)\"" } ?? "nil"),\n"
            code += "        url: \"\(citation.url ?? "")\",\n"
            code += "        citationType: .\(citation.citationType.rawValue)\n"
            code += "    ),\n"
        }

        code += "]\n"
        return code
    }

    private static func escapeSwiftString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

// MARK: - Usage Example (for testing/running conversion)

#if DEBUG
extension SourceDatabaseConverter {
    /// Example usage - can be called from app or test
    static func performConversion() {
        let projectRoot = "/Users/tradeflowj/Desktop/Dev/growth-training"
        let jsonPath = "\(projectRoot)/docs/content-research/source-database.json"

        do {
            let citations = try convertSourceDatabase(fromPath: jsonPath)
            print("✅ Successfully converted \(citations.count) sources to Citation models")

            // Print first few for verification
            print("\n📚 Sample Citations:")
            for (index, citation) in citations.prefix(3).enumerated() {
                print("\n\(index + 1). \(citation.title)")
                print("   Authors: \(citation.authors)")
                print("   Year: \(citation.year)")
                print("   Type: \(citation.citationType)")
                if let doi = citation.doi {
                    print("   DOI: \(doi)")
                }
                if let pmid = citation.pmid {
                    print("   PMID: \(pmid)")
                }
            }

            // Optionally export as Swift code
            // let swiftCode = exportAsSwiftCode(citations)
            // print("\n\n// Swift Code:\n\(swiftCode)")

        } catch {
            print("❌ Error converting source database: \(error)")
        }
    }
}
#endif
