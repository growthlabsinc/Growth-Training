# Epic 16: Immersive Routine & Multi-Method Practice Experience

**Goal:** To develop a fully guided and immersive experience for users following routines, including seamless multi-method session flows, smart transitions, engaging rest day interactions, and intelligent exit handling.

**Source Document:** `UI/UX Integration Plan (Updated)` (for all stories within this epic)

## Story List

### Story 16.1: Develop Multi-Method Guided Practice Flow
- **User Story / Goal:** As a User following a routine with multiple methods in a single day, I want a guided flow that automatically progresses me from one method to the next with clear transitions.
- **Detailed Requirements:**
  - Implement the "Guided Practice Flow" for routine days that have multiple methods.
  - When a method within a multi-method session is completed (timer ends), automatically transition to the next scheduled method.
  - Display context-aware navigation controls (e.g., "Next Method," "Previous Method" if applicable, current position like "Method 1 of 3").
  - Show an "Up Next" preview or a method queue visualization during practice to inform the user about what's coming in the current session.
  - Display total estimated session time remaining for the entire multi-method block.
- **Acceptance Criteria (ACs):**
  - AC1: Users are automatically guided from one method to the next in a multi-method routine day.
  - AC2: "Up Next" previews and overall session progress (e.g., "Method X of Y," total time remaining) are displayed.
  - AC3: Contextual navigation controls for multi-method sessions are functional.

### Story 16.2: Implement Day-Specific Timer Interfaces & Routine Details
- **User Story / Goal:** As a User, I want the timer interface to be specific to my routine's scheduled day and method, and easily access details about my weekly routine schedule.
- **Detailed Requirements:**
  - **Day-Specific Timers:** The timer interface within the Unified Practice screen (from previous UI/UX plan, now evolved for routines) must load configurations based on the specific method scheduled for that routine day (intensity, duration, specific Angion Method).
  - **Routine Day Cards & Details (Routines Tab):**
    - Implement "Day cards" in the "Current Routine" weekly overview, showing practice type (Heavy, Moderate, Light, Rest), method count badges, and visual intensity indicators (color-coded).
    - Allow users to tap on a day card to see collapsible day details with all scheduled methods and their parameters.
- **Acceptance Criteria (ACs):**
  - AC1: The timer interface is configured dynamically based on the selected routine day and method.
  - AC2: The "Current Routine" view in the Routines tab displays day cards with practice type, method count, and intensity indicators.
  - AC3: Users can expand day cards to see detailed method breakdowns for each day of their routine.

### Story 16.3: Create Engaging "Rest Day" Experience
- **User Story / Goal:** As a User on a scheduled rest day, I want a meaningful and engaging experience in the app, rather than a confusing empty timer or lack of guidance.
- **Detailed Requirements:**
  - Design and implement a dedicated interface for "Rest Days" within a routine. This should replace the standard timer interface.
  - Provide valuable content for rest days, such as:
    - Recovery tips.
    - Light stretching suggestions or short guided meditations.
    - Links to relevant "Learn" section articles.
  - Allow users to log wellness activities on rest days (e.g., "Logged 10 mins stretching," "Read recovery article").
  - Track rest day engagement differently than practice day session logging.
  - Ensure the "Today's Focus" on the Dashboard clearly indicates it's a rest day and links to this dedicated experience.
- **Acceptance Criteria (ACs):**
  - AC1: A dedicated UI is presented for rest days, distinct from practice day interfaces.
  - AC2: Rest day interface provides recovery tips and/or suggestions for light activities.
  - AC3: Users can log simple wellness activities on rest days.
  - AC4: Rest day engagement metrics are tracked separately.

### Story 16.4: Implement Intelligent Exit Handling & Session Completion Prompts
- **User Story / Goal:** As a User, when I complete or exit a session (single or multi-method), I want clear prompts that encourage me to log my progress accurately.
- **Detailed Requirements:**
  - Upon completion of a single method or an entire multi-method block, display intelligent session completion prompts.
  - Prompts should encourage progress logging and reflect the completed activities.
  - If exiting mid-session, clarify if partial progress should be logged or the session discarded.
  - Ensure exit session dialogs are not confusing and do not appear unnecessarily (e.g., not for rest days after viewing content).
- **Acceptance Criteria (ACs):**
  - AC1: Session completion prompts intelligently summarize the completed work (e.g., "Log 2 methods for Day 5?").
  - AC2: Exiting mid-session provides clear options for logging partial progress or discarding.
  - AC3: Confusing or unnecessary exit dialogs (e.g., on rest days after no active timer) are eliminated.

## Change Log

| Date       | Version | Description                                                          | Author   |
| :--------- | :------ | :------------------------------------------------------------------- | :------- |
| 2025-05-29 | 0.1     | Initial Draft based on Updated UI/UX Integration Plan - Phase 2.     | 2 - PM   |