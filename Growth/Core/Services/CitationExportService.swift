//
//  CitationExportService.swift
//  Growth
//
//  Created by Developer on 10/6/25.
//

import Foundation

/// Service for exporting citations to various formats
class CitationExportService {

    static let shared = CitationExportService()

    private init() {}

    // MARK: - BibTeX Export

    /// Exports citations to BibTeX format
    func exportToBibTeX(_ citations: [Citation]) -> String {
        var bibtex = ""

        for citation in citations {
            bibtex += convertToBibTeX(citation)
            bibtex += "\n\n"
        }

        return bibtex.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func convertToBibTeX(_ citation: Citation) -> String {
        // Determine BibTeX entry type based on citation type
        let entryType: String
        switch citation.citationType {
        case .journalArticle:
            entryType = "article"
        case .book:
            entryType = "book"
        case .bookChapter:
            entryType = "inbook"
        case .conference:
            entryType = "inproceedings"
        case .report:
            entryType = "techreport"
        case .thesis:
            entryType = "phdthesis"
        }

        // Generate citation key (first author last name + year)
        let citationKey = generateBibTeXKey(citation)

        var fields: [String] = []

        // Required fields
        fields.append("  author = {\(escapeBibTeX(citation.authors))}")
        fields.append("  title = {\(escapeBibTeX(citation.title))}")
        fields.append("  year = {\(citation.year)}")

        // Type-specific fields
        if citation.citationType == .journalArticle {
            fields.append("  journal = {\(escapeBibTeX(citation.journal))}")
        } else if citation.citationType == .book || citation.citationType == .bookChapter {
            fields.append("  publisher = {\(escapeBibTeX(citation.journal))}")
        } else {
            fields.append("  journal = {\(escapeBibTeX(citation.journal))}")
        }

        // Optional fields
        if let volume = citation.volume {
            fields.append("  volume = {\(volume)}")
        }
        if let issue = citation.issue {
            fields.append("  number = {\(issue)}")
        }
        if let pages = citation.pages {
            fields.append("  pages = {\(pages)}")
        }
        if let doi = citation.doi {
            fields.append("  doi = {\(doi)}")
        }
        if let url = citation.url {
            fields.append("  url = {\(url)}")
        }
        if let pmid = citation.pmid {
            fields.append("  note = {PMID: \(pmid)}")
        }

        let bibtex = """
        @\(entryType){\(citationKey),
        \(fields.joined(separator: ",\n"))
        }
        """

        return bibtex
    }

    private func generateBibTeXKey(_ citation: Citation) -> String {
        // Extract first author's last name
        let firstAuthor = citation.authors.components(separatedBy: ",").first ?? "Unknown"
        let lastName = firstAuthor.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").first ?? "Unknown"

        // Clean the last name (remove special characters)
        let cleanLastName = lastName.replacingOccurrences(of: "[^a-zA-Z]", with: "", options: .regularExpression)

        return "\(cleanLastName)\(citation.year)".replacingOccurrences(of: " ", with: "")
    }

    private func escapeBibTeX(_ string: String) -> String {
        // Escape special BibTeX characters
        return string
            .replacingOccurrences(of: "&", with: "\\&")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "#", with: "\\#")
            .replacingOccurrences(of: "_", with: "\\_")
            .replacingOccurrences(of: "{", with: "\\{")
            .replacingOccurrences(of: "}", with: "\\}")
    }

    // MARK: - RIS Export

    /// Exports citations to RIS format
    func exportToRIS(_ citations: [Citation]) -> String {
        var ris = ""

        for citation in citations {
            ris += convertToRIS(citation)
            ris += "\n\n"
        }

        return ris.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func convertToRIS(_ citation: Citation) -> String {
        var lines: [String] = []

        // Type of reference (TY)
        let risType: String
        switch citation.citationType {
        case .journalArticle:
            risType = "JOUR"
        case .book:
            risType = "BOOK"
        case .bookChapter:
            risType = "CHAP"
        case .conference:
            risType = "CONF"
        case .report:
            risType = "RPRT"
        case .thesis:
            risType = "THES"
        }
        lines.append("TY  - \(risType)")

        // Authors (AU) - split by comma and add each
        let authorList = citation.authors.components(separatedBy: ",")
        for author in authorList {
            let trimmed = author.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                lines.append("AU  - \(trimmed)")
            }
        }

        // Title (TI)
        lines.append("TI  - \(citation.title)")

        // Journal/Source (JO or T2 depending on type)
        if citation.citationType == .journalArticle {
            lines.append("JO  - \(citation.journal)")
        } else {
            lines.append("T2  - \(citation.journal)")
        }

        // Year (PY)
        lines.append("PY  - \(citation.year)")

        // Volume (VL)
        if let volume = citation.volume {
            lines.append("VL  - \(volume)")
        }

        // Issue (IS)
        if let issue = citation.issue {
            lines.append("IS  - \(issue)")
        }

        // Pages (SP and EP for start/end, or just SP for range)
        if let pages = citation.pages {
            if pages.contains("-") {
                let pageComponents = pages.components(separatedBy: "-")
                if pageComponents.count == 2 {
                    lines.append("SP  - \(pageComponents[0].trimmingCharacters(in: .whitespaces))")
                    lines.append("EP  - \(pageComponents[1].trimmingCharacters(in: .whitespaces))")
                }
            } else {
                lines.append("SP  - \(pages)")
            }
        }

        // DOI (DO)
        if let doi = citation.doi {
            lines.append("DO  - \(doi)")
        }

        // PMID (as note - N1)
        if let pmid = citation.pmid {
            lines.append("N1  - PMID: \(pmid)")
        }

        // URL (UR)
        if let url = citation.url {
            lines.append("UR  - \(url)")
        }

        // End of reference (ER)
        lines.append("ER  -")

        return lines.joined(separator: "\n")
    }

    // MARK: - Plain Text Export

    /// Exports citations to plain text (APA format)
    func exportToPlainText(_ citations: [Citation]) -> String {
        return citations.map { $0.formattedAPA }.joined(separator: "\n\n")
    }

    // MARK: - Copy Single Citation

    /// Returns formatted string for a single citation in specified format
    func formatCitationForCopy(_ citation: Citation, format: ExportFormat) -> String {
        switch format {
        case .apa:
            return citation.formattedAPA
        case .bibtex:
            return convertToBibTeX(citation)
        case .ris:
            return convertToRIS(citation)
        }
    }
}

// MARK: - Export Formats

enum ExportFormat: String, CaseIterable {
    case apa = "APA 7th Edition"
    case bibtex = "BibTeX"
    case ris = "RIS"

    var fileExtension: String {
        switch self {
        case .apa:
            return "txt"
        case .bibtex:
            return "bib"
        case .ris:
            return "ris"
        }
    }

    var mimeType: String {
        switch self {
        case .apa:
            return "text/plain"
        case .bibtex:
            return "application/x-bibtex"
        case .ris:
            return "application/x-research-info-systems"
        }
    }
}
