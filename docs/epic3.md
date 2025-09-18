# Epic 3: Guided Growth Method Training System - Content Delivery & UI

**Goal:** Enable authenticated users to access, navigate, and view detailed instructional content (text, visuals) for all Growth Method stages (Beginner to Elite) in a clear, safe, and user-friendly manner. This includes information on required tools and prominent safety notices.

## Story List

### Story 3.1: Methods Overview Screen (Dashboard-Style Cards)
- **User Story / Goal:** As a User, I want to see an overview of all available Growth Method stages on a dedicated screen, so I can easily understand the progression and select a method to learn about.
- **Detailed Requirements:**
  - Design and implement a "Methods" screen that displays Growth Methods grouped by stage (e.g., Beginner, Intermediate, Advanced, Elite).
  - Each method/stage should be represented by a "Method Card" (as per `docs/style-guide.md` and `docs/ui-ux-spec.md`).
  - Method Card should display:
    - Method Name / Stage Name
    - Short Description
    - Placeholder for a visual/icon representing the method/stage.
    - (Future: User's current progress bar for that method/stage - placeholder for now).
  - Fetch method/stage data from Firestore (`growthMethods` collection).
  - Cards should be tappable to navigate to the Method Detail Screen.
  - UI should follow `docs/style-guide.md` and `docs/ui-ux-spec.md`.
- **Acceptance Criteria (ACs):**
  - AC1: Methods Overview screen displays all seeded Growth Methods from Firestore, grouped by stage.
  - AC2: Each method is presented as a tappable card with the specified information (name, short description, visual placeholder).
  - AC3: Tapping a Method Card navigates to the (placeholder initially) Method Detail Screen, passing the selected method's ID.
  - AC4: Screen is scrollable if content exceeds view.
  - AC5: UI adheres to the style guide, including light/dark mode.

### Story 3.2: Method Detail Screen - Structure & Content Display
- **User Story / Goal:** As a User, I want to view detailed information and instructions for a selected Growth Method, so I can understand how to perform it correctly and safely.
- **Detailed Requirements:**
  - Design and implement a "Method Detail" screen.
  - Screen should receive a `methodId` and fetch corresponding data from Firestore.
  - Display:
    - Method Title.
    - Full Description.
    - Detailed step-by-step instructions (text-based for MVP).
    - Information on required tools/equipment for the method.
    - Prominent safety notices and medical disclaimers specific to the method or generally applicable (content to be provided).
    - Placeholder for instructional visuals/animations (e.g., an image view or a note "Visuals coming soon").
  - Clear navigation back to the Methods Overview screen.
  - CTA to access the "In-App Exercise Timer" for this method (functionality in a later Epic).
  - UI should follow `docs/style-guide.md` and `docs/ui-ux-spec.md`, focusing on readability and clarity.
- **Acceptance Criteria (ACs):**
  - AC1: Method Detail screen correctly displays all specified information for a selected method fetched from Firestore.
  - AC2: Instructional text is well-formatted and easy to read.
  - AC3: Safety notices and disclaimers are prominently displayed.
  - AC4: Placeholders for visuals are present.
  - AC5: CTA for the timer is present (though non-functional until timer epic).
  - AC6: User can navigate back to the Methods Overview screen.

### Story 3.3: Basic Content Management for Methods (Seed Data)
- **User Story / Goal:** As a Developer/Admin, I need a way to ensure Growth Method content (instructions, descriptions, safety notes, stages, etc.) is