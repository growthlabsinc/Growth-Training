//
//  GrowthMethodService.swift
//  Growth
//
//  Created by Developer on 5/9/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

/// Service for fetching growth method data from Firestore
class GrowthMethodService {
    /// Shared instance for singleton access
    static let shared = GrowthMethodService()
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Collection name for growth methods in Firestore
    private let collectionName = "growthMethods"
    
    /// In-memory cache for growth methods
    private var methodsCache = NSCache<NSString, NSArray>()
    
    /// Cache for individual methods (internal for cache lookup)
    var methodCache = NSCache<NSString, NSCoding>()
    
    /// Last fetch time to control refresh frequency
    private var lastFetchTimestamp: Date?
    
    /// Time interval for cache expiration (30 minutes)
    private let cacheExpirationInterval: TimeInterval = 30 * 60
    
    /// Private initializer for singleton
    private init() {
        // Configure cache limits
        methodsCache.countLimit = 1 // We only need to cache one list of methods
        methodCache.countLimit = 50 // Limit individual method cache to 50 items
    }
    
    /// Fetch all growth methods from Firestore or cache
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh from Firestore
    ///   - completion: Completion handler with result
    func fetchAllMethods(forceRefresh: Bool = false, completion: @escaping (Result<[GrowthMethod], Error>) -> Void) {
        // Check if we should use cached data
        if !forceRefresh, 
           let lastFetch = lastFetchTimestamp, 
           Date().timeIntervalSince(lastFetch) < cacheExpirationInterval,
           let cachedMethods = methodsCache.object(forKey: "allMethods") as? [GrowthMethod] {
            // Return cached data if available and not expired
            Logger.info("GrowthMethodService: Using cached methods (\(cachedMethods.count) methods)")
            completion(.success(cachedMethods))
            return
        }
        
        Logger.info("GrowthMethodService: Fetching methods from Firestore collection: \(collectionName)")
        
        // Fetch from Firestore
        db.collection(collectionName).getDocuments { [weak self] snapshot, error in
            guard let self = self else { 
                Logger.info("GrowthMethodService: Self reference lost")
                completion(.failure(NSError(domain: "GrowthMethodService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Service reference lost"])))
                return 
            }
            
            if let error = error {
                Logger.error("GrowthMethodService: Error fetching methods: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                Logger.info("GrowthMethodService: No documents found in collection")
                // Return empty array instead of error if no documents exist
                completion(.success([]))
                return
            }
            
            Logger.info("GrowthMethodService: Processing \(documents.count) documents")
            
            let methods = documents.compactMap { document -> GrowthMethod? in
                // No need for do-catch since GrowthMethod(document:) doesn't throw
                if let method = GrowthMethod(document: document) {
                    Logger.info("GrowthMethodService: Successfully parsed document: \(document.documentID)")
                    return method
                } else {
                    Logger.error("GrowthMethodService: Failed to parse document with ID: \(document.documentID)")
                    
                    // Let's try to diagnose the issue
                    let data = document.data()
                    Logger.info("GrowthMethodService: Document data: \(data.keys.joined(separator: ", "))")
                    
                    if let title = data["title"] as? String {
                        Logger.info("GrowthMethodService: Title: \(title)")
                    } else {
                        Logger.info("GrowthMethodService: Missing title field")
                    }
                    
                    // Check if description or similar field exists
                    if let desc = data["description"] as? String {
                        Logger.info("GrowthMethodService: Has description field: \(desc.prefix(20))...")
                    } else {
                        Logger.info("GrowthMethodService: Missing description field")
                    }
                    
                    return nil
                }
            }
            
            Logger.info("GrowthMethodService: Successfully parsed \(methods.count) methods")
            
            // Update cache
            self.methodsCache.setObject(methods as NSArray, forKey: "allMethods")
            self.lastFetchTimestamp = Date()
            
            // Cache individual methods for faster access
            for method in methods {
                if let id = method.id, let data = try? NSKeyedArchiver.archivedData(withRootObject: method, requiringSecureCoding: false) {
                    self.methodCache.setObject(data as NSData, forKey: id as NSString)
                }
            }
            
            completion(.success(methods))
        }
    }
    
    /// Fetch a single growth method by ID
    /// - Parameters:
    ///   - id: Method ID to fetch
    ///   - forceRefresh: Whether to force a refresh from Firestore
    ///   - completion: Completion handler with result
    func fetchMethod(withId id: String, forceRefresh: Bool = false, completion: @escaping (Result<GrowthMethod, Error>) -> Void) {
        // Check cache first
        if !forceRefresh, let cachedData = methodCache.object(forKey: id as NSString) as? Data,
           let cachedMethod = try? NSKeyedUnarchiver.unarchivedObject(ofClass: GrowthMethod.self, from: cachedData) {
            completion(.success(cachedMethod))
            return
        }
        
        // Fetch from Firestore by document ID
        db.collection(collectionName).document(id).getDocument { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let fetchError = error {
                Logger.error("GrowthMethodService: Firestore error while fetching method \(id): \(fetchError.localizedDescription)")
                // Try local sample fallback
                if let sample = SampleGrowthMethods.method(for: id) {
                    completion(.success(sample))
                    return
                }
                completion(.failure(fetchError))
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                // Try local sample fallback
                if let sample = SampleGrowthMethods.method(for: id) {
                    completion(.success(sample))
                    return
                }
                completion(.failure(NSError(domain: "GrowthMethodService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Method not found or document does not exist."])))
                return
            }
            
            guard let method = GrowthMethod(document: document) else {
                completion(.failure(NSError(domain: "GrowthMethodService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse method data from document \(id)."])))
                return
            }
            
            // Cache the method
            if let id = method.id, let data = try? NSKeyedArchiver.archivedData(withRootObject: method, requiringSecureCoding: false) {
                self.methodCache.setObject(data as NSData, forKey: id as NSString)
            }
            
            completion(.success(method))
        }
    }
    
    /// Search methods by keyword (searches title, description, and instructions)
    /// - Parameters:
    ///   - keyword: Search term
    ///   - completion: Completion handler with result
    func searchMethods(keyword: String, completion: @escaping (Result<[GrowthMethod], Error>) -> Void) {
        // Get all methods first, then filter locally (more efficient for small datasets)
        fetchAllMethods { result in
            switch result {
            case .success(let methods):
                // If keyword is empty, return all methods
                if keyword.isEmpty {
                    completion(.success(methods))
                    return
                }
                
                // Case-insensitive search
                let lowercasedKeyword = keyword.lowercased()
                
                // Filter methods that match the keyword
                let filteredMethods = methods.filter { method in
                    method.title.lowercased().contains(lowercasedKeyword) ||
                    method.methodDescription.lowercased().contains(lowercasedKeyword) ||
                    method.instructionsText.lowercased().contains(lowercasedKeyword)
                }
                
                completion(.success(filteredMethods))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Filter methods by category
    /// - Parameters:
    ///   - category: Category to filter by
    ///   - completion: Completion handler with result
    func filterByCategory(category: String, completion: @escaping (Result<[GrowthMethod], Error>) -> Void) {
        // Get all methods first, then filter locally (more efficient for small datasets)
        fetchAllMethods { result in
            switch result {
            case .success(let methods):
                // Filter methods by category
                let filteredMethods = methods.filter { method in
                    method.categories.contains(category)
                }
                
                completion(.success(filteredMethods))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Clear cache (useful when user logs out or for testing)
    func clearCache() {
        methodsCache.removeAllObjects()
        methodCache.removeAllObjects()
        lastFetchTimestamp = nil
    }
    
    /// Upload sample methods to Firestore for testing and demo purposes
    /// - Parameter methods: Array of growth methods to upload
    ///   - Returns: A publisher that completes when all methods are uploaded
    func uploadSampleMethods(_ methods: [GrowthMethod]) -> AnyPublisher<Void, Error> {
        let batch = db.batch()
        
        // Create a publisher for each method upload
        let uploads = methods.map { method -> AnyPublisher<Void, Error> in
            Future<Void, Error> { [weak self] promise in
                guard let self = self else {
                    promise(.failure(NSError(domain: "GrowthMethodService", code: 500, 
                                           userInfo: [NSLocalizedDescriptionKey: "Service not available"])))
                    return
                }
                
                // Create a reference for this method
                if let id = method.id {
                    let docRef = self.db.collection(self.collectionName).document(id)
                    
                    // Prepare the data
                    let data: [String: Any] = [
                        "methodId": id,
                        "stage": method.stage,
                        "title": method.title,
                        "description": method.methodDescription,
                        "instructions_text": method.instructionsText,
                        "visual_placeholder_url": method.visualPlaceholderUrl ?? "",
                        "equipment_needed": method.equipmentNeeded,
                        "estimated_time_minutes": method.estimatedDurationMinutes ?? 0,
                        "categories": method.categories,
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
    
    /// Upload sample methods to Firestore (for development/testing)
    /// - Parameters:
    ///   - methods: Array of growth method objects to upload
    ///   - completion: Callback with result of the operation
    func uploadSampleMethods(methods: [GrowthMethod], completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()
        
        for method in methods {
            if let id = method.id {
                let docRef = db.collection(collectionName).document(id)
                batch.setData(method.toDictionary(), forDocument: docRef)
            }
        }
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Clear cache to ensure fresh data on next fetch
                self.methodsCache.removeAllObjects()
                self.methodCache.removeAllObjects()
                self.lastFetchTimestamp = nil
                
                completion(.success(()))
            }
        }
    }
}