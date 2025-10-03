//
//  NetworkService.swift
//  Growth
//
//  Created by Developer on 7/15/25.
//

import Foundation

/// Service for handling network requests
class NetworkService {
    /// Shared instance for singleton access
    static let shared = NetworkService()
    
    /// URL session for network requests
    private let session: URLSession
    
    /// Default request timeout in seconds
    private let defaultTimeout: TimeInterval = 30.0
    
    /// Initialize the network service
    /// - Parameter session: URLSession to use (defaults to shared session)
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Make a GET request to the specified URL
    /// - Parameters:
    ///   - url: URL to request
    ///   - headers: Optional headers to include
    /// - Returns: Response data
    func get(from url: URL, headers: [String: String]? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = defaultTimeout
        
        // Add headers if provided
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return data
    }
    
    /// Make a POST request to the specified URL
    /// - Parameters:
    ///   - url: URL to request
    ///   - body: Body data to send
    ///   - headers: Optional headers to include
    /// - Returns: Response data
    func post(to url: URL, body: Data, headers: [String: String]? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = defaultTimeout
        
        // Add Content-Type header if not specified
        var requestHeaders = headers ?? [:]
        if requestHeaders["Content-Type"] == nil {
            requestHeaders["Content-Type"] = "application/json"
        }
        
        // Add headers
        requestHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return data
    }
    
    /// Make a POST request with JSON body
    /// - Parameters:
    ///   - url: URL to request
    ///   - json: JSON object to encode and send
    ///   - headers: Optional headers to include
    /// - Returns: Response data
    func postJSON<T: Encodable>(to url: URL, json: T, headers: [String: String]? = nil) async throws -> Data {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(json)
        return try await post(to: url, body: jsonData, headers: headers)
    }
    
    /// Validate the HTTP response
    /// - Parameter response: URLResponse to validate
    /// - Throws: NetworkError if response is invalid
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            return
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimitExceeded
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
}

/// Network request errors
enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case rateLimitExceeded
    case serverError(Int)
    case unexpectedStatusCode(Int)
    case encodingError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .badRequest:
            return "Bad request. Please check your input."
        case .unauthorized:
            return "Authentication required. Please log in."
        case .forbidden:
            return "Access forbidden. You don't have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .unexpectedStatusCode(let code):
            return "Unexpected error (Status \(code)). Please try again later."
        case .encodingError:
            return "Failed to encode request data."
        case .decodingError:
            return "Failed to decode response data."
        }
    }
} 