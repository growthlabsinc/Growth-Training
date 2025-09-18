## Data Models Documentation (Draft 1)

This document outlines the primary data models for the "Growth" application, stored in Cloud Firestore. These models are designed to support the application's features, including user management, content delivery, AI Chat Coach functionality, and GDPR compliance.

**General Firestore Conventions:**

  * **Timestamps:** Use Firestore server timestamps (`FieldValue.serverTimestamp()`) for fields like `createdAt`, `updatedAt` to ensure consistency.
  * **User Association:** Most user-specific data will be stored in collections directly under a user's document or in root collections with a `userId` field for querying and security rules. The AI Chat Coach conversation history uses a user-centric path.
  * **Data Residency:** The entire Firestore database will be located in an EU region (e.g., `europe-west1` or `eur3`) as per the Technology Stack Specification.

**1. Users Collection**

  * **Collection Path:** `users`
  * **Document ID:** `{userId}` (Matches Firebase Authentication UID)
  * **Description:** Stores information about each registered user.
  * **Fields:**
      * `uid` (String, Required): The user's unique Firebase Authentication ID. (Duplicate of document ID for querying if needed).
      * `email` (String, Required, Private): User's email address. (Access controlled by security rules).
      * `createdAt` (Timestamp, Required): Timestamp of account creation.
      * `updatedAt` (Timestamp, Required): Timestamp of the last profile update.
      * `onboardingCompleted` (Boolean, Default: `false`): Flag indicating if the user has completed the initial onboarding flow (disclaimers, terms).
      * `consents` (Map, Optional): Stores consent information.
          * `medicalDisclaimerVersion` (String): Version of the medical disclaimer accepted (e.g., "1.0").
          * `medicalDisclaimerAcceptedAt` (Timestamp): When the medical disclaimer was accepted.
          * `privacyPolicyVersion` (String): Version of the privacy policy accepted.
          * `privacyPolicyAcceptedAt` (Timestamp): When the privacy policy was accepted.
          * `termsOfUseVersion` (String): Version of the terms of use accepted.
          * `termsOfUseAcceptedAt` (Timestamp): When the terms of use were accepted.
      * `appSettings` (Map, Optional): User-specific application settings.
          * `prefersDarkMode` (Boolean, Default: `false`)
          * `notificationPreferences` (Map)
      * `currentGrowthStageFocus` (String, Optional): Document ID of the `growthMethods` document the user is currently focused on (Story 9.4).
      * `currentGrowthStageFocusNote` (String, Optional): User's note about why they set the current focus (Story 9.4).
      * `gamification` (Map, Optional): User-specific gamification data.
          * `currentStreak` (Integer, Default: 0): Current session streak (Story 8.1).
          * `lastSessionLoggedDate` (Timestamp): Date of the last logged session, for streak calculation.
          * `awardedBadgeIds` (Array\<String\>): List of Badge IDs the user has earned (Story 8.2).
      * `aiCoachSettings` (Map, Optional):
          * `coachDisclaimerAcknowledgedAt` (Timestamp): When the AI Coach specific disclaimer was acknowledged.

**2. Growth Methods Collection (Knowledge Base Content)**

  * **Collection Path:** `growthMethods`
  * **Document ID:** Auto-generated unique ID (or meaningful slug if preferred for CMS, e.g., `beginner-stage-1-method-A`)
  * **Description:** Stores instructional content for each Growth Method. This collection is part of the AI Coach's knowledge base.
  * **Fields:**
      * `methodId` (String, Required): Unique identifier for the method.
      * `title` (String, Required): Display name of the method/stage.
      * `stage` (String, Required): Stage grouping (e.g., "Beginner", "Intermediate", "Advanced", "Elite" - Story 3.1).
      * `shortDescription` (String, Required): Brief overview of the method (Story 3.1).
      * `fullDescription` (String, Required, Text): Detailed explanation of the method (Story 3.2).
      * `stepByStepInstructions` (String, Required, Text): Formatted text (e.g., Markdown or rich text) for step-by-step guidance (Story 3.2).
      * `toolsRequired` (Array\<String\>, Optional): List of tools or equipment needed (Story 3.2).
      * `safetyNotes` (String, Optional, Text): Specific safety warnings for this method (Story 3.2).
      * `visualPlaceholderUrl` (String, Optional): Placeholder URL for an image/icon (Story 3.1).
      * `timerConfiguration` (Map, Optional): Configuration for the in-app timer (Story 7.2).
          * `recommendedDurationSeconds` (Integer)
          * `isCountdown` (Boolean)
          * `intervals` (Array\<Map\>): `[{name: "Phase 1", durationSeconds: X}, ...]`
          * `maxRecommendedDurationSeconds` (Integer, Story 7.3)
      * `progressionCriteria` (Map, Optional): Criteria to suggest readiness for the next stage (Story 9.1).
          * `minSessionsAtThisStage` (Integer)
          * `minConsecutiveDaysPractice` (Integer)
          * `subjectiveFeedbackRequirement` (String) // e.g., "GOOD\_3\_CONSECUTIVE"
          * `timeSpentAtStageMinutes` (Integer)
      * `published` (Boolean, Default: `false`): Whether the method is visible to users.
      * `createdAt` (Timestamp, Required): Content creation timestamp.
      * `updatedAt` (Timestamp, Required): Last content update timestamp.
      * `version` (String, Optional): Content version number.

**3. Educational Resources Collection (Knowledge Base Content)**

  * **Collection Path:** `educationalResources`
  * **Document ID:** Auto-generated unique ID (or meaningful slug)
  * **Description:** Stores educational articles. This collection is part of the AI Coach's knowledge base. (Epic 5)
  * **Fields:**
      * `resourceId` (String, Required): Unique identifier for the article.
      * `title` (String, Required): Article title.
      * `category` (String, Required): Category for grouping (e.g., "Vascular Health Basics", "Safety & Best Practices" - Story 5.1).
      * `summary` (String, Required): Short summary for listing views (Story 5.1).
      * `fullContentText` (String, Required, Text): Full article content (e.g., Markdown or rich text - Story 5.2).
      * `visualPlaceholderUrls` (Array\<String\>, Optional): URLs for any embedded visuals (Story 5.2).
      * `publicationDate` (Timestamp, Required): Date article was published/updated (Story 5.3).
      * `author` (String, Optional): Author of the content.
      * `published` (Boolean, Default: `false`): Whether the article is visible to users.
      * `createdAt` (Timestamp, Required).
      * `updatedAt` (Timestamp, Required).
      * `version` (String, Optional).

**4. AI Coach Conversation History**

  * **Collection Path:** `users/{userId}/coachConversations`

  * **Document ID:** `{conversationId}` (Client-generated UUID, or generated by Cloud Function on first message if not provided)

  * **Description:** Represents a single conversation session between a user and the AI Coach. Designed for GDPR compliance, especially erasure.

  * **Fields:**

      * `conversationId` (String, Required): The unique ID for this conversation.
      * `userId` (String, Required, Indexed): The ID of the user who had this conversation. (Redundant with path but useful for potential future direct queries if rules allow, or for denormalization to other systems).
      * `createdAt` (Timestamp, Required): Timestamp when the conversation started.
      * `updatedAt` (Timestamp, Required): Timestamp of the last message in this conversation.
      * `summary` (String, Optional): A very brief summary of the conversation (potentially AI-generated, TBD, consider privacy).
      * `clientContext` (Map, Optional): Context provided by the client when the conversation started (e.g., app version).

  * **Subcollection: Messages**

      * **Collection Path:** `users/{userId}/coachConversations/{conversationId}/messages`
      * **Document ID:** `{messageId}` (Auto-generated unique ID)
      * **Description:** An individual message within a conversation.
      * **Fields:**
          * `messageId` (String, Required): Unique ID for the message.
          * `timestamp` (Timestamp, Required): Timestamp of when the message was sent/received. (Use server timestamp).
          * `role` (String, Required): Who sent the message. Enum: `"user"`, `"ai"`.
          * `content` (String, Required, Text): The actual text content of the message.
          * `contentType` (String, Default: `"text"`): Type of content, for future expansion (e.g., "image\_url").
          * `(Optional)` `feedback` (Map): User feedback on this specific AI message (e.g., `{rating: "thumbs_up", comment: "Helpful!"}`).

**5. Session Logs Collection**

  * **Collection Path:** `users/{userId}/sessionLogs` (or `sessionLogs` with a `userId` field if cross-user admin views are prioritized over user-data collocation, but subcollection is better for GDPR Story 10.2)
  * **Document ID:** Auto-generated unique ID
  * **Description:** Records of user's training sessions (Epic 4).
  * **Fields:**
      * `logId` (String, Required): Unique ID for this log entry.
      * `userId` (String, Required, Indexed): The ID of the user who logged this session.
      * `methodId` (String, Required): ID of the `growthMethods` document practiced.
      * `methodTitle` (String, Required): Denormalized title of the method for display.
      * `sessionDateTime` (Timestamp, Required): Date and time of the session (user can set this - Story 4.1).
      * `durationMinutes` (Integer, Required): Duration of the session in minutes (Story 4.1).
      * `notes` (String, Optional, Text): User's personal notes for the session (Story 4.1).
      * `moodBefore` (String, Optional): Mood selected before session (e.g., "GOOD", "NEUTRAL", "BAD" - Story 8.4).
      * `moodAfter` (String, Optional): Mood selected after session (Story 8.4).
      * `createdAt` (Timestamp, Required): Timestamp when the log was created in the system.

**6. Badges Collection (Gamification - Definition)**

  * **Collection Path:** `badges`
  * **Document ID:** Auto-generated unique ID (or meaningful slug, e.g., `first-session-logged`)
  * **Description:** Definitions for achievable badges (Story 8.2).
  * **Fields:**
      * `badgeId` (String, Required): Unique identifier for the badge.
      * `name` (String, Required): Display name of the badge.
      * `description` (String, Required): How to earn the badge / its meaning.
      * `iconUrl` (String, Required): URL to the badge icon (can be placeholder initially).
      * `criteria` (Map, Required): Conditions to earn the badge.
          * Example: `{"sessionsLogged": 10}`, `{"streakAchieved": 7}`, `{"methodCompleted": "methodIdXYZ"}`
      * `isActive` (Boolean, Default: `true`): Whether this badge can currently be earned.

**(Note: Awarded badges are stored in the `users` document's `gamification.awardedBadgeIds` array.)**

-----
