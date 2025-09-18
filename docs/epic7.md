# Epic 7: In-App Exercise Timer

**Goal:** Provide users with method-specific timers (countdown/stopwatch) including alerts for breaks or overexertion (based on method guidelines), to help them accurately perform their exercises and log time.

## Story List

### Story 7.1: Basic Timer UI & Functionality
- **User Story / Goal:** As a User, I want a simple timer screen with start, pause, resume, and reset/stop controls, so I can time my exercises.
- **Detailed Requirements:**
  - Design and implement a "Timer" screen.
  - UI elements:
    - Digital display for time (MM:SS).
    - Start button.
    - Pause/Resume button (button text/icon changes based on state).
    - Reset/Stop button (or a "Finish" button that stops and prompts for logging).
  - Timer can function as a stopwatch (counting up) or countdown (see Story 7.2). Default to stopwatch if method doesn't specify duration.
  - Timer should continue running if the app is backgrounded (within OS limits, provide notification if killed).
  - UI adheres to `docs/style-guide.md`.
- **Acceptance Criteria (ACs):**
  - AC1: Timer displays time accurately.
  - AC2: Start, pause, resume, and reset/stop functionalities work as expected.
  - AC3: Timer continues to run when the app is briefly backgrounded.
  - AC4: UI is clear, usable, and adheres to the style guide.

### Story 7.2: Method-Specific Timer Configuration (Countdown & Intervals)
- **User Story / Goal:** As a User, when I start a timer for a specific Growth Method, I want it to be pre-configured for that method's recommended duration or interval structure.
- **Detailed Requirements:**
  - Extend `growthMethods` data model in Firestore to include timer configuration (e.g., `recommendedDurationSeconds`, `isCountdown: true/false`, `intervals: [{name: "Phase 1", durationSeconds: X}, {name: "Break", durationSeconds: Y}]`).
  - When launching the timer from a Method Detail screen, pre-load these settings.
  - If `isCountdown` is true, timer counts down from `recommendedDurationSeconds`.
  - If `intervals` are defined, the timer should guide the user through each interval, displaying the current interval name and its duration.
  - Provide an alert (sound/vibration - user configurable) when an interval ends or the total duration is met.
- **Acceptance Criteria (ACs):**
  - AC1: Timer correctly loads configuration from the selected Growth Method data.
  - AC2: Countdown timer works as specified.
  - AC3: Interval timer guides through phases with names and alerts.
  - AC4: Alerts (sound/vibration, if enabled) trigger at appropriate times.
  - AC5: If no specific configuration, timer defaults to stopwatch mode.

### Story 7.3: Timer Alerts for Breaks/Overexertion
- **User Story / Goal:** As a User, I want the timer to alert me for scheduled breaks or if I exceed a recommended maximum duration for a method, to promote safe practice.
- **Detailed Requirements:**
  - Utilize the interval timer (Story 7.2) for scheduled breaks.
  - For methods with a maximum recommended duration (to be added to `growthMethods` data model as `maxRecommendedDurationSeconds`), if the timer (stopwatch mode) exceeds this, provide a distinct "Overexertion Warning" alert (visual and optional sound/vibration).
  - User should be able to dismiss the alert and continue if they choose, but the warning should be clear.
- **Acceptance Criteria (ACs):**
  - AC1: Scheduled break alerts are provided via the interval timer.
  - AC2: Overexertion warning alert triggers if `maxRecommendedDurationSeconds` is exceeded in stopwatch mode.
  - AC3: Overexertion alert is distinct and provides a clear warning.
  - AC4: User can dismiss the overexertion alert.

### Story 7.4: Post-Timer Flow: Tagging Time Log with Session Notes
- **User Story / Goal:** As a User, after completing an exercise with the timer, I want to easily log this session with the duration pre-filled and add notes.
- **Detailed Requirements:**
  - When the timer is stopped/finished (or a countdown completes):
    - Prompt the user: "Log this session?"
    - If "Yes": Navigate to the "Log Session" screen (from Epic 4).
    - Pre-fill the "Date/Time" (current), "Method" (the one timer was for), and "Duration" (from the timer) fields.
    - User can then add notes and save the log.
  - If "No": Discard timer data and navigate back to the Method Detail or Methods screen.
- **Acceptance Criteria (ACs):**
  - AC1: User is prompted to log session after timer completion.
  - AC2: If user chooses to log, Log Session screen is presented with Method and Duration pre-filled.
  - AC3: User can successfully add notes and save the pre-filled log.
  - AC4: If user chooses not to log, no session is saved.

## Change Log

| Date       | Version | Description     | Author   |
| :--------- | :------ | :-------------- | :------- |
| 2025-05-08 | 0.1     | Initial Draft   | 2 - PM   |