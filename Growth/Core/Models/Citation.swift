//
//  Citation.swift
//  Growth
//
//  Created by Developer on 10/6/25.
//

import Foundation
import FirebaseFirestore

/// Type of scientific citation source
enum CitationType: String, Codable, CaseIterable {
    case journalArticle
    case book
    case bookChapter
    case report
    case thesis
    case conference
}

/// Model representing a scientific citation for educational resources
struct Citation: Codable, Identifiable, Hashable {
    /// Unique identifier for the citation
    let id: String

    /// Authors in APA format (e.g., "Smith, J., & Jones, A.")
    let authors: String

    /// Publication year
    let year: String

    /// Title of the research or article
    let title: String

    /// Journal or publication source
    let journal: String

    /// Volume number (optional)
    let volume: String?

    /// Issue number (optional, e.g., "2" in "109(2)")
    let issue: String?

    /// Page range (optional, e.g., "45-67")
    let pages: String?

    /// Digital Object Identifier (optional)
    let doi: String?

    /// PubMed ID (optional)
    let pmid: String?

    /// URL to the source (optional)
    let url: String?

    /// Date when the source was accessed (optional)
    let accessDate: Date?

    /// Type of citation source
    let citationType: CitationType

    // Explicit memberwise initializer for previews and testing
    init(
        id: String,
        authors: String,
        year: String,
        title: String,
        journal: String,
        volume: String? = nil,
        issue: String? = nil,
        pages: String? = nil,
        doi: String? = nil,
        pmid: String? = nil,
        url: String? = nil,
        accessDate: Date? = nil,
        citationType: CitationType = .journalArticle
    ) {
        self.id = id
        self.authors = authors
        self.year = year
        self.title = title
        self.journal = journal
        self.volume = volume
        self.issue = issue
        self.pages = pages
        self.doi = doi
        self.pmid = pmid
        self.url = url
        self.accessDate = accessDate
        self.citationType = citationType
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case authors
        case year
        case title
        case journal
        case volume
        case issue
        case pages
        case doi
        case pmid
        case url
        case accessDate = "access_date"
        case citationType = "citation_type"
    }

    // MARK: - APA Formatting

    /// Formatted citation in APA 7th edition style
    var formattedAPA: String {
        var formatted = "\(authors). (\(year)). \(title). *\(journal)*"

        if let vol = volume, !vol.isEmpty {
            formatted += ", *\(vol)*"
            if let iss = issue, !iss.isEmpty {
                formatted += "(\(iss))"
            }
            if let pgs = pages, !pgs.isEmpty {
                formatted += ", \(pgs)"
            }
        }

        if let doi = doi, !doi.isEmpty {
            formatted += ". https://doi.org/\(doi)"
        } else if let pmid = pmid, !pmid.isEmpty {
            formatted += ". PMID: \(pmid)"
        } else if let url = url, !url.isEmpty {
            formatted += ". \(url)"
        }

        return formatted
    }

    // MARK: - Firestore Conversion

    /// Creates a Citation from a Firestore document
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else {
            Logger.error("Error: Document data was nil for Citation ID: \(document.documentID)")
            return nil
        }

        // Extract required fields
        guard let id = data["id"] as? String,
              let authors = data["authors"] as? String,
              let year = data["year"] as? String,
              let title = data["title"] as? String,
              let journal = data["journal"] as? String else {
            Logger.error("Error: Missing required fields for Citation ID: \(document.documentID)")
            return nil
        }

        self.id = id
        self.authors = authors
        self.year = year
        self.title = title
        self.journal = journal

        // Extract optional fields
        self.volume = data["volume"] as? String
        self.issue = data["issue"] as? String
        self.pages = data["pages"] as? String
        self.doi = data["doi"] as? String
        self.pmid = data["pmid"] as? String
        self.url = data["url"] as? String

        // Extract access date if present
        if let timestamp = data["access_date"] as? Timestamp {
            self.accessDate = timestamp.dateValue()
        } else {
            self.accessDate = nil
        }

        // Extract citation type, default to journalArticle if missing
        if let typeString = data["citation_type"] as? String,
           let type = CitationType(rawValue: typeString) {
            self.citationType = type
        } else {
            self.citationType = .journalArticle
        }
    }

    /// Converts the Citation to a dictionary for Firestore
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            CodingKeys.id.rawValue: id,
            CodingKeys.authors.rawValue: authors,
            CodingKeys.year.rawValue: year,
            CodingKeys.title.rawValue: title,
            CodingKeys.journal.rawValue: journal,
            CodingKeys.citationType.rawValue: citationType.rawValue
        ]

        if let vol = volume {
            data[CodingKeys.volume.rawValue] = vol
        }

        if let iss = issue {
            data[CodingKeys.issue.rawValue] = iss
        }

        if let pgs = pages {
            data[CodingKeys.pages.rawValue] = pgs
        }

        if let doi = doi {
            data[CodingKeys.doi.rawValue] = doi
        }

        if let pmid = pmid {
            data[CodingKeys.pmid.rawValue] = pmid
        }

        if let url = url {
            data[CodingKeys.url.rawValue] = url
        }

        if let accessDate = accessDate {
            data[CodingKeys.accessDate.rawValue] = Timestamp(date: accessDate)
        }

        return data
    }
}
