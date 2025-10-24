//
//  CitationExportService.swift
//  Growth
//
//  Created by Developer on 10/6/25.
//

import Foundation

/// Export format options for citations
enum CitationExportFormat: String, CaseIterable {
    case apa = "APA 7th Edition"
    case bibtex = "BibTeX"
    case plainText = "Plain Text"
    case ris = "RIS"

    var fileExtension: String {
        switch self {
        case .apa, .plainText:
            return "txt"
        case .bibtex:
            return "bib"
        case .ris:
            return "ris"
        }
    }
}

/// Service for exporting citations in various formats
class CitationExportService {
    static let shared = CitationExportService()

    private init() {}

    /// Format a citation for copying or exporting
    func formatCitationForCopy(_ citation: Citation, format: CitationExportFormat) -> String {
        switch format {
        case .apa:
            return formatAPA(citation)
        case .bibtex:
            return formatBibTeX(citation)
        case .plainText:
            return formatPlainText(citation)
        case .ris:
            return formatRIS(citation)
        }
    }

    // MARK: - Format Implementations

    private func formatAPA(_ citation: Citation) -> String {
        return citation.formattedAPA
    }

    private func formatBibTeX(_ citation: Citation) -> String {
        // Generate BibTeX key from first author and year
        let firstAuthor = citation.authors.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")
            .lowercased() ?? "unknown"
        let key = "\(firstAuthor)\(citation.year)"

        var bibtex = "@article{\(key),\n"
        bibtex += "  author = {\(citation.authors)},\n"
        bibtex += "  title = {\(citation.title)},\n"
        bibtex += "  journal = {\(citation.journal)},\n"
        bibtex += "  year = {\(citation.year)}"

        if let volume = citation.volume {
            bibtex += ",\n  volume = {\(volume)}"
        }

        if let issue = citation.issue {
            bibtex += ",\n  number = {\(issue)}"
        }

        if let pages = citation.pages {
            bibtex += ",\n  pages = {\(pages)}"
        }

        if let doi = citation.doi {
            bibtex += ",\n  doi = {\(doi)}"
        }

        if let pmid = citation.pmid {
            bibtex += ",\n  pmid = {\(pmid)}"
        }

        if let url = citation.url {
            bibtex += ",\n  url = {\(url)}"
        }

        bibtex += "\n}\n"
        return bibtex
    }

    private func formatPlainText(_ citation: Citation) -> String {
        var text = "Authors: \(citation.authors)\n"
        text += "Year: \(citation.year)\n"
        text += "Title: \(citation.title)\n"
        text += "Journal: \(citation.journal)\n"

        if let volume = citation.volume {
            text += "Volume: \(volume)\n"
        }

        if let issue = citation.issue {
            text += "Issue: \(issue)\n"
        }

        if let pages = citation.pages {
            text += "Pages: \(pages)\n"
        }

        if let doi = citation.doi {
            text += "DOI: \(doi)\n"
        }

        if let pmid = citation.pmid {
            text += "PubMed ID: \(pmid)\n"
        }

        if let url = citation.url {
            text += "URL: \(url)\n"
        }

        return text
    }

    private func formatRIS(_ citation: Citation) -> String {
        var ris = "TY  - JOUR\n"  // Journal article

        // Authors (one per line)
        let authors = citation.authors.components(separatedBy: " & ")
        for author in authors {
            ris += "AU  - \(author.trimmingCharacters(in: .whitespaces))\n"
        }

        ris += "TI  - \(citation.title)\n"
        ris += "T2  - \(citation.journal)\n"
        ris += "PY  - \(citation.year)\n"

        if let volume = citation.volume {
            ris += "VL  - \(volume)\n"
        }

        if let issue = citation.issue {
            ris += "IS  - \(issue)\n"
        }

        if let pages = citation.pages {
            ris += "SP  - \(pages)\n"
        }

        if let doi = citation.doi {
            ris += "DO  - \(doi)\n"
        }

        if let url = citation.url {
            ris += "UR  - \(url)\n"
        }

        ris += "ER  - \n"
        return ris
    }
}
