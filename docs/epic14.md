# Epic 14: Dashboard & Core UX/UI Modernization Pass

**Goal:** To significantly elevate the app's user experience and interface by implementing a modern visual design, enhancing interactivity across core components (especially the Dashboard), and improving user engagement through refined UI elements and motivational features.

## Story List

### Story 14.1: Visual Design Refresh - Color, Typography, and Dark Mode
- **User Story / Goal:** As a User, I want the app to have a more sophisticated and modern visual appearance with an updated color scheme, improved typography, and robust dark mode, making it more enjoyable to use.
- **Detailed Requirements:**
  - **Color Scheme & Branding:**
    - Implement a refined color palette using gradients instead of flat colors where appropriate.
    - Utilize the green accent color strategically, creating gradients from emerald to teal for key elements.
    - Introduce subtle background textures or patterns to add visual interest, avoiding monotony.
  - **Dark Mode:**
    - Implement or thoroughly review and enhance dark mode support across all screens, ensuring proper contrast ratios for readability and aesthetics.
  - **Typography & Hierarchy:**
    - Upgrade to SF Pro Display font family for a native iOS feel (if not already in use).
    - Establish a clearer visual hierarchy using varied font weights (e.g., Light, Regular, Medium, Semibold, Bold from style guide) and sizes to guide the eye.
    - Ensure important information is consistently larger and bolder.
    - Implement proper spacing between text elements for improved readability throughout the app.
- **Acceptance Criteria (ACs):**
  - AC1: Gradients are tastefully applied to UI elements as per new design guidelines.
  - AC2: Green accent gradients (emerald to teal) are used strategically on key interactive elements or branding accents.
  - AC3: Subtle background textures/patterns are implemented where they enhance visual appeal without cluttering.
  - AC4: Dark mode is fully supported with correct color palettes and contrast ratios on all MVP screens.
  - AC5: SF Pro Display (or chosen modern font) is consistently applied.
  - AC6: Text hierarchy is clear, with improved use of font weights, sizes, and spacing.

### Story 14.2: Layout & Card Design Modernization
- **User Story / Goal:** As a User, I want interface elements like cards to look more modern and for content to be organized more clearly using a consistent grid system, enhancing visual appeal and information hierarchy.
- **Detailed Requirements:**
  - **Card Design:**
    - Update all primary cards (e.g., Method Cards, Dashboard summary cards) to use rounded corners (16-20px radius).
    - Add subtle shadows and elevation layers to cards to create a sense of depth.
    - Implement card hover/press states with gentle animations (e.g., slight scale, shadow change).
    - Ensure generous padding within cards for content "breathing room."
  - **Grid System & Layout:**
    - Review and reorganize Dashboard content (and other key list/grid views) using a proper grid system with consistent spacing.
    - Group related information together more logically within sections.
    - Strive for better visual balance between different UI sections on screens like the Dashboard.
- **Acceptance Criteria (ACs):**
  - AC1: All primary cards feature rounded corners, subtle shadows/elevation, and appropriate padding.
  - AC2: Card press states are implemented with gentle animations.
  - AC3: Key screens, especially the Dashboard, demonstrate improved content organization based on a grid system and logical grouping.
  - AC4: Consistent spacing rules are applied, improving visual balance.

### Story 14.3: Enhanced Navigation Bar & Calendar Interactivity
- **User Story / Goal:** As a User, I want the bottom navigation and the dashboard calendar to be more prominent, interactive, and visually appealing, making them easier and more delightful to use.
- **Detailed Requirements:**
  - **Bottom Navigation Bar (Tab Bar):**
    - Make icons slightly larger for better prominence and touchability.
    - Add subtle animations (e.g., fade, slight scale) when switching between tabs.
    - Use filled icons for the active tab state, outlined for inactive (or a similar clear distinction).
    - Implement haptic feedback (e.g., `UIImpactFeedbackGenerator`) for tab selection interactions.
  - **Calendar Component (Dashboard 7-Day View - Epic 12, Story 12.6):**
    - Enhance visual appeal (referencing `Centr iOS 26.jpg` and style guide).
    - Add subtle animations when switching between weeks (e.g., smooth scroll, fade-in/out of dates).
    - Implement clear color-coding to show workout days (e.g., a dot of accent color) vs. rest days.
    - Make the current day visually more prominent (e.g., stronger highlight, different background).
- **Acceptance Criteria (ACs):**
  - AC1: Bottom navigation icons are appropriately sized, with active/inactive states clearly distinguished (e.g., filled vs. outlined).
  - AC2: Tab switching includes subtle animations and haptic feedback.
  - AC3: The 7-day dashboard calendar is visually enhanced, with animations for week switching.
  - AC4: Calendar clearly color-codes workout days and makes the current day prominent.

### Story 14.4: Upgraded Streak Tracking & Progress Visualization
- **User Story / Goal:** As a User, I want my streaks and progress to be visualized in a more engaging and motivational way, helping me see my accomplishments clearly.
- **Detailed Requirements:**
  - **Streak Tracking (Dashboard - Epic 11, Story 11.4):**
    - Transform the basic streak text (e.g., "1 Day Streak") into a more engaging visualization.
    - Consider using progress rings or bars to show progress towards next streak milestone (e.g., 7-day, 30-day).
    - Utilize fire/flame iconography more creatively and dynamically.
    - Implement visual "celebrations" or highlights for reaching key streak milestones (e.g., 7-day, 30-day, 100-day).
  - **Progress Visualization (Badges - Epic 8, Story 8.3 & Progress Tab - Epic 4):**
    - Where badges are displayed, consider upgrading static icons to have subtle animations or a more premium feel if they represent significant progress. (Full "animated progress indicators" might be complex for all badges, focus on key ones or a general style uplift).
    - Add completion percentages to relevant goals or stages where applicable (e.g., progress through a method stage if criteria allow percentage calculation).
    - Use micro-animations to show progress changes when new data is logged or a milestone is achieved.
    - On the Progress Tab, consider adding a weekly/monthly progress summary section.
- **Acceptance Criteria (ACs):**
  - AC1: Streak tracking on the Dashboard is visually more engaging (e.g., using rings/bars, improved iconography).
  - AC2: Key streak milestones trigger a visual celebration/acknowledgment.
  - AC3: Badge display is visually enhanced.
  - AC4: Completion percentages are shown for relevant progress items.
  - AC5: Micro-animations provide feedback on progress updates.
  - AC6: A weekly/monthly progress summary component is available on the Progress tab.

### Story 14.5: Improved Workout Information Display & Quick Actions
- **User Story / Goal:** As a User, I want to see clearer information about my next workout and have easier access to common actions like logging a session or starting a recent workout.
- **Detailed Requirements:**
  - **"Next Session" Display (Dashboard - Epic 12, Story 12.1 & Next Session Detail View - Epic 12, Story 12.2):**
    - Make the "Next: [Workout Name]" section more prominent on the Dashboard.
    - In the "Next Session Detail View," add workout preview thumbnails or simple illustrations relevant to the method type.
    - Clearly display estimated duration, difficulty indicators (if this data exists or can be derived for methods), and equipment needed at a glance.
  - **Quick Actions:**
    - Ensure the "Log a Session" button (Dashboard - Epic 11, Story 11.3) is visually prominent and easily accessible.
    - Consider adding a "Quick Actions" section or context menu (e.g., long-press on a workout item) for tasks like:
        - "Start Most Recent Workout" (if applicable).
        - (Future/Advanced): "Skip Today's Workout," "Modify Routine." For this story, focus on "Start Most Recent."
- **Acceptance Criteria (ACs):**
  - AC1: The "Next Session" information on the Dashboard and in the "Next Session Detail View" is more prominent and includes visual cues (thumbnails/illustrations), duration, difficulty (if available), and equipment.
  - AC2: The "Log a Session" button is prominent.
  - AC3: A "Start Most Recent Workout" quick action is implemented and accessible.

### Story 14.6: Modernize Buttons, Controls & Interactive Elements
- **User Story / Goal:** As a User, I want all buttons and interactive controls to have a modern look and feel, providing clear feedback and smooth interactions.
- **Detailed Requirements:**
  - **Buttons & Controls:**
    - Upgrade all button styles (primary, secondary, text) with modern styling: rounded corners, consistent use of gradients (if part of new theme), subtle shadows.
    - Implement loading states within buttons for actions that take time (e.g., a spinner within the button, text changes to "Saving...").
    - Add success animations or feedback (e.g., button briefly changes to a checkmark or success color) upon completion of an action.
    - Implement proper touch feedback for all buttons and controls (e.g., subtle scaling effect, highlight change on press).
    - Ensure button styles are used consistently throughout the app.
  - **Gestures & Interactions:**
    - Ensure swipe gestures for calendar navigation (7-day view) are smooth and intuitive.
    - Implement pull-to-refresh functionality on relevant list views (e.g., session history, methods list if dynamic).
    - Consider long-press menus for quick actions on list items where appropriate (e.g., on a logged session in history).
    - Ensure all scrolling views have smooth scrolling with appropriate momentum.
- **Acceptance Criteria (ACs):**
  - AC1: All button types are updated with modern styling and consistent application.
  - AC2: Buttons show loading states and success animations/feedback.
  - AC3: All interactive elements provide clear touch feedback.
  - AC4: Swipe for calendar navigation, pull-to-refresh, and smooth scrolling are implemented correctly.
  - AC5: Long-press context menus are added for at least one relevant use case.

### Story 14.7: Basic Dashboard Personalization & Smart Recommendation Placeholder
- **User Story / Goal:** As a User, I want some initial ability to personalize my dashboard and see a placeholder for future smart recommendations, hinting at a more tailored experience.
- **Detailed Requirements:**
  - **Dashboard Customization (Initial Step):**
    - Allow users to reorder at least one pair of dashboard sections (e.g., swap "Next Session" with "Streak Tracking") via a simple setting. (Full widget system is out of scope for this initial story but this is a first step).
  - **Smart Recommendations (Placeholder/Simple):**
    - Add a section on the Dashboard titled "Recommended for You" or "Tips for You."
    - For MVP of this enhancement, this section can display:
        - A link to a relevant Educational Resource article.
        - A general motivational tip.
        - (Future logic for weather, optimal times, history-based recommendations will be separate).
- **Acceptance Criteria (ACs):**
  - AC1: Users can reorder at least one pair of pre-defined sections on their dashboard.
  - AC2: A "Recommended for You" or "Tips for You" section is present on the dashboard.
  - AC3: This section displays a simple, non-personalized tip or link to an educational article for this iteration.

### Story 14.8: Initial Goal Setting Integration & Quick Stats Display
- **User Story / Goal:** As a User, I want to be able to set simple fitness goals and see a quick overview of my key stats, making my progress more tangible.
- **Detailed Requirements:**
  - **Goal Setting (Initial Implementation):**
    - If a "My Goals" section exists but is empty, transform it into an initial goal-setting experience.
    - Allow users to set one simple, predefined goal type (e.g., "Log X sessions this week/month" or "Complete Y minutes of training this week/month").
    - Display visual progress tracking (e.g., a progress bar) towards this active goal on the Dashboard or in the "My Goals" section.
    - (Templates and social sharing are out of scope for this initial story).
  - **Quick Stats Dashboard Section:**
    - Add a "Weekly Overview" or "Quick Stats" section to the main Dashboard.
    - Display key metrics such as: Total sessions this week, Total time this week.
    - (Comparative data and upcoming milestones are out of scope for this initial story).
    - Include a placeholder for a daily motivational quote or tip in this section.
- **Acceptance Criteria (ACs):**
  - AC1: Users can set at least one type of simple, predefined fitness goal.
  - AC2: Visual progress towards the active goal is displayed.
  - AC3: A "Quick Stats" section on the Dashboard displays total sessions and time for the current week.
  - AC4: A motivational quote/tip placeholder is present in the Quick Stats section.

### Story 14.9: Implement Enhanced Loading & Empty States
- **User Story / Goal:** As a User, I want the app to feel responsive and informative even when content is loading or sections are empty, by providing clear loading states and encouraging empty states.
- **Detailed Requirements:**
  - **Loading States:**
    - Replace generic loading indicators (or messages like "Next session information unavailable") with proper loading states.
    - Implement skeleton screens for key content areas while data is being fetched (e.g., for method cards on the Methods screen, session list, dashboard sections).
    - Implement graceful error states with clear messages and "Retry" options when data fetching fails.
  - **Empty States:**
    - Design engaging empty states for sections that might not have content yet (e.g., no sessions logged, no badges earned, no goals set).
    - Empty states should include:
        - A relevant illustration or subtle animation.
        - A clear message explaining why the section is empty.
        - A call-to-action (CTA) to guide the user on how to populate it (e.g., "Log your first session!", "Explore Methods to earn badges").
- **Acceptance Criteria (ACs):**
  - AC1: Skeleton screens are implemented for at least 2-3 key list/card views during data loading.
  - AC2: Graceful error states with retry options are implemented for common data fetching scenarios.
  - AC3: Engaging empty states (illustration, message, CTA) are implemented for at least 3 key sections when they have no content.

### Story 14.10: Accessibility & Usability Polish - Touch Targets & Content Clarity
- **User Story / Goal:** As a User, I want all interactive elements to be easy to tap and all information to be clear and understandable, ensuring a frustration-free experience.
- **Detailed Requirements:**
  - **Touch Targets:**
    - Review all interactive elements (buttons, list items, tabs, icons) to ensure they meet Apple's minimum 44x44 point touch target size.
    - Ensure adequate spacing between clickable elements to prevent accidental taps.
    - Confirm clear visual feedback (highlight, scaling) for all interactions.
  - **Content Clarity:**
    - Ensure icons are used consistently and their meaning is clear from context or supplemented by labels.
    - For any potentially unclear terms or complex features, consider adding small info icons with tooltips or brief explanations (on tap/long-press).
    - Review critical information flows to ensure important details are not buried in submenus or hard to find.
- **Acceptance Criteria (ACs):**
  - AC1: A review confirms all key interactive elements meet minimum touch target sizes and have adequate spacing.
  - AC2: Visual feedback for interactions is consistently applied.
  - AC3: Icons are used consistently, and at least one example of a tooltip/explanation for an unclear term/icon is implemented.
  - AC4: A review of information architecture ensures no critical information is unnecessarily buried.

## Change Log

| Date       | Version | Description                                       | Author   |
| :--------- | :------ | :------------------------------------------------ | :------- |
| 2025-05-21 | 0.1     | Initial Draft for Dashboard & Core UX/UI Modernization | 2 - PM   |