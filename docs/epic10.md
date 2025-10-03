# Epic 10: Privacy, Security Hardening & Compliance Checks (MVP)

**Goal:** Ensure all MVP features adhere to defined privacy (HIPAA/GDPR principles), security best practices, and Apple App Store guidelines. Implement necessary data handling, encryption, and consent mechanisms not covered in specific feature epics.

## Story List

### Story 10.1: Review and Implement Data Encryption (At Rest & In Transit)
- **User Story / Goal:** As a User, I want my sensitive personal and health-related data to be securely encrypted both when stored on my device, on the server, and when being transmitted.
- **Detailed Requirements:**
  - **Device (At Rest):** Confirm all sensitive data stored locally (e.g., session drafts, user preferences if any) uses appropriate iOS data protection classes or Keychain for critical items.
  - **Server (At Rest - Firestore):** Firestore encrypts data at rest by default. Confirm this meets requirements. Evaluate need for Customer-Managed Encryption Keys (CMEK) with Architect if more stringent control is needed (likely default is sufficient for MVP but verify).
  - **In Transit:** Ensure all communication between the app and Firebase/GCP services uses TLS 1.2+ (HTTPS), which Firebase SDKs and GCP client libraries handle by default. Verify no insecure communication paths.
  - Document encryption strategies in `docs/architecture.md`.
- **Acceptance Criteria (ACs):**
  - AC1: Data at rest on device utilizes appropriate iOS encryption mechanisms.
  - AC2: Data at rest in Firestore leverages Google's default encryption.
  - AC3: All app-to-server communication is over HTTPS (TLS 1.2+).
  - AC4: Encryption measures are documented.

### Story 10.2: User Data Deletion Request Handling (Basic MVP)
- **User Story / Goal:** As a User, I want to be able to request the deletion of my account and associated data, respecting my privacy rights (e.g., GDPR Right to Erasure).
- **Detailed Requirements:**
  - Provide a mechanism within app settings for a user to request account and data deletion.
  - For MVP, this might generate a support request to a manual backend process. Clearly state the expected timeframe for deletion.
  - (Backend) Define a procedure for admins to securely delete a user's Firebase Auth record and their associated data in Firestore (e.g., `user` profile, `sessionLogs`). This needs to be thorough.
  - Ensure this process is documented for internal use.
- **Acceptance Criteria (ACs):**
  - AC1: User can find and use an option in settings to request data deletion.
  - AC2: Request clearly informs the user about the process and timeframe.
  - AC3: A documented internal procedure exists for handling deletion requests.
  - AC4: Successful deletion removes user's Auth record and all their associated Firestore documents.

### Story 10.3: Refine and Finalize In-App Disclaimers, Privacy Policy, and Terms of Use
- **User Story / Goal:** As a User, I want to have access to clear, comprehensive, and accurate legal information (disclaimers, privacy policy, terms) within the app at all times.
- **Detailed Requirements:**
  - Work with Legal/Content team to finalize the text for:
    - Medical Disclaimers (general and method-specific if any).
    - Privacy Policy (detailing data collection, storage, usage, user rights, HIPAA/GDPR info).
    - Terms of Use.
  - Ensure these documents are easily accessible from within the app's settings menu after onboarding.
  - Ensure the versions accepted during onboarding (Story 2.3, 2.4) are correctly referenced/stored.
  - Verify Privacy Policy addresses data used by AI Chat Coach and analytics.
- **Acceptance Criteria (ACs):**
  - AC1: Finalized legal texts for disclaimers, privacy policy, and terms are integrated into the app.
  - AC2: Users can access this information from a clearly marked section in settings.
  - AC3: Privacy Policy accurately reflects all data processing activities in the MVP, including AI and analytics.

### Story 10.4: Apple App Store Guideline Compliance Review
- **User Story / Goal:** As the Development Team, we need to ensure the app fully complies with Apple App Store Review Guidelines, particularly those related to health, safety, mature content, user data privacy, and AI.
- **Detailed Requirements:**
  - Conduct a thorough review of the app against relevant App Store Guidelines (Sections 1 - Safety, 5 - Privacy).
  - Pay special attention to:
    - 1.4 Physical Harm (ensure methods are presented safely, disclaimers are prominent).
    - 1.5 Developer Identity (ensure accurate contact info).
    - 5.1 Data Collection and Storage (privacy policy, consent, data minimization).
    - 5.6 Health and Medical (accuracy of claims, user safety, data handling for health apps, HIPAA considerations if applicable for App Store review).
    - AI guidelines (transparency, no harmful content).
  - Prepare necessary metadata for App Store submission (descriptions, keywords, privacy labels).
- **Acceptance Criteria (ACs):**
  - AC1: A compliance review against App Store Guidelines has been completed and documented.
  - AC2: Any identified potential issues are addressed before submission.
  - AC3: App Store submission metadata, including privacy labels, is prepared and accurate.

### Story 10.5: HIPAA/GDPR Compliance Configuration & Documentation (GCP/Firebase)
- **User Story / Goal:** As the Organization, we need to ensure our Google Cloud and Firebase setup is configured to support HIPAA/GDPR compliance for relevant user data, and this is documented.
- **Detailed Requirements:**
  - Sign a Business Associate Agreement (BAA) with Google Cloud for all services handling PHI (Protected Health Information). 
  - Verify and document which Firebase services (Firestore, Cloud Functions, Firebase Auth if used for PHI) are covered by the BAA.
  - For GDPR:
    - Ensure data processing agreements are in place with Google.
    - Configure data storage locations (e.g., Firestore region) to EU if handling EU user data and aiming for data residency.
    - Document how user consent is obtained and managed.
    - Document how data subject rights (access, rectification, erasure - see Story 10.2) will be handled.
  - Implement appropriate IAM roles and audit logging on GCP/Firebase.
  - Document these configurations and processes in `docs/compliance-config.md`.
- **Acceptance Criteria (ACs):**
  - AC1: BAA with Google Cloud is in place or process initiated.
  - AC2: Firebase/GCP services are configured aligning with HIPAA/GDPR principles (e.g., data regions, audit logs).
  - AC3: Data Processing Agreements for GDPR are confirmed.
  - AC4: Key compliance configurations and procedures are documented in `docs/compliance-config.md`.

## Change Log

| Date       | Version | Description     | Author   |
| :--------- | :------ | :-------------- | :------- |
| 2025-05-08 | 0.1     | Initial Draft   | 2 - PM   |