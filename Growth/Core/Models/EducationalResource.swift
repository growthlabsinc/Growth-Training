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
    
    /// Category of the resource
    let category: ResourceCategory
    
    /// URL for an image placeholder
    let visualPlaceholderUrl: String?
    
    /// Local image asset name (takes precedence over visualPlaceholderUrl if provided)
    let localImageName: String?
    
    // Explicit memberwise initializer for previews and testing
    init(id: String? = nil, title: String, contentText: String, category: ResourceCategory, visualPlaceholderUrl: String? = nil, localImageName: String? = nil) {
        self.id = id
        self.title = title
        self.contentText = contentText
        self.category = category
        self.visualPlaceholderUrl = visualPlaceholderUrl
        self.localImageName = localImageName
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        // 'id' is handled by @DocumentID, so it's not included here.
        // If 'id' were a regular field *in* the Firestore document (e.g., named "resourceId"),
        // then it would be: case id = "resourceId"
        case title // Assumes Firestore field name is "title"
        case contentText = "content_text" // Explicitly maps to "content_text" in Firestore
        case category // Assumes Firestore field name is "category"
        case visualPlaceholderUrl = "visual_placeholder_url" // Explicitly maps
        case localImageName = "local_image_name" // Maps to "local_image_name" in Firestore
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
              let categoryRaw = data["category"] as? String,
              let category = ResourceCategory(rawValue: categoryRaw) else { // Ensure categoryRaw matches enum cases
            Logger.error("Error: Missing or invalid required fields (title, content_text, category) for document ID: \(document.documentID)")
            return nil
        }
        
        self.title = title
        self.contentText = contentText
        self.category = category
        
        // Extract optional fields
        self.visualPlaceholderUrl = data["visual_placeholder_url"] as? String // Corresponds to CodingKeys
        self.localImageName = data["local_image_name"] as? String // Corresponds to CodingKeys
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