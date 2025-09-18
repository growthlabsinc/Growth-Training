/**
 * Configuration for Vertex AI Proxy
 * 
 * This file provides environment-specific configuration for the Vertex AI proxy Cloud Function.
 * Values can be overridden by environment variables.
 */

const environments = {
  // Development environment configuration
  development: {
    // Vertex AI settings
    vertexAiRegion: 'us-central1',
    vertexAiProjectId: 'growth-app-dev',
    vertexAiSearchDatastore: 'growth-methods-dev',
    
    // Gemini model settings
    geminiModel: 'gemini-2.0-flash-lite-001',
    maxOutputTokens: 4096,
    temperature: 0.2,
    topP: 0.8,
    topK: 40,
    
    // Authentication
    authMethod: 'SERVICE_ACCOUNT', // Options: API_KEY, SECRET_MANAGER, SERVICE_ACCOUNT
    apiKeySecretName: 'vertex-ai-api-key-dev',
    
    // Other settings
    logLevel: 'debug',
    maxQueryLength: 500,
    maxHistoryMessages: 10,
  },
  
  // Production environment configuration
  production: {
    // Vertex AI settings
    vertexAiRegion: 'us-central1',
    vertexAiProjectId: 'growth-app-prod',
    vertexAiSearchDatastore: 'growth-methods-prod',
    
    // Gemini model settings
    geminiModel: 'gemini-2.0-flash-lite-001',
    maxOutputTokens: 4096,
    temperature: 0.2,
    topP: 0.8,
    topK: 40,
    
    // Authentication
    authMethod: 'SECRET_MANAGER', // More secure for production
    apiKeySecretName: 'vertex-ai-api-key',
    
    // Other settings
    logLevel: 'info',
    maxQueryLength: 500,
    maxHistoryMessages: 10,
  },
};

// Determine the current environment
const getCurrentEnvironment = () => {
  const nodeEnv = process.env.NODE_ENV || 'development';
  return environments[nodeEnv] || environments.development;
};

// Export the configuration
module.exports = {
  ...getCurrentEnvironment(),
  
  // Allow environment variables to override config
  vertexAiRegion: process.env.VERTEX_AI_REGION || getCurrentEnvironment().vertexAiRegion,
  vertexAiProjectId: process.env.VERTEX_AI_PROJECT_ID || getCurrentEnvironment().vertexAiProjectId,
  vertexAiSearchDatastore: process.env.VERTEX_AI_SEARCH_DATASTORE || getCurrentEnvironment().vertexAiSearchDatastore,
  geminiModel: process.env.GEMINI_MODEL || getCurrentEnvironment().geminiModel,
  maxOutputTokens: parseInt(process.env.MAX_OUTPUT_TOKENS || getCurrentEnvironment().maxOutputTokens.toString(), 10),
  temperature: parseFloat(process.env.TEMPERATURE || getCurrentEnvironment().temperature.toString()),
  topP: parseFloat(process.env.TOP_P || getCurrentEnvironment().topP.toString()),
  topK: parseInt(process.env.TOP_K || getCurrentEnvironment().topK.toString(), 10),
  authMethod: process.env.AUTH_METHOD || getCurrentEnvironment().authMethod,
  apiKeySecretName: process.env.API_KEY_SECRET_NAME || getCurrentEnvironment().apiKeySecretName,
  logLevel: process.env.LOG_LEVEL || getCurrentEnvironment().logLevel,
  maxQueryLength: parseInt(process.env.MAX_QUERY_LENGTH || getCurrentEnvironment().maxQueryLength.toString(), 10),
  maxHistoryMessages: parseInt(process.env.MAX_HISTORY_MESSAGES || getCurrentEnvironment().maxHistoryMessages.toString(), 10),
}; 