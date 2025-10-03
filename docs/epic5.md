# Epic 5: Educational Resources Center - Content Delivery

**Goal:** Provide users with easy access to a library of curated educational articles and visuals on topics relevant to Growth Methods, vascular health, safety, and managing expectations, supporting their overall understanding and journey.

## Story List

### Story 5.1: Educational Resources Listing Screen
- **User Story / Goal:** As a User, I want to browse a list or categorized view of available educational articles, so I can easily find and select topics I'm interested in learning more about.
- **Detailed Requirements:**
  - Design and implement an "Educational Resources" or "Learn" screen.
  - Fetch educational article metadata (title, category, short summary, thumbnail placeholder) from the `educationalResources` collection in Firestore.
  - Display articles in a list, potentially filterable or grouped by categories (e.g., "Vascular Health Basics," "Safety & Best Practices," "Understanding Progress").
  - Each item in the list should be tappable to navigate to the Article View Screen.
  - UI should follow `docs/style-guide.md` and `docs/ui-ux-spec.md`.
- **Acceptance Criteria (ACs):**
  - AC1: Educational Resources screen displays a list of available articles fetched from Firestore.
  - AC2: Articles can be presented with titles, summaries, and category tags.
  - AC3: Tapping an article navigates to the Article View screen, passing the selected resource's ID.
  - AC4: If no articles are available (e.g., initially), a user-friendly message is shown.
  - AC5: UI is clean, organized, and adheres to the style guide.

### Story 5.2: Article View Screen
- **User Story / Goal:** As a User, I want to read the full content of a selected educational article, including text and any embedded visuals, so I can gain knowledge on the topic.
- **Detailed Requirements:**
  - Design and implement an "Article View" screen.
  - Screen should receive a `resourceId` and fetch the full article content from Firestore.
  - Display:
    - Article Title.
    - Full article text content (fetched from `educationalResources` collection).
    - Placeholder(s) for any inline images or visuals (actual image URLs would be in Firestore).
  - Ensure content is scrollable and formatted for optimal readability (font sizes, line spacing as per style guide).
  - Clear navigation back to the Educational Resources listing screen.
- **Acceptance Criteria (ACs):**
  - AC1: Article View screen correctly displays the full title and text content for a selected article.
  - AC2: Text is well-formatted, readable, and supports accessibility (e.g., dynamic type).
  - AC3: Placeholders for visuals are correctly positioned if specified in the content data.
  - AC4: User can easily navigate back to the list of articles.

### Story 5.3: Basic Content Management for Educational Resources (Seed Data)
- **User Story / Goal:** As a Developer/Admin, I need a way to ensure educational content is available in Firestore for the app to display.
- **Detailed Requirements:**
  - Finalize the structure for `educationalResources` collection in Firestore (ensure fields for title, category, full_content_text, summary, visual_placeholder_urls, publication_date).
  - Prepare and upload content for at least 3-5 core educational articles into Firestore directly (manual upload or via a script for MVP). Topics should cover:
    - Basic vascular health principles relevant to Growth Methods. 
    - ED myths & risk awareness. 
    - Managing results expectations. 
    - General safety when practicing Growth Methods. 
  - Content should be accurate, clearly written, and aligned with the app's supportive tone.
- **Acceptance Criteria (ACs):**
  - AC1: At least 3-5 educational articles with complete content are present in Firestore.
  - AC2: The data structure in Firestore matches the fields required by the listing and view screens.
  - AC3: Content is well-written and aligns with the app's educational goals.

## Change Log

| Date       | Version | Description     | Author   |
| :--------- | :------ | :-------------- | :------- |
| 2025-05-08 | 0.1     | Initial Draft   | 2 - PM   |