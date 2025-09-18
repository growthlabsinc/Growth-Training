console.log('Starting test load...');

try {
  console.log('Loading firebase-admin...');
  const admin = require('firebase-admin');
  console.log('✓ firebase-admin loaded');
  
  console.log('Loading firebase-functions...');
  const functions = require('firebase-functions/v2/https');
  console.log('✓ firebase-functions loaded');
  
  console.log('Loading modules...');
  console.log('- vertexAiProxy...');
  const vertexAIProxy = require('./vertexAiProxy');
  console.log('✓ vertexAiProxy loaded');
  
  console.log('- fallbackKnowledge...');
  const { getFallbackResponse } = require('./fallbackKnowledge');
  console.log('✓ fallbackKnowledge loaded');
  
  console.log('- addMissingRoutines...');
  const { addMissingRoutines } = require('./addMissingRoutines');
  console.log('✓ addMissingRoutines loaded');
  
  console.log('- liveActivityUpdates...');
  const liveActivityFunctions = require('./liveActivityUpdates');
  console.log('✓ liveActivityUpdates loaded');
  
  console.log('- manageLiveActivityUpdates...');
  const { manageLiveActivityUpdates } = require('./manageLiveActivityUpdates');
  console.log('✓ manageLiveActivityUpdates loaded');
  
  console.log('All modules loaded successfully!');
  process.exit(0);
} catch (error) {
  console.error('Error loading modules:', error);
  process.exit(1);
}