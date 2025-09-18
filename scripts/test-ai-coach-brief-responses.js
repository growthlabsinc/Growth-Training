/**
 * Test script to verify AI Coach provides brief initial responses
 * and handles medical questions appropriately
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85',
});

// Test queries
const testQueries = [
  {
    name: "Technical Method Question",
    query: "What is AM1?"
  },
  {
    name: "Medical Question with Angion Context",
    query: "Does AM1 help with erectile dysfunction?"
  },
  {
    name: "Pure Medical Question",
    query: "What medications should I take for my condition?"
  },
  {
    name: "Detailed Method Request",
    query: "Explain the complete SABRE technique"
  },
  {
    name: "Follow-up Request",
    query: "Yes, please provide more details about the pyramid rush variation"
  }
];

async function testAICoachResponse(queryInfo) {
  try {
    console.log(`\n🧪 Testing: ${queryInfo.name}`);
    console.log(`Query: "${queryInfo.query}"`);
    
    const functions = admin.functions();
    const generateAIResponse = functions.httpsCallable('generateAIResponse');
    
    const result = await generateAIResponse({ query: queryInfo.query });
    
    const responseText = result.data.text;
    const sources = result.data.sources || [];
    
    console.log(`\n📄 Response:`);
    console.log('---');
    console.log(responseText);
    console.log('---');
    
    // Check response characteristics
    const sentences = responseText.split(/[.!?]/).filter(s => s.trim().length > 0);
    console.log(`\n📊 Analysis:`);
    console.log(`- Sentence count: ${sentences.length}`);
    console.log(`- Character count: ${responseText.length}`);
    console.log(`- Sources found: ${sources.length}`);
    
    // Check if response asks for follow-up
    const hasFollowUp = responseText.includes('Would you like') || 
                       responseText.includes('Do you have') ||
                       responseText.includes('more details') ||
                       responseText.includes('want to know more');
    console.log(`- Contains follow-up question: ${hasFollowUp ? '✅' : '❌'}`);
    
    // Check for medical disclaimer if medical question
    const hasMedicalDisclaimer = responseText.includes('cannot provide medical advice') ||
                                responseText.includes('While I cannot provide medical advice');
    if (queryInfo.name.includes('Medical')) {
      console.log(`- Contains medical disclaimer: ${hasMedicalDisclaimer ? '✅' : '❌'}`);
    }
    
    // Check if brief (less than 500 characters for initial response)
    const isBrief = responseText.length < 500;
    console.log(`- Is brief initial response: ${isBrief ? '✅' : '⚠️  (may be detailed)'}`);
    
  } catch (error) {
    console.error(`\n❌ Error for "${queryInfo.name}":`, error.message);
  }
}

async function runAllTests() {
  console.log('🚀 Testing AI Coach Brief Response System\n');
  console.log('Expected behavior:');
  console.log('1. Brief initial responses (2-3 sentences)');
  console.log('2. Follow-up questions offering more details');
  console.log('3. Medical questions handled with Angion Method context when available');
  console.log('4. Pure medical questions declined appropriately\n');
  
  for (const query of testQueries) {
    await testAICoachResponse(query);
    console.log('\n' + '='.repeat(60));
  }
}

// Run the tests
runAllTests()
  .then(() => {
    console.log('\n✅ All tests complete');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });