//
//  Citation.swift
//  Growth
//
//  Created by Developer on 10/6/25.
//

import Foundation
import FirebaseFirestore

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

    /// Page range (optional, e.g., "45-67")
    let pages: String?

    /// Digital Object Identifier (optional)
    let doi: String?

    /// URL to the source (optional)
    let url: String?

    // Explicit memberwise initializer for previews and testing
    init(
        id: String,
        authors: String,
        year: String,
        title: String,
        journal: String,
        volume: String? = nil,
        pages: String? = nil,
        doi: String? = nil,
        url: String? = nil
    ) {
        self.id = id
        self.authors = authors
        self.year = year
        self.title = title
        self.journal = journal
        self.volume = volume
        self.pages = pages
        self.doi = doi
        self.url = url
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case authors
        case year
        case title
        case journal
        case volume
        case pages
        case doi
        case url
    }

    // MARK: - APA Formatting

    /// Formatted citation in APA 7th edition style
    var formattedAPA: String {
        var formatted = "\(authors). (\(year)). \(title). *\(journal)*"

        if let vol = volume, !vol.isEmpty {
            formatted += ", *\(vol)*"
            if let pgs = pages, !pgs.isEmpty {
                formatted += ", \(pgs)"
            }
        }

        if let doi = doi, !doi.isEmpty {
            formatted += ". https://doi.org/\(doi)"
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
        self.pages = data["pages"] as? String
        self.doi = data["doi"] as? String
        self.url = data["url"] as? String
    }

    /// Converts the Citation to a dictionary for Firestore
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            CodingKeys.id.rawValue: id,
            CodingKeys.authors.rawValue: authors,
            CodingKeys.year.rawValue: year,
            CodingKeys.title.rawValue: title,
            CodingKeys.journal.rawValue: journal
        ]

        if let vol = volume {
            data[CodingKeys.volume.rawValue] = vol
        }

        if let pgs = pages {
            data[CodingKeys.pages.rawValue] = pgs
        }

        if let doi = doi {
            data[CodingKeys.doi.rawValue] = doi
        }

        if let url = url {
            data[CodingKeys.url.rawValue] = url
        }

        return data
    }
}
