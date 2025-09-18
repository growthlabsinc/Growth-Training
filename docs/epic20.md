# Epic 20: First-Time User App Tour

**Goal:** To orient new users to the app's key features and layout immediately after onboarding is complete, ensuring they understand how to find their daily tasks, browse routines, start a practice session, and where to find help, thereby increasing user confidence and initial engagement.

**Source Documents:** This epic is based on the established app structure from Epics 15-19 and common UX principles for user tours.

## Story List

### Story 20.1: Implement App Tour Trigger & Orchestration Framework
- **User Story / Goal:** As a New User who has just completed onboarding, I want to be offered a brief, optional tour of the app's main features, so I can quickly understand how to navigate and use the application.
- **Detailed Requirements:**
  - Implement logic to trigger the App Tour automatically the very first time a user lands on the Home (Dashboard) screen after successfully completing the entire onboarding flow (from Epic 19).
  - The tour should be implemented using a "coach mark" or "spotlight" style, which dims the background and highlights specific UI elements one by one.
  - The framework must include a clear "Skip Tour" or "X" button, visible at all times, allowing the user to exit the tour at any point.
  - A progress indicator (e.g., "Step 1 of 5") should be visible to manage user expectations.
  - Once the tour is completed or skipped, a flag should be set in the user's profile to ensure it does not appear again on subsequent sessions.
- **Acceptance Criteria (ACs):**
  - AC1: The App Tour is automatically initiated for a new user upon their first arrival at the Home screen post-onboarding.
  - AC2: The tour is not shown to returning users or users who have previously completed or skipped it.
  - AC3: The user can clearly see and use a button to skip or exit the tour at any step.
  - AC4: A progress indicator (e.g., step counter) is present.

### Story 20.2: Tour Step 1 - The "Today View" Dashboard
- **User Story / Goal:** As a New User on the app tour, I want to understand the purpose of the Home (Dashboard) screen, so I know where to look for my daily tasks and progress snapshot.
- **Detailed Requirements:**
  - Create the first step of the tour, highlighting the main components of the "Today View" Dashboard (from Epic 15, Story 15.2).
  - A popover or coach mark should explain: "This is your Home screen, your starting point for each day. Your 'Today's Focus' shows you exactly what to do."
  - A second highlight in this step could point to the "Weekly Progress Snapshot" with the text: "Quickly check your weekly progress and streak right here."
- **Acceptance Criteria (ACs):**
  - AC1: The tour correctly highlights the "Today's Focus" area on the Dashboard.
  - AC2: The popover text clearly and concisely explains the purpose of the Home screen and its main sections.
  - AC3: Tapping "Next" proceeds to the next step of the tour.

### Story 20.3: Tour Step 2 - The "Routines" Section
- **User Story / Goal:** As a New User on the app tour, I want to learn about the "Routines" section, so I know where to find structured programs if I want to follow one.
- **Detailed Requirements:**
  - The tour highlights the "Routines" tab in the bottom navigation bar.
  - The popover text should explain: "Explore the 'Routines' tab to find guided, multi-week programs designed to help you progress consistently."
- **Acceptance Criteria (ACs):**
  - AC1: The tour correctly highlights the "Routines" tab in the bottom navigation.
  - AC2: The popover text clearly explains the purpose of the Routines section.
  - AC3: Tapping "Next" proceeds to the next step.

### Story 20.4: Tour Step 3 - The Unified "Practice" Section
- **User Story / Goal:** As a New User on the app tour, I want to understand the "Practice" section, so I know how to start a single, ad-hoc session whenever I want.
- **Detailed Requirements:**
  - The tour highlights the "Practice" tab in the bottom navigation bar.
  - The popover text should explain: "Want to do a quick, unscheduled session? The 'Practice' tab lets you choose and perform any method you've unlocked."
- **Acceptance Criteria (ACs):**
  - AC1: The tour correctly highlights the "Practice" tab in the bottom navigation.
  - AC2: The popover text clearly explains how to start an ad-hoc ("Quick Practice") session.
  - AC3: Tapping "Next" proceeds to the next step.

### Story 20.5: Tour Step 4 - The Consolidated "Progress" Section
- **User Story / Goal:** As a New User on the app tour, I want to know where to find my detailed history and achievements, so I can review my journey over time.
- **Detailed Requirements:**
  - The tour highlights the "Progress" tab in the bottom navigation bar.
  - The popover text should explain: "Track your journey in the 'Progress' tab. Here you'll find your detailed session history, stats, and achievements all in one place."
- **Acceptance Criteria (ACs):**
  - AC1: The tour correctly highlights the "Progress" tab in the bottom navigation.
  - AC2: The popover text accurately describes the contents of the consolidated Progress section.
  - AC3: Tapping "Next" proceeds to the final step.

### Story 20.6: Tour Step 5 - Introducing the AI "Coach"
- **User Story / Goal:** As a New User on the app tour, I want to be introduced to the AI Coach, so I know I have a resource for questions.
- **Detailed Requirements:**
  - The final step of the tour highlights the "Coach" tab in the bottom navigation bar.
  - The popover text should explain: "Have questions? Our AI 'Coach' is here to help guide you based on the app's content and community insights. Tap here any time you need support."
  - The final "Done" or "Get Started" button in the popover should dismiss the tour and complete it.
- **Acceptance Criteria (ACs):**
  - AC1: The tour correctly highlights the "Coach" tab.
  - AC2: The popover text introduces the AI Coach and its purpose.
  - AC3: Tapping the final button in the popover successfully ends the tour and sets the flag so it won't appear again.

## Change Log

| Date       | Version | Description                               | Author   |
| :--------- | :------ | :---------------------------------------- | :------- |
| 2025-06-07 | 0.1     | Initial Draft for First-Time User App Tour. | 2 - PM   |