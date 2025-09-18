# Epic 17: Unified Progress Visualization & Contextual Insights

**Goal:** To consolidate all progress views into a cohesive and intuitive dashboard, implement robust routine adherence tracking, and provide users with contextual insights into their performance and trends.

**Source Document:** `UI/UX Integration Plan (Updated)` (for all stories within this epic)

## Story List

### Story 17.1: Develop Consolidated Progress Overview Dashboard
- **User Story / Goal:** As a User, I want a single, consolidated "Progress" section where I can get a comprehensive overview of my journey, including my calendar, stats, and achievements, without navigating to multiple places.
- **Detailed Requirements:**
  - Design and implement the new "Progress" tab's main screen as an "Overview Dashboard."
  - This dashboard should synthesize key information from previously separate views:
    - A summarized calendar view (e.g., monthly, showing workout intensity).
    - Key performance statistics (e.g., total sessions, total time, average intensity).
    - Highlights of recent achievements or progress towards current achievements.
    - Routine adherence percentage (from Story 17.2).
  - Ensure information is presented in a visually appealing and easy-to-understand manner.
- **Acceptance Criteria (ACs):**
  - AC1: The "Progress" tab features a new Overview Dashboard consolidating calendar, stats, and achievement highlights.
  - AC2: The dashboard provides a clear, single-glance understanding of overall progress.
  - AC3: Data from different progress tracking aspects is presented cohesively.

### Story 17.2: Implement Routine Adherence Tracking & Visualization
- **User Story / Goal:** As a User following a routine, I want to see how well I'm adhering to my scheduled plan, so I can stay on track and motivated.
- **Detailed Requirements:**
  - Develop logic to track routine adherence:
    - Compare logged sessions against the scheduled methods/days in the user's active routine.
    - Calculate an adherence percentage (e.g., weekly, or for the entire routine).
  - Display routine adherence percentage prominently:
    - On the "Weekly Progress Snapshot" on the Home (Dashboard). (Integration with Epic 15)
    - Within the "Current Routine" view in the Routines tab.
    - On the consolidated "Progress Overview Dashboard."
  - Visualize adherence (e.g., progress bar, checkmarks on a weekly view).
- **Acceptance Criteria (ACs):**
  - AC1: Routine adherence is calculated based on logged sessions vs. scheduled routine activities.
  - AC2: Adherence percentage is displayed in the Home Dashboard's weekly snapshot, Current Routine view, and Progress Overview Dashboard.
  - AC3: Visual indicators clearly show adherence status.

### Story 17.3: Merge Calendar, Stats, and Detailed Progress Views
- **User Story / Goal:** As a User, I want to access detailed views of my practice calendar (showing intensity) and specific statistics from the consolidated Progress section, ensuring all my progress data tells a cohesive story.
- **Detailed Requirements:**
  - **Calendar View (within Progress Tab):**
    - Implement a full calendar view accessible from the Progress Overview Dashboard.
    - This calendar should visualize practice intensity and duration for logged sessions on each day (e.g., using color-coding and size of indicators).
  - **Statistics View (within Progress Tab):**
    - Implement a detailed statistics view accessible from the Progress Overview Dashboard.
    - Display weekly, monthly, and long-term trends for key metrics (e.g., total time, sessions per method, adherence over time).
  - **Achievements View (within Progress Tab):**
    - Ensure the Achievements display is accessible from the Progress Overview Dashboard.
  - Ensure these detailed views are consistent with the overall progress narrative and UI.
- **Acceptance Criteria (ACs):**
  - AC1: A detailed calendar view within the Progress tab displays logged session intensity and duration.
  - AC2: A detailed statistics view within the Progress tab shows trends for key metrics.
  - AC3: All progress views (Overview, Calendar, Stats, Achievements) are logically linked and present a cohesive story of user progress.

### Story 17.4: Add Contextual Insights to Progress Data
- **User Story / Goal:** As a User, I want the app to provide contextual insights based on my progress data, helping me understand my performance better and identify areas for improvement.
- **Detailed Requirements:**
  - Based on analyzed progress data (trends, adherence, session details), provide simple, actionable insights to the user.
  - Examples:
    - "You've increased your Vascion practice time by 20% this month!"
    - "Your adherence to the 'Beginner Growth' routine is excellent this week!"
    - "Noticing a drop in session frequency? Try scheduling your next session."
  - These insights can be displayed on the Progress Overview Dashboard or as occasional highlights.
  - Initial implementation can be rule-based; more complex AI-driven insights can be part of Epic 18.
- **Acceptance Criteria (ACs):**
  - AC1: The app displays at least 3-5 types of rule-based contextual insights based on user's progress data.
  - AC2: Insights are presented in a clear, positive, and actionable manner.
  - AC3: Insights are displayed on the Progress Overview Dashboard or as relevant highlights.

## Change Log

| Date       | Version | Description                                                          | Author   |
| :--------- | :------ | :------------------------------------------------------------------- | :------- |
| 2025-05-29 | 0.1     | Initial Draft based on Updated UI/UX Integration Plan - Phase 3.     | 2 - PM   |