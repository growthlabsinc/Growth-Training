# Epic 12: MVP Enhancements, View Build-Outs, and Timer Activation

**Goal:** Enhance key MVP views with more detailed functionality, address necessary backend optimizations, ensure the In-App Timer system is fully integrated and operational, and provide a clear, contextual "Next Session" experience.

## Story List

### Story 12.1: Develop "Next Session" Suggestion on Dashboard
- **User Story / Goal:** As a User, I want to see a clear suggestion for my "Next Session" on the Dashboard, so I can easily understand what to do next and decide to view more details.
- **Detailed Requirements:**
  - Design a UI component on the Dashboard (Epic 11) to display the "Next Session" suggestion.
  - The suggestion logic should be based on the user's "current focused stage" (from Epic 9, Story 9.4), their readiness status (Epic 9, Story 9.2), and potentially the last session logged for that method.
  - Display the name of the suggested Growth Method and stage.
  - Include a CTA button like "View Next Session Details" or "Prepare for Session" that navigates to the new "Next Session Detail View" (defined in Story 12.2).
  - If no "next session" can be determined (e.g., user needs to select a focus, or has completed all available content), display a relevant message on the Dashboard.
- **Acceptance Criteria (ACs):**
  - AC1: A "Next Session" suggestion (method name & stage) is displayed to the user on the Dashboard.
  - AC2: The suggestion logic correctly uses the user's current focus, readiness, and session history.
  - AC3: A CTA ("View Next Session Details" or similar) navigates to the "Next Session Detail View" (Story 12.2).
  - AC4: Appropriate messages are shown on the Dashboard if no next session can be determined.

### Story 12.2: Build Out "Next Session Detail" View
- **User Story / Goal:** As a User, after tapping the "Next Session" suggestion, I want to see a dedicated view with more details about the suggested session, so I can confirm it's what I want to do before starting the timer.
- **Detailed Requirements:**
  - Design and implement a new "Next Session Detail" screen. This screen is displayed after the user taps the CTA from Story 12.1.
  - This screen should clearly present information about the suggested Growth Method session:
    - Prominent display of the Method Name and Stage.
    - A brief description or key objectives/focus points for this specific session/method.
    - Expected duration (fetched from method configuration).
    - List of required equipment, if any (fetched from method configuration).
    - Option to quickly review the full method instructions (e.g., a button linking to the main Method Detail screen - Epic 3, Story 3.2).
    - A clear "Begin Session" or "Start Timer" CTA that navigates to the In-App Timer screen (from Epic 7), pre-configured for this suggested method.
  - UI should be clean, focused, and motivating, adhering to `docs/style-guide.md`.
- **Acceptance Criteria (ACs):**
  - AC1: The "Next Session Detail" view is displayed after tapping the "Next Session" suggestion CTA from the Dashboard.
  - AC2: The view accurately displays the method name, stage, description/objectives, duration, and required equipment for the suggested session.
  - AC3: A link/button to view full method instructions is present and functional.
  - AC4: A "Begin Session" CTA is present and, when tapped, navigates to the In-App Timer, correctly configured for the suggested method.
  - AC5: The UI is consistent with the app's style guide.

### Story 12.3: Enhance "Log Session" View Functionality
- **User Story / Goal:** As a User, I want the "Log Session" view to be more robust and potentially offer more detailed input options, so I can track my sessions more accurately.
- **Detailed Requirements:**
  - Review the existing "Log Session" screen (from Epic 4, Story 4.1).
  - Enhancements to consider:
    - **Intensity/Difficulty input:** Allow user to rate session intensity or difficulty (e.g., on a 1-5 scale). Store this in `sessionLogs`.
    - **Specific exercise variations:** If a Growth Method has distinct variations not warranting a separate method entry, allow selection here. (May be post-MVP, assess complexity).
    - **Improved UI/UX:** Refine the layout for clarity and ease of input based on initial designs and potential early feedback.
    - Ensure mood check-in integration (from Epic 8, Story 8.4) is seamless if not already fully covered.
- **Acceptance Criteria (ACs):**
  - AC1: Users can optionally log session intensity/difficulty.
  - AC2: The Log Session view UI is polished and user-friendly.
  - AC3: Mood check-in integration is confirmed to be working smoothly.
  - AC4: All logged data, including new fields, is correctly saved to Firestore.

### Story 12.4: Implement Required Firestore Composite Index for 'goals' Query
- **User Story / Goal:** As a Backend Developer, I need to create a specific Firestore composite index to ensure a query on the 'goals' collection performs efficiently and does not result in errors.
- **Detailed Requirements:**
  - Access the Firebase console for the project.
  - Navigate to Firestore > Indexes.
  - Create a new composite index for the collection group `goals`.
  - Index fields:
    1. `userId` (Ascending)
    2. `createdAt` (Ascending or Descending as per the query requirement - user link implies Ascending for both, but typically one is for filtering, the other for ordering. Assuming Ascending for `createdAt` as per link structure.)
    - **Note:** The `goals` collection was not explicitly defined in previous epics. Confirm if this refers to a new data entity (e.g., user-defined goals for their practice) or if the query is intended for an existing collection like `sessionLogs` or `userProfiles` where `createdAt` might be relevant for tracking goal-related progress. If it's a new `goals` entity, its data model should be defined. For this story, assume the `goals` collection exists or will be created by another feature team/story, and this task is purely to create the specified index. The link provided in the user prompt will be used for exact specification of the index path.
    - Link: `https://console.firebase.google.com/v1/r/project/growth-70a85/firestore/indexes?create_composite=Ckpwcm9qZWN0-cy9ncm93dGgtNzBhODUvZGFOYWJhc2V-zLyhkZWZhdWxOKS9jb2xsZWNOaW9u-R3JvdXBzL2dvYWxzL2luZGV4ZXMvXx-ABGgoKBnVzZXJJZBABGgOKCWNy-|ZWFOZWRBdBABGgwKCF9fbmFtZV9fEAE`
- **Acceptance Criteria (ACs):**
  - AC1: The specified composite index (`userId` ASC, `createdAt` ASC) for the `goals` collection group is successfully created and enabled in Firestore.
  - AC2: The query that previously required this index now runs without "index required" errors.
  - AC3: The purpose/entity of the `goals` collection is clarified and documented if it's new.

### Story 12.5: Activate "Start In-App Timer" Button and Finalize Timer View
- **User Story / Goal:** As a User, I want the "Start In-App Timer" button on all Method Detail pages (from Epic 3) and from the "Next Session Detail" view (Story 12.2) to be fully functional, launching the correctly configured In-App Timer view.
- **Detailed Requirements:**
  - Ensure the "Start In-App Timer" CTA on the Method Detail screen (from Epic 3, Story 3.2) correctly navigates to the In-App Timer screen (built in Epic 7).
  - Ensure the "Begin Session" CTA on the "Next Session Detail" view (Story 12.2) correctly navigates to the In-App Timer screen.
  - Pass the selected `methodId` and its timer configurations (recommended duration, countdown settings, intervals from Epic 7, Story 7.2) to the Timer screen from both entry points.
  - Verify the Timer screen (Epic 7, Stories 7.1, 7.2, 7.3) is fully built out and correctly:
    - Loads method-specific configurations.
    - Functions as a stopwatch or countdown.
    - Handles intervals and alerts (breaks, overexertion).
    - Connects to the post-timer logging flow (Epic 7, Story 7.4).
  - Conduct thorough testing of the end-to-end flows:
    1. Method Detail -> Timer -> Log Session.
    2. Dashboard -> Next Session Suggestion -> Next Session Detail View -> Timer -> Log Session.
- **Acceptance Criteria (ACs):**
  - AC1: Tapping "Start In-App Timer" on any Method Detail page launches the In-App Timer view.
  - AC2: Tapping "Begin Session" on the "Next Session Detail" view launches the In-App Timer view.
  - AC3: The In-App Timer is correctly pre-configured with the specific method's duration, countdown/stopwatch mode, and interval settings from both entry points.
  - AC4: All functionalities of the In-App Timer view (start, pause, resume, reset, alerts) work as designed in Epic 7.
  - AC5: The post-timer flow to log the session with pre-filled data is functional.

### Story 12.6: Add Functional 7-Day Calendar to Dashboard View
- **User Story / Goal:** As a User, I want to see a 7-day interactive calendar on my Dashboard, so I can quickly view my activity for the week and navigate to different days.
- **Detailed Requirements:**
  - Design and implement a horizontal, scrollable 7-day calendar view component to be displayed prominently on the Dashboard screen (Epic 11).
  - The calendar should display the current week by default (e.g., Monday to Sunday, or rolling 7 days with today highlighted).
  - Allow users to tap on a day in this 7-day view.
  - Tapping a day should:
    - Visually select/highlight that day in the 7-day calendar.
    - Potentially filter or update other content on the Dashboard to reflect activity/plans for the selected day (e.g., if a "Today's Sessions" list exists, it would update. For MVP, this might just be visual selection).
  - Indicate days where sessions were logged (e.g., a dot beneath the date, similar to the full calendar view in Epic 4, Story 4.4, but simplified for the 7-day view).
  - Allow navigation to previous/next weeks within this 7-day view (e.g., via swipe gestures or < > arrow buttons).
  - Refer to the provided `Centr iOS 26.jpg` image for visual inspiration regarding the horizontal 7-day selector.
  - UI should adhere to `docs/style-guide.md` and integrate seamlessly with the overall Dashboard design.
- **Acceptance Criteria (ACs):**
  - AC1: A horizontal 7-day calendar is displayed on the Dashboard.
  - AC2: The current day is highlighted by default.
  - AC3: Users can tap on a day to select it, and the selection is visually indicated.
  - AC4: Users can navigate to previous/next weeks in the 7-day calendar.
  - AC5: Days with logged sessions are visually marked in the 7-day calendar.
  - AC6: The calendar design is consistent with the app's style guide and inspired by the provided image.
  - AC7: (Stretch for MVP, or for future iteration) Tapping a day updates a relevant section of the dashboard to show data/activities for the selected date.

## Change Log

| Date       | Version | Description                                                    | Author   |
| :--------- | :------ | :------------------------------------------------------------- | :------- |
| 2025-05-18 | 0.1     | Initial Draft for Enhancements & Timer Fix                      | 2 - PM   |
| 2025-05-18 | 0.2     | Added Story 12.5 for 7-Day Dashboard Calendar                  | 2 - PM   |
| 2025-05-18 | 0.3     | Inserted Story 12.2 for "Next Session Detail" View, re-numbered. | 2 - PM   |