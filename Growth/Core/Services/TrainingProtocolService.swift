//
//  TrainingProtocolService.swift
//  Growth
//
//  Renamed from GrowthMethodService.swift for Epic 5 Story 5.3
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

/// Service for fetching training protocol data from Firestore
class TrainingProtocolService {
    /// Shared instance for singleton access
    static let shared = TrainingProtocolService()

    /// Firestore database reference
    private let db = Firestore.firestore()

    /// Collection name for training protocols in Firestore
    /// CRITICAL: Collection name "growth_exercises" preserved for backward compatibility
    private let collectionName = "growth_exercises"

    /// In-memory cache for training protocols
    private var protocolsCache = NSCache<NSString, NSArray>()

    /// Cache for individual protocols (internal for cache lookup)
    var protocolCache = NSCache<NSString, NSCoding>()

    /// Last fetch time to control refresh frequency
    private var lastFetchTimestamp: Date?

    /// Time interval for cache expiration (30 minutes)
    private let cacheExpirationInterval: TimeInterval = 30 * 60

    /// Private initializer for singleton
    private init() {
        // Configure cache limits
        protocolsCache.countLimit = 1 // We only need to cache one list of protocols
        protocolCache.countLimit = 50 // Limit individual protocol cache to 50 items
    }

    /// Fetch all training protocols from Firestore or cache
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh from Firestore
    ///   - completion: Completion handler with result
    func fetchAllMethods(forceRefresh: Bool = false, completion: @escaping (Result<[TrainingProtocol], Error>) -> Void) {
        // Check if we should use cached data
        if !forceRefresh,
           let lastFetch = lastFetchTimestamp,
           Date().timeIntervalSince(lastFetch) < cacheExpirationInterval,
           let cachedProtocols = protocolsCache.object(forKey: "allMethods") as? [TrainingProtocol] {
            // Return cached data if available and not expired
            Logger.info("TrainingProtocolService: Using cached protocols (\(cachedProtocols.count) protocols)")
            completion(.success(cachedProtocols))
            return
        }

        Logger.info("TrainingProtocolService: Fetching protocols from Firestore collection: \(collectionName)")

        // Fetch from Firestore
        db.collection(collectionName).getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                Logger.info("TrainingProtocolService: Self reference lost")
                completion(.failure(NSError(domain: "TrainingProtocolService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Service reference lost"])))
                return
            }

            if let error = error {
                Logger.error("TrainingProtocolService: Error fetching protocols: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                Logger.info("TrainingProtocolService: No documents found in collection")
                // Return empty array instead of error if no documents exist
                completion(.success([]))
                return
            }

            Logger.info("TrainingProtocolService: Processing \(documents.count) documents")

            let protocols = documents.compactMap { document -> TrainingProtocol? in
                // No need for do-catch since TrainingProtocol(document:) doesn't throw
                if let `protocol` = TrainingProtocol(document: document) {
                    Logger.info("TrainingProtocolService: Successfully parsed document: \(document.documentID)")
                    return `protocol`
                } else {
                    Logger.error("TrainingProtocolService: Failed to parse document with ID: \(document.documentID)")

                    // Let's try to diagnose the issue
                    let data = document.data()
                    Logger.info("TrainingProtocolService: Document data: \(data.keys.joined(separator: ", "))")

                    if let title = data["title"] as? String {
                        Logger.info("TrainingProtocolService: Title: \(title)")
                    } else {
                        Logger.info("TrainingProtocolService: Missing title field")
                    }

                    // Check if description or similar field exists
                    if let desc = data["description"] as? String {
                        Logger.info("TrainingProtocolService: Has description field: \(desc.prefix(20))...")
                    } else {
                        Logger.info("TrainingProtocolService: Missing description field")
                    }

                    return nil
                }
            }

            Logger.info("TrainingProtocolService: Successfully parsed \(protocols.count) protocols")

            // Update cache
            self.protocolsCache.setObject(protocols as NSArray, forKey: "allMethods")
            self.lastFetchTimestamp = Date()

            // Cache individual protocols for faster access
            for `protocol` in protocols {
                if let id = `protocol`.id, let data = try? NSKeyedArchiver.archivedData(withRootObject: `protocol`, requiringSecureCoding: false) {
                    self.protocolCache.setObject(data as NSData, forKey: id as NSString)
                }
            }

            completion(.success(protocols))
        }
    }

    /// Fetch actionable training protocols (excludes Level 0/educational protocols) from Firestore or cache
    /// Level 0 protocols are educational content meant for the Learning Center, not actionable training.
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh from Firestore
    ///   - completion: Completion handler with result containing only stage > 0 protocols
    func fetchActionableProtocols(forceRefresh: Bool = false, completion: @escaping (Result<[TrainingProtocol], Error>) -> Void) {
        // Check if we should use cached data
        if !forceRefresh,
           let lastFetch = lastFetchTimestamp,
           Date().timeIntervalSince(lastFetch) < cacheExpirationInterval,
           let cachedProtocols = protocolsCache.object(forKey: "actionableMethods") as? [TrainingProtocol] {
            // Return cached data if available and not expired
            Logger.info("TrainingProtocolService: Using cached actionable protocols (\(cachedProtocols.count) protocols)")
            completion(.success(cachedProtocols))
            return
        }

        Logger.info("TrainingProtocolService: Fetching actionable protocols (filtering stage > 0)")

        // Fetch all protocols first, then filter in-memory
        // This approach is more efficient than a Firestore query for small datasets
        fetchAllMethods(forceRefresh: forceRefresh) { [weak self] result in
            guard let self = self else {
                Logger.info("TrainingProtocolService: Self reference lost")
                completion(.failure(NSError(domain: "TrainingProtocolService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Service reference lost"])))
                return
            }

            switch result {
            case .success(let allProtocols):
                // Filter out Level 0 (educational) protocols
                // Only include stage > 0 (actionable training protocols)
                let actionableProtocols = allProtocols.filter { $0.stage > 0 }

                Logger.info("TrainingProtocolService: Filtered to \(actionableProtocols.count) actionable protocols (excluded \(allProtocols.count - actionableProtocols.count) Level 0 protocols)")

                // Cache the filtered list separately
                self.protocolsCache.setObject(actionableProtocols as NSArray, forKey: "actionableMethods")

                completion(.success(actionableProtocols))

            case .failure(let error):
                Logger.error("TrainingProtocolService: Error fetching protocols for filtering: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    /// Fetch a single training protocol by ID
    /// - Parameters:
    ///   - id: Protocol ID to fetch
    ///   - forceRefresh: Whether to force a refresh from Firestore
    ///   - completion: Completion handler with result
    func fetchMethod(withId id: String, forceRefresh: Bool = false, completion: @escaping (Result<TrainingProtocol, Error>) -> Void) {
        // Check cache first
        if !forceRefresh, let cachedData = protocolCache.object(forKey: id as NSString) as? Data,
           let cachedProtocol = try? NSKeyedUnarchiver.unarchivedObject(ofClass: TrainingProtocol.self, from: cachedData) {
            completion(.success(cachedProtocol))
            return
        }

        // Fetch from Firestore by document ID
        db.collection(collectionName).document(id).getDocument { [weak self] documentSnapshot, error in
            guard let self = self else { return }

            if let fetchError = error {
                Logger.error("TrainingProtocolService: Firestore error while fetching protocol \(id): \(fetchError.localizedDescription)")
                // Try local sample fallback
                if let sample = SampleGrowthMethods.getSampleGrowthMethod(for: id) {
                    completion(.success(sample))
                    return
                }
                completion(.failure(fetchError))
                return
            }

            guard let document = documentSnapshot, document.exists else {
                // Try local sample fallback
                if let sample = SampleGrowthMethods.getSampleGrowthMethod(for: id) {
                    completion(.success(sample))
                    return
                }
                completion(.failure(NSError(domain: "TrainingProtocolService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Protocol not found or document does not exist."])))
                return
            }

            guard let `protocol` = TrainingProtocol(document: document) else {
                completion(.failure(NSError(domain: "TrainingProtocolService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse protocol data from document \(id)."])))
                return
            }

            // Cache the protocol
            if let id = `protocol`.id, let data = try? NSKeyedArchiver.archivedData(withRootObject: `protocol`, requiringSecureCoding: false) {
                self.protocolCache.setObject(data as NSData, forKey: id as NSString)
            }

            completion(.success(`protocol`))
        }
    }

    /// Search protocols by keyword (searches title, description, and instructions)
    /// - Parameters:
    ///   - keyword: Search term
    ///   - completion: Completion handler with result
    func searchMethods(keyword: String, completion: @escaping (Result<[TrainingProtocol], Error>) -> Void) {
        // Get all protocols first, then filter locally (more efficient for small datasets)
        fetchAllMethods { result in
            switch result {
            case .success(let protocols):
                // If keyword is empty, return all protocols
                if keyword.isEmpty {
                    completion(.success(protocols))
                    return
                }

                // Case-insensitive search
                let lowercasedKeyword = keyword.lowercased()

                // Filter protocols that match the keyword
                let filteredProtocols = protocols.filter { `protocol` in
                    `protocol`.title.lowercased().contains(lowercasedKeyword) ||
                    `protocol`.protocolDescription.lowercased().contains(lowercasedKeyword) ||
                    `protocol`.instructionsText.lowercased().contains(lowercasedKeyword)
                }

                completion(.success(filteredProtocols))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Filter protocols by category
    /// - Parameters:
    ///   - category: Category to filter by
    ///   - completion: Completion handler with result
    func filterByCategory(category: String, completion: @escaping (Result<[TrainingProtocol], Error>) -> Void) {
        // Get all protocols first, then filter locally (more efficient for small datasets)
        fetchAllMethods { result in
            switch result {
            case .success(let protocols):
                // Filter protocols by category
                let filteredProtocols = protocols.filter { `protocol` in
                    `protocol`.categories.contains(category)
                }

                completion(.success(filteredProtocols))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Clear cache (useful when user logs out or for testing)
    /// Clears both allMethods and actionableMethods caches
    func clearCache() {
        protocolsCache.removeAllObjects()
        protocolCache.removeAllObjects()
        lastFetchTimestamp = nil
    }

    /// Upload sample protocols to Firestore for testing and demo purposes
    /// - Parameter protocols: Array of training protocols to upload
    ///   - Returns: A publisher that completes when all protocols are uploaded
    func uploadSampleMethods(_ protocols: [TrainingProtocol]) -> AnyPublisher<Void, Error> {
        let batch = db.batch()

        // Create a publisher for each protocol upload
        let uploads = protocols.map { `protocol` -> AnyPublisher<Void, Error> in
            Future<Void, Error> { [weak self] promise in
                guard let self = self else {
                    promise(.failure(NSError(domain: "TrainingProtocolService", code: 500,
                                           userInfo: [NSLocalizedDescriptionKey: "Service not available"])))
                    return
                }

                // Create a reference for this protocol
                if let id = `protocol`.id {
                    let docRef = self.db.collection(self.collectionName).document(id)

                    // Prepare the data
                    let data: [String: Any] = [
                        "methodId": id,
                        "stage": `protocol`.stage,
                        "title": `protocol`.title,
                        "description": `protocol`.protocolDescription,
                        "instructions_text": `protocol`.instructionsText,
                        "visual_placeholder_url": `protocol`.visualPlaceholderUrl ?? "",
                        "equipment_needed": `protocol`.equipmentNeeded,
                        "estimated_time_minutes": `protocol`.estimatedDurationMinutes ?? 0,
                        "categories": `protocol`.categories,
                        "timestamp": FieldValue.serverTimestamp()
                    ]

                    // Add document to batch
                    batch.setData(data, forDocument: docRef, merge: true)
                }

                // Since we're using a batch, we'll resolve immediately
                promise(.success(()))
            }
            .eraseToAnyPublisher()
        }

        // Combine all upload publishers
        return Publishers.MergeMany(uploads)
            .collect()
            .flatMap { _ -> AnyPublisher<Void, Error> in
                // Execute the batch
                return Future<Void, Error> { promise in
                    batch.commit { error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            // Clear cache after successful upload
                            self.clearCache()
                            promise(.success(()))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Upload sample protocols to Firestore (for development/testing)
    /// - Parameters:
    ///   - protocols: Array of training protocol objects to upload
    ///   - completion: Callback with result of the operation
    func uploadSampleMethods(methods: [TrainingProtocol], completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()

        for `protocol` in methods {
            if let id = `protocol`.id {
                let docRef = db.collection(collectionName).document(id)
                batch.setData(`protocol`.toDictionary(), forDocument: docRef)
            }
        }

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Clear cache to ensure fresh data on next fetch
                self.protocolsCache.removeAllObjects()
                self.protocolCache.removeAllObjects()
                self.lastFetchTimestamp = nil

                completion(.success(()))
            }
        }
    }
}
