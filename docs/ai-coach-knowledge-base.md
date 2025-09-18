# AI Coach Knowledge Base Documentation

## Overview

The AI Coach in Growth app requires access to structured knowledge about growth methods, educational resources, and best practices. This document explains how we use Vertex AI Search to create and manage the AI Coach's knowledge base.

## Knowledge Base Structure

The knowledge base is built on Google Cloud's Vertex AI Search (formerly Enterprise Search), which provides advanced search and retrieval capabilities including semantic search and context-aware results.

### Data Structure

The knowledge base contains two primary data types:

1. **Growth Methods**
   ```json
   {
     "methodId": "string",        // Unique identifier
     "stage": "integer",          // Difficulty/progression stage
     "title": "string",           // Method title
     "description": "string",     // Brief description
     "instructionsText": "string", // Detailed instructions
     "equipmentNeeded": ["string"], // Required equipment (array)
     "progressionCriteria": "string", // When to advance
     "safetyNotes": "string"      // Safety warnings and considerations
   }
   ```

2. **Educational Resources**
   ```json
   {
     "resourceId": "string",     // Unique identifier
     "title": "string",          // Resource title
     "contentText": "string",    // Main content (can be markdown)
     "category": "string"        // Category (basics, technique, science, etc.)
   }
   ```

## Vertex AI Search Configuration

### Datastore Setup

The knowledge base uses a Vertex AI Search datastore with the following configuration:

- **Location**: EU (for GDPR compliance)
- **Industry Vertical**: GENERIC
- **Solution Type**: SEARCH
- **Content Config**: CONTENT_REQUIRED

### Schema Definition

The schema is defined to support our data models with appropriate field types:

- **STRING**: Basic text fields with exact matching (IDs, titles, categories)
- **INTEGER**: Numeric values (stage numbers)
- **TEXT**: Long-form content with semantic search capabilities (instructions, content)

## Data Ingestion Process

### Initial Setup

The knowledge base is set up using the following scripts:

1. `scripts/vertex-ai-search-setup.js`: Creates and configures the Vertex AI Search datastore
2. `scripts/vertex-ai-search-ingest.js`: Ingests sample data into the datastore
3. `scripts/vertex-ai-search-test.js`: Tests search functionality

### Running the Setup

To create a new knowledge base:

```bash
# Set environment variables
export GOOGLE_CLOUD_PROJECT=your-project-id
export VERTEX_AI_SEARCH_LOCATION=eu

# Run setup script
node scripts/vertex-ai-search-setup.js

# Ingest sample data
node scripts/vertex-ai-search-ingest.js

# Test search functionality
node scripts/vertex-ai-search-test.js
```

### Adding New Content

To add new content to the knowledge base:

1. Add new entries to the sample JSON files (`data/sample-methods.json` or `data/sample-resources.json`)
2. Run the ingestion script: `node scripts/vertex-ai-search-ingest.js`

Future iterations will include an admin interface for content management.

## Searching the Knowledge Base

### Search API

The knowledge base can be queried through a Cloud Function:

- **HTTP Endpoint**: `https://{region}-{project-id}.cloudfunctions.net/searchVertexAI`
- **Method**: GET or POST
- **Parameters**:
  - `q` or `query`: Search query (required)
  - `pageSize`: Number of results (default: 5)
  - `filter`: Optional filter string (e.g., "growthMethods.stage=1")

### Sample Queries

The knowledge base supports various query types:

1. **Method-specific queries**:
   - "beginner techniques for vascular health"
   - "intermediate level exercises"

2. **Topic-based queries**:
   - "safety precautions for circulation exercises"
   - "proper technique execution"

3. **Equipment-based queries**:
   - "exercises without equipment"
   - "methods that require a mat"

## Integration with AI Coach

The AI Coach integrates with the knowledge base through a Cloud Function that:

1. Receives user queries
2. Searches the knowledge base for relevant information
3. Uses retrieved content to inform AI responses, guided by specific prompt templates defined in `docs/ai-coach-prompt-templates.md`.

This approach enables grounding in factual information while maintaining conversational flow and adhering to defined response strategies.

## Testing and Verification

### Manual Testing

You can test the knowledge base using the included test script:

```bash
# Run with sample queries
node scripts/vertex-ai-search-test.js

# Run with a specific query
node scripts/vertex-ai-search-test.js "how to perform beginner exercises"
```

### Integration Testing

The Cloud Function can be tested directly:

```bash
curl -X GET "https://{region}-{project-id}.cloudfunctions.net/searchVertexAI?q=beginner%20techniques"
```

## Future Enhancements

Planned enhancements for the knowledge base:

1. **Automatic Content Updates**: Trigger content updates from Firestore changes
2. **Content Versioning**: Track and manage content versions
3. **User Feedback Integration**: Improve search results based on user interactions
4. **Multi-language Support**: Expand to support multiple languages
5. **Enhanced Media**: Add support for images and video content 