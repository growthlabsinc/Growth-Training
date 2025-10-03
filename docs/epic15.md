# Epic 15: Next-Gen Foundation - New IA, "Today View" Dashboard & Unified Practice Entry

**Goal:** To implement the foundational elements of the updated UI/UX Integration Plan, including a revamped Information Architecture with a new "Routines" section, a "Today View" focused Dashboard as the primary user hub, and unified entry points for practice.

**Source Document:** `UI/UX Integration Plan (Updated)` (for all stories within this epic)

## Story List

### Story 15.1: Implement Revised Information Architecture (IA)
- **User Story / Goal:** As a User, I want a clear and intuitive app structure with new sections for "Routines" and consolidated "Practice" and "Progress" areas, making it easier to navigate and understand the app's offerings.
- **Detailed Requirements:**
  - Restructure the app's main navigation (bottom tab bar) to reflect the new IA:
    - **Home (Dashboard - Redesigned):** Focus on "Today's Focus" and "Weekly Progress Snapshot."
    - **Routines (New Section):** Current Routine, Browse Routines, Routine History.
    - **Practice (Unified Section):** Entry point for Guided Sessions (from routine) and Quick Practice (ad-hoc), leading to Timer & Logging.
    - **Progress (Consolidated Section):** Overview Dashboard, Calendar View, Statistics, Achievements.
    - **Profile:** (Implicitly retained from previous IA, ensure it's still accessible, e.g., containing Settings, Session History, Personal Stats as per previous plan).
  - Migrate existing content and features to their new locations within this IA.
  - Update all internal routing and deep links.
- **Acceptance Criteria (ACs):**
  - AC1: The app's main navigation is updated to the new IA structure including Home (Dashboard), Routines, Practice, Progress, and Profile.
  - AC2: The new "Routines" section is implemented with placeholders for its sub-sections (Current, Browse, History).
  - AC3: The "Practice" section serves as a unified entry point for both routine-based and ad-hoc sessions.
  - AC4: The "Progress" section is structured with placeholders for its consolidated views.

### Story 15.2: Develop "Today View" Dashboard as Primary Hub
- **User Story / Goal:** As a User, I want my Dashboard ("Home") to primarily show me what I need to focus on today, whether it's a routine activity, a quick practice option, or rest day information.
- **Detailed Requirements:**
  - Redesign the Home screen to be the "Today View" dashboard.
  - Implement the "Today's Focus" section dynamically displaying:
    - **Routine Day Overview:** If the user is following a routine and it's a practice day (method(s), intensity, duration).
    - **Quick Practice Option:** If no routine is active, or the routine day is completed, offer quick practice suggestions.
    - **Rest Day Activities:** If it's a designated rest day in the routine.
  - Implement the "Weekly Progress Snapshot" section showing:
    - Routine Adherence (placeholder for logic from Epic 17).
    - Total Practice Time this week.
    - Current Streak Status.
  - Implement "Quick Actions Based on Context" (e.g., "Start Today's Routine," "Log Quick Practice").
- **Acceptance Criteria (ACs):**
  - AC1: The Home screen is redesigned as the "Today View" dashboard.
  - AC2: The "Today's Focus" section dynamically shows routine day overview, quick practice options, or rest day activities based on user context.
  - AC3: The "Weekly Progress Snapshot" displays streak, total practice time, and a placeholder for routine adherence.
  - AC4: Contextual quick action buttons are available on the dashboard.

### Story 15.3: Unify Practice Entry Points & Initial Routine Selection Flow
- **User Story / Goal:** As a User, I want clear and distinct ways to start either a structured routine session or an ad-hoc quick practice, and easily select or browse routines.
- **Detailed Requirements:**
  - **Unified Practice Entry:**
    - Ensure the "Practice" tab/section clearly offers options for "Guided Sessions (from my routine)" and "Quick Practice (select any method)."
    - The Dashboard "Today's Focus" will also serve as a primary entry point for routine-based sessions.
  - **Routine Section (Initial Setup):**
    - "Current Routine" (in Routines Tab): Displays the active routine's weekly overview and day-by-day breakdown (details in Epic 16). If no routine is active, prompts to browse.
    - "Browse Routines" (in Routines Tab): Allows users to view available programs (Beginner, Intermediate, Advanced placeholders). Implement basic list view. Detailed routine content in Epic 16.
    - "Routine History" (in Routines Tab): Placeholder for displaying past completed/attempted routines.
  - Implement progressive disclosure for routine details to avoid overwhelming users.
- **Acceptance Criteria (ACs):**
  - AC1: Clear pathways exist from the "Practice" tab and Dashboard to start either a routine session or a quick practice session.
  - AC2: The "Routines" tab structure (Current, Browse, History) is implemented.
  - AC3: Users can browse a list of placeholder routines categorized by difficulty.
  - AC4: The "Current Routine" view shows an overview if a routine is active, or a prompt to select one.

### Story 15.4: Implement New Navigation Transitions & Context Preservation
- **User Story / Goal:** As a User, I want navigation to feel smart and context-aware, helping me understand where I am in a complex flow, like a multi-method routine day.
- **Detailed Requirements:**
  - Implement new transition strategies:
    - **Continuous Flow:** Design for seamless progression through multi-method days (technical implementation in Epic 16).
    - **Context Preservation:** Implement breadcrumb-like indicators (e.g., "Day 5 > Method 1 of 3") during multi-method practice sessions.
    - **Smart Returns:** Ensure that after completing a practice or logging, the app returns the user to a meaningful next action or overview screen, not just the immediate previous screen.
- **Acceptance Criteria (ACs):**
  - AC1: Breadcrumb-style context (e.g., "Day X > Method Y of Z") is displayed during multi-method sessions.
  - AC2: Navigation logic implements "smart returns" to contextually relevant screens post-activity.
  - AC3: Design for continuous flow transitions in multi-method sessions is established.

## Change Log

| Date       | Version | Description                                                          | Author   |
| :--------- | :------ | :------------------------------------------------------------------- | :------- |
| 2025-05-29 | 0.1     | Initial Draft based on Updated UI/UX Integration Plan - Phase 1.     | 2 - PM   |