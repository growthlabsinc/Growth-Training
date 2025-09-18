# Epic 2: User Onboarding, Authentication & Consent

**Goal:** Implement a secure user registration and login flow, and ensure all users are presented with and accept comprehensive safety disclaimers, privacy policy, and terms of use before accessing core app features.

## Story List

### Story 2.1: Account Creation Screen & Logic
- **User Story / Goal:** As a new User, I want to be able to create a new account using an email and password, so that my data can be saved and synced.
- **Detailed Requirements:**
  - Design and implement the UI for account creation (Email, Password, Confirm Password fields).
  - Use Firebase Authentication for email/password account creation.
  - Provide clear error handling for invalid email format, weak password, email already in use, etc.
  - On successful account creation, the user should be marked as authenticated.
  - Store basic user profile information (e.g., UID, creation date) in Firestore.
- **Acceptance Criteria (ACs):**
  - AC1: User can successfully create an account with valid email and password.
  - AC2: Firebase Authentication creates a new user.
  - AC3: A corresponding user document is created in Firestore.
  - AC4: Appropriate error messages are shown for invalid inputs or existing accounts.
  - AC5: UI adheres to the `docs/style-guide.md`.

### Story 2.2: Login Screen & Logic
- **User Story / Goal:** As an existing User, I want to be able to log in with my email and password, so that I can access my existing data and progress.
- **Detailed Requirements:**
  - Design and implement the UI for login (Email, Password fields).
  - Use Firebase Authentication for email/password sign-in.
  - Provide clear error handling for incorrect credentials, user not found, etc.
  - Implement a "Forgot Password" flow (triggers Firebase password reset email).
  - On successful login, the user should be marked as authenticated.
- **Acceptance Criteria (ACs):**
  - AC1: User can successfully log in with correct credentials.
  - AC2: User is authenticated via Firebase.
  - AC3: "Forgot Password" functionality successfully sends a reset email.
  - AC4: Appropriate error messages are shown for login failures.
  - AC5: UI adheres to the `docs/style-guide.md`.

### Story 2.3: Medical Disclaimer & Safety Information Presentation
- **User Story / Goal:** As a new User, I want to be presented with clear medical disclaimers and safety information before I can use the app, so that I understand the nature of the app and its limitations.
- **Detailed Requirements:**
  - Create a screen or series of screens to display the full medical disclaimer and critical safety warnings. (Content to be provided by Legal/Content team).
  - User must explicitly acknowledge/accept this information to proceed (e.g., checkbox and "Agree & Continue" button).
  - This flow must occur after account creation/login for new users, before accessing the main app.
  - Record user's acceptance (timestamp, version of disclaimer accepted) in their Firestore user profile.
- **Acceptance Criteria (ACs):**
  - AC1: Medical disclaimer and safety information are clearly displayed.
  - AC2: User cannot proceed to the main app without acknowledging the disclaimer.
  - AC3: Acceptance is recorded in the user's profile in Firestore.
  - AC4: UI is clear, readable, and professional.

### Story 2.4: Privacy Policy & Terms of Use Presentation
- **User Story / Goal:** As a new User, I want to be presented with the Privacy Policy and Terms of Use before I can use the app, so that I understand how my data is handled and the terms of service.
- **Detailed Requirements:**
  - Create a screen or series of screens to display the Privacy Policy and Terms of Use. (Content to be provided by Legal/Content team).
  - Links to view full documents should be available. A summary can be presented.
  - User must explicitly accept these to proceed (e.g., checkbox and "Agree & Continue" button).
  - This flow must occur after medical disclaimer acceptance, before accessing the main app.
  - Record user's acceptance (timestamp, version of policy/terms accepted) in their Firestore user profile.
- **Acceptance Criteria (ACs):**
  - AC1: Privacy Policy and Terms of Use (or summaries with links) are clearly displayed.
  - AC2: User cannot proceed to the main app without accepting.
  - AC3: Acceptance is recorded in the user's profile in Firestore.
  - AC4: UI is clear, readable, and professional.

### Story 2.5: Onboarding Flow Orchestration
- **User Story / Goal:** As a new User, I want a smooth onboarding sequence that guides me through account creation, disclaimers, and policy acceptance before landing on the main app dashboard.
- **Detailed Requirements:**
  - Orchestrate the sequence of onboarding screens:
    1. Welcome/Intro (Optional, can be part of Login/Create)
    2. Account Creation / Login
    3. Medical Disclaimer & Safety Info
    4. Privacy Policy & Terms of Use
    5. (Optional: Brief app tutorial or initial profile setup questions)
    6. Main App Dashboard
  - Ensure that if a user drops off during onboarding, they can resume from where they left off (or the beginning of the consent steps) upon next app open.
  - Once onboarding is complete, users should go directly to the main app on subsequent launches.
- **Acceptance Criteria (ACs):**
  - AC1: Onboarding flow proceeds in the correct, defined order.
  - AC2: User state (completed steps) is correctly tracked.
  - AC3: Users who have completed onboarding are taken directly to the main app.
  - AC4: The flow feels logical and not overly burdensome to the user.

## Change Log

| Date       | Version | Description     | Author   |
| :--------- | :------ | :-------------- | :------- |
| 2025-05-08 | 0.1     | Initial Draft   | 2 - PM   |