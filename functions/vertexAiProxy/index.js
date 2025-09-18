const { HttpsError } = require('firebase-functions/v2/https');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const { VertexAI } = require('@google-cloud/vertexai');
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Configuration and environment variables
const config = {
  // Region where Vertex AI is deployed
  vertexAiRegion: process.env.VERTEX_AI_REGION || 'us-central1',
  // Project ID to use for Vertex AI
  vertexAiProjectId: process.env.VERTEX_AI_PROJECT_ID || process.env.GCLOUD_PROJECT || 'growth-70a85',
  // Vertex AI Search datastore details
  vertexAiSearchDatastore: process.env.VERTEX_AI_SEARCH_DATASTORE || 'growth-methods-datastore',
  // Gemini model to use
  geminiModel: process.env.GEMINI_MODEL || 'gemini-2.0-flash-lite-001',
  // Maximum tokens for the response
  maxOutputTokens: parseInt(process.env.MAX_OUTPUT_TOKENS || '4096', 10),
  // API key secret name (for SECRET_MANAGER option)
  apiKeySecretName: process.env.API_KEY_SECRET_NAME || 'vertex-ai-api-key',
  // Authentication method (API_KEY, SECRET_MANAGER, SERVICE_ACCOUNT)
  authMethod: process.env.AUTH_METHOD || 'SERVICE_ACCOUNT',
  // Direct API key (not recommended for production)
  apiKey: process.env.VERTEX_AI_API_KEY,
  // Log level
  logLevel: process.env.LOG_LEVEL || 'info',
};

// Secret Manager client for retrieving API keys
let secretManagerClient = null;

/**
 * Get API key from Secret Manager
 * @returns {Promise<string>} The API key
 */
const getApiKeyFromSecretManager = async () => {
  if (config.authMethod !== 'SECRET_MANAGER') {
    return null;
  }
  
  try {
    // Initialize client lazily
    if (!secretManagerClient) {
      secretManagerClient = new SecretManagerServiceClient();
    }
    const secretName = `projects/${config.vertexAiProjectId}/secrets/${config.apiKeySecretName}/versions/latest`;
    const [version] = await secretManagerClient.accessSecretVersion({ name: secretName });
    return version.payload.data.toString();
  } catch (error) {
    console.error(`Error retrieving API key from Secret Manager: ${error}`);
    throw new Error('Failed to retrieve API key');
  }
};

/**
 * Initialize Vertex AI client
 * @param {string} apiKey Optional API key for authentication
 * @returns {Object} Vertex AI client
 */
const initializeVertexAI = (apiKey = null) => {
  try {
    const vertex = new VertexAI({
      project: config.vertexAiProjectId,
      location: config.vertexAiRegion,
      apiKey: apiKey,
    });
    
    return vertex.getGenerativeModel({ model: config.geminiModel });
  } catch (error) {
    console.error(`Error initializing Vertex AI: ${error}`);
    throw new Error('Failed to initialize AI services');
  }
};

// Import the enhanced search function
const { searchKnowledgeBase: enhancedSearch } = require('./knowledgeBaseSearch');

/**
 * Search the knowledge base for relevant content
 * @param {string} query User query
 * @returns {Promise<Array>} Knowledge sources
 */
const searchKnowledgeBase = async (query) => {
  try {
    // Import Firestore
    const { getFirestore } = require('firebase-admin/firestore');
    const db = getFirestore();
    
    // Use the enhanced search function
    return await enhancedSearch(query, db);
    
  } catch (error) {
    console.error('Error searching knowledge base:', error);
    // Return empty array if search fails
    return [];
  }
};

/**
 * Generate system prompt for the AI model
 * @param {Array} knowledgeSources Knowledge sources from search
 * @returns {string} System prompt
 */
const generateSystemPrompt = (knowledgeSources) => {
  const basePrompt = `You are the Growth Coach, an AI assistant for the Growth mobile app specializing in vascular training techniques and the Angion Methods.

CORE PRINCIPLE: You provide educational guidance about vascular training exercises and techniques based on the knowledge base content.

RESPONSE APPROACH:
- Answer questions directly and helpfully based on the available knowledge
- When users ask about routines, progressions, or techniques, provide specific guidance from the knowledge base
- Focus on being helpful and educational rather than deflecting questions
- These are vascular training exercises for improving blood flow, not medical treatments

KEY GUIDELINES:
1. Use the knowledge base content to formulate natural, helpful responses
2. For questions about pelvic floor tension, reference the documented guidance about relaxation and avoiding overuse
3. Provide practical advice about progression, duration, and technique based on the Angion Method documentation
4. Be conversational and supportive while sharing the educational content
5. If specific information isn't in the knowledge base, acknowledge this honestly
`;

  // If we have relevant knowledge, include it in the prompt
  if (knowledgeSources && knowledgeSources.length > 0) {
    // Use full content when available for better context
    const contextSection = knowledgeSources.map(source => {
      const content = source.fullContent || source.snippet;
      return `SOURCE: "${source.title}"\nTYPE: ${source.type || 'unknown'}\nCONTENT: ${content}\n`;
    }).join('\n---\n');
    
    return `${basePrompt}

RELEVANT KNOWLEDGE FROM THE APP'S DATABASE:
${contextSection}

INSTRUCTIONS FOR USING THE KNOWLEDGE BASE:
- Analyze the user's question and the provided knowledge base content
- Formulate a direct, helpful response using the information available
- If the knowledge mentions pelvic floor considerations (like in AM2 documentation), incorporate that naturally
- Provide specific guidance about progression and technique when asked
- Never say "I cannot provide specific exercise plans" - instead, share the educational content from the knowledge base
- Be conversational and natural in your response while accurately conveying the knowledge base information
- If the user asks about something not covered in the available knowledge, be honest about what information you have`;
  }

  return basePrompt;
};

/**
 * Format the conversation history for the AI model
 * @param {Array} conversationHistory Previous messages
 * @param {string} userQuery Current user query
 * @param {string} systemPrompt System prompt to prepend to the first user message
 * @returns {Array} Formatted conversation
 */
const formatConversation = (conversationHistory, userQuery, systemPrompt) => {
  // Map existing conversation history
  const formattedHistory = conversationHistory?.map(msg => ({
    role: msg.sender === 'user' ? 'user' : 'model',
    parts: [{ text: msg.text }],
  })) || [];
  
  // Create the new message
  const newUserMessage = {
    role: 'user',
    parts: [{ text: userQuery }]
  };
  
  // Build the final conversation array
  const conversation = [...formattedHistory, newUserMessage];
  
  // If we have a system prompt and there's at least one user message,
  // prepend it to the first user message we can find
  if (systemPrompt && systemPrompt.length > 0) {
    const firstUserMsgIndex = conversation.findIndex(msg => msg.role === 'user');
    if (firstUserMsgIndex >= 0) {
      // Clone the array to avoid modifying the original
      const result = [...conversation];
      const originalMsg = result[firstUserMsgIndex].parts[0].text;
      result[firstUserMsgIndex] = {
        role: 'user',
        parts: [{ text: `${systemPrompt}\n\nUser Query: ${originalMsg}` }]
      };
      return result;
    }
  }
  
  return conversation;
};

/**
 * Handle incoming request and generate AI response
 * @param {Object} data Request data
 * @param {Object} context Function call context
 * @returns {Promise<Object>} Response object
 */
const generateAIResponse = async (data, context) => {
  try {
    // Extract query and conversation history from request data
    const { query, conversationHistory } = data;
    
    if (!query || typeof query !== 'string') {
      throw new Error('Missing or invalid query parameter');
    }
    
    // Log the incoming request (with sensitive data redacted)
    if (config.logLevel === 'debug') {
      console.log(`Received query: ${query}`);
      console.log(`With conversation history: ${conversationHistory?.length || 0} messages`);
    }
    
    // Get API key if using API key auth method
    let apiKey = null;
    if (config.authMethod === 'API_KEY') {
      apiKey = config.apiKey;
    } else if (config.authMethod === 'SECRET_MANAGER') {
      apiKey = await getApiKeyFromSecretManager();
    }
    
    // Search knowledge base for relevant content
    const knowledgeSources = await searchKnowledgeBase(query);
    
    console.log(`📚 Knowledge search returned ${knowledgeSources.length} sources`);
    if (knowledgeSources.length > 0) {
      console.log('Sources found:', knowledgeSources.map(s => s.title).join(', '));
    }
    
    // Initialize Vertex AI
    const model = initializeVertexAI(apiKey);
    
    // Generate system prompt
    const systemPrompt = generateSystemPrompt(knowledgeSources);
    
    // Format conversation for Gemini (passing in the system prompt)
    const formattedConversation = formatConversation(conversationHistory, query, systemPrompt);
    
    // Generate response from Gemini
    const result = await model.generateContent({
      contents: formattedConversation,
      generationConfig: {
        temperature: 0.2,
        topP: 0.8,
        topK: 40,
        maxOutputTokens: config.maxOutputTokens,
      },
    });
    
    // Extract text from response - handle different response formats for various Gemini models
    const response = result.response;
    let aiText;
    
    // Debug - log the response structure
    if (config.logLevel === 'debug') {
      console.log('Response structure:', JSON.stringify(response));
    }
    
    // Safely extract text from different possible response structures
    try {
      if (typeof response.text === 'function') {
        // For models that have response.text() function (like older Gemini 1.0)
        aiText = response.text();
      } else if (response.candidates && response.candidates[0] && response.candidates[0].content) {
        // For models that use the candidates[0].content.parts[0].text structure (like Gemini 2.0)
        aiText = response.candidates[0].content.parts[0].text;
      } else if (response.candidates && response.candidates[0] && response.candidates[0].text) {
        // Alternative structure with direct text property
        aiText = response.candidates[0].text;
      } else {
        // If we can't find the text in the expected structures, try to stringify the whole response
        console.warn('Unexpected response structure, attempting to extract text');
        aiText = JSON.stringify(response);
      }
    } catch (error) {
      console.error('Error extracting text from response:', error);
      aiText = 'Sorry, I encountered an issue processing your request.';
    }
    
    // Return formatted response
    return {
      text: aiText,
      sources: knowledgeSources.length > 0 ? knowledgeSources : null,
    };
  } catch (error) {
    console.error(`Error generating AI response: ${error}`);
    
    // Format the error correctly for callable functions
    let code = 'internal';
    let message = 'An unexpected error occurred';
    
    if (error.message.includes('API key')) {
      code = 'unauthenticated';
      message = 'Authentication failed';
    } else if (error.message.includes('rate limit')) {
      code = 'resource-exhausted';
      message = 'Rate limit exceeded. Please try again later.';
    } else if (error.message.includes('Missing or invalid')) {
      code = 'invalid-argument';
      message = error.message;
    }
    
    throw new HttpsError(code, message, { 
      originalError: error.message 
    });
  }
};

// Export the function (fix the circular reference)
exports.generateAIResponse = generateAIResponse;