## Technology Stack Specification (Draft 1)

This document outlines the specific technologies, frameworks, SDKs, and services that will be utilized to build the "Growth" iOS application, with a particular focus on the AI Chat Coach feature. Version numbers indicate the latest stable version recommended at the time of this document (May 8, 2025) or a minimum required version. Specific minor/patch versions will be determined by the development team at the time of implementation, prioritizing stability and compatibility.

**1. iOS Application (Client)**

* **Platform:** iOS
* **Primary Language:** Swift (Latest stable version, e.g., Swift 5.10+)
* **UI Framework:** SwiftUI (for all new UI development, including the AI Chat Coach interface - Story 6.1)
* **Minimum iOS Target:** iOS 16.0 (To ensure availability of modern SwiftUI features and system APIs. Confirm based on target audience device penetration if necessary).
* **Core iOS SDKs:**
    * `FirebaseClient` (Latest stable version):
        * `FirebaseAuth` (for user authentication - Story 2.1, 2.2)
        * `FirebaseFunctions` (for calling HTTPS Callable Functions - Story 6.2)
        * `FirebaseFirestore` (for any direct Firestore interactions, if applicable, though most will be via Functions)
        * `FirebaseAppCheck` (for verifying app integrity - Story 6.2)
        * `FirebaseCrashlytics` (for crash reporting)
        * `FirebasePerformance` (for performance monitoring)
        * `FirebaseRemoteConfig` (for feature flagging, A/B testing AI Coach prompts/configs - as per research doc Section 6.5)
* **Local Data Persistence (if needed beyond simple caching):**
    * Core Data (for complex local data if `UserDefaults` or simple file caching is insufficient)
    * `UserDefaults` (for user preferences, cached disclaimers - as per research doc Section 6.6)
* **Networking (Primary):** Firebase Functions SDK (for backend interaction). URLSession for other external calls if any.
* **Dependency Management:** Swift Package Manager (SPM)

**2. Backend Orchestration & Logic**

* **Platform:** Google Cloud Platform (GCP)
* **Primary Service:** Cloud Functions for Firebase (2nd Gen recommended for better performance, longer timeouts, and concurrency controls)
* **Runtime:** Node.js (Latest LTS version, e.g., Node.js 20.x) or Python (Latest stable version, e.g., Python 3.11+)
    * *Decision Point:* The research document examples used Python. Confirm language preference with the development team. Python is generally strong for AI/ML integrations.
* **Key GCP SDKs/Libraries (for chosen runtime, e.g., Python):**
    * `firebase-admin` (Python/Node.js SDK for interacting with Firebase services from backend - Story 6.2, research doc Section 6.3)
    * `google-cloud-aiplatform` (Python/Node.js SDK for Vertex AI - Gemini, Search - Story 6.2, research doc Section 3.2, 6.2)
    * `google-cloud-dlp` (Python/Node.js SDK for Cloud Data Loss Prevention API - research doc Section 3.3, 6.3)
    * `google-cloud-firestore` (if not using `firebase-admin` for Firestore interactions)
    * `google-cloud-logging` (for structured logging, if needed beyond standard `print`/`console.log`)

**3. Database & Data Storage**

* **Primary Database:** Cloud Firestore (in Native mode)
    * **Region:** EU multi-region (e.g., `eur3`) or a specific EU region (e.g., `europe-west1`) to comply with GDPR data residency requirements (Story 10.5, research doc Section 4.4).
    * **Usage:**
        * User profiles and authentication-related data (Story 2.1).
        * Consent records (Story 2.3, 2.4).
        * AI Chat Coach knowledge base (Growth Methods, Educational Articles - Epic 3, Epic 5, research doc Section 3.1).
        * AI Chat Coach conversation history (user-centric structure - research doc Section 3.4, 6.3).
        * Session logs (Epic 4).
        * Gamification data (streaks, badges - Epic 8).
        * User progression data (Epic 9).
* **Knowledge Base Indexing:** Vertex AI Search (details below)

**4. AI Services (Vertex AI)**

* **Knowledge Retrieval:** Vertex AI Search
    * **Data Source:** Firestore (via Cloud Function triggers for ingestion/updates - research doc Section 3.1, 6.1).
    * **Edition:** Enterprise Edition (if features like CMEK or advanced layout-aware chunking are deemed essential and confirmed to require it). Standard edition otherwise.
    * **Region:** EU multi-region (e.g., `eu`) for data residency (research doc Section 4.4).
* **LLM for Response Generation:** Vertex AI - Gemini Models
    * **Specific Model:** Gemini 2.0 Flash-Lite (e.g., `gemini-2.0-flash-lite-001` or latest stable GA version) as the primary recommendation. Gemini 2.0 Flash as a fallback if higher performance is needed (research doc Section 3.2, 6.2).
    * **Access Method:** Direct API calls via Vertex AI SDK from Cloud Functions (research doc Section 3.2).
    * **Endpoint Region:** EU regional endpoint (e.g., `europe-west1-aiplatform.googleapis.com`) (research doc Section 4.4, 6.4).

**5. Security & Compliance Services**

* **Authentication:** Firebase Authentication (Email/Password, potentially others later).
* **App Integrity:** Firebase App Check (SafetyNet/DeviceCheck/Play Integrity).
* **Access Control:** Google Cloud IAM (Identity and Access Management).
* **Data Masking (for logs):** Cloud Data Loss Prevention (DLP) API (research doc Section 3.3, 4.1).
* **Network Security (Recommended for Production):**
    * VPC Service Controls.
    * Private Endpoints for Vertex AI (via Private Service Connect).
* **Encryption:**
    * **In Transit:** TLS 1.2+ (default for Firebase/GCP services - Story 10.1).
    * **At Rest:** Google Default Encryption (recommended). Cloud KMS for CMEK if specific stringent requirements arise (Story 10.1, research doc Section 4.1).
* **Audit & Logging:** Cloud Audit Logging (Admin Activity, Data Access logs for relevant services - research doc Section 4.5, Story 10.5), Cloud Logging.

**6. Development & Operations**

* **Source Code Management:** Git (e.g., GitHub, GitLab, Cloud Source Repositories).
* **CI/CD:** GitHub Actions, GitLab CI/CD, or Cloud Build.
* **Infrastructure as Code (IaC - Recommended for GCP resources):** Terraform or Google Cloud Deployment Manager.
* **Monitoring & Alerting:** Cloud Monitoring, Firebase Performance Monitoring, Firebase Crashlytics.

---