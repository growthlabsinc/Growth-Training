# Epic 4: Session Logging & Basic Progress Display

**Goal:** Enable users to manually log their training sessions (method, duration, subjective feedback) and view a basic history and visualization of their logged sessions to track consistency and adherence.

## Story List

### Story 4.1: Manual Session Logging Screen & Logic
- **User Story / Goal:** As a User, I want to manually log a training session, including the method, duration, date/time, and personal notes, so I can keep a record of my practice.
- **Detailed Requirements:**
  - Design and implement a "Log Session" screen.
  - Fields to include:
    - Date & Time of session (default to now, but allow user to change).
    - Growth Method Practiced (user can select from a list of methods fetched from Firestore).
    - Class of Method (if applicable, e.g., if a method has sub-variants - TBD if needed for MVP, can be part of method name).
    - Duration (e.g., using a number input or picker for minutes).
    - Subjective User Feedback/Notes (multi-line text input).
    - (Optional MVP) Mood Check-in before/after (simple selection - to be integrated from Gamification Epic).
  - Save the logged session data to a `sessionLogs` collection in Firestore, associated with the authenticated user's ID.
  - Ensure data is stored securely and privately.
  - Provide clear confirmation to the user upon successful logging.
  - UI adheres to `docs/style-guide.md`.
- **Acceptance Criteria (ACs):**
  - AC1: User can access the Log Session screen.
  - AC2: User can select the date/time, method, enter duration, and add notes.
  - AC3: Session log is successfully saved to Firestore under the correct user ID.
  - AC4: User receives confirmation after saving a log.
  - AC5: Input validation is present (e.g., duration must be a positive number).

### Story 4.2: Session History List View
- **User Story / Goal:** As a User, I want to view a chronological list of my past logged sessions, so I can review my training history.
- **Detailed Requirements:**
  - Design and implement a "Session History" screen (likely part of the "Progress" tab).
  - Fetch and display all logged sessions for the authenticated user from Firestore, ordered by date (most recent first).
  - For each log entry, display key information:
    - Date of session.
    - Method Name.
    - Duration.
    - Snippet of notes (if any).
  - Allow tapping on a log entry to view full details (see Story 4.3).
  - Implement pagination or infinite scrolling if the list can become very long.
- **Acceptance Criteria (ACs):**
  - AC1: User can view a list of their logged sessions, sorted chronologically.
  - AC2: Each list item displays date, method name, duration, and a notes snippet.
  - AC3: Tapping a list item navigates to the Session Detail view.
  - AC4: If no sessions are logged, a clear "No sessions logged yet" message is displayed.

### Story 4.3: Session Detail View
- **User Story / Goal:** As a User, I want to view all the details of a specific past logged session, so I can recall my experience and notes for that session.
- **Detailed Requirements:**
  - Design and implement a "Session Detail" screen.
  - Screen should display all data for a selected session log from Firestore:
    - Date & Time.
    - Method Name.
    - Duration.
    - Full User Notes.
    - (Optional MVP) Mood Check-in details.
  - Provide options to Edit or Delete the log entry (Edit may be post-MVP, Delete is important for privacy).
- **Acceptance Criteria (ACs):**
  - AC1: All details of a selected session log are displayed accurately.
  - AC2: User can navigate back to the Session History list.
  - AC3: A "Delete" option is present and functional (with confirmation dialog).
  - AC4: (Post-MVP) An "Edit" option is present (can navigate to Log Session screen pre-filled).

### Story 4.4: Basic Progress Visualization - Calendar View
- **User Story / Goal:** As a User, I want to see a calendar view highlighting the days I've logged training sessions, so I can quickly see my consistency.
- **Detailed Requirements:**
  - On the "Progress" tab, implement a calendar view (e.g., using a native iOS calendar component or a third-party library).
  - Fetch logged session dates for the authenticated user.
  - Mark days on the calendar where one or more sessions were logged (e.g., with a dot or background color).
  - (Optional MVP) Tapping a marked day on the calendar could filter the Session History list to show sessions for that day.
- **Acceptance Criteria (ACs):**
  - AC1: Calendar view is displayed on the Progress tab.
  - AC2: Days with logged sessions are visually marked on the calendar.
  - AC3: Calendar correctly reflects logged session data for the current user.
  - AC4: User can navigate between months/weeks in the calendar.

### Story 4.5: Basic Progress Visualization - Session Consistency Chart
- **User Story / Goal:** As a User, I want to see a simple chart showing my session frequency over the last few weeks/months, so I can understand my consistency trends.
- **Detailed Requirements:**
  - On the "Progress" tab, implement a simple chart (e.g., bar chart).
  - Chart should display the number of logged sessions per week for the last 4-8 weeks (or per month for the last 3-6 months).
  - Data for the chart is derived from the user's logged sessions in Firestore.
- **Acceptance Criteria (ACs):**
  - AC1: A chart showing session frequency (e.g., sessions per week) is displayed on the Progress tab.
  - AC2: The chart accurately reflects the user's logged session data.
  - AC3: Chart is clearly labeled and easy to understand.

## Change Log

| Date       | Version | Description     | Author   |
| :--------- | :------ | :-------------- | :------- |
| 2025-05-08 | 0.1     | Initial Draft   | 2 - PM   |