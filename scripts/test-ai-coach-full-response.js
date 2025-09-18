/**
 * Test script to verify AI Coach returns full responses without truncation
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85',
});

// Test query that should generate a long response
const testQuery = "Can you explain the complete AM1 (Angion Method 1) technique in detail? Please include all the steps, the pyramid rush variation, and any important tips or warnings.";

async function testAICoachResponse() {
  try {
    console.log('🧪 Testing AI Coach response length...\n');
    console.log('Query:', testQuery);
    console.log('\n📞 Calling generateAIResponse function...\n');
    
    const functions = admin.functions();
    const generateAIResponse = functions.httpsCallable('generateAIResponse');
    
    const result = await generateAIResponse({ query: testQuery });
    
    const responseText = result.data.text;
    const sources = result.data.sources || [];
    
    console.log('✅ Response received!');
    console.log(`📏 Response length: ${responseText.length} characters`);
    console.log(`📚 Sources found: ${sources.length}`);
    
    if (sources.length > 0) {
      console.log('\nSources:');
      sources.forEach((source, index) => {
        console.log(`${index + 1}. ${source.title} (${Math.round(source.confidence * 100)}% confidence)`);
      });
    }
    
    console.log('\n📄 Full response:');
    console.log('=====================================');
    console.log(responseText);
    console.log('=====================================\n');
    
    // Check if response appears truncated
    const lastSentence = responseText.trim().split('.').pop();
    const appearsComplete = responseText.trim().endsWith('.') || 
                           responseText.trim().endsWith('!') || 
                           responseText.trim().endsWith('?');
    
    if (!appearsComplete) {
      console.log('⚠️  WARNING: Response may be truncated!');
      console.log(`Last sentence fragment: "${lastSentence}"`);
    } else {
      console.log('✅ Response appears complete');
    }
    
    // Token estimate (rough calculation)
    const estimatedTokens = Math.ceil(responseText.length / 4);
    console.log(`\n🔢 Estimated tokens used: ~${estimatedTokens}`);
    
    if (estimatedTokens > 1000) {
      console.log('✅ Response exceeds old 1024 token limit - fix is working!');
    }
    
  } catch (error) {
    console.error('❌ Error testing AI Coach:', error);
    if (error.code) {
      console.error('Error code:', error.code);
    }
    if (error.details) {
      console.error('Error details:', error.details);
    }
  }
}

// Run the test
testAICoachResponse()
  .then(() => {
    console.log('\n🏁 Test complete');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });