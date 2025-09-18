# Growth UI/UX Specification

## Introduction

This document defines the user experience goals, information architecture, user flows, and visual design specifications for the "Growth" iOS application's user interface. Its purpose is to ensure a consistent, user-centered design that is calm, professional, supportive, discreet, and icon-forward, prioritizing user safety and ease of use.

-   **Link to Primary Design Files:** [Figma Design for Growth iOS App](https://www.figma.com/design/7KW2CPstr0dgseeVWptqyi/UX-Pilot--AI-UI-Generator---AI-Wireframe-Generator--Community-?node-id=1-446&t=oueCP1XvFsZgvW1q-1)
-   **Link to Deployed Storybook / Design System:** {Not applicable for MVP, but for future reference if components are built in a web-based storybook}
-   **Link to Style Guide:** `docs/style-guide.md`

## Overall UX Goals & Principles

-   **Target User Personas:** 
    * **Primary:** Adult men (18+) seeking structured guidance for Growth Methods. Ranges from individuals with ED to those seeking general vascular health enhancement.
    * **Key Traits & Needs:** Committed to self-improvement, value privacy/discretion, seek trustworthy/clear guidance, tech-savvy for app use, motivated by progress, concerned about safety.
-   **Usability Goals:**
    * **Ease of Learning:** Users should quickly understand how to navigate the app, find exercises, log sessions, and access help.
    * **Efficiency of Use:** Core tasks (starting a session, logging, checking progress) should be accomplishable with minimal steps.
    * **Error Prevention:** Design to minimize errors, especially in logging or method selection. Provide clear confirmation and undo options where appropriate.
    * **Discoverability:** Educational content and AI coach should be easily discoverable.
-   **Design Principles:**
    1.  **Safety & Trust First:** Every design decision must prioritize user safety, data privacy, and build trust through transparency and clarity. Medical disclaimers and safety warnings are paramount.
    2.  **Discreet & Professional:** The UI should be calm, respectful, and professional, avoiding overly clinical or overtly sexualized aesthetics. Support user discretion. 
    3.  **Clarity & Simplicity:** Instructions, navigation, and data presentation must be exceptionally clear and simple. Avoid jargon where possible or explain it. Icon-forward design to aid quick comprehension. 
    4.  **Supportive & Motivational:** The app should feel like a supportive partner in the user's journey, offering encouragement and positive reinforcement. 
    5.  **Progressive Disclosure:** Show essential information first. Allow users to drill down for more details as needed to avoid overwhelming them.

## Information Architecture (IA)

-   **Site Map / Screen Inventory (High-Level MVP):**
    ```mermaid
    graph TD
        subgraph "Onboarding"
            A0[Welcome Screen] --> A1[Medical Disclaimer & Safety Info];
            A1 --> A2[Privacy Policy & Terms Acceptance];
            A2 --> A3[Account Creation/Login];
            A3 --> A4[Optional: Initial Goal Setting/Profile Qs];
        end

        subgraph "Main App Tabs"
            B[Dashboard/Home]
            C[Methods]
            D[Progress]
            E[Coach]
            F[Resources/Learn]
        end

        A4 --> B;

        B --> B1[Summary of Current Stage/Next Session];
        B --> B2[Quick Log Access];
        B --> B3[Motivational Snippet/Tip];
        B --> B4[Streak/Badge Highlights];

        C --> C1[Methods Overview (Dashboard-style Cards)];
        C1 -- Select Method --> C2[Method Detail Screen];
        C2 --> C3[Instructional Content (Text/Visuals)];
        C2 --> C4[In-App Timer Screen];
        C2 --> C5[Log Session Screen from Method];

        D --> D1[Visual Dashboards (Charts, Calendar)];
        D --> D2[Session History List];
        D --> D3[Goal Progression View];

        E --> E1[Chat Interface with AI Growth Coach];
        E1 --> E2[Coach Disclaimers];

        F --> F1[Educational Articles List/Categories];
        F1 -- Select Article --> F2[Article View Screen];

        subgraph "Settings & More"
            G[Settings (Accessible from all main tabs)]
            G --> G1[Profile Management];
            G1 --> G1A[Logout/Delete Account];
            G --> G2[Notification Preferences];
            G --> G3[Privacy Policy/Terms/Disclaimers Access];
            G --> G4[Support/FAQ];
            G --> G5[Overtraining Alert Settings];
            G --> G6[Data Export/Management - Future];
        end

        C4 --> C5;
        C5 --> D;
    ```
-   **Navigation Structure:**
    * **Primary Navigation:** Bottom Tab Bar for main sections (Dashboard, Methods, Progress, Coach, Resources). Icon-forward design for tab items.
    * **Secondary Navigation:** Standard iOS navigation patterns (e.g., navigation bars with back buttons, modal views for specific tasks like logging or timers).
    * **Access to Settings:** Gear icon in the navigation bar of main screens or within a "More" tab if space is constrained.

## User Flows

### 1. New User Onboarding & First Method View

-   **Goal:** New user successfully creates an account, understands safety/privacy, and views their first method.
-   **Steps / Diagram:**
    ```mermaid
    graph TD
        Start((App Launch First Time)) --> Welcome[Display Welcome Screen - Calm, professional];
        Welcome --> Disclaimer[Present Medical Disclaimer & Safety Info - Clear, prominent];
        Disclaimer -- User Acknowledges --> Privacy[Present Privacy Policy & Terms - Easy to read];
        Privacy -- User Accepts --> Account[Account Creation/Login Screen (Firebase Auth) - Secure, simple];
        Account -- Success --> OptProfile[Optional: Initial Profile Questions (e.g., starting point) - Supportive tone];
        OptProfile -- Continue/Skip --> MainDashboard[Navigate to Main Dashboard];
        MainDashboard --> MethodsTab[User taps 'Methods' Tab (Clear Icon)];
        MethodsTab --> MethodList[Display Methods Overview (Dashboard-style Cards) - Icon-forward];
        MethodList -- User selects a Beginner Method --> MethodDetail[Display Method Detail Screen with Instructions - Clear, professional];
    ```

### 2. Logging a Training Session (Post-Method)

-   **Goal:** User completes a method using the timer and logs their session with notes.
-   **Steps / Diagram:**
    ```mermaid
    graph TD
        Start(From Method Detail Screen) --> TimerScreen[User initiates In-App Timer for selected method - Intuitive controls];
        TimerScreen -- Timer Completes/User Stops --> LogSessionPrompt[Prompt to Log Session - Clear CTA];
        LogSessionPrompt -- Yes --> LogScreen[Display Log Session Screen: Method pre-filled, Duration from timer - Discreet fields];
        LogScreen --> AddNotes[User adds subjective feedback/notes - Supportive prompts if used];
        AddNotes --> MoodCheck[Optional: Mood Check-in - Simple, discreet icons];
        MoodCheck -- Continue --> SaveLog[User Saves Log];
        SaveLog -- Success --> Confirmation[Show Confirmation & Navigate to Progress or Methods - Positive reinforcement];
        LogSessionPrompt -- No --> BackToMethods[Return to Methods Screen];
    ```

### 3. Interacting with AI Growth Coach

-   **Goal:** User asks the AI Coach a question about a method and receives a relevant answer.
-   **Steps / Diagram:**
    ```mermaid
    graph TD
        Start(From any main screen) --> CoachTab[User taps 'Coach' Tab (Clear Icon)];
        CoachTab --> ChatUI[Display Chat Interface - Clean, professional, conversational];
        ChatUI --> DisclaimerCoach[Show AI Coach Disclaimer (first time/periodically) - Prominent];
        DisclaimerCoach --> UserInput[User types question about a method];
        UserInput -- Sends Question --> AIProcessing{AI Processes Question (RAG)};
        AIProcessing -- Valid & In-Scope --> AIResponse[Display AI-generated answer & source if applicable - Supportive tone];
        AIProcessing -- Out-of-Scope/Unclear --> AINoMedical[Display "I cannot provide medical advice..." or "Please rephrase..." message - Clear, firm but polite];
        AIResponse --> ChatUI;
        AINoMedical --> ChatUI;
    ```

### 4. Reviewing Progress

-   **Goal:** User reviews their session consistency and overall progress.
-   **Steps / Diagram:**
    ```mermaid
    graph TD
        Start(From any main screen) --> ProgressTab[User taps 'Progress' Tab (Clear Icon)];
        ProgressTab --> ProgressDashboard[Display Progress Dashboard: Charts, Calendar - Clear, icon-forward data viz];
        ProgressDashboard --> ViewHistory[User taps to view detailed session history];
        ViewHistory --> SessionList[Display list of logged sessions - Easy to scan];
        SessionList -- Selects a session --> SessionDetail[Display details of selected session - Discreet presentation of notes];
    ```

## Wireframes & Mockups

-   The primary design reference is now available in [Figma](https://www.figma.com/design/7KW2CPstr0dgseeVWptqyi/UX-Pilot--AI-UI-Generator---AI-Wireframe-Generator--Community-?node-id=1-4&t=rGdqeT2tPZIsyrD6-1)
-   Key screens developed in Figma:
    * **Onboarding Screens:** Disclaimer, Privacy, Account. (Emphasis: Calm, trustworthy)
    * **Methods Overview Screen:** Dashboard-style cards. (Emphasis: Icon-forward, clear progression) 
    * **Method Detail Screen:** Instructions, timer access. (Emphasis: Professional, clear instructions, safety prominent)
    * **In-App Timer Screen.** (Emphasis: Simple, functional)
    * **Session Log Screen.** (Emphasis: Discreet, supportive)
    * **Progress Dashboard Screen.** (Emphasis: Motivational, icon-forward data)
    * **AI Coach Chat Interface.** (Emphasis: Professional, supportive, clear disclaimers)
    * **Educational Resource Article View.** (Emphasis: Readable, calm)
    * **Settings Screen.** (Emphasis: Clear, discreet options for privacy/data)
-   Design specifications adhere to `docs/style-guide.md`. Emphasis on an icon-forward, calm, professional, and supportive aesthetic.

## Component Library / Design System Reference

-   Primary reference: `docs/style-guide.md` for colors, typography, basic component styling (buttons, cards, inputs).
-   Specific iOS native components will be used, styled according to the guide.
-   Custom components (e.g., progress rings, method cards, specific icon sets) will be designed based on the style guide to reinforce the calm, professional, supportive, and discreet nature of the app.
-   All implemented component designs can be viewed in the StyleGuideViewController.

## Style Guide Implementation Status

-   **Implementation Status:** Story 1.4 (Style Guide Implementation) has been completed with all core UI elements from the style guide implemented as reusable components:
    * **Theming System:** Core color palette and typography styles implemented with dark mode support.
    * **Buttons:** Primary, Secondary, Text, and Icon buttons with proper state handling.
    * **Cards:** Standard, Workout, and Progress cards with proper styling and layout.
    * **Text Inputs:** Text fields with all states (normal, focused, error, disabled).
    * **Typography:** Complete typography system with all text styles from the style guide.
-   **Component Demo:** All implemented components can be viewed in the StyleGuideViewController, which provides a comprehensive showcase of the style guide in action.
-   **Design System Structure:**
    * Core theming files in `Growth/Core/UI/Theme/`
    * Component implementations in `Growth/Core/UI/Components/`
    * UI extensions in `Growth/Core/UI/Extensions/`
-   **Figma Reference:** 
    * The Figma designs serve as a visual reference for UI implementations.
    * Note that the style guide (`docs/style-guide.md`) takes precedence over the Figma designs when there are any discrepancies.

## Branding & Style Guide Reference

-   See `docs/style-guide.md`.
-   The Figma designs have been created to align with this style guide.

## Accessibility (AX) Requirements

-   **Target Compliance:** WCAG 2.1 Level AA where feasible within MVP.
-   **Specific Requirements:**
    * Support for iOS Dynamic Type for text scaling.
    * Sufficient color contrast for text and interactive elements as per `docs/style-guide.md` and WCAG AA.
    * VoiceOver compatibility: All interactive elements must have clear labels; images to have alt text or be marked decorative. Icons used for navigation or conveying information must have clear accessibility labels.
    * Ensure touch targets meet Apple's HIG (minimum 44x44 points).
    * Provide clear focus states for interactive elements.

## Responsiveness

-   Not applicable for iOS native app in the same way as web, but UI must adapt gracefully to different iPhone screen sizes and orientations (portrait primarily, landscape for specific views like video if added later).
-   Utilize Auto Layout and Size Classes effectively.
-   Designs in Figma have been created with adaptability in mind.

## Change Log

| Date       | Version | Description                                                                                                | Author   |
| :--------- | :------ | :--------------------------------------------------------------------------------------------------------- | :------- |
| 2025-05-08 | 0.1     | Initial Draft based on PRD and Project Brief.txt.                                                            | 2 - PM   |
| 2025-05-08 | 0.2     | Updated to explicitly incorporate "calm, professional, supportive, discreet, icon-forward" principles.     | 2 - PM   |
| 2025-05-09 | 0.3     | Added Figma design link and updated with Style Guide implementation status.                                | Claude 3.7|

## Design System

-   **Brand Colors:**
    -   Primary: `#0A5042` (Core Green)
    -   Secondary: `#D1EC2D` (Mint Green)
    -   Accent: `#00BFA5` (Bright Teal)
    -   Background: `#F8FAFA` (Background Light)
    -   Card Background: `#FFFFFF` (Surface White)

-   **Typography:**
    -   Headings: System Font, Bold, 20-32pt
    -   Body: System Font, Regular, 15-17pt
    -   Buttons: System Font, Medium, 16pt
    -   Captions: System Font, Regular, 12pt

-   **Components:**
    -   Buttons: 8px corner radius, 52px height for primary/secondary
    -   Cards: 12-16px corner radius, white background with subtle shadow
    -   Text fields: 8px corner radius, 56px height

-   **Figma Implementation Notes:**
    - The Figma design serves as the primary reference for all UI components
    - Color values, typography styles, spacing, and component measurements should strictly follow the Figma specifications
    - Any deviations from the Figma design must be documented with rationale
    - The design system in code should be updated to match Figma specifications exactly

## iOS-Specific Guidelines

-   **Navigation:**
    -   Tab-based primary navigation
    -   Push navigation for detail screens
    -   Modal presentation for settings and creation flows

-   **Interactions:**
    -   Tap feedback using subtle haptics
    -   Swipe gestures for list item actions
    -   Pull-to-refresh for content updates

-   **Transitions:**
    -   Standard push/pop navigation animations
    -   Custom transitions for modal presentations (slide up)
    -   Subtle fade transitions for content updates

-   **Accessibility:**
    -   Support Dynamic Type for all text
    -   Ensure minimum touch targets of 44x44pt
    -   Provide appropriate voice over labels
    -   Support Dark Mode with appropriate color adjustments

## Wireframes & Mockups

-   **Onboarding Flow:**
    -   Welcome screen
    -   Account creation/login
    -   Initial setup questions
    -   Dashboard introduction

-   **Main Dashboard:**
    -   Summary metrics at top
    -   Quick action buttons
    -   Recent activity feed
    -   Progress indicators

-   **Method Library:**
    -   Categorized grid of method cards
    -   Detail view for each method
    -   Implementation steps with illustrations
    -   Progress tracking

-   **Journal:**
    -   Calendar view of entries
    -   Entry creation form
    -   Entry detail view
    -   Data visualization of trends

-   **Settings:**
    -   Account management
    -   Notification preferences
    -   Privacy settings
    -   Feedback mechanism