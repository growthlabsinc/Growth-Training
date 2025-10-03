/**
 * Comprehensive Test Suite for Conversation Templates
 * Story 3.7: Develop Conversation Templates
 *
 * Tests template selection, processing, and safety integration
 */

const assert = require('assert');
const {
  getTemplateById,
  getTemplatesByTag,
  getTemplatesByCategory,
  TEMPLATE_PRIORITY
} = require('../vertexAiProxy/conversationTemplates');
const {
  selectBestTemplate,
  selectTemplate,
  checkSafetyOverride,
  INTENT_PATTERNS
} = require('../vertexAiProxy/templateSelector');
const {
  processTemplate,
  enhanceTemplateWithDynamicContent,
  validateTemplateVariables,
  getDefaultVariables,
  getContextVariables
} = require('../vertexAiProxy/templateProcessor');

// Test colors for console output
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Test helper functions
function testSection(name) {
  console.log('\n' + '='.repeat(60));
  log(`Testing: ${name}`, 'blue');
  console.log('='.repeat(60));
}

function testCase(description, fn) {
  try {
    fn();
    log(`✓ ${description}`, 'green');
    return true;
  } catch (error) {
    log(`✗ ${description}`, 'red');
    console.error(`  Error: ${error.message}`);
    return false;
  }
}

// Main test runner
async function runTests() {
  let totalTests = 0;
  let passedTests = 0;

  log('\n🧪 Conversation Templates Test Suite\n', 'yellow');

  // 1. Test Template Definitions
  testSection('Template Definitions');

  totalTests++;
  if (testCase('Should load beginner welcome template', () => {
    const template = getTemplateById('beginner_welcome');
    assert(template, 'Template should exist');
    assert(template.priority === TEMPLATE_PRIORITY.BEGINNER_GUIDANCE, 'Should have correct priority');
    assert(template.tags.includes('beginner'), 'Should have beginner tag');
    assert(template.template.includes('Welcome'), 'Should contain welcome text');
  })) passedTests++;

  totalTests++;
  if (testCase('Should load safety stop signal template', () => {
    const template = getTemplateById('safety_stop_signal');
    assert(template, 'Template should exist');
    assert(template.priority === TEMPLATE_PRIORITY.SAFETY_CRITICAL, 'Should have critical priority');
    assert(template.tags.includes('safety'), 'Should have safety tag');
    assert(template.template.includes('STOP'), 'Should contain STOP instruction');
  })) passedTests++;

  totalTests++;
  if (testCase('Should get templates by tag', () => {
    const safetyTemplates = getTemplatesByTag('safety');
    assert(safetyTemplates.length > 0, 'Should find safety templates');
    assert(safetyTemplates.every(t => t.tags.includes('safety')), 'All should have safety tag');
  })) passedTests++;

  totalTests++;
  if (testCase('Should get templates by category', () => {
    const beginnerTemplates = getTemplatesByCategory('beginner');
    assert(beginnerTemplates.length > 0, 'Should find beginner templates');
    assert(beginnerTemplates.every(t => t.category === 'beginner'), 'All should be beginner category');
  })) passedTests++;

  // 2. Test Template Selection
  testSection('Template Selection');

  totalTests++;
  if (testCase('Should select safety template for injury query', () => {
    const query = 'I have severe pain and numbness';
    const result = selectBestTemplate(query);
    assert(result, 'Should return a template');
    assert(result.templateId === 'safety_stop_signal', 'Should select safety stop template');
    assert(result.confidence === 'very_high', 'Should have very high confidence');
    assert(result.override === true, 'Should be a safety override');
  })) passedTests++;

  totalTests++;
  if (testCase('Should select beginner template for new user', () => {
    const query = 'Hello, I am new here';
    const context = { conversationHistory: [] };
    const result = selectBestTemplate(query, context);
    assert(result, 'Should return a template');
    assert(result.templateId === 'beginner_welcome', 'Should select welcome template');
    assert(result.confidence !== 'very_low', 'Should have reasonable confidence');
  })) passedTests++;

  totalTests++;
  if (testCase('Should select routine template for routine query', () => {
    const query = 'Can you check my routine for me?';
    const context = { userExperienceLevel: 'intermediate' };
    const result = selectBestTemplate(query, context);
    assert(result, 'Should return a template');
    assert(result.templateId === 'routine_assessment', 'Should select routine assessment template');
  })) passedTests++;

  totalTests++;
  if (testCase('Should handle follow-up conversations', () => {
    const query = 'What routine should I start with?';
    const context = {
      previousTemplateId: 'beginner_welcome',
      conversationHistory: [
        { sender: 'user', text: 'Hello' },
        { sender: 'assistant', text: 'Welcome!' }
      ]
    };
    const result = selectBestTemplate(query, context);
    assert(result, 'Should return a template');
    assert(result.templateId === 'beginner_first_routine', 'Should select first routine template');
    assert(result.reason.includes('Follow-up'), 'Should indicate follow-up flow');
  })) passedTests++;

  totalTests++;
  if (testCase('Should detect safety triggers', () => {
    const queries = [
      'turning blue',
      'completely numb',
      'severe pain',
      'bleeding'
    ];

    queries.forEach(query => {
      const result = checkSafetyOverride(query, {});
      assert(result, `Should detect safety trigger for: ${query}`);
      assert(result.templateId === 'safety_stop_signal', 'Should return safety template');
      assert(result.override === true, 'Should be marked as override');
    });
  })) passedTests++;

  // 3. Test Template Processing
  testSection('Template Processing');

  totalTests++;
  if (testCase('Should process template with default variables', () => {
    const processed = processTemplate('beginner_welcome');
    assert(processed, 'Should return processed template');
    assert(processed.text, 'Should have text property');
    assert(!processed.text.includes('{{'), 'Should not contain unprocessed variables');
    assert(processed.variablesUsed.includes('appName'), 'Should use default variables');
  })) passedTests++;

  totalTests++;
  if (testCase('Should process template with custom variables', () => {
    const customVars = {
      userName: 'John',
      experienceLevel: 'beginner'
    };
    const processed = processTemplate('beginner_welcome', customVars);
    assert(processed, 'Should return processed template');
    assert(processed.text.includes('John') || processed.text.includes('Hello'), 'Should use custom name');
  })) passedTests++;

  totalTests++;
  if (testCase('Should process context variables', () => {
    const context = {
      userExperienceLevel: 'advanced',
      userName: 'Sarah',
      primaryGoal: 'length'
    };
    const contextVars = getContextVariables(context);
    assert(contextVars.experienceLevel === 'advanced', 'Should extract experience level');
    assert(contextVars.sessionDuration === '45-60', 'Should set advanced session duration');
    assert(contextVars.primaryTechnique === 'manual stretching', 'Should set length-focused technique');
  })) passedTests++;

  totalTests++;
  if (testCase('Should validate template variables', () => {
    const validation = validateTemplateVariables('beginner_welcome');
    assert(validation.valid === true, 'Should be valid with default variables');
    assert(validation.missingVariables.length === 0, 'Should have no missing variables');
  })) passedTests++;

  totalTests++;
  if (testCase('Should enhance template with dynamic content', () => {
    const processed = processTemplate('beginner_welcome', {}, {
      userName: 'Mike',
      riskLevel: 'high'
    });
    const enhanced = enhanceTemplateWithDynamicContent(processed, {
      userName: 'Mike',
      riskLevel: 'high'
    });
    assert(enhanced, 'Should return enhanced template');
    assert(enhanced.text.includes('safety is paramount'), 'Should add safety reminder for high risk');
  })) passedTests++;

  // 4. Test Safety Integration
  testSection('Safety Integration');

  totalTests++;
  if (testCase('Should enforce safety limits in templates', () => {
    const defaults = getDefaultVariables();
    assert(defaults.maxDuration === '60', 'Should have 60 minute max duration');
    assert(defaults.beginnerLimit === '15', 'Should have 15 minute beginner limit');
    assert(defaults.requiredRest.includes('1-2'), 'Should require rest days');
  })) passedTests++;

  totalTests++;
  if (testCase('Should prioritize safety templates', () => {
    const templates = [
      getTemplateById('safety_stop_signal'),
      getTemplateById('beginner_welcome'),
      getTemplateById('routine_assessment')
    ];

    const sorted = templates.sort((a, b) => b.priority - a.priority);
    assert(sorted[0].id === 'safety_stop_signal', 'Safety should be highest priority');
  })) passedTests++;

  totalTests++;
  if (testCase('Should include medical disclaimers', () => {
    const safetyTemplates = getTemplatesByTag('safety');
    safetyTemplates.forEach(template => {
      const processed = processTemplate(template.id);
      assert(
        processed.text.includes('medical') ||
        processed.text.includes('healthcare') ||
        processed.text.includes('doctor'),
        `Template ${template.id} should include medical disclaimer`
      );
    });
  })) passedTests++;

  // 5. Test Intent Pattern Matching
  testSection('Intent Pattern Matching');

  totalTests++;
  if (testCase('Should match injury intent patterns', () => {
    const patterns = INTENT_PATTERNS.injury.patterns;
    const testQueries = [
      'I have pain in my area',
      'It hurts when I do this',
      'There is some swelling'
    ];

    testQueries.forEach(query => {
      const matches = patterns.some(pattern => pattern.test(query));
      assert(matches, `Should match injury pattern for: ${query}`);
    });
  })) passedTests++;

  totalTests++;
  if (testCase('Should match beginner intent patterns', () => {
    const patterns = INTENT_PATTERNS.newUser.patterns;
    const testQueries = [
      'Hello there',
      'I want to start PE',
      'First time doing this'
    ];

    testQueries.forEach(query => {
      const matches = patterns.some(pattern => pattern.test(query));
      assert(matches, `Should match newUser pattern for: ${query}`);
    });
  })) passedTests++;

  // 6. Test Edge Cases
  testSection('Edge Cases');

  totalTests++;
  if (testCase('Should handle missing template gracefully', () => {
    const processed = processTemplate('non_existent_template');
    assert(processed === null, 'Should return null for missing template');
  })) passedTests++;

  totalTests++;
  if (testCase('Should handle empty query', () => {
    const result = selectBestTemplate('', {});
    assert(result === null || result.templateId === 'beginner_welcome',
      'Should return null or default template');
  })) passedTests++;

  totalTests++;
  if (testCase('Should handle null context', () => {
    const processed = processTemplate('beginner_welcome', {}, null);
    assert(processed, 'Should process with null context');
    assert(processed.text, 'Should still generate text');
  })) passedTests++;

  // 7. Test Complex Scenarios
  testSection('Complex Scenarios');

  totalTests++;
  if (testCase('Should handle multi-turn conversation', () => {
    const context = {
      conversationHistory: [
        { sender: 'user', text: 'Hello' },
        { sender: 'assistant', text: 'Welcome!' },
        { sender: 'user', text: 'I want to start' },
        { sender: 'assistant', text: 'Great!' }
      ],
      userExperienceLevel: 'beginner',
      previousTemplateId: 'beginner_welcome'
    };

    const result = selectBestTemplate('What exercises should I do?', context);
    assert(result, 'Should select template for multi-turn conversation');
    assert(['routine_exercise_selection', 'beginner_first_routine'].includes(result.templateId),
      'Should select appropriate follow-up template');
  })) passedTests++;

  totalTests++;
  if (testCase('Should combine multiple context factors', () => {
    const context = {
      userExperienceLevel: 'intermediate',
      primaryGoal: 'girth',
      sessionType: 'pre-workout',
      progressData: {
        streak: 10,
        totalSessions: 50
      }
    };

    const contextVars = getContextVariables(context);
    assert(contextVars.sessionDuration === '30-45', 'Should set intermediate duration');
    assert(contextVars.primaryTechnique === 'jelqing', 'Should set girth technique');
    assert(contextVars.currentStreak === 10, 'Should include streak');
  })) passedTests++;

  // Print test results
  console.log('\n' + '='.repeat(60));
  log('Test Results', 'yellow');
  console.log('='.repeat(60));

  const percentage = Math.round((passedTests / totalTests) * 100);
  const resultColor = percentage === 100 ? 'green' : percentage >= 80 ? 'yellow' : 'red';

  log(`Passed: ${passedTests}/${totalTests} tests (${percentage}%)`, resultColor);

  if (passedTests === totalTests) {
    log('\n✨ All tests passed! Template system is working correctly.', 'green');
  } else {
    log(`\n⚠️ ${totalTests - passedTests} tests failed. Please review the errors above.`, 'red');
  }

  return passedTests === totalTests;
}

// Run tests if called directly
if (require.main === module) {
  runTests()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('Test suite error:', error);
      process.exit(1);
    });
}

module.exports = { runTests };