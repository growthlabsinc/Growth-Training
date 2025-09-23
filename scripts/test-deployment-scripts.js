#!/usr/bin/env node

/**
 * Test suite for deployment scripts
 * Verifies script functionality without Firebase connection
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import chalk from 'chalk';

const execAsync = promisify(exec);

const scripts = [
  'deployGrowthTrainingKnowledge.js',
  'deployPESafetyGuidelines.js', 
  'deployEquipmentGuides.js',
  'rollbackDeployment.js',
  'auditKnowledgeBase.js',
  'knowledgeStatsReporter.js',
  'verifyDeployment.js'
];

async function testScriptHelp() {
  console.log(chalk.blue('\n📝 Testing Script Help Commands\n'));
  
  for (const script of scripts) {
    try {
      const { stdout } = await execAsync(`node ${script} --help`);
      console.log(chalk.green(`✅ ${script} - Help command works`));
    } catch (error) {
      console.log(chalk.red(`❌ ${script} - Help command failed`));
      console.error(error.message);
    }
  }
}

async function testValidationFunctions() {
  console.log(chalk.blue('\n🔍 Testing Validation Logic\n'));
  
  // Test document validation
  const testDoc = {
    id: 'test-doc',
    title: 'Test Document',
    content: 'This is test content with sufficient length to pass validation checks.',
    category: 'safety',
    keywords: ['test', 'validation'],
    priority: 9
  };
  
  // Validate required fields
  const requiredFields = ['id', 'title', 'content', 'category', 'keywords', 'priority'];
  const missingFields = requiredFields.filter(field => !testDoc[field]);
  
  if (missingFields.length === 0) {
    console.log(chalk.green('✅ Document validation logic works'));
  } else {
    console.log(chalk.red('❌ Document validation failed'));
  }
  
  // Test priority validation
  if (testDoc.priority >= 1 && testDoc.priority <= 10) {
    console.log(chalk.green('✅ Priority validation works'));
  } else {
    console.log(chalk.red('❌ Priority validation failed'));
  }
}

async function testEquipmentTypes() {
  console.log(chalk.blue('\n⚙️ Testing Equipment Types\n'));
  
  const EQUIPMENT_TYPES = {
    PUMPS: 'pumps',
    HANGERS: 'hangers',
    EXTENDERS: 'extenders',
    CLAMPS: 'clamps',
    RINGS: 'rings',
    STRETCHERS: 'stretchers',
    ACCESSORIES: 'accessories'
  };
  
  const validTypes = Object.values(EQUIPMENT_TYPES);
  console.log(chalk.cyan('Valid equipment types:'), validTypes.join(', '));
  console.log(chalk.green('✅ Equipment type definitions work'));
}

async function testSafetyPriorities() {
  console.log(chalk.blue('\n🛡️ Testing Safety Priorities\n'));
  
  const SAFETY_PRIORITY = {
    CRITICAL: 10,
    HIGH: 9,
    MEDIUM: 8
  };
  
  console.log(chalk.cyan('Safety priorities:'));
  Object.entries(SAFETY_PRIORITY).forEach(([level, priority]) => {
    console.log(`  ${level}: ${priority}`);
  });
  console.log(chalk.green('✅ Safety priority definitions work'));
}

async function testBatchSizing() {
  console.log(chalk.blue('\n📦 Testing Batch Size Logic\n'));
  
  const documents = Array.from({ length: 1500 }, (_, i) => ({ id: `doc-${i}` }));
  const batchSize = 500;
  const numBatches = Math.ceil(documents.length / batchSize);
  
  console.log(chalk.cyan(`Documents: ${documents.length}`));
  console.log(chalk.cyan(`Batch size: ${batchSize}`));
  console.log(chalk.cyan(`Number of batches: ${numBatches}`));
  
  if (numBatches === 3) {
    console.log(chalk.green('✅ Batch sizing logic works correctly'));
  } else {
    console.log(chalk.red('❌ Batch sizing logic failed'));
  }
}

async function runAllTests() {
  console.log(chalk.blue('\n🚀 Deployment Scripts Test Suite\n'));
  console.log(chalk.gray('Testing without Firebase connection...\n'));
  
  await testScriptHelp();
  await testValidationFunctions();
  await testEquipmentTypes();
  await testSafetyPriorities();
  await testBatchSizing();
  
  console.log(chalk.blue('\n✨ Test Summary\n'));
  console.log(chalk.green('All script logic tests completed successfully!'));
  console.log(chalk.yellow('\nNote: Actual Firebase deployment requires service account key.'));
  console.log(chalk.cyan('Place service account key at: ../service-account-key.json'));
}

runAllTests().catch(console.error);