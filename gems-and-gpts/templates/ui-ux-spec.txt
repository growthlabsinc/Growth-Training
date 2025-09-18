# {Project Name} UI/UX Specification

## Introduction

{State the purpose - to define the user experience goals, information architecture, user flows, and visual design specifications for the project's user interface.}

- **Link to Primary Design Files:** {e.g., Figma, Sketch, Adobe XD URL}
- **Link to Deployed Storybook / Design System:** {URL, if applicable}

## Overall UX Goals & Principles

- **Target User Personas:** {Reference personas or briefly describe key user types and their goals.}
- **Usability Goals:** {e.g., Ease of learning, efficiency of use, error prevention.}
- **Design Principles:** {List 3-5 core principles guiding the UI/UX design - e.g., "Clarity over cleverness", "Consistency", "Provide feedback".}

## Information Architecture (IA)

- **Site Map / Screen Inventory:**
  ```mermaid
  graph TD
      A[Homepage] --> B(Dashboard);
      A --> C{Settings};
      B --> D[View Details];
      C --> E[Profile Settings];
      C --> F[Notification Settings];
  ```
  _(Or provide a list of all screens/pages)_
- **Navigation Structure:** {Describe primary navigation (e.g., top bar, sidebar), secondary navigation, breadcrumbs, etc.}

## User Flows

{Detail key user tasks. Use diagrams or descriptions.}

### {User Flow Name, e.g., User Login}

- **Goal:** {What the user wants to achieve.}
- **Steps / Diagram:**
  ```mermaid
  graph TD
      Start --> EnterCredentials[Enter Email/Password];
      EnterCredentials --> ClickLogin[Click Login Button];
      ClickLogin --> CheckAuth{Auth OK?};
      CheckAuth -- Yes --> Dashboard;
      CheckAuth -- No --> ShowError[Show Error Message];
      ShowError --> EnterCredentials;
  ```
  _(Or: Link to specific flow diagram in Figma/Miro)_

### {Another User Flow Name}

{...}

## Wireframes & Mockups

{Reference the main design file link above. Optionally embed key mockups or describe main screen layouts.}

- **Screen / View Name 1:** {Description of layout and key elements. Link to specific Figma frame/page.}
- **Screen / View Name 2:** {...}

## Component Library / Design System Reference

{Link to the primary source (Storybook, Figma Library). If none exists, define key components here.}

### {Component Name, e.g., Primary Button}

- **Appearance:** {Reference mockup or describe styles.}
- **States:** {Default, Hover, Active, Disabled, Loading.}
- **Behavior:** {Interaction details.}

### {Another Component Name}

{...}

## Branding & Style Guide Reference

{Link to the primary source or define key elements here.}

- **Color Palette:** {Primary, Secondary, Accent, Feedback colors (hex codes).}
- **Typography:** {Font families, sizes, weights for headings, body, etc.}
- **Iconography:** {Link to icon set, usage notes.}
- **Spacing & Grid:** {Define margins, padding, grid system rules.}

## Accessibility (AX) Requirements

- **Target Compliance:** {e.g., WCAG 2.1 AA}
- **Specific Requirements:** {Keyboard navigation patterns, ARIA landmarks/attributes for complex components, color contrast minimums.}

## Responsiveness

- **Breakpoints:** {Define pixel values for mobile, tablet, desktop, etc.}
- **Adaptation Strategy:** {Describe how layout and components adapt across breakpoints. Reference designs.}

## Change Log

| Change        | Date       | Version | Description         | Author         |
| ------------- | ---------- | ------- | ------------------- | -------------- |
| Initial draft | YYYY-MM-DD | 0.1     | Initial draft       | {Agent/Person} |
| Added Flow X  | YYYY-MM-DD | 0.2     | Defined user flow X | {Agent/Person} |
| ...           | ...        | ...     | ...                 | ...            |

< style-guide>
# Growth App Style Guide

## Overview
Growth is an AI-powered vascular health trainer that guides users through personalized Angion Method routines and tracks progress using structured data. The app features intelligent insights, adaptive coaching, and progress forecasting through vector embeddings of user activity, training history, and feedback.

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
- **H1:** 32px/36px, Bold, Letter spacing -0.3px
  - Used for screen titles and major headers
- **H2:** 26px/30px, Bold, Letter spacing -0.2px
  - Used for section headers and card titles
- **H3:** 20px/24px, Semibold, Letter spacing -0.1px
  - Used for subsection headers and important text

#### Body Text
- **Body Large:** 17px/24px, Regular, Letter spacing 0px
  - Primary reading text for detailed content
- **Body:** 15px/20px, Regular, Letter spacing 0px
  - Standard text for most UI elements
- **Body Small:** 13px/18px, Regular, Letter spacing 0.1px
  - Secondary information and supporting text

#### Special Text
- **Caption:** 12px/16px, Medium, Letter spacing 0.2px
  - Used for timestamps, metadata, and labels
- **Button Text:** 16px/20px, Medium, Letter spacing 0.1px
  - Used specifically for buttons and interactive elements
- **Metric Value:** 22px/26px, Semibold, Letter spacing 0px
  - Used for displaying progress numbers and key metrics
- **Progress Label:** 14px/18px, Medium, Letter spacing 0px, Core Green
  - Used for labeling progress indicators and achievements

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

#### Workout Card
- Background: White (#FFFFFF)
- Shadow: Y-offset 2dp, Blur 8dp, Opacity 8%
- Corner Radius: 16dp
- Padding: 16dp
- Image Treatment: 50% overlay gradient from Core Green to transparent
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

#### Selection Controls
- Checkbox/Radio Size: 24dp x 24dp
- Toggle Width: 50dp
- Toggle Height: 30dp
- Selected Color: Core Green (#0A5042)
- Unselected Color: Neutral Gray (#9E9E9E)

### Navigation

#### Tab Bar
- Background: White (#FFFFFF) / Dark Surface (#263A36)
- Active Icon: Core Green (#0A5042)
- Inactive Icon: Neutral Gray (#9E9E9E)
- Text: 12px, Medium
- Icon Size: 24dp x 24dp
- Height: 56dp
- Indicator: 2dp line under active tab (Core Green)

#### Top Navigation
- Background: Transparent or White (#FFFFFF)
- Title: H2 style, centered
- Back Button: Icon button with left arrow
- Action Buttons: Icon buttons aligned right
- Height: 56dp

### Icons

- **Primary Icons:** 24dp x 24dp
- **Small Icons:** 20dp x 20dp
- **Navigation Icons:** 28dp x 28dp
- **Primary color for interactive icons:** Core Green (#0A5042)
- **Secondary color for inactive/decorative icons:** Neutral Gray (#9E9E9E)
- **Icon Style:** Outlined with 2dp stroke width, rounded corners

### Progress Indicators

#### Linear Progress
- Height: 8dp
- Corner Radius: 4dp
- Background: Pale Green (#E6F4F0)
- Filled: Core Green (#0A5042)
- Animation: Smooth fill from left to right

#### Circular Progress
- Stroke Width: 4dp
- Background Track: Pale Green (#E6F4F0)
- Progress Track: Core Green (#0A5042)
- Animation: Clockwise fill

#### Activity Rings
- Stroke Width: 6dp
- Multiple Rings: Different metrics in concentric circles
- Colors: Core Green, Mint Green, Bright Teal, Vital Yellow
- Animation: Clockwise fill with subtle bounce at completion

## Spacing System

- **4dp** - Micro spacing (between related elements)
- **8dp** - Small spacing (internal padding)
- **16dp** - Default spacing (standard margins)
- **24dp** - Medium spacing (between sections)
- **32dp** - Large spacing (major sections separation)
- **48dp** - Extra large spacing (screen padding top/bottom)

## Motion & Animation

- **Standard Transition:** 250ms, Ease-out curve
- **Emphasis Transition:** 300ms, Spring curve (tension: 300, friction: 35)
- **Microinteractions:** 150ms, Ease-in-out
- **Page Transitions:** 350ms, Custom cubic-bezier(0.2, 0.8, 0.2, 1)
- **Progress Animations:** 600ms, Ease-out with slight overshoot
- **Breathing Animation:** For meditation features - 4s inhale, 4s exhale, subtle scaling

## Dark Mode Variants

- **Dark Background:** #1A2A27 (primary dark background)
- **Dark Surface:** #263A36 (card backgrounds)
- **Dark Primary:** #26A69A (adjusted for contrast)
- **Dark Text Primary:** #F5F5F5
- **Dark Text Secondary:** #B0BEC5
- **Dark Inputs:** #324A46 background with #26A69A borders

## Accessibility Guidelines

- Minimum touch target size: 44dp x 44dp
- Color contrast ratios: 4.5:1 for normal text, 3:1 for large text and UI components
- Text scalability: All text elements should support dynamic type
- VoiceOver/TalkBack support: All interactive elements labeled appropriately
- Haptic feedback: Subtle feedback for important interactions
- Focus states: Clear visual indication of focused elements

## Layout Principles

- **Content-First:** Prioritize user data and exercise visuals
- **Progressive Disclosure:** Show most important information first, reveal details on demand
- **Visual Hierarchy:** Use size, color, and spacing to establish clear information hierarchy
- **Breathing Space:** Ample whitespace around content blocks for visual clarity
- **Consistency:** Maintain consistent spacing, alignment, and component usage

## App-Specific Components

### Exercise Display
- Video Background: Full-width with play controls
- Exercise Name: H3 style, bold
- Stats Display: Large, clear metrics with icons
- Rep Counter: Extra large (40px), bold, centered during active exercise
- Form Feedback: Highlighted visualization of correct form

### Progress Tracking
- Graph Style: Smooth curved lines with gradient fill below
- Data Points: Small circular indicators on important points
- Time Range Selector: Segmented control for day/week/month/year views
- Current vs. Goal Visualization: Split progress bars showing relative progress

### AI Coaching Elements
- Coach Messages: Card with avatar, slightly rounded corners
- Personalized Tips: Icon + short text in highlight cards
- Feedback Collection: Simple thumbs up/down with optional text input
- Adaptive Suggestions: Contextual cards that appear based on progress

## Image Treatment
- Exercise Thumbnails: 16:9 ratio with subtle Core Green overlay
- Profile Photos: Circular with white border
- Achievement Badges: Flat design with Core Green to Bright Teal gradient
- Background Elements: Low opacity patterns derived from circular vascular imagery

## Special Features

### Vascular Health Visualizer
- Abstract representation of vascular system
- Color-coded for health status (Core Green to Bright Teal gradient)
- Subtle animation for blood flow simulation
- Progress indicators integrated into visualization

### AI Progress Forecast
- Forecast Line: Dotted line extending from current progress
- Confidence Interval: Light fill showing range of potential outcomes
- Milestone Markers: Small flags indicating upcoming achievements
- Comparison View: Ghost lines showing previous periods
</style-guide> 
</context>