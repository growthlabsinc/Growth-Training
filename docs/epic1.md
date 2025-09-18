# Epic 1: Foundation & Core Infrastructure Setup

**Goal:** Establish the project, core backend services (Firebase/GCP), data models for essential entities (User, SessionLog, MethodContent), and initial iOS app structure with basic navigation, ready for feature development.

## Story List

### Story 1.1: Project Initialization & iOS App Shell
- **User Story / Goal:** As a Developer, I want a new iOS project created with Swift, basic folder structure, and necessary SDKs (Firebase) integrated, so that I can start building features.
- **Detailed Requirements:**
  - Create new Xcode project for an iOS app (Swift).
  - Set up Bundle ID, versioning, and target iOS version.
  - Integrate Firebase SDK (Firestore, Auth, Functions, Analytics, Crashlytics).
  - Configure Firebase for different environments (Dev, Staging, Prod - using different Firebase projects or configurations).
  - Establish basic app delegate/scene delegate setup.
  - Create a basic Tab Bar Controller shell with placeholder view controllers for main sections (Dashboard, Methods, Progress, Coach, Resources, Settings).
  - Define preliminary app icon and launch screen.
- **Acceptance Criteria (ACs):**
  - AC1: iOS project compiles and runs on a simulator and a physical device.
  - AC2: Firebase SDKs are integrated and a basic connection to Firebase (e.g., fetching remote config or a test Firestore read) is successful.
  - AC3: Basic tab bar navigation is functional, switching between placeholder views.
  - AC4: Project is committed to a version control system (e.g., Git).

### Story 1.2: Firebase Firestore Setup & Basic Data Models
- **User Story / Goal:** As a Backend Developer, I want initial Firestore database rules and data models for User, GrowthMethod, SessionLog, and EducationalResource defined, so that app features can store and retrieve data securely.
- **Detailed Requirements:**
  - Define Firestore data structure for:
    - `users`: (userId, creationDate, lastLogin, linkedProgressData, settings)
    - `growthMethods`: (methodId, stage, title, description, instructions_text, visual_placeholder_url, equipment_needed, progression_criteria, safety_notes)
    - `sessionLogs`: (logId, userId, methodId, startTime, duration, userNotes, moodBefore, moodAfter - structure for privacy)
    - `educationalResources`: (resourceId, title, content_text, category, visual_placeholder_url)
  - Implement basic Firestore security rules:
    - Users can only read/write their own `sessionLogs` and `user` settings.
    - `growthMethods` and `educationalResources` are read-only for authenticated users.
    - Default deny all other access.
  - Seed Firestore with sample data for `growthMethods` (at least 2-3 methods across different stages) and `educationalResources` (1-2 articles) for development.
- **Acceptance Criteria (ACs):**
  - AC1: Firestore data models are documented (e.g., in `docs/data-models.md`).
  - AC2: Basic Firestore security rules are implemented and tested via Firestore emulator or unit tests.
  - AC3: Sample data is successfully seeded into Firestore and can be read by a test client.
  - AC4: Data structures consider privacy needs (e.g., not storing overly sensitive free-text directly if it can be categorized).

### Story 1.3: Backend Setup for AI Coach Knowledge Base (Placeholder)
- **User Story / Goal:** As a Backend Developer, I want to set up the initial infrastructure for the AI Coach's knowledge base ingestion using Vertex AI Search, so that curated content can be indexed for retrieval.
- **Detailed Requirements:**
  - Set up a Vertex AI Search datastore in Google Cloud.
  - Define a schema for the knowledge base content (e.g., method instructions, educational articles, FAQs).
  - Manually upload 2-3 sample documents (e.g., a method instruction page, an educational article snippet) into the Vertex AI Search datastore to test indexing.
  - (No AI response generation in this story, just data ingestion and basic retrieval test via GCP console or API call).
- **Acceptance Criteria (ACs):**
  - AC1: Vertex AI Search datastore is created and configured.
  - AC2: Sample documents are successfully ingested and indexed.
  - AC3: A basic search query via GCP console or a test script retrieves relevant chunks from the sample documents.

### Story 1.4: Style Guide Implementation - Core UI Elements
- **User Story / Goal:** As an iOS Developer, I want to implement reusable UI components for core elements (buttons, cards, input fields, typography) based on `docs/style-guide.md`, so that the app has a consistent visual foundation.
- **Detailed Requirements:**
  - Create Swift extensions or subclasses for `UIButton`, `UILabel`, `UITextField`, `UIView` (for cards) to apply styles from `docs/style-guide.md`.
  - Define global font and color settings (e.g., in an AppTheme class or similar).
  - Implement Primary Button style.
  - Implement Standard Card style.
  - Implement basic Text Input style.
  - Apply H1, H2, Body text styles to placeholder labels/views.
  - Ensure implemented styles support Dark Mode.
- **Acceptance Criteria (ACs):**
  - AC1: Core UI elements (buttons, cards, text inputs) are styled according to the style guide.
  - AC2: Typography (fonts, sizes, weights) matches the style guide for implemented elements.
  - AC3: Implemented elements correctly adapt to Light and Dark mode.
  - AC4: Styled components are demonstrated in a sample view controller.

## Change Log

| Date       | Version | Description     | Author   |
| :--------- | :------ | :-------------- | :------- |
| 2025-05-08 | 0.1     | Initial Draft   | 2 - PM   |