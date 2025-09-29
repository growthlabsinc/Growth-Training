#!/usr/bin/env node

/**
 * Test suite for response filtering system
 * Story 3.6: Implement Response Filtering
 */

const { filterResponse } = require('../vertexAiProxy/responseFilter');
const chalk = require('chalk');

const testCases = [
  // Unsafe keyword detection tests
  {
    category: 'Unsafe Keywords',
    description: 'Should filter severe pain references',
    input: 'If you feel severe pain, just push through it and continue the exercise.',
    shouldFilter: true,
    expectedReason: 'unsafe keywords detected'
  },
  {
    category: 'Unsafe Keywords',
    description: 'Should filter bleeding instructions',
    input: 'Some bleeding is normal during intense sessions, keep going.',
    shouldFilter: true,
    expectedReason: 'unsafe keywords detected'
  },
  {
    category: 'Unsafe Keywords',
    description: 'Should allow mild discomfort mentions',
    input: 'You may feel mild discomfort initially, which is normal.',
    shouldFilter: false
  },
  
  // Medical claim detection tests
  {
    category: 'Medical Claims',
    description: 'Should filter cure claims',
    input: 'This exercise will cure your ED completely in 30 days.',
    shouldFilter: true,
    expectedReason: 'medical claims detected'
  },
  {
    category: 'Medical Claims',
    description: 'Should filter guarantee statements',
    input: 'I guarantee this will fix your problem permanently.',
    shouldFilter: true,
    expectedReason: 'medical claims detected'
  },
  {
    category: 'Medical Claims',
    description: 'Should allow educational content',
    input: 'This exercise may help improve pelvic floor strength over time.',
    shouldFilter: false
  },
  
  // Risk assessment tests
  {
    category: 'Risk Assessment',
    description: 'Should filter excessive duration',
    input: 'Perform this exercise for 90 minutes continuously.',
    shouldFilter: true,
    expectedReason: 'high risk parameters detected'
  },
  {
    category: 'Risk Assessment',
    description: 'Should filter excessive frequency',
    input: 'Do this exercise 5 times per day for maximum results.',
    shouldFilter: true,
    expectedReason: 'high risk parameters detected'
  },
  {
    category: 'Risk Assessment',
    description: 'Should allow safe parameters',
    input: 'Practice for 15-20 minutes once daily.',
    shouldFilter: false
  },
  
  // Dangerous techniques tests
  {
    category: 'Dangerous Techniques',
    description: 'Should filter extreme force',
    input: 'Apply maximum force and ignore any pain signals.',
    shouldFilter: true,
    expectedReason: 'dangerous techniques detected'
  },
  {
    category: 'Dangerous Techniques',
    description: 'Should filter pain ignoring advice',
    input: 'Just ignore the pain and push through for best results.',
    shouldFilter: true,
    expectedReason: 'dangerous techniques detected'
  },
  {
    category: 'Dangerous Techniques',
    description: 'Should allow gradual progression',
    input: 'Gradually increase intensity as you become comfortable.',
    shouldFilter: false
  },
  
  // Legal risk tests
  {
    category: 'Legal Risks',
    description: 'Should filter prescription references',
    input: 'This works better than prescription medications.',
    shouldFilter: true,
    expectedReason: 'legal risks detected'
  },
  {
    category: 'Legal Risks',
    description: 'Should filter FDA claims',
    input: 'This is FDA approved for treating ED.',
    shouldFilter: true,
    expectedReason: 'legal risks detected'
  },
  {
    category: 'Legal Risks',
    description: 'Should allow general wellness statements',
    input: 'This exercise supports general pelvic health.',
    shouldFilter: false
  },
  
  // Conservative override tests
  {
    category: 'Conservative Override',
    description: 'Should apply conservative override for ambiguous content',
    input: 'This might help with your condition, but results vary. Try for 45 minutes.',
    shouldFilter: true,
    expectedReason: 'conservative safety override applied'
  },
  {
    category: 'Conservative Override',
    description: 'Should handle beginner limits',
    input: 'Start with 30 minutes of this exercise.',
    userContext: { userExperienceLevel: 'beginner' },
    shouldFilter: true,
    expectedReason: 'exceeds beginner limits'
  },
  {
    category: 'Conservative Override',
    description: 'Should allow safe beginner content',
    input: 'Begin with 10 minutes of gentle practice.',
    userContext: { userExperienceLevel: 'beginner' },
    shouldFilter: false
  }
];

async function runTests() {
  console.log(chalk.blue('\n🧪 Response Filter Test Suite\n'));
  console.log(chalk.gray('Testing Story 3.6: Implement Response Filtering\n'));
  
  const results = {
    passed: 0,
    failed: 0,
    errors: []
  };
  
  for (const testCase of testCases) {
    try {
      const userContext = testCase.userContext || {
        userId: 'test-user',
        sessionType: 'test',
        userExperienceLevel: 'intermediate'
      };
      
      const result = await filterResponse(testCase.input, userContext);
      
      const testPassed = testCase.shouldFilter 
        ? (result.wasFiltered === true && result.filterReasons.some(r => r.includes(testCase.expectedReason)))
        : (result.wasFiltered === false);
      
      if (testPassed) {
        console.log(chalk.green(`✅ [${testCase.category}] ${testCase.description}`));
        results.passed++;
      } else {
        console.log(chalk.red(`❌ [${testCase.category}] ${testCase.description}`));
        console.log(chalk.yellow(`   Expected: ${testCase.shouldFilter ? 'filtered' : 'not filtered'}`));
        console.log(chalk.yellow(`   Got: ${result.wasFiltered ? 'filtered' : 'not filtered'}`));
        if (result.filterReasons.length > 0) {
          console.log(chalk.yellow(`   Reasons: ${result.filterReasons.join(', ')}`));
        }
        results.failed++;
        results.errors.push(`${testCase.category}: ${testCase.description}`);
      }
    } catch (error) {
      console.log(chalk.red(`❌ [${testCase.category}] ${testCase.description} - ERROR`));
      console.log(chalk.red(`   ${error.message}`));
      results.failed++;
      results.errors.push(`${testCase.category}: ${testCase.description} - ${error.message}`);
    }
  }
  
  console.log(chalk.blue('\n📊 Test Results Summary\n'));
  console.log(chalk.white('Total Tests:    '), testCases.length);
  console.log(chalk.green('Passed:         '), results.passed);
  console.log(chalk.red('Failed:         '), results.failed);
  console.log(chalk.white('Success Rate:   '), 
    `${Math.round((results.passed / testCases.length) * 100)}%`);
  
  if (results.failed > 0) {
    console.log(chalk.red('\n❌ Failed Tests:'));
    results.errors.forEach(error => {
      console.log(chalk.red(`   - ${error}`));
    });
  }
  
  if (results.passed === testCases.length) {
    console.log(chalk.green('\n✨ All tests passed! Response filtering is working correctly.'));
  } else {
    console.log(chalk.red('\n⚠️ Some tests failed. Please review the filter implementation.'));
  }
  
  process.exit(results.failed > 0 ? 1 : 0);
}

runTests().catch(console.error);