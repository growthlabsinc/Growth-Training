import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service responsible for fetching legal documents and recording user acceptance.
@MainActor
final class LegalDocumentService: ObservableObject {
    // MARK: - Singleton
    static let shared = LegalDocumentService()
    private init() {}
    
    // Firestore reference
    private let db = Firestore.firestore()
    
    // Cached documents
    @Published private(set) var documents: [String: LegalDocument] = [:]
    
    // MARK: - Fetching
    /// Fetch a document by ID from Firestore (or return cached version).
    func fetchDocument(withId id: String, completion: @escaping (LegalDocument?) -> Void) {
        Logger.info("LegalDocumentService: Fetching document \(id)")
        
        if let cached = documents[id] {
            Logger.info("LegalDocumentService: Returning cached document \(id)")
            completion(cached)
            return
        }
        
        db.collection("legalDocuments").document(id).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                Logger.info("LegalDocumentService: Self is nil")
                completion(nil)
                return
            }
            
            if let error = error {
                Logger.error("LegalDocumentService: Error fetching \(id): \(error.localizedDescription)")
                // Return default document if fetch fails
                completion(self.getDefaultDocument(for: id))
                return
            }
            
            guard let data = snapshot?.data() else {
                Logger.info("LegalDocumentService: No data found for \(id), using default")
                // Return default document if no data
                completion(self.getDefaultDocument(for: id))
                return
            }
            
            Logger.info("LegalDocumentService: Retrieved data for \(id): \(data.keys)")
            
            if let snapshot = snapshot, let doc = self.parseLegalDocument(id: snapshot.documentID, data: data) {
                self.documents[id] = doc
                Logger.info("LegalDocumentService: Successfully parsed and cached \(id)")
                completion(doc)
            } else {
                Logger.error("LegalDocumentService: Failed to parse document \(id)")
                completion(self.getDefaultDocument(for: id))
            }
        }
    }
    
    /// Get default document content for when Firestore fetch fails
    private func getDefaultDocument(for id: String) -> LegalDocument? {
        switch id {
        case "privacy_policy":
            return LegalDocument(
                id: id,
                title: "Privacy Policy",
                content: """
                PRIVACY POLICY

                Effective Date: January 6, 2025

                1. INTRODUCTION

                Welcome to Growth ("we," "our," or "us"). This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this privacy policy carefully.

                2. INFORMATION WE COLLECT

                We may collect information about you in a variety of ways:

                Personal Data:
                - Email address
                - Name (if provided)
                - User preferences and settings

                Health & Fitness Data:
                - Practice session logs
                - Progress measurements
                - Routine preferences
                - Goals and achievements

                Usage Data:
                - App interactions
                - Feature usage patterns
                - Device information
                - Crash reports and diagnostics

                3. HOW WE USE YOUR INFORMATION

                We use the information we collect to:
                - Provide and maintain our service
                - Track your progress and achievements
                - Send push notifications (if enabled)
                - Improve app performance and features
                - Ensure security and prevent fraud

                4. DATA STORAGE AND SECURITY

                Your data is stored securely using Firebase services with encryption at rest and in transit. We implement appropriate technical and organizational measures to protect your personal information.

                5. DATA SHARING

                We do not sell, trade, or rent your personal information to third parties. We may share information only in the following situations:
                - With your consent
                - To comply with legal obligations
                - To protect our rights and safety

                6. YOUR DATA RIGHTS

                You have the right to:
                - Access your personal data
                - Correct inaccurate data
                - Request deletion of your data
                - Export your data
                - Opt-out of certain data uses

                7. CHILDREN'S PRIVACY

                Our service is not intended for users under 18 years of age. We do not knowingly collect information from children under 18.

                8. THIRD-PARTY SERVICES

                We use the following third-party services:
                - Firebase (Google) for authentication and data storage
                - Analytics services for app improvement

                9. DATA RETENTION

                We retain your data for as long as your account is active or as needed to provide you services. You can request deletion at any time through the app settings.

                10. CHANGES TO THIS POLICY

                We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Effective Date" at the top of this policy.

                11. CONTACT US

                If you have questions about this Privacy Policy, please contact us at:
                - Email: support@growthlabs.coach
                - Website: https://www.growthlabs.coach/privacy-policy

                12. CALIFORNIA PRIVACY RIGHTS

                California residents have additional rights under the California Consumer Privacy Act (CCPA). You may request information about data collection and exercise your rights by contacting us.

                13. INTERNATIONAL DATA TRANSFERS

                Your information may be transferred to and processed in countries other than your country of residence. By using our app, you consent to such transfers.
                """,
                version: "1.0.0",
                lastUpdated: Date()
            )
        case "terms_of_use", "terms_of_service":
            return LegalDocument(
                id: id,
                title: "Terms of Use",
                content: """
                TERMS OF USE

                Effective Date: January 6, 2025

                1. ACCEPTANCE OF TERMS

                By downloading, installing, or using the Growth app ("Service"), you agree to be bound by these Terms of Use ("Terms"). If you do not agree to these Terms, do not use the Service.

                2. DESCRIPTION OF SERVICE

                Growth is a mobile application designed to provide educational content and tracking tools for personal development and physical wellness practices.

                3. USER ACCOUNTS

                - You must provide accurate and complete information when creating an account
                - You are responsible for maintaining the confidentiality of your account credentials
                - You are responsible for all activities that occur under your account
                - You must be at least 18 years old to use this Service

                4. ACCEPTABLE USE

                You agree not to:
                - Use the Service for any illegal purpose
                - Violate any laws in your jurisdiction
                - Transmit any malicious code or viruses
                - Attempt to gain unauthorized access to the Service
                - Harass, abuse, or harm other users
                - Use the Service in any way that could damage or overburden our infrastructure

                5. MEDICAL DISCLAIMER

                THE SERVICE DOES NOT PROVIDE MEDICAL ADVICE. The information provided is for educational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with qualified healthcare providers.

                6. INTELLECTUAL PROPERTY

                All content in the Service, including text, graphics, logos, and software, is the property of Growth or its licensors and is protected by intellectual property laws.

                7. USER CONTENT

                By submitting content to the Service, you:
                - Grant us a license to use, store, and display your content
                - Represent that you have the right to submit the content
                - Agree that we may use aggregated, anonymized data for service improvement

                8. PRIVACY

                Your use of the Service is also governed by our Privacy Policy, which is incorporated into these Terms by reference.

                9. DISCLAIMERS

                THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. We disclaim all warranties, express or implied, including:
                - MERCHANTABILITY
                - FITNESS FOR A PARTICULAR PURPOSE
                - NON-INFRINGEMENT
                - ACCURACY OR RELIABILITY OF INFORMATION

                10. LIMITATION OF LIABILITY

                TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE SERVICE.

                11. INDEMNIFICATION

                You agree to indemnify and hold harmless Growth and its affiliates from any claims arising from:
                - Your use of the Service
                - Your violation of these Terms
                - Your violation of any rights of another party

                12. TERMINATION

                We may terminate or suspend your account at any time for any reason. You may delete your account at any time through the app settings.

                13. CHANGES TO TERMS

                We reserve the right to modify these Terms at any time. We will notify users of material changes through the app or via email.

                14. GOVERNING LAW

                These Terms shall be governed by the laws of the United States, without regard to conflict of law principles.

                15. DISPUTE RESOLUTION

                Any disputes arising from these Terms shall be resolved through binding arbitration in accordance with the rules of the American Arbitration Association.

                16. SEVERABILITY

                If any provision of these Terms is found to be unenforceable, the remaining provisions shall continue in full force and effect.

                17. ENTIRE AGREEMENT

                These Terms constitute the entire agreement between you and Growth regarding the use of the Service.

                18. CONTACT INFORMATION

                For questions about these Terms, please contact us at:
                - Email: support@growthlabs.coach
                - Website: https://www.growthlabs.coach/terms
                """,
                version: "1.0.0",
                lastUpdated: Date()
            )
        case "medical_disclaimer", "disclaimer":
            return LegalDocument(
                id: id,
                title: "Medical Disclaimer",
                content: """
                MEDICAL DISCLAIMER AND SAFETY INFORMATION

                IMPORTANT: READ CAREFULLY BEFORE USING THE GROWTH APP

                1. NOT A SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE

                The Growth app provides educational information and tools for self-improvement purposes only. The content in this app is not intended to be a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.
                
                The exercise and wellness techniques discussed in this app are based on peer-reviewed scientific research. Key areas of research include:
                
                • Blood flow and vascular health (Tew et al., 2010; Green et al., 2011)
                • Tissue adaptation through mechanical stimulation (Schoenfeld, 2010; Hornberger & Esser, 2004)
                • Angiogenesis and vascular growth (Prior et al., 2004; Gavin et al., 2004)
                • Exercise recovery and adaptation (Dupuy et al., 2018; Schoenfeld et al., 2016)
                • Progressive training principles (Kraemer & Ratamess, 2004)
                • Injury prevention strategies (Lauersen et al., 2014)

                2. CONSULT HEALTHCARE PROVIDERS

                Before beginning any new exercise routine, mental practice, or health regimen suggested within this app, consult with appropriate healthcare providers, especially if you have any pre-existing physical or mental health conditions.

                3. ASSUMPTION OF RISK

                By using the Growth app, you understand and acknowledge that physical and mental exercises carry inherent risks. You assume full responsibility for your safety and well-being while using techniques described in this app.

                4. PHYSICAL ACTIVITY WARNINGS

                - Stop immediately if you experience pain, discomfort, or unusual symptoms
                - Do not exceed your physical limitations
                - Allow adequate recovery time between sessions
                - Stay hydrated and maintain proper nutrition
                - Use appropriate safety equipment when necessary

                5. MEDICAL CONDITIONS

                Do not use this app if you have:
                - Uncontrolled high blood pressure
                - Heart conditions or cardiovascular disease
                - Recent surgery or injury
                - Any condition that your doctor has advised against physical activity

                Unless cleared by your healthcare provider.

                6. LIMITATIONS OF APP CONTENT

                Information provided through Growth is general in nature and not tailored to individual circumstances. Methods described may not be appropriate for everyone. Results vary by individual.

                7. EMERGENCY SITUATIONS

                This app is not designed to address emergency situations. If you experience a medical emergency or feel you may harm yourself or others, stop using the app immediately and call emergency services (911) or go to your nearest emergency room.

                8. MONITORING AND SELF-AWARENESS

                Pay close attention to how your body and mind respond to any practice. Discontinue use if you experience:
                - Pain or discomfort
                - Dizziness or lightheadedness
                - Shortness of breath
                - Psychological distress
                - Any concerning symptoms

                9. PROFESSIONAL SUPERVISION

                Some techniques may require professional supervision or instruction. Do not attempt advanced practices without proper guidance.

                10. AGE RESTRICTIONS

                This app is intended for users 18 years and older. Minors should not use this app without parental supervision and consent.

                11. MEDICATION INTERACTIONS

                If you are taking any medications, consult your healthcare provider before beginning any new wellness practices, as some activities may interact with medications.

                12. DISCLAIMER OF WARRANTIES

                We make no representations or warranties about the accuracy, reliability, completeness, or timeliness of any content in the app. All content is provided "as is."

                13. INDIVIDUAL RESPONSIBILITY

                Your health and safety are your responsibility. We are not liable for any injuries or damages resulting from your use of the app or implementation of any techniques described within.

                By using the Growth app, you acknowledge that you have read, understood, and agree to all the warnings and disclaimers stated above.
                """,
                version: "1.0.0",
                lastUpdated: Date()
            )
        default:
            return nil
        }
    }
    
    private func parseLegalDocument(id: String, data: [String: Any]) -> LegalDocument? {
        guard let title = data["title"] as? String,
              let content = data["content"] as? String,
              let version = data["version"] as? String,
              let ts = data["lastUpdated"] as? Timestamp else {
            return nil
        }
        return LegalDocument(id: id, title: title, content: content, version: version, lastUpdated: ts.dateValue())
    }
    
    // MARK: - Acceptance Tracking
    /// Record that current user accepted given document version.
    func recordAcceptance(for document: LegalDocument, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "LegalDocumentService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        let data: [String: Any] = [
            "documentId": document.id,
            "documentVersion": document.version,
            "acceptedAt": FieldValue.serverTimestamp()
        ]
        db.collection("users").document(uid)
            .collection("documentAcceptances").document(document.id)
            .setData(data, merge: true) { error in
                completion(error)
            }
    }
    
    /// Record consent for a document and update user profile with consent record
    func recordConsentWithProfile(for document: LegalDocument, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "LegalDocumentService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let consentRecord = ConsentRecord(
            documentId: document.id,
            documentVersion: document.version,
            acceptedAt: Date(),
            ipAddress: nil
        )
        
        // Update both the documentAcceptances subcollection and the user profile
        let batch = db.batch()
        
        // Update documentAcceptances subcollection
        let acceptanceRef = db.collection("users").document(uid)
            .collection("documentAcceptances").document(document.id)
        let acceptanceData: [String: Any] = [
            "documentId": document.id,
            "documentVersion": document.version,
            "acceptedAt": FieldValue.serverTimestamp()
        ]
        batch.setData(acceptanceData, forDocument: acceptanceRef, merge: true)
        
        // Update user profile with consent record
        let userRef = db.collection("users").document(uid)
        let consentData: [String: Any] = [
            "documentId": consentRecord.documentId,
            "documentVersion": consentRecord.documentVersion,
            "acceptedAt": Timestamp(date: consentRecord.acceptedAt)
        ]
        batch.updateData([
            "consentRecords": FieldValue.arrayUnion([consentData])
        ], forDocument: userRef)
        
        // Commit the batch
        batch.commit { error in
            completion(error)
        }
    }
    
    /// Record consent for multiple documents at once
    func recordBatchConsent(for documents: [LegalDocument], completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "LegalDocumentService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let batch = db.batch()
        let userRef = db.collection("users").document(uid)
        
        var consentDataArray: [[String: Any]] = []
        
        for document in documents {
            // Update documentAcceptances subcollection
            let acceptanceRef = db.collection("users").document(uid)
                .collection("documentAcceptances").document(document.id)
            let acceptanceData: [String: Any] = [
                "documentId": document.id,
                "documentVersion": document.version,
                "acceptedAt": FieldValue.serverTimestamp()
            ]
            batch.setData(acceptanceData, forDocument: acceptanceRef, merge: true)
            
            // Prepare consent record data
            let consentData: [String: Any] = [
                "documentId": document.id,
                "documentVersion": document.version,
                "acceptedAt": FieldValue.serverTimestamp()
            ]
            consentDataArray.append(consentData)
        }
        
        // Update user profile with all consent records at once
        if !consentDataArray.isEmpty {
            batch.updateData([
                "consentRecords": FieldValue.arrayUnion(consentDataArray)
            ], forDocument: userRef)
        }
        
        // Commit the batch
        batch.commit { error in
            completion(error)
        }
    }
    
    /// Check if user has accepted latest version.
    func hasUserAcceptedLatest(document: LegalDocument, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false); return
        }
        db.collection("users").document(uid)
            .collection("documentAcceptances").document(document.id)
            .getDocument { snap, _ in
                guard let data = snap?.data(),
                      let version = data["documentVersion"] as? String else {
                    completion(false)
                    return
                }
                completion(!document.isNewer(than: version))
            }
    }
} 