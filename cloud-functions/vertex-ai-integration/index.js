/**
 * Cloud Function for Vertex AI Search Integration
 * 
 * This function provides a serverless API for interacting with the
 * Vertex AI Search datastore for the Growth app AI Coach knowledge base.
 */

const { DiscoveryEngineServiceClient } = require('@google-cloud/discoveryengine').v1beta;

// Environment variables
const projectId = process.env.GOOGLE_CLOUD_PROJECT;
const location = process.env.VERTEX_AI_SEARCH_LOCATION || 'eu';
const datastoreId = process.env.VERTEX_AI_SEARCH_DATASTORE_ID;

// Initialize the Discovery Engine client
const client = new DiscoveryEngineServiceClient();

/**
 * Validates the required configuration variables
 * @returns {Object|null} - Error object if validation fails, null otherwise
 */
function validateConfig() {
  if (!projectId) {
    return { code: 500, message: 'GOOGLE_CLOUD_PROJECT environment variable is not set' };
  }
  
  if (!datastoreId) {
    return { code: 500, message: 'VERTEX_AI_SEARCH_DATASTORE_ID environment variable is not set' };
  }
  
  return null;
}

/**
 * Performs a search against the Vertex AI Search datastore
 * @param {string} query - Search query
 * @param {number} pageSize - Number of results to return per page
 * @param {string} filter - Optional filter string (e.g., "growthMethods.stage=1")
 * @returns {Object} - Search results or error
 */
async function searchKnowledgeBase(query, pageSize = 5, filter = '') {
  try {
    // Define the serving config
    const servingConfig = client.servingConfigPath(
      projectId,
      location,
      datastoreId,
      'default_config'
    );
    
    // Define the search request
    const request = {
      servingConfig,
      query,
      pageSize,
      filter, // Optional filter
      contentSearchSpec: {
        snippetSpec: {
          returnSnippet: true,
        },
        extractiveContentSpec: {
          maxExtractiveAnswerCount: 1,
          maxExtractiveSegmentCount: 1,
        },
      },
    };
    
    // Execute the search
    const [response] = await client.search(request);
    
    // Format the response to be more API-friendly
    const formattedResults = {
      totalResults: response.totalSize,
      results: response.results.map(result => {
        const { document, snippet } = result;
        const documentData = document.jsonData.growthMethods || document.jsonData.educationalResources;
        const documentType = document.jsonData.growthMethods ? 'growthMethod' : 'educationalResource';
        
        return {
          id: document.id,
          type: documentType,
          data: documentData,
          relevantSnippet: snippet?.snippet || '',
          score: result.score || 0
        };
      })
    };
    
    return {
      code: 200,
      data: formattedResults
    };
  } catch (error) {
    console.error('Error searching knowledge base:', error);
    return {
      code: 500,
      message: `Error searching knowledge base: ${error.message}`
    };
  }
}

/**
 * Main handler for the Cloud Function
 * @param {Object} req - HTTP request object
 * @param {Object} res - HTTP response object
 */
exports.searchVertexAI = async (req, res) => {
  // Set CORS headers for preflight requests
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method === 'OPTIONS') {
    // Send response to OPTIONS requests
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.set('Access-Control-Max-Age', '3600');
    res.status(204).send('');
    return;
  }
  
  // Validate config
  const configError = validateConfig();
  if (configError) {
    res.status(configError.code).json({ error: configError.message });
    return;
  }
  
  // Get parameters from request
  const query = req.query.q || req.body?.query;
  const pageSize = parseInt(req.query.pageSize || req.body?.pageSize || '5', 10);
  const filter = req.query.filter || req.body?.filter || '';
  
  // Validate query
  if (!query) {
    res.status(400).json({ error: 'Missing required parameter: query' });
    return;
  }
  
  try {
    // Perform search
    const result = await searchKnowledgeBase(query, pageSize, filter);
    
    // Send response
    res.status(result.code).json(result.code === 200 ? result.data : { error: result.message });
  } catch (error) {
    console.error('Unexpected error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Alternative handler for the Cloud Function using Callable Functions
 * This can be used for Firebase Cloud Functions Callable API
 */
exports.searchVertexAICallable = async (data, context) => {
  // Validate authentication (optional)
  if (context.auth) {
    // User is authenticated
    console.log(`Request from authenticated user: ${context.auth.uid}`);
  } else {
    // Uncomment to require authentication
    // throw new Error('Unauthenticated request');
  }
  
  // Validate config
  const configError = validateConfig();
  if (configError) {
    throw new Error(configError.message);
  }
  
  // Get parameters from request
  const { query, pageSize = 5, filter = '' } = data;
  
  // Validate query
  if (!query) {
    throw new Error('Missing required parameter: query');
  }
  
  // Perform search
  const result = await searchKnowledgeBase(query, pageSize, filter);
  
  // Return result
  if (result.code === 200) {
    return result.data;
  } else {
    throw new Error(result.message);
  }
}; 