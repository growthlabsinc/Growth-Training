# Epic 8: Gamification & Emotional Intelligence System - Core MVP

**Goal:** Implement initial gamification elements (streaks, badges) and an optional mood check-in system to encourage consistent practice, provide positive reinforcement, and gather subjective feedback.

## Story List

### Story 8.1: Session Streaks Logic & Display
- **User Story / Goal:** As a User, I want the app to track my consecutive days of logged sessions (streaks) and display my current streak, so I feel motivated to practice consistently.
- **Detailed Requirements:**
  - When a session is logged, update user's streak data in their Firestore user profile.
    - Streak is maintained if at least one session is logged on a given day.
    - Streak increments if a session is logged on the day immediately following the previous logged day.
    - Streak resets to 0 or 1 if a day is missed.
  - Display the current session streak prominently on the Dashboard/Home screen.
  - (Visual: Simple number with a flame/star icon).
- **Acceptance Criteria (ACs):**
  - AC1: Session streak is correctly calculated based on logged session dates.
  - AC2: Current streak is displayed on the Dashboard.
  - AC3: Streak increments correctly with consecutive daily logging.
  - AC4: Streak resets correctly if a day of logging is missed.

### Story 8.2: Milestone Badges - Definition & Awarding Logic
- **User Story / Goal:** As a User, I want to earn badges for achieving milestones (e.g., completing a stage, specific number of sessions), so I feel a sense of accomplishment.
- **Detailed Requirements:**
  - Define an initial set of 3-5 MVP badges in Firestore (`badges` collection: badgeId, name, description, criteria (e.g., `sessionsLogged: 10`, `stageCompleted: "Beginner"`), icon_placeholder_url).
  - Examples:
    - "First Session Logged"
    - "7 Day Streak"
    - "Beginner Stage Mastered" (requires integration with progression logic - Story 9.X)
    - "25 Sessions Logged"
  - When user actions meet badge criteria, award the badge to the user (e.g., store awarded badge IDs in their user profile).
  - Display a simple, non-intrusive notification/animation when a new badge is earned.
- **Acceptance Criteria (ACs):**
  - AC1: Badge definitions are stored in Firestore.
  - AC2: Logic correctly awards badges to users when criteria are met.
  - AC3: Users receive a notification (e.g., a small banner or alert) upon earning a new badge.
  - AC4: Awarded badges are recorded for the user.

### Story 8.3: Badges Display Screen
- **User Story / Goal:** As a User, I want to view all the badges I've earned and see which ones are still locked, so I can track my achievements.
- **Detailed Requirements:**
  - Create a "My Badges" or "Achievements" screen (e.g., accessible from Profile/Settings or Dashboard).
  - Display all defined badges.
  - Clearly differentiate between earned badges (e.g., full color icon, achievement date) and locked badges (e.g., grayscale icon, criteria visible).
  - Fetch badge definitions from Firestore and user's earned badges from their profile.
- **Acceptance Criteria (ACs):**
  - AC1: User can view a screen listing all available badges.
  - AC2: Earned badges are visually distinct from locked badges.
  - AC3: Information about how to earn locked badges (criteria) is visible.

### Story 8.4: Optional Mood Check-Ins (Before/After Session)
- **User Story / Goal:** As a User, I want the option to quickly log my mood before and/or after a session, so I (and potentially the AI coach in the future) can see correlations with my training.
- **Detailed Requirements:**
  - When starting a session via the timer, or when manually logging a session, provide an *optional* prompt for a "Pre-Session Mood Check-in".
  - After completing a timed session or when saving a manual log, provide an *optional* prompt for a "Post-Session Mood Check-in".
  - Mood input should be simple (e.g., 3-5 emoticons/options: Very Good, Good, Neutral, Bad, Very Bad).
  - Store selected mood(s) as part of the `sessionLogs` entry in Firestore.
  - Users should be able to easily skip this step.
- **Acceptance Criteria (ACs):**
  - AC1: Optional mood check-in prompts are presented at appropriate times (before/after session).
  - AC2: User can select a mood from a simple set of options or skip the step.
  - AC3: Selected mood data is saved with the session log in Firestore if provided.
  - AC4: The process is quick and unobtrusive.

### Story 8.5: Effort-Based Affirmations & Encouraging Messages
- **User Story / Goal:** As a User, I want to receive occasional effort-based affirmations or encouraging messages, so I feel supported in my journey.
- **Detailed Requirements:**
  - Create a small pool of positive affirmations/encouraging messages (text-based).
  - Display a random message from this pool:
    - Occasionally on the Dashboard/Home screen.
    - After successfully logging a session.
    - When a streak is maintained or a badge is earned.
  - Messages should be short, supportive, and focus on effort and consistency rather than specific outcomes. (e.g., "Great job staying consistent!", "Every session counts towards your goal.", "Keep up the great effort!").
- **Acceptance Criteria (ACs):**
  - AC1: A pool of at least 10-15 affirmations/messages is available.
  - AC2: Affirmations are displayed at appropriate triggers (Dashboard, post-log, streak/badge).
  - AC3: Messages are varied and supportive.

### Story 8.6: Journaling Prompts
- **User Story / Goal:** As a User, I want to be offered occasional journaling prompts related to my journey and experience, so I can reflect more deeply, with these notes integrated into my session logs.
- **Detailed Requirements:**
  - Create a small pool of journaling prompts (e.g., "What was one thing I learned from today's session?", "How am I feeling about my progress this week?", "What's my main focus for the next session?").
  - When a user is adding notes to a session log (Story 4.1), optionally display one of these prompts to inspire their notes.
  - This is an enhancement to the existing session notes field, not a separate journaling feature for MVP.
- **Acceptance Criteria (ACs):**
  - AC1: A pool of at least 5-10 journaling prompts is available.
  - AC2: A relevant prompt is optionally displayed within the session logging interface when adding notes.
  - AC3: User can ignore the prompt and write free-form notes as usual.

## Change Log

| Date       | Version | Description     | Author   |
| :--------- | :------ | :-------------- | :------- |
| 2025-05-08 | 0.1     | Initial Draft   | 2 - PM   |