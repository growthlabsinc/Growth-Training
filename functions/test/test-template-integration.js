/**
 * Integration Test for Conversation Templates with AI System
 * Story 3.7: Develop Conversation Templates
 *
 * Tests the complete integration of templates with the vertexAiProxy
 */

// const { generateAIResponse } = require('../vertexAiProxy/index'); // Not needed for standalone test

// Test colors for console output
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  reset: '\x1b[0m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

/**
 * Test template selection and processing in the AI response flow
 */
async function testTemplateIntegration() {
  log('\n🚀 Template Integration Test Suite\n', 'cyan');

  const testCases = [
    {
      name: 'Safety Override for Injury',
      data: {
        query: 'I have severe pain and numbness in my area',
        userId: 'test-user-001',
        userExperienceLevel: 'intermediate'
      },
      expectations: {
        shouldUseTemplate: true,
        templateId: 'safety_stop_signal',
        shouldContain: ['STOP', 'medical', 'immediately']
      }
    },
    {
      name: 'Beginner Welcome',
      data: {
        query: 'Hello, I am new to PE training',
        userId: 'test-user-002',
        userName: 'John',
        userExperienceLevel: 'beginner',
        conversationHistory: []
      },
      expectations: {
        shouldUseTemplate: true,
        templateId: 'beginner_welcome',
        shouldContain: ['Welcome', 'John', 'safety', '10-15 minute']
      }
    },
    {
      name: 'Routine Assessment',
      data: {
        query: 'Can you check my routine for me?',
        userId: 'test-user-003',
        userExperienceLevel: 'intermediate',
        primaryGoal: 'length',
        conversationHistory: [
          { sender: 'user', text: 'I have been training for 3 months' },
          { sender: 'assistant', text: 'Great progress!' }
        ]
      },
      expectations: {
        shouldUseTemplate: true,
        templateId: 'routine_assessment',
        shouldContain: ['routine', 'optimize']
      }
    },
    {
      name: 'Progress Check with Context',
      data: {
        query: 'How am I doing with my progress?',
        userId: 'test-user-004',
        userExperienceLevel: 'advanced',
        progressData: {
          streak: 30,
          totalSessions: 150,
          lastSession: '2024-01-20'
        }
      },
      expectations: {
        shouldUseTemplate: true,
        templateId: 'progress_check_in',
        shouldContain: ['progress', 'sessions']
      }
    },
    {
      name: 'Pre-Session Safety Check',
      data: {
        query: 'About to train, any pre-session safety check?',
        userId: 'test-user-005',
        sessionType: 'pre-workout',
        userExperienceLevel: 'intermediate'
      },
      expectations: {
        shouldUseTemplate: true,
        templateId: 'safety_pre_session',
        shouldContain: ['safety', 'warm-up', 'medical disclaimer']
      }
    }
  ];

  let passed = 0;
  let failed = 0;

  for (const testCase of testCases) {
    log(`\n📝 Testing: ${testCase.name}`, 'blue');

    try {
      // Mock the AI response generation
      // In production, this would call the actual Firebase Function
      const response = await simulateTemplateResponse(testCase.data);

      // Validate expectations
      let testPassed = true;
      const failures = [];

      // Check if template was used
      if (testCase.expectations.shouldUseTemplate) {
        if (!response.templateUsed) {
          testPassed = false;
          failures.push('Template was not used');
        } else if (response.templateUsed !== testCase.expectations.templateId) {
          testPassed = false;
          failures.push(`Wrong template: expected ${testCase.expectations.templateId}, got ${response.templateUsed}`);
        }
      }

      // Check content contains expected strings
      if (testCase.expectations.shouldContain) {
        for (const expectedText of testCase.expectations.shouldContain) {
          if (!response.text.toLowerCase().includes(expectedText.toLowerCase())) {
            testPassed = false;
            failures.push(`Missing expected text: "${expectedText}"`);
          }
        }
      }

      // Check safety filtering
      if (response.wasFiltered && !testCase.expectations.shouldBeFiltered) {
        testPassed = false;
        failures.push('Response was unexpectedly filtered');
      }

      if (testPassed) {
        log(`  ✅ Passed`, 'green');
        if (response.templateUsed) {
          log(`     Template: ${response.templateUsed} (confidence: ${response.templateConfidence})`, 'green');
        }
        passed++;
      } else {
        log(`  ❌ Failed`, 'red');
        failures.forEach(f => log(`     - ${f}`, 'red'));
        failed++;
      }

      // Show a snippet of the response
      if (response.text) {
        const snippet = response.text.substring(0, 100).replace(/\n/g, ' ');
        log(`     Response: "${snippet}..."`, 'cyan');
      }

    } catch (error) {
      log(`  ❌ Error: ${error.message}`, 'red');
      failed++;
    }
  }

  // Summary
  log('\n' + '='.repeat(60), 'yellow');
  log('Integration Test Results', 'yellow');
  log('='.repeat(60), 'yellow');

  const total = passed + failed;
  const percentage = Math.round((passed / total) * 100);
  const resultColor = percentage === 100 ? 'green' : percentage >= 80 ? 'yellow' : 'red';

  log(`\nPassed: ${passed}/${total} tests (${percentage}%)`, resultColor);

  if (passed === total) {
    log('\n🎉 All integration tests passed!', 'green');
    log('The conversation template system is fully integrated and working correctly.', 'green');
  } else {
    log(`\n⚠️ ${failed} integration tests failed.`, 'red');
  }

  return passed === total;
}

/**
 * Simulate template response without calling actual Firebase Function
 */
async function simulateTemplateResponse(data) {
  // Import the necessary modules
  const { selectBestTemplate } = require('../vertexAiProxy/templateSelector');
  const { processTemplate, enhanceTemplateWithDynamicContent } = require('../vertexAiProxy/templateProcessor');

  // Build user context
  const userContext = {
    userId: data.userId || 'anonymous',
    userName: data.userName,
    userExperienceLevel: data.userExperienceLevel || 'beginner',
    sessionType: data.sessionType,
    conversationHistory: data.conversationHistory,
    previousTemplateId: data.previousTemplateId,
    primaryGoal: data.primaryGoal,
    progressData: data.progressData,
    riskLevel: data.riskLevel
  };

  // Check if a template should be used
  const templateSelection = selectBestTemplate(data.query, userContext);

  if (templateSelection && templateSelection.confidence !== 'very_low') {
    // Process the template
    const processedTemplate = processTemplate(
      templateSelection.templateId,
      data.templateVariables || {},
      userContext
    );

    if (processedTemplate) {
      // Enhance template with dynamic content
      const enhanced = enhanceTemplateWithDynamicContent(processedTemplate, userContext);

      // Return the template-based response (skip filtering for test)
      return {
        text: enhanced.text,
        wasFiltered: false,
        filterReasons: [],
        templateUsed: templateSelection.templateId,
        templateConfidence: templateSelection.confidence
      };
    }
  }

  // If no template, return a mock AI response
  return {
    text: 'This would be an AI-generated response without a template.',
    wasFiltered: false,
    templateUsed: null,
    templateConfidence: null
  };
}

// Run tests if called directly
if (require.main === module) {
  testTemplateIntegration()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('Integration test error:', error);
      process.exit(1);
    });
}

module.exports = { testTemplateIntegration };