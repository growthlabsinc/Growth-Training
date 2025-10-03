# AI Coach Knowledge Base Sources

This document lists all content sources that have been ingested into the Vertex AI Search datastore for the Growth Coach.

## 1. Growth Methods

This section details the Growth Methods extracted from Firestore and ingested into the knowledge base.

| Method ID | Title                       | Stage        | Categories          | Ingestion Date |
|-----------|-----------------------------|--------------|---------------------|----------------|
| GM-001    | Example Method 1            | Beginner     | Technique, Focus    | 2025-05-16     |
| GM-002    | Example Method 2            | Intermediate | Science, Recovery   | 2025-05-16     |
| *... (add more methods as they are ingested)* |                             |              |                     |                |

## 2. Educational Resources

This section details the Educational Resources extracted from Firestore and ingested into the knowledge base.

| Resource ID | Title                                 | Category   | Ingestion Date |
|-------------|---------------------------------------|------------|----------------|
| ER-001      | Understanding Growth Basics           | Basics     | 2025-05-16     |
| ER-002      | The Science Behind Optimal Recovery   | Science    | 2025-05-16     |
| *... (add more resources as they are ingested)* |                                       |            |                |

## Notes:

- **Source of Truth:** The primary source for this content remains Firestore.
- **Extraction Process:** Content is extracted via scripts (see `scripts/vertex-ai-search-ingest.js`).
- **Schema:** Data is transformed to align with the schema defined in `docs/ai-coach-knowledge-base.md`.
- **Updates:** This document should be updated whenever new content is ingested or existing content is refreshed in the Vertex AI Search datastore. 