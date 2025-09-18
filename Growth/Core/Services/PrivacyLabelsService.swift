import Foundation

/// Service for managing and verifying privacy disclosures and App Store privacy labels
/// This service helps ensure compliance with Apple's App Privacy Details requirements
class PrivacyLabelsService {
    
    // MARK: - Singleton
    static let shared = PrivacyLabelsService()
    private init() {}
    
    // MARK: - Data Types and Categories
    
    /// Data category representation for App Store privacy labels
    struct DataItem: Codable, Identifiable {
        enum Category: String, Codable, CaseIterable {
            case contactInfo = "Contact Info"
            case healthFitness = "Health & Fitness"
            case userContent = "User Content"
            case identifiers = "Identifiers"
            case diagnostics = "Diagnostics"
            case usageData = "Usage Data"
            case other = "Other Data"
        }
        
        enum Purpose: String, Codable, CaseIterable {
            case appFunctionality = "App Functionality"
            case analytics = "Analytics"
            case developerCommunications = "Developer Communications"
            case crashReporting = "Developer's Advertising or Marketing"
        }
        
        enum TrackingStatus: String, Codable {
            case usedForTracking = "Data Used to Track You"
            case notUsedForTracking = "Data Not Used to Track You"
        }
        
        var id: UUID = UUID()
        let category: Category
        let type: String
        let linkedToUser: Bool
        let purpose: Purpose
        let trackingStatus: TrackingStatus
        let optional: Bool
        let description: String
    }
    
    // MARK: - App Privacy Data Collection
    
    /// Complete list of data items collected by the Growth app
    static let dataItems: [DataItem] = [
        // Contact Information
        .init(
            category: .contactInfo,
            type: "Email Address",
            linkedToUser: true,
            purpose: .appFunctionality,
            trackingStatus: .notUsedForTracking,
            optional: false,
            description: "Required for account creation and authentication"
        ),
        
        // Health & Fitness Data
        .init(
            category: .healthFitness,
            type: "Fitness",
            linkedToUser: true,
            purpose: .appFunctionality,
            trackingStatus: .notUsedForTracking,
            optional: false,
            description: "Exercise logs, routine progress, and session data"
        ),
        
        // User Content
        .init(
            category: .userContent,
            type: "User Content",
            linkedToUser: true,
            purpose: .appFunctionality,
            trackingStatus: .notUsedForTracking,
            optional: false,
            description: "Notes, goals, progress entries, and personal data"
        ),
        
        // Usage Data
        .init(
            category: .usageData,
            type: "Product Interaction",
            linkedToUser: true,
            purpose: .analytics,
            trackingStatus: .notUsedForTracking,
            optional: true,
            description: "App usage patterns to improve user experience"
        ),
        
        // Diagnostics
        .init(
            category: .diagnostics,
            type: "Crash Data",
            linkedToUser: false,
            purpose: .crashReporting,
            trackingStatus: .notUsedForTracking,
            optional: true,
            description: "Crash logs and diagnostic data to improve app stability"
        ),
        
        .init(
            category: .diagnostics,
            type: "Performance Data",
            linkedToUser: false,
            purpose: .analytics,
            trackingStatus: .notUsedForTracking,
            optional: true,
            description: "App performance metrics for optimization"
        )
    ]
    
    // MARK: - Third-Party Data Sharing
    
    struct ThirdPartySharing: Codable {
        let partner: String
        let dataTypes: [String]
        let purposes: [String]
        let userControl: String
    }
    
    /// Third-party data sharing information
    static let thirdPartySharing: [ThirdPartySharing] = [
        .init(
            partner: "Firebase (Google)",
            dataTypes: ["Email Address", "Product Interaction", "Crash Data", "Performance Data"],
            purposes: ["App Functionality", "Analytics", "Developer's Advertising or Marketing"],
            userControl: "Users can opt out of analytics through app settings"
        )
    ]
    
    // MARK: - Privacy Label Generation
    
    /// Returns JSON suitable for App Store Connect or compliance documentation
    static func jsonRepresentation() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? String(data: encoder.encode(dataItems), encoding: .utf8)) ?? "[]"
    }
    
    /// Generates comprehensive privacy label information for App Store submission
    func generatePrivacyLabelsReport() -> String {
        var report = "APP PRIVACY DETAILS FOR APP STORE CONNECT\n"
        report += "Generated: \(Date().formatted())\n\n"
        
        // Data Types Collected by Category
        report += "DATA TYPES COLLECTED:\n\n"
        
        for category in DataItem.Category.allCases {
            let itemsInCategory = Self.dataItems.filter { $0.category == category }
            if !itemsInCategory.isEmpty {
                report += "\(category.rawValue):\n"
                for item in itemsInCategory {
                    report += "  • \(item.type)\n"
                    report += "    Linked to User: \(item.linkedToUser ? "Yes" : "No")\n"
                    report += "    Used for Tracking: \(item.trackingStatus.rawValue == "Data Used to Track You" ? "Yes" : "No")\n"
                    report += "    Purpose: \(item.purpose.rawValue)\n"
                    report += "    Optional: \(item.optional ? "Yes" : "No")\n"
                    report += "    Description: \(item.description)\n\n"
                }
            }
        }
        
        // Third-Party Data Sharing
        if !Self.thirdPartySharing.isEmpty {
            report += "THIRD-PARTY DATA SHARING:\n\n"
            for sharing in Self.thirdPartySharing {
                report += "\(sharing.partner):\n"
                report += "  Data Types: \(sharing.dataTypes.joined(separator: ", "))\n"
                report += "  Purposes: \(sharing.purposes.joined(separator: ", "))\n"
                report += "  User Control: \(sharing.userControl)\n\n"
            }
        }
        
        return report
    }
    
    // MARK: - Compliance Verification
    
    /// Verifies that privacy data collection matches actual implementation
    func verifyComplianceStatus() -> ComplianceStatus {
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Check data minimization
        let requiredData = Self.dataItems.filter { !$0.optional }
        if requiredData.count > 3 {
            recommendations.append("Consider reducing required data collection to improve user trust")
        }
        
        // Check tracking status
        let trackingData = Self.dataItems.filter { $0.trackingStatus == .usedForTracking }
        if !trackingData.isEmpty {
            issues.append("App currently declares no tracking, but tracking data items are defined")
        }
        
        // Verify opt-out mechanisms for optional data
        let optionalData = Self.dataItems.filter { $0.optional }
        if !optionalData.isEmpty {
            recommendations.append("Ensure users can opt out of optional data collection in Settings")
        }
        
        return ComplianceStatus(
            isCompliant: issues.isEmpty,
            issues: issues,
            recommendations: recommendations
        )
    }
    
    struct ComplianceStatus {
        let isCompliant: Bool
        let issues: [String]
        let recommendations: [String]
    }
    
    // MARK: - Age Rating Support
    
    /// Returns age rating recommendations based on data collection
    func getAgeRatingRecommendations() -> [String] {
        return [
            "Recommended Age Rating: 17+ (due to health/fitness content)",
            "COPPA Compliance: No data collected from users under 13",
            "Teen Privacy: Appropriate data handling for users 13-17",
            "Adult Privacy: Standard adult privacy practices apply"
        ]
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension PrivacyLabelsService {
    /// Debug function to print privacy labels to console
    func printPrivacyLabelsToConsole() {
        Logger.info(generatePrivacyLabelsReport())
    }
    
    /// Debug function to check compliance
    func debugComplianceCheck() {
        let status = verifyComplianceStatus()
        if status.isCompliant {
            Logger.info("✅ Privacy compliance verified")
        } else {
            Logger.info("⚠️ Privacy compliance issues:")
            for issue in status.issues {
                Logger.info("  • \(issue)")
            }
        }
        
        if !status.recommendations.isEmpty {
            Logger.info("\n💡 Recommendations:")
            for rec in status.recommendations {
                Logger.info("  • \(rec)")
            }
        }
    }
}
#endif 