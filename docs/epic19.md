# Epic 19: Enhanced User Onboarding Experience & Initial Engagement

**Goal:** To implement a comprehensive, supportive, and seamless onboarding experience that effectively communicates the app's value, ensures user understanding of safety and privacy, guides users to an appropriate starting point (including conditional routing for Angio Pumping), facilitates initial routine selection, and fosters high initial engagement, based on the detailed Onboarding Plan.

**Source Documents:** `Project Brief.txt`, `UI/UX Integration Plan (Updated)`, `Untitled 5.txt` (for Angio Pumping context), previous Epics (especially Epic 2 for foundational consent, Epic 13 for Angio Pumping method details, Epic 14 for UI styling). The primary source for story structure is the "Expert iOS App Onboarding Plan Generator" content previously created.

## Story List

### Story 19.1: Implement Welcome & Value Proposition Screen
- **User Story / Goal:** As a New User, I want to be greeted with a clear and professional welcome screen that concisely explains the app's core value, so I understand its purpose and feel encouraged to proceed.
- **Detailed Requirements:**
  - Design and implement the "Welcome & Value Proposition" screen.
  - UI Elements:
    - Prominent app logo and headline (e.g., "A Structured Path to Vascular Health").
    - 2-3 bullet points highlighting key benefits (e.g., "Guided, Science-Based Methods," "Private and Secure Tracking," "Supportive Community Insights").
    - Single, prominent "Get Started" button.
  - Visual Design: Adhere to the app's primary color scheme (Core Green, teal/emerald accents, white space) for a calm, clean, professional feel. Abstract visuals, no explicit imagery.
- **Acceptance Criteria (ACs):**
  - AC1: The Welcome screen is displayed upon first app launch.
  - AC2: All specified UI elements (logo, headline, benefits, button) are present and correctly styled.
  - AC3: Tapping "Get Started" navigates to the Medical Disclaimer screen.

### Story 19.2: Implement Mandatory Medical, Safety, Privacy & Terms Consent Flow
- **User Story / Goal:** As a New User, I must review and explicitly consent to the app's medical disclaimers, safety guidelines, privacy policy, and terms of use before accessing any features, ensuring I am fully informed and my consent is recorded.
- **Detailed Requirements:**
  - Implement two sequential mandatory screens:
    1.  **Medical Disclaimer & Safety Consent Screen:**
        - Title: "Important: Your Safety Comes First."
        - [cite_start]Scrollable text view with full medical disclaimer and safety warnings (key points bolded). 
        - Mandatory checkbox: "I have read and agree to the Safety & Medical Disclaimer."
        - "Continue" button, disabled until checkbox is checked.
    2.  **Privacy & Terms of Use Consent Screen:**
        - Title: "Your Privacy is Our Priority."
        - Concise summary of privacy policy (data encryption, no sharing of personal logs) with prominent links to full documents.
        - Mandatory checkbox: "I agree to the Privacy Policy and Terms of Use."
        - "Continue" button, disabled until checkbox is checked.
  - Account Creation: After these consents, navigate to the account creation screen (functionality from Epic 2, Story 2.1).
  - Record acceptance (timestamp, version of documents accepted) in the user's Firestore profile.
- **Acceptance Criteria (ACs):**
  - AC1: Medical & Safety Disclaimer screen is presented with all specified elements; "Continue" is enabled only after consent.
  - AC2: Privacy & Terms screen is presented with summary, links, and consent mechanism; "Continue" is enabled only after consent.
  - AC3: User cannot proceed to account creation or app usage without agreeing to both.
  - AC4: Consents (with version and timestamp) are recorded in the user's Firestore profile.

### Story 19.3: Implement Initial User Assessment for Method Routing
- **User Story / Goal:** As a New User, after creating my account, I want to answer a simple question that helps the app guide me to the most appropriate starting Growth Method based on my physical ability.
- **Detailed Requirements:**
  - Implement the "Initial Assessment" screen.
  - UI Elements:
    - Supportive question: "Let's find your ideal starting point."
    - [cite_start]Single, clear question based on Angion documentation: "Can you achieve and maintain an erection suitable for practice without aids?" 
    - Two large, clear buttons: "Yes, I can" and "No, I need assistance."
  - Logic:
    - If "No, I need assistance," set the user's starting point/current focused stage to "Angio Pumping."
    - If "Yes, I can," set the user's starting point/current focused stage to "Angion Method 1.0 (Beginner)."
  - Store this initial assessment outcome or derived starting stage in the user's profile.
- **Acceptance Criteria (ACs):**
  - AC1: The Initial Assessment screen is displayed after account creation.
  - AC2: All UI elements (question, two distinct answer buttons) are present and clear.
  - AC3: User selection correctly routes them to either "Angio Pumping" or "Angion Method 1.0 (Beginner)" as their initial focused method in their profile.
  - AC4: The interaction feels supportive and non-clinical.

### Story 19.4: Implement Onboarding Routine & Goal Selection Screen
- **User Story / Goal:** As a New User, I want to choose whether to start with a guided routine or opt for ad-hoc practice, so I can align the app with my preferences from the outset.
- **Detailed Requirements:**
  - Implement the "Routine & Goal Selection" screen.
  - UI Elements:
    - Encouraging title: "Choose Your Path."
    - Two primary options presented as visually appealing cards:
        - "Start a Guided Routine" (subtitle: "Follow a structured weekly program for consistent progress"). This should be the recommended option.
        - "I prefer Quick Practice" (subtitle: "Practice any method, any time, at your own pace").
    - A less prominent "Skip for now" text link.
  - Logic:
    - If "Guided Routine" is selected, navigate to a simplified routine browser (initially showing Beginner routines, from Epic 15 Story 15.3).
    - If "Quick Practice" or "Skip for now" is selected, set user preference to ad-hoc practice.
- **Acceptance Criteria (ACs):**
  - AC1: The Routine & Goal Selection screen is displayed with its specified UI elements.
  - AC2: The "Start a Guided Routine" option is visually recommended.
  - AC3: Selecting "Guided Routine" leads to a routine selection/Browse flow.
  - AC4: Selecting "Quick Practice" or "Skip for now" sets the user's preference accordingly and proceeds to the next step.

### Story 19.5: Implement Contextual Notification Permissions Screen
- **User Story / Goal:** As a New User, towards the end of my onboarding, I want to be asked for notification permissions with a clear explanation of why they are beneficial, so I can make an informed choice.
- **Detailed Requirements:**
  - Implement the "Notification Permissions" screen.
  - UI Elements:
    - Informative title: "Stay on Track."
    - Explanation: "Allow notifications to receive helpful reminders for your scheduled routine sessions and celebrate your progress."
    - Buttons: "Enable Notifications" (triggers native iOS prompt) and "Maybe Later."
  - Display this screen after routine selection (if applicable) or before navigating to the main app.
- **Acceptance Criteria (ACs):**
  - AC1: The Notification Permissions screen is displayed with its specified UI elements.
  - AC2: The explanation clearly states the value of notifications in the app's context.
  - AC3: Tapping "Enable Notifications" correctly triggers the native iOS permission prompt.
  - AC4: User can choose "Maybe Later" and proceed to the main app.

### Story 19.6: Implement Onboarding Flow Orchestration & Interactive Elements
- **User Story / Goal:** As a New User, I want a smooth, guided onboarding flow with clear progress indication and satisfying interactive elements, making the initial setup feel effortless and engaging.
- **Detailed Requirements:**
  - **Flow Orchestration:** Ensure the screens (19.1 to 19.5) are presented in the correct sequence as per the User Flow Diagram.
  - **Progress Indicator:** Implement a subtle, segmented progress bar at the top or bottom of each onboarding screen. Segments fill with an animation (e.g., emerald-to-teal gradient) upon step completion.
  - **Button Feedback:** Primary action buttons ("Get Started," "Continue") provide haptic feedback and a gentle scaling animation on tap.
  - **Selection Animation:** Checkboxes and key selection elements (e.g., assessment choice) use subtle animations to confirm selection.
  - **Skip Logic:** If user skips routine selection (Story 19.4), ensure they are smoothly transitioned to Notification Permissions and then the main app (defaulting to ad-hoc practice).
- **Acceptance Criteria (ACs):**
  - AC1: The onboarding screens appear in the defined logical order.
  - AC2: A visual progress indicator accurately reflects the user's stage in the onboarding flow.
  - AC3: Primary buttons and selection elements provide the specified haptic and visual feedback.
  - AC4: Skip logic is handled correctly, leading to a coherent user experience.

### Story 19.7: Implement Initial Onboarding Retention Hooks
- **User Story / Goal:** As a Product Team, we want to implement initial retention strategies within the onboarding flow to encourage users to complete onboarding and take their first key actions in the app.
- **Detailed Requirements:**
  - **Quick Value Demonstration:** Ensure the onboarding flow swiftly guides the user to a state where their "Today View" dashboard (Epic 15, Story 15.2) shows a clear next step (e.g., "Start Angio Pumping," "Begin Angion Method 1.0," or "Explore Beginner Routines").
  - **Preview Achievements:** On the final onboarding screen or upon first landing on the dashboard, briefly highlight the achievement system (e.g., "Your first achievement is just one session away!").
  - **Re-engagement Logic (Placeholder for Future):** Design the logic for a potential re-engagement notification if a user abandons onboarding after account creation but before completing critical setup (like routine selection). Actual notification implementation with push services can be a separate story if complex.
- **Acceptance Criteria (ACs):**
  - AC1: The onboarding flow concludes by landing the user on a Home/Dashboard screen that presents an immediate, actionable next step based on their onboarding choices.
  - AC2: A brief, motivational mention of the achievement system is included towards the end of onboarding or on first dashboard view.
  - AC3: The logic/trigger points for a future re-engagement notification for onboarding abandonment are defined and documented.

## Change Log

| Date       | Version | Description                                                                 | Author   |
| :--------- | :------ | :-------------------------------------------------------------------------- | :------- |
| 2025-06-05 | 0.1     | Initial Draft of Enhanced Onboarding Epic from detailed Onboarding Plan.    | 2 - PM   |