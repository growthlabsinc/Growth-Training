//
//  EducationalResource.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import Foundation
import FirebaseFirestore
// import FirebaseFirestoreSwift // Removed deprecated import

/// Model representing an educational resource in the application
struct EducationalResource: Codable, Identifiable, Hashable {
    /// Unique identifier for the educational resource, mapped from Firestore document ID
    @DocumentID var id: String?
    
    /// Title of the resource
    let title: String
    
    /// Main content text of the resource
    let contentText: String
    
    /// Category of the resource (stored as string, may not match enum)
    let category: ResourceCategory

    /// Raw category string from Firestore (for categories not in enum)
    let categoryRaw: String?
    
    /// URL for an image placeholder
    let visualPlaceholderUrl: String?
    
    /// Local image asset name (takes precedence over visualPlaceholderUrl if provided)
    let localImageName: String?

    /// Array of scientific citations for the resource (optional)
    let citations: [Citation]?

    /// Medical disclaimer text for safety warnings (optional)
    let medicalDisclaimer: String?

    /// Last verification timestamp for citations (optional)
    let lastVerified: Date?

    /// Verification status of citations (optional)
    /// Possible values: "verified", "broken_links", "needs_review"
    let verificationStatus: String?

    /// Subcategories for more specific classification (optional)
    let subcategories: [String]?

    /// Reading difficulty level (optional)
    let readingLevel: String?

    /// Word count of the article (optional)
    let wordCount: Int?

    /// Number of citations (optional)
    let citationCount: Int?

    /// Medical review status (optional)
    let medicalReviewStatus: String?

    /// Legal review status (optional)
    let legalReviewStatus: String?

    /// Last updated timestamp (optional)
    let lastUpdated: String?

    /// Firestore creation timestamp (optional)
    let createdAt: Date?

    /// Firestore update timestamp (optional)
    let updatedAt: Date?

    // MARK: - Custom Codable Implementation

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode simple fields
        title = try container.decode(String.self, forKey: .title)
        contentText = try container.decode(String.self, forKey: .contentText)
        visualPlaceholderUrl = try container.decodeIfPresent(String.self, forKey: .visualPlaceholderUrl)
        localImageName = try container.decodeIfPresent(String.self, forKey: .localImageName)
        citations = try container.decodeIfPresent([Citation].self, forKey: .citations)
        medicalDisclaimer = try container.decodeIfPresent(String.self, forKey: .medicalDisclaimer)
        lastVerified = try container.decodeIfPresent(Date.self, forKey: .lastVerified)
        verificationStatus = try container.decodeIfPresent(String.self, forKey: .verificationStatus)
        subcategories = try container.decodeIfPresent([String].self, forKey: .subcategories)
        readingLevel = try container.decodeIfPresent(String.self, forKey: .readingLevel)
        wordCount = try container.decodeIfPresent(Int.self, forKey: .wordCount)
        citationCount = try container.decodeIfPresent(Int.self, forKey: .citationCount)
        medicalReviewStatus = try container.decodeIfPresent(String.self, forKey: .medicalReviewStatus)
        legalReviewStatus = try container.decodeIfPresent(String.self, forKey: .legalReviewStatus)
        lastUpdated = try container.decodeIfPresent(String.self, forKey: .lastUpdated)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        // Decode category with fallback
        let categoryString = try container.decode(String.self, forKey: .category)
        categoryRaw = categoryString

        // Try to map to enum, fallback to .science if unknown
        if let mappedCategory = ResourceCategory(rawValue: categoryString) {
            category = mappedCategory
        } else {
            // Map unknown categories to .science as default
            category = .science
        }
    }

    // Explicit memberwise initializer for previews and testing
    init(id: String? = nil, title: String, contentText: String, category: ResourceCategory, visualPlaceholderUrl: String? = nil, localImageName: String? = nil, citations: [Citation]? = nil, medicalDisclaimer: String? = nil, lastVerified: Date? = nil, verificationStatus: String? = nil, subcategories: [String]? = nil, readingLevel: String? = nil, wordCount: Int? = nil, citationCount: Int? = nil, medicalReviewStatus: String? = nil, legalReviewStatus: String? = nil, lastUpdated: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, categoryRaw: String? = nil) {
        self.id = id
        self.title = title
        self.contentText = contentText
        self.category = category
        self.categoryRaw = categoryRaw
        self.visualPlaceholderUrl = visualPlaceholderUrl
        self.localImageName = localImageName
        self.citations = citations
        self.medicalDisclaimer = medicalDisclaimer
        self.lastVerified = lastVerified
        self.verificationStatus = verificationStatus
        self.subcategories = subcategories
        self.readingLevel = readingLevel
        self.wordCount = wordCount
        self.citationCount = citationCount
        self.medicalReviewStatus = medicalReviewStatus
        self.legalReviewStatus = legalReviewStatus
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        // 'id' is handled by @DocumentID, so it's not included here.
        // If 'id' were a regular field *in* the Firestore document (e.g., named "resourceId"),
        // then it would be: case id = "resourceId"
        case title // Assumes Firestore field name is "title"
        case contentText = "content_text" // Explicitly maps to "content_text" in Firestore
        case category // Assumes Firestore field name is "category"
        case categoryRaw // Not stored in Firestore, computed from category
        case visualPlaceholderUrl = "visual_placeholder_url" // Explicitly maps
        case localImageName = "local_image_name" // Maps to "local_image_name" in Firestore
        case citations // Maps to "citations" array in Firestore
        case medicalDisclaimer = "medical_disclaimer" // Maps to "medical_disclaimer" in Firestore
        case lastVerified = "last_verified" // Maps to "last_verified" timestamp in Firestore
        case verificationStatus = "verification_status" // Maps to "verification_status" string in Firestore
        case subcategories
        case readingLevel = "reading_level"
        case wordCount = "word_count"
        case citationCount = "citation_count"
        case medicalReviewStatus = "medical_review_status"
        case legalReviewStatus = "legal_review_status"
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Firestore Conversion
    
    /// Creates an EducationalResource from a Firestore document.
    /// This manual initializer is kept for flexibility, e.g., if some fetch paths
    /// don't use `document.data(as: Type.self)`.
    /// However, ensure it's consistent with Codable mapping if both are used.
    init?(document: DocumentSnapshot) {
        self.id = document.documentID // Always set the id from the document's actual ID

        guard let data = document.data() else {
            Logger.error("Error: Document data was nil for ID: \(document.documentID)")
            return nil
        }
        
        // Extract required fields from the document data
        guard let title = data["title"] as? String,
              let contentText = data["content_text"] as? String, // Corresponds to CodingKeys
              let categoryString = data["category"] as? String else {
            Logger.error("Error: Missing or invalid required fields (title, content_text, category) for document ID: \(document.documentID)")
            return nil
        }

        self.title = title
        self.contentText = contentText
        self.categoryRaw = categoryString

        // Try to map category to enum, fallback to .science if unknown
        if let mappedCategory = ResourceCategory(rawValue: categoryString) {
            self.category = mappedCategory
        } else {
            self.category = .science
        }

        // Extract optional fields
        self.visualPlaceholderUrl = data["visual_placeholder_url"] as? String // Corresponds to CodingKeys
        self.localImageName = data["local_image_name"] as? String // Corresponds to CodingKeys

        // Parse citations array if present
        if let citationsArray = data["citations"] as? [[String: Any]] {
            self.citations = citationsArray.compactMap { citationData in
                guard let id = citationData["id"] as? String,
                      let authors = citationData["authors"] as? String,
                      let year = citationData["year"] as? String,
                      let title = citationData["title"] as? String,
                      let journal = citationData["journal"] as? String else {
                    return nil
                }

                // Parse citation type, default to journalArticle
                let citationType: CitationType
                if let typeString = citationData["citation_type"] as? String,
                   let type = CitationType(rawValue: typeString) {
                    citationType = type
                } else {
                    citationType = .journalArticle
                }

                // Parse access date if present
                let accessDate: Date?
                if let timestamp = citationData["access_date"] as? Timestamp {
                    accessDate = timestamp.dateValue()
                } else {
                    accessDate = nil
                }

                return Citation(
                    id: id,
                    authors: authors,
                    year: year,
                    title: title,
                    journal: journal,
                    volume: citationData["volume"] as? String,
                    issue: citationData["issue"] as? String,
                    pages: citationData["pages"] as? String,
                    doi: citationData["doi"] as? String,
                    pmid: citationData["pmid"] as? String,
                    url: citationData["url"] as? String,
                    accessDate: accessDate,
                    citationType: citationType
                )
            }
        } else {
            self.citations = nil
        }

        // Extract medical disclaimer
        self.medicalDisclaimer = data["medical_disclaimer"] as? String

        // Extract verification fields
        if let verifiedTimestamp = data["last_verified"] as? Timestamp {
            self.lastVerified = verifiedTimestamp.dateValue()
        } else {
            self.lastVerified = nil
        }
        self.verificationStatus = data["verification_status"] as? String

        // Extract additional metadata fields
        self.subcategories = data["subcategories"] as? [String]
        self.readingLevel = data["reading_level"] as? String
        self.wordCount = data["word_count"] as? Int
        self.citationCount = data["citation_count"] as? Int
        self.medicalReviewStatus = data["medical_review_status"] as? String
        self.legalReviewStatus = data["legal_review_status"] as? String
        self.lastUpdated = data["last_updated"] as? String

        // Extract Firestore timestamps
        if let createdTimestamp = data["created_at"] as? Timestamp {
            self.createdAt = createdTimestamp.dateValue()
        } else {
            self.createdAt = nil
        }

        if let updatedTimestamp = data["updated_at"] as? Timestamp {
            self.updatedAt = updatedTimestamp.dateValue()
        } else {
            self.updatedAt = nil
        }
    }
    
    /// Converts the EducationalResource to a dictionary for Firestore.
    /// This is generally used when *not* directly passing the Codable struct to `setData`.
    /// If passing the struct itself, Firestore uses `Encodable` conformance.
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            CodingKeys.title.rawValue: title,
            CodingKeys.contentText.rawValue: contentText,
            CodingKeys.category.rawValue: category.rawValue // Uses the rawValue of the enum
        ]
        
        // The 'id' field is typically not included when creating a *new* document,
        // as Firestore can auto-generate it. If updating an existing document where
        // the ID is known and part of the path, it's also not part of the data dictionary.
        // @DocumentID handles mapping it back when fetching.

        if let visualUrl = visualPlaceholderUrl {
            data[CodingKeys.visualPlaceholderUrl.rawValue] = visualUrl
        }
        
        if let localImage = localImageName {
            data[CodingKeys.localImageName.rawValue] = localImage
        }

        if let cites = citations {
            data[CodingKeys.citations.rawValue] = cites.map { $0.toFirestoreData() }
        }

        if let disclaimer = medicalDisclaimer {
            data[CodingKeys.medicalDisclaimer.rawValue] = disclaimer
        }

        return data
    }

    // Removed the LLM-added explicit Hashable conformance.
    // Swift will synthesize Hashable if all stored properties are Hashable.
    // If a custom one was here originally, it should be restored to its original form.
    // For now, assuming synthesized is sufficient or was the original state.
}

/// Categories for educational resources
enum ResourceCategory: String, Codable, CaseIterable, Hashable {
    /// Basic introductory content
    case basics = "Basics" // Capitalized to match assumed Firestore data
    
    /// Technical guidance and methodology
    case technique = "Technique" // Capitalized
    
    /// Scientific research and evidence
    case science = "Science" // Capitalized
    
    /// Safety information and precautions
    case safety = "Safety" // Capitalized
    
    /// Progression guidance and milestones
    case progression = "Progression" // Capitalized
} 