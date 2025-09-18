# Epic 11: Dashboard / Home Screen Implementation

**Goal:** Implement the main Dashboard/Home screen, providing users with a personalized overview of their current status, quick access to key actions, and motivational elements like streaks and affirmations.

## Story List

### Story 11.1: Dashboard Screen Structure & Layout
- **User Story / Goal:** As an iOS Developer, I want to implement the basic structure and layout for the Dashboard/Home tab's view controller, adhering to the UI/UX specification and style guide.
- **Detailed Requirements:**
  - Replace the placeholder view controller created in Epic 1 for the Dashboard tab with a functional view controller.
  - Implement the overall layout as defined in the eventual wireframes/mockups based on the UI/UX Spec IA:
    - Section for Current Stage/Next Session Summary.
    - Section for Quick Log Access.
    - Section for Motivational Snippet/Tip.
    - Section for Streak/Badge Highlights.
  - Ensure the layout adapts correctly to different iPhone screen sizes.
  - Adhere strictly to `docs/style-guide.md` for fonts, colors, spacing.
- **Acceptance Criteria (ACs):**
  - AC1: A dedicated view controller exists for the Dashboard tab.
  - AC2: The basic layout structure with placeholders for different sections is implemented.
  - AC3: Layout adheres to the style guide and adapts to different screen sizes.

### Story 11.2: Display Current Stage / Next Session Summary
- **User Story / Goal:** As a User, I want to see a summary of my current Growth Method stage or a suggestion for my next session on the dashboard, so I know where I stand.
- **Detailed Requirements:**
  - Fetch the user's "current focused stage" (from Epic 9, Story 9.4) from their Firestore profile.
  - Display the name of the current focused Growth Method/Stage.
  - Include a CTA button like "View Current Method" or "Start Next Session" that navigates to the relevant Method Detail screen (from Epic 3) or the Timer screen (from Epic 7).
  - Fetch and display the readiness suggestion status (from Epic 9, Story 9.2) if available ("Ready to Consider Next Stage," etc.).
- **Acceptance Criteria (ACs):**
  - AC1: The user's current focused Growth Method/Stage name is displayed.
  - AC2: A relevant CTA navigates to the Method Detail or Timer screen.
  - AC3: The readiness suggestion status is displayed if calculated.
  - AC4: If no focus stage is set yet, a prompt to select one is shown.

### Story 11.3: Quick Session Log Access
- **User Story / Goal:** As a User, I want a quick way to access the session logging screen directly from the dashboard, so I can easily log a manual session.
- **Detailed Requirements:**
  - Implement a prominent button or CTA on the Dashboard labeled "Log a Session" or similar.
  - Tapping this button should navigate the user directly to the "Log Session" screen (built in Epic 4, Story 4.1).
- **Acceptance Criteria (ACs):**
  - AC1: A "Log a Session" CTA is clearly visible on the Dashboard.
  - AC2: Tapping the CTA successfully navigates to the Log Session screen.

### Story 11.4: Integrate Streak Display
- **User Story / Goal:** As a Developer, I want to integrate the session streak display component (logic from Epic 8, Story 8.1) into the Dashboard layout.
- **Detailed Requirements:**
  - Fetch the user's current session streak data from their Firestore profile.
  - Display the streak number along with its associated icon (e.g., flame) in the designated dashboard section.
  - Ensure this display updates correctly when the user logs sessions that affect the streak.
- **Acceptance Criteria (ACs):**
  - AC1: The user's current session streak is correctly displayed on the Dashboard.
  - AC2: The visual presentation matches the intended design (number + icon).

### Story 11.5: Integrate Motivational Affirmations Display
- **User Story / Goal:** As a Developer, I want to integrate the motivational affirmation display component (logic from Epic 8, Story 8.5) into the Dashboard layout.
- **Detailed Requirements:**
  - Implement the logic to occasionally display a random affirmation from the predefined pool in the designated dashboard section.
  - Ensure the text is displayed clearly and adheres to the style guide.
- **Acceptance Criteria (ACs):**
  - AC1: A motivational affirmation is displayed occasionally on the Dashboard.
  - AC2: The text presentation adheres to the style guide.

### Story 11.6: Display Recent Badge Highlights
- **User Story / Goal:** As a User, I want to see highlights of my recently earned badges on the dashboard, so I feel recognized for my achievements.
- **Detailed Requirements:**
  - Fetch the user's recently earned badges (e.g., the last 1-3 earned) from their Firestore profile (data structure defined in Epic 8, Story 8.2).
  - Display the icons and names of these recent badges in the designated dashboard section.
  - Tapping on this section could navigate to the full "My Badges" screen (from Epic 8, Story 8.3).
- **Acceptance Criteria (ACs):**
  - AC1: Recently earned badges (icons/names) are displayed on the Dashboard.
  - AC2: If no badges are earned yet, the section displays a placeholder or is hidden gracefully.
  - AC3: Tapping the badge highlight area navigates to the full badge list screen.

## Change Log

| Date       | Version | Description                        | Author   |
| :--------- | :------ | :--------------------------------- | :------- |
| 2025-05-12 | 0.1     | Initial Draft to build Dashboard | 2 - PM   | 