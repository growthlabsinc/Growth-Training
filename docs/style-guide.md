# Growth App Style Guide

## Overview
Growth is an AI-powered vascular health trainer that guides users through personalized Angion Method routines and tracks progress using structured data. The app features intelligent insights, adaptive coaching, and progress forecasting through vector embeddings of user activity, training history, and feedback. The UI/UX should be calm, professional, supportive, discreet, and icon-forward.

## Color Palette

### Primary Colors
- **Pure White** - #FFFFFF (Clean surfaces, cards, and content areas) 
- **Core Green** - #0A5042 (Primary brand color for key elements and emphasis) 

### Secondary Colors
- **Mint Green** - #4CAF92 (Secondary elements, active states) 
- **Pale Green** - #E6F4F0 (Subtle backgrounds, selected states) 

### Accent Colors
- **Bright Teal** - #00BFA5 (Important actions, focus points, and progress indicators) 
- **Vital Yellow** - #FFD54F (Highlights, notifications, and alerts) 

### Functional Colors
- **Success Green** - #43A047 (Completion states and positive feedback) 
- **Warning Amber** - #FFB300 (Caution states and intermediary alerts) 
- **Error Red** - #E53935 (Errors and critical notifications) 
- **Neutral Gray** - #9E9E9E (Secondary text and disabled states) 
- **Dark Text** - #212121 (Primary text) 

### Background Colors
- **Surface White** - #FFFFFF (Cards and foreground elements) 
- **Background Light** - #F8FAFA (App background, light mode) 
- **Background Dark** - #1A2A27 (Dark mode primary background) 
- **Surface Dark** - #263A36 (Dark mode card backgrounds) 

## Typography

### Font Family
- **Primary Font:** SF Pro Display (iOS) / Roboto (Android) 
- **Alternative Font:** Inter (Web fallback) 

### Font Weights
- Light: 300 (Used sparingly for large display text) 
- Regular: 400 (Body text and general content) 
- Medium: 500 (Emphasis and interactive elements) 
- Semibold: 600 (Section headers and important content) 
- Bold: 700 (Main headers and critical information) 

### Text Styles

#### Headings
- **H1:** 32px/36px, Bold, Letter spacing -0.3px (Used for screen titles and major headers) 
- **H2:** 26px/30px, Bold, Letter spacing -0.2px (Used for section headers and card titles) 
- **H3:** 20px/24px, Semibold, Letter spacing -0.1px (Used for subsection headers and important text) 

#### Body Text
- **Body Large:** 17px/24px, Regular, Letter spacing 0px (Primary reading text for detailed content) 
- **Body:** 15px/20px, Regular, Letter spacing 0px (Standard text for most UI elements) 
- **Body Small:** 13px/18px, Regular, Letter spacing 0.1px (Secondary information and supporting text) 

#### Special Text
- **Caption:** 12px/16px, Medium, Letter spacing 0.2px (Used for timestamps, metadata, and labels) 
- **Button Text:** 16px/20px, Medium, Letter spacing 0.1px (Used specifically for buttons and interactive elements) 
- **Metric Value:** 22px/26px, Semibold, Letter spacing 0px (Used for displaying progress numbers and key metrics) 
- **Progress Label:** 14px/18px, Medium, Letter spacing 0px, Core Green (Used for labeling progress indicators and achievements) 

## Component Styling

### Buttons

#### Primary Button
- Background: Core Green (#0A5042) 
- Text: White (#FFFFFF) 
- Height: 52dp 
- Corner Radius: 8dp 
- Padding: 16dp horizontal 
- State Changes:
  - Pressed: 15% darker overlay 
  - Disabled: 40% opacity 

#### Secondary Button
- Border: 1.5dp Core Green (#0A5042) 
- Text: Core Green (#0A5042) 
- Background: Transparent 
- Height: 52dp 
- Corner Radius: 8dp 
- State Changes:
  - Pressed: 10% Core Green background 
  - Disabled: 40% opacity 

#### Text Button
- Text: Core Green (#0A5042) 
- No background or border 
- Height: 44dp 
- State Changes:
  - Pressed: 10% Core Green background 
  - Disabled: 40% opacity 

#### Icon Button
- Size: 44dp x 44dp 
- Icon Size: 24dp x 24dp 
- Touch Target: Minimum 44dp x 44dp 
- State Changes:
  - Pressed: 10% overlay 
  - Disabled: 40% opacity 

### Cards

#### Standard Card
- Background: White (#FFFFFF) 
- Shadow: Y-offset 2dp, Blur 8dp, Opacity 8% 
- Corner Radius: 12dp 
- Padding: 16dp 
- Border: None (Light mode) / 1dp #384A46 (Dark mode) 

#### Workout Card (Method Card)
- Background: White (#FFFFFF) 
- Shadow: Y-offset 2dp, Blur 8dp, Opacity 8% 
- Corner Radius: 16dp 
- Padding: 16dp 
- Image Treatment: 50% overlay gradient from Core Green to transparent (if images used) 
- Text: White over image areas, Dark Text elsewhere 

#### Progress Card
- Background: Pale Green (#E6F4F0) 
- Corner Radius: 12dp 
- Padding: 16dp 
- Progress Bar: 8dp height, Core Green filled, White background 

### Input Fields

#### Text Input
- Height: 56dp 
- Corner Radius: 8dp 
- Border: 1dp Neutral Gray (#9E9E9E) 
- Active Border: 2dp Core Green (#0A5042) 
- Background: White (#FFFFFF) 
- Text: Dark Text (#212121) 
- Placeholder Text: Neutral Gray (#9E9E9E) 
- Padding: 16dp horizontal, 0dp vertical 

#### Selection Controls (for Mood Check-ins, Settings)
- Checkbox/Radio Size: 24dp x 24dp 
- Toggle Width: 50dp 
- Toggle Height: 30dp 
- Selected Color: Core Green (#0A5042) 
- Unselected Color: Neutral Gray (#9E9E9E) 

### Navigation

#### Tab Bar (Bottom)
- Background: White (#FFFFFF) / Dark Surface (#263A36) 
- Active Icon: Core Green (#0A5042) 
- Inactive Icon: Neutral Gray (#9E9E9E) 
- Text: 12px, Medium 
- Icon Size: 24dp x 24dp (Ensure these are icon-forward and clear) 
- Height: Standard iOS Tab Bar Height (approx 49-56dp, depending on device/safe areas) 
- Indicator: Subtle visual cue for active tab (e.g., icon color change, text boldness, no line needed if icons are clear).

#### Top Navigation (Navigation Bar)
- Background: Transparent or White (#FFFFFF) / Dark Surface (#263A36) 
- Title: H2 style, centered or leading based on context. 
- Back Button: Standard iOS back chevron with "Back" or screen title. Core Green. 
- Action Buttons: Icon buttons aligned right (e.g., Settings gear). Core Green. 
- Height: Standard iOS Navigation Bar Height. 

### Icons
- **Primary Icons:** 24dp x 24dp (for content areas, list items) 
- **Small Icons:** 20dp x 20dp (for inline text, secondary info) 
- **Navigation Icons (Tab Bar):** 28dp x 28dp (or as appropriate for clarity and touch target) 
- **Primary color for interactive icons:** Core Green (#0A5042) 
- **Secondary color for inactive/decorative icons:** Neutral Gray (#9E9E9E) 
- **Icon Style:** Outlined with 2dp stroke width, rounded corners, chosen for clarity and professional feel. (A consistent icon set should be selected/designed).

### Progress Indicators

#### Linear Progress (e.g., for stage progression on method cards)
- Height: 8dp 
- Corner Radius: 4dp 
- Background: Pale Green (#E6F4F0) 
- Filled: Core Green (#0A5042) 
- Animation: Smooth fill from left to right 

#### Circular Progress (e.g., for timer, daily goal)
- Stroke Width: 4dp-6dp (adjust for visual balance) 
- Background Track: Pale Green (#E6F4F0) 
- Progress Track: Core Green (#0A5042) or Bright Teal (#00BFA5) for emphasis 
- Animation: Clockwise fill 

#### Activity Rings (for dashboard summaries, if adopted)
- Stroke Width: 6dp 
- Multiple Rings: Different metrics in concentric circles 
- Colors: Core Green, Mint Green, Bright Teal, Vital Yellow 
- Animation: Clockwise fill with subtle bounce at completion 

## Spacing System (iOS points, treat dp as pt for iOS)

- **4pt** - Micro spacing (between related elements, e.g., icon and text label) 
- **8pt** - Small spacing (internal padding for small components) 
- **16pt** - Default spacing (standard margins, padding within cards, between list items) 
- **24pt** - Medium spacing (between distinct sections or larger cards) 
- **32pt** - Large spacing (major screen sections separation) 
- **48pt** - Extra large spacing (screen padding top/bottom, less common, use safe areas) 

## Motion & Animation

- **Standard Transition (Navigation):** Use default iOS transitions (push, modal). Duration ~250-300ms. 
- **Emphasis Transition:** 300ms, Spring curve (tension: 300, friction: 35) - for rewarding actions. 
- **Microinteractions:** 150ms, Ease-in-out (e.g., button press, toggle switch). 
- **Progress Animations:** 600ms, Ease-out (for progress bars/rings). 
- **Subtlety is Key:** Animations should enhance UX, not distract. Focus on smooth, professional transitions.

## Dark Mode Variants

- **Dark Background:** #1A2A27 (primary dark background) 
- **Dark Surface:** #263A36 (card backgrounds) 
- **Dark Primary (Interactive):** #26A69A (adjusted Core Green for contrast) 
- **Dark Text Primary:** #F5F5F5 
- **Dark Text Secondary:** #B0BEC5 
- **Dark Inputs:** #324A46 background with #26A69A borders 
- Ensure all color combinations in dark mode meet WCAG AA contrast ratios.

## Accessibility Guidelines (Recap from UI/UX Spec)

- Minimum touch target size: 44pt x 44pt (standard for iOS). 
- Color contrast ratios: 4.5:1 for normal text, 3:1 for large text and UI components against background. Verify with tools. 
- Text scalability: Support Dynamic Type. All text elements should scale appropriately. 
- VoiceOver/TalkBack support: All interactive elements labeled appropriately. Decorative images hidden. 
- Haptic feedback: Subtle feedback for important interactions (e.g., timer completion, log saving), user-configurable. 
- Focus states: Clear visual indication of focused elements for keyboard/switch control users (though less common for primary interaction on iOS). 

## Layout Principles

- **Content-First:** Prioritize instructional content, user data, and exercise visuals. Maintain a clean, uncluttered interface. 
- **Progressive Disclosure:** Show essential information. Allow users to drill down for details (e.g., full session notes, detailed method history). 
- **Visual Hierarchy:** Use size, color, weight, and spacing to establish clear importance of elements on screen. Guide the user's eye. 
- **Breathing Space:** Ample whitespace around content blocks for visual clarity and a calm feel. 
- **Consistency:** Maintain consistent use of spacing, alignment, typography, color, and component behavior throughout the app. Follow Apple Human Interface Guidelines. 

## App-Specific Components (Design Considerations)

### Exercise Display (Method Detail Screen)
- Clear title for the Method and Stage.
- Structured instructional text, possibly with iconography for key actions or warnings.
- Placeholder for images/animations if added later.
- Prominent "Start Timer" CTA.
- Easy access to safety notes/disclaimers relevant to that method.

### Progress Tracking (Dashboard & Charts)
- Graphs: Smooth curved lines with gradient fill below (as per original style guide, if feasible for native charts). Bar charts for consistency. 
- Data Points: Clear markers on graphs.
- Time Range Selector: Segmented control for Day/Week/Month views. 
- Current vs. Goal Visualization: Simple progress bars or textual representation. 

### AI Coaching Elements (Chat Interface)
- Coach Messages: Distinct visual style for AI messages (e.g., different background color, avatar). Card-like with rounded corners. 
- User Messages: Standard chat bubble style.
- Input field clear and accessible.
- Prominent disclaimer about AI capabilities.
- Personalized Tips (if AI suggests them): Icon + short text in highlight cards or distinct message style. 
- Feedback Collection (Thumbs up/down on AI responses): Simple, unobtrusive icons. 

## Image Treatment (If used for methods/education)
- Exercise Thumbnails (for method cards, if used): 16:9 or similar aspect ratio with subtle Core Green overlay or branding. 
- Educational Content Images: Clear, professional, and directly relevant to the text.
- Profile Photos (if implemented): Circular with a simple border. 
- Achievement Badges: Flat design with Core Green to Bright Teal gradient, clear iconography representing the achievement.