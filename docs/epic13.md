# Epic 13: Core Method Content Overhaul & Recommended Routines

**Goal:** Update and restructure all Growth Methods in the app based on the provided official documentation, implement a new classification system (Beginner, Foundation, Intermediate, Expert, Master), introduce recommended routines, and prepare supplementary user experience data for the AI Coach's knowledge base.

## Story List

### Story 13.1: Re-Define and Re-Classify Core Growth Methods
- **User Story / Goal:** As a Content Admin/PM, I need to update the `growth_methods` collection in Firestore to reflect the definitive list of methods from the provided documents (`docs/Untitled 5.txt`), using the new classification: Beginner, Foundation, Intermediate, Expert, Master.
- **Detailed Requirements:**
  - Analyze `docs/Untitled 5.txt` ("Angion Methods COMPLETE LIST") to identify the definitive methods and their details.
  - Map these methods to the new classification:
    - **Beginner:** ANGION METHOD 1.0 [cite: 216]
    - **Foundation:** ANGION METHOD 2.0  [cite: 234]
    - **Intermediate:** ANGION METHOD 2.5  (B CLASS from doc) [cite: 250]
    - **Expert:** VASCION  [cite: 267]
    - **Master:** ANGIO-WHEEL  [cite: 280] (Note: LMC MkII can be mentioned as an advanced variant if appropriate under Angio-Wheel content).
  - For each method, update/create entries in the `growth_methods` Firestore collection with:
    - New classification (Beginner, Foundation, etc.).
    - Accurate title.
    - Detailed description and technique based *only* on `docs/Untitled 5.txt` and `docs/Untitled 6.txt`.
    - Specific progression/graduation criteria as outlined in `docs/Untitled 5.txt` (e.g., for AM 1.0: "maintain an erection for the full duration of a 30 minute... session and are able to easily palpate a pulse in your dorsal arteries" [cite: 233]).
    - Important safety notes and operational constraints (e.g., "DO NOT PERFORM... WHILE IN A SEATED POSITION" [cite: 189]).
    - Information on required tools (e.g., lubricant for AM 1.0[cite: 218], pump and ACE bandage for Angio Pumping[cite: 199, 200], Angio-Wheel device for Master level [cite: 285]).
  - Remove any methods from Firestore that are not in this definitive list.
- **Acceptance Criteria (ACs):**
  - AC1: The `growth_methods` collection in Firestore accurately reflects the methods from `docs/Untitled 5.txt`, reclassified as Beginner, Foundation, Intermediate, Expert, Master.
  - AC2: All method descriptions, techniques, progression criteria, and safety notes are updated based *only* on the provided `docs/Untitled 5.txt` and `docs/Untitled 6.txt` documents.
  - AC3: Information on required tools for each method is clearly documented.
  - AC4: Outdated or non-definitive methods are removed from the database.

### Story 13.2: Implement "Angio Pumping" Conditional Pre-Stage
- **User Story / Goal:** As a User who is unable to achieve an erection on my own, I want the app to guide me to "Angio Pumping" as my starting point before proceeding to the standard Beginner method.
- **Detailed Requirements:**
  - Based on `docs/Untitled 5.txt`, "ANGIO PUMPING (E CLASS)" is for users with "non-compliant Erectile Dysfunction" who cannot achieve an erection unassisted. [cite: 189, 190]
  - During user onboarding (after initial profile setup - Epic 2), or via a self-assessment quiz, ask the user if they can achieve an erection suitable for Angion Method 1.0 without aids.
  - If the user indicates they cannot, their "Current Focused Stage" should be set to "Angio Pumping."
  - Create a dedicated method entry in `growth_methods` for "Angio Pumping" including its specific technique (fluctuating pressure, ACE bandage, quick release pump [cite: 193, 196, 199, 200]), session times (initially short, up to 10 mins, aim for 30 mins [cite: 211, 212, 213]), and graduation criteria ("able to maintain an erection for at least 15 minutes without the use of devices or vaso-active substances" [cite: 215]).
  - Users graduating from Angio Pumping should then be guided to ANGION METHOD 1.0 (Beginner).
- **Acceptance Criteria (ACs):**
  - AC1: Users who self-identify as unable to achieve unassisted erections are directed to Angio Pumping as their starting method.
  - AC2: Angio Pumping is detailed as a method in Firestore with its specific technique, session times, and graduation criteria from `docs/Untitled 5.txt`.
  - AC3: Upon meeting Angio Pumping graduation criteria, the user is guided to start Angion Method 1.0.
  - AC4: Users who can achieve unassisted erections bypass Angio Pumping and start with Angion Method 1.0 (Beginner) or as per their selection.

### Story 13.3: Update Method Overview & Detail UI for New Content
- **User Story / Goal:** As a User, I want the "Methods" overview and detail screens to clearly display the updated and reclassified Growth Methods, including their new descriptions, techniques, and progression criteria.
- **Detailed Requirements:**
  - Modify the "Methods Overview Screen" (Epic 3, Story 3.1) to display methods under the new classification headers (Beginner, Foundation, Intermediate, Expert, Master).
  - Ensure the "Method Detail Screen" (Epic 3, Story 3.2) correctly fetches and displays all updated content for each reclassified method from Firestore, including:
    - Detailed technique steps.
    - Progression criteria.
    - Required tools.
    - Specific safety warnings from `docs/Untitled 5.txt` (e.g., AM 2.0: "AVOID ABUSING YOUR PELVIC FLOOR MUSCLES"[cite: 249]; Vascion: "common for your Corpora Spongiosum to go flat" [cite: 277]).
  - The UI must clearly present this potentially complex information in an easy-to-digest format.
- **Acceptance Criteria (ACs):**
  - AC1: Methods Overview screen correctly lists methods under the new classifications.
  - AC2: Method Detail screens display all updated content (description, technique, progression, tools, safety notes) accurately from Firestore for each method.
  - AC3: The UI effectively presents the detailed information from `docs/Untitled 5.txt` and `docs/Untitled 6.txt`.

### Story 13.4: Design and Develop "Recommended Routine(s)" Feature
- **User Story / Goal:** As a User, I want to be able to view and potentially follow a recommended training routine, so I have guidance on how to structure my practice throughout the week.
- **Detailed Requirements:**
  - Analyze the routine described in `docs/Untitled 7.txt` ("Typical Week": HEAVY Day, Full Rest Day, Standard Day, SABER Day, S2S/Light Day [cite: 117]) and the "1on1off schedule" mentioned in `docs/Untitled 5.txt`[cite: 294].
  - Define 1-2 "Recommended Routines" for the app (e.g., "Standard Growth Routine," "Advanced Vascularity Routine").
    - The "Standard Growth Routine" could be based on the 1on1off principle for the core Angion Methods.
    - **Note:** SABER and S2S are mentioned in `docs/Untitled 7.txt` [cite: 72, 97] but not in the Angion Method "COMPLETE LIST" (`docs/Untitled 5.txt`). For the purpose of *this app's defined Growth Methods*, routines should primarily focus on the Angion Methods from `docs/Untitled 5.txt`. SABER/S2S could be "Optional Additions" or part of educational content on complementary practices, rather than core scheduled methods *within the app's Angion Method progression flow*, unless clarified to include them as primary methods. For now, the routine will focus on the app's core methods.
  - Design a new section in the app (e.g., "Routines" tab, or a subsection under "Resources" or "Dashboard") where users can view these recommended routines.
  - For each routine, display:
    - Name of the routine.
    - Overall goal/description.
    - A weekly schedule template (e.g., Day 1: AM X, Day 2: Rest, Day 3: AM Y).
  - Allow users to "select" a routine they wish to follow (this selection can be stored in their user profile).
- **Acceptance Criteria (ACs):**
  - AC1: At least one "Recommended Routine" focusing on Angion Methods from `docs/Untitled 5.txt` is defined and available in the app.
  - AC2: Users can view the details of recommended routines, including a weekly schedule template.
  - AC3: Users can select a routine to follow, and this preference is saved.
  - AC4: The design for presenting routines is clear and easy to understand.

### Story 13.5: Integrate Selected Routine with "Next Session" Logic
- **User Story / Goal:** As a User following a selected routine, I want the "Next Session" suggestion (from Epic 12) to align with my chosen routine's schedule.
- **Detailed Requirements:**
  - Modify the "Next Session" suggestion logic (Epic 12, Story 12.1 & 12.2) to consider the user's selected routine (if any, from Story 13.4).
  - If a routine is active, the "Next Session" should primarily suggest the method scheduled for the current/next training day in that routine.
  - The system should still consider the user's current method mastery/progression criteria. If a user is not yet ready for the routine's scheduled next method, the app should indicate this (e.g., "Routine suggests AM X, but ensure you've met criteria for your current stage first").
- **Acceptance Criteria (ACs):**
  - AC1: If a user has selected a routine, the "Next Session" suggestion aligns with the routine's schedule for the appropriate day.
  - AC2: The "Next Session" suggestion still respects the user's current progression status and readiness for a given method.
  - AC3: Clear guidance is provided if the routine's next step conflicts with current progression readiness.

### Story 13.6: Prepare User Journey/Subreddit Data for AI Knowledge Base
- **User Story / Goal:** As an AI Content Manager, I need to process and structure anonymized user journey information (like `docs/Untitled 7.txt`) and other relevant, vetted subreddit data for ingestion into the AI Coach's knowledge base, so the AI can provide more empathetic and context-aware support.
- **Detailed Requirements:**
  - Review `docs/Untitled 7.txt` ("My personal PE journey...") for key themes, experiences, challenges, and motivational aspects that would be valuable for the AI Coach to understand.
  - If other similar (anonymized, vetted) data from the subreddit is provided by the Product Owner, include it in this processing.
  - Structure this information into a Q&A format, or topical summaries that can be easily indexed and retrieved by Vertex AI Search.
    - Example topics: "User experiences starting AM1", "Managing sensitivity with AM2/Vascion", "Importance of patience and research", "Combining Angion Methods with other PE (user perspectives)".
  - Ensure all content is strictly aligned with the app's safety guidelines and "Growth Method" terminology; adapt and vet any community content carefully. 
  - This data is supplementary to the core method instructions already in the AI KB and should not contradict official method guidance.
  - Add these new structured documents to the Vertex AI Search datastore (Epic 6, Story 1.3 & 6.5).
  - Update `docs/ai-knowledge-base-sources.md` to include these new supplementary sources.
- **Acceptance Criteria (ACs):**
  - AC1: Key insights from `docs/Untitled 7.txt` (and any other provided/vetted subreddit data) are extracted, anonymized, and structured for AI knowledge base ingestion.
  - AC2: The structured data is ingested into the Vertex AI Search datastore.
  - AC3: `docs/ai-knowledge-base-sources.md` is updated.
  - AC4: The AI Coach can (in testing) retrieve and use this supplementary information appropriately to provide more nuanced, experience-based answers (without giving medical advice).

## Change Log

| Date       | Version | Description                                     | Author   |
| :--------- | :------ | :---------------------------------------------- | :------- |
| 2025-05-19 | 0.1     | Initial Draft for Core Method Content Overhaul | 2 - PM   |