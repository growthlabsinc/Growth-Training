/**
 * Vertex AI Proxy for Growth App
 * Handles AI responses using Google Cloud Vertex AI
 */

const { VertexAI } = require('@google-cloud/vertexai');
const { getFallbackResponse } = require('./fallbackKnowledge');

// Initialize Vertex AI
const PROJECT_ID = process.env.GCLOUD_PROJECT || 'growth-70a85';
const LOCATION = 'us-central1';
const MODEL = 'gemini-1.5-flash';

let vertexAI;
let generativeModel;

// Initialize Vertex AI client
function initializeVertexAI() {
  if (!vertexAI) {
    vertexAI = new VertexAI({
      project: PROJECT_ID,
      location: LOCATION,
    });
    
    generativeModel = vertexAI.preview.getGenerativeModel({
      model: MODEL,
      generationConfig: {
        maxOutputTokens: 2048,
        temperature: 0.7,
        topP: 0.8,
        topK: 40,
      },
    });
  }
  return generativeModel;
}

/**
 * Generate AI response using Vertex AI
 * @param {Object} data - Request data containing query and conversationHistory
 * @param {Object} context - Request context containing auth and app info
 * @returns {Promise<Object>} AI response with text and sources
 */
async function generateAIResponse(data, context) {
  try {
    const model = initializeVertexAI();
    
    // Build the prompt with context
    let prompt = `You are a knowledgeable Growth Methods coach helping users with the Growth app. 
    
Provide helpful, accurate information about:
- Growth Methods (AM1, AM2, Vascion, etc.)
- Techniques and proper form
- Safety guidelines and precautions
- Progression timelines and expectations
- App features and navigation

Be conversational but professional. Keep responses concise and focused.

User question: ${data.query}`;

    // Add conversation history if available
    if (data.conversationHistory && data.conversationHistory.length > 0) {
      prompt = `Previous conversation:
${data.conversationHistory.map(msg => `${msg.role}: ${msg.content}`).join('\n')}

${prompt}`;
    }

    // Generate response
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    return {
      text: text,
      sources: null, // Vertex AI doesn't provide sources like this
    };
    
  } catch (error) {
    console.error('Vertex AI error:', error);
    
    // Fall back to knowledge base
    const fallbackText = getFallbackResponse(data.query);
    if (fallbackText) {
      return {
        text: fallbackText,
        sources: null,
      };
    }
    
    throw error;
  }
}

module.exports = {
  generateAIResponse
};