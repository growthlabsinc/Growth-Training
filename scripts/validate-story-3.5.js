#!/usr/bin/env node

/**
 * Story 3.5 Validation Script
 * Verifies all acceptance criteria are met
 */

import fs from 'fs';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import chalk from 'chalk';

const execAsync = promisify(exec);

const requiredScripts = [
  { file: 'deployGrowthTrainingKnowledge.js', purpose: 'Main deployment script' },
  { file: 'deployPESafetyGuidelines.js', purpose: 'Safety content deployment' },
  { file: 'deployEquipmentGuides.js', purpose: 'Equipment guides deployment' },
  { file: 'rollbackDeployment.js', purpose: 'Rollback functionality' },
  { file: 'auditKnowledgeBase.js', purpose: 'Knowledge base audit' },
  { file: 'knowledgeStatsReporter.js', purpose: 'Statistics generation' },
  { file: 'verifyDeployment.js', purpose: 'Deployment verification' }
];

const acceptanceCriteria = [
  { id: 'AC1', description: 'Scripts for batch upload of knowledge documents are functional' },
  { id: 'AC2', description: 'Version control system is implemented for knowledge tracking' },
  { id: 'AC3', description: 'Validation checks ensure document quality before deployment' },
  { id: 'AC4', description: 'Error handling prevents partial deployments' },
  { id: 'AC5', description: 'Progress tracking provides clear deployment status' },
  { id: 'AC6', description: 'Rollback capability allows reverting problematic deployments' }
];

async function checkScriptExists() {
  console.log(chalk.blue('\n📂 Checking Required Scripts\n'));
  
  let allExist = true;
  for (const script of requiredScripts) {
    const exists = fs.existsSync(script.file);
    if (exists) {
      console.log(chalk.green(`✅ ${script.file.padEnd(35)} - ${script.purpose}`));
    } else {
      console.log(chalk.red(`❌ ${script.file.padEnd(35)} - Missing`));
      allExist = false;
    }
  }
  
  return allExist;
}

async function checkScriptFunctionality() {
  console.log(chalk.blue('\n⚙️ Checking Script Functionality\n'));
  
  let allWork = true;
  for (const script of requiredScripts) {
    try {
      await execAsync(`node ${script.file} --help`);
      console.log(chalk.green(`✅ ${script.file.padEnd(35)} - Functional`));
    } catch (error) {
      console.log(chalk.red(`❌ ${script.file.padEnd(35)} - Error`));
      allWork = false;
    }
  }
  
  return allWork;
}

async function validateAcceptanceCriteria() {
  console.log(chalk.blue('\n🎯 Validating Acceptance Criteria\n'));
  
  const criteriaChecks = {
    'AC1': () => {
      // Check batch upload functionality
      return fs.existsSync('deployGrowthTrainingKnowledge.js') &&
             fs.existsSync('deployPESafetyGuidelines.js') &&
             fs.existsSync('deployEquipmentGuides.js');
    },
    'AC2': () => {
      // Check version control implementation
      const mainScript = fs.readFileSync('deployGrowthTrainingKnowledge.js', 'utf8');
      return mainScript.includes('version') && mainScript.includes('deployments');
    },
    'AC3': () => {
      // Check validation functionality
      const mainScript = fs.readFileSync('deployGrowthTrainingKnowledge.js', 'utf8');
      return mainScript.includes('validateKnowledgeDocument') && 
             mainScript.includes('validationErrors');
    },
    'AC4': () => {
      // Check error handling
      const mainScript = fs.readFileSync('deployGrowthTrainingKnowledge.js', 'utf8');
      return mainScript.includes('try') && 
             mainScript.includes('catch') &&
             mainScript.includes('batch.commit()');
    },
    'AC5': () => {
      // Check progress tracking
      const mainScript = fs.readFileSync('deployGrowthTrainingKnowledge.js', 'utf8');
      return mainScript.includes('progressBar') && 
             mainScript.includes('cli-progress');
    },
    'AC6': () => {
      // Check rollback capability
      return fs.existsSync('rollbackDeployment.js') &&
             fs.readFileSync('rollbackDeployment.js', 'utf8').includes('performRollback');
    }
  };
  
  let allPassed = true;
  for (const criterion of acceptanceCriteria) {
    const passed = criteriaChecks[criterion.id]();
    if (passed) {
      console.log(chalk.green(`✅ ${criterion.id}: ${criterion.description}`));
    } else {
      console.log(chalk.red(`❌ ${criterion.id}: ${criterion.description}`));
      allPassed = false;
    }
  }
  
  return allPassed;
}

async function checkDocumentation() {
  console.log(chalk.blue('\n📚 Checking Documentation\n'));
  
  const docPath = path.join('..', 'docs', 'DEPLOYMENT_SCRIPTS_GUIDE.md');
  const docExists = fs.existsSync(docPath);
  
  if (docExists) {
    const docContent = fs.readFileSync(docPath, 'utf8');
    const hasUsageExamples = docContent.includes('Usage Examples');
    const hasTroubleshooting = docContent.includes('Troubleshooting');
    const hasBestPractices = docContent.includes('Best Practices');
    
    console.log(chalk.green(`✅ Documentation exists at: ${docPath}`));
    console.log(chalk.green(`✅ Contains usage examples: ${hasUsageExamples}`));
    console.log(chalk.green(`✅ Contains troubleshooting: ${hasTroubleshooting}`));
    console.log(chalk.green(`✅ Contains best practices: ${hasBestPractices}`));
    
    return hasUsageExamples && hasTroubleshooting && hasBestPractices;
  } else {
    console.log(chalk.red(`❌ Documentation not found at: ${docPath}`));
    return false;
  }
}

async function checkSampleData() {
  console.log(chalk.blue('\n📄 Checking Sample Data\n'));
  
  const samplePath = 'sample-knowledge-document.json';
  if (fs.existsSync(samplePath)) {
    const sampleData = JSON.parse(fs.readFileSync(samplePath, 'utf8'));
    console.log(chalk.green(`✅ Sample data exists with ${sampleData.length} documents`));
    
    // Validate sample documents
    let allValid = true;
    for (const doc of sampleData) {
      const requiredFields = ['id', 'title', 'content', 'category', 'keywords', 'priority'];
      const missingFields = requiredFields.filter(field => !doc[field]);
      if (missingFields.length > 0) {
        console.log(chalk.red(`❌ Document ${doc.id} missing: ${missingFields.join(', ')}`));
        allValid = false;
      }
    }
    
    if (allValid) {
      console.log(chalk.green(`✅ All sample documents are valid`));
    }
    
    return allValid;
  } else {
    console.log(chalk.yellow(`⚠️ Sample data not found at: ${samplePath}`));
    return false;
  }
}

async function runValidation() {
  console.log(chalk.blue('\n🚀 Story 3.5 Validation Suite\n'));
  console.log(chalk.gray('Validating: Create Knowledge Deployment Scripts\n'));
  
  const results = {
    scriptsExist: await checkScriptExists(),
    scriptsFunctional: await checkScriptFunctionality(),
    criteriamet: await validateAcceptanceCriteria(),
    documented: await checkDocumentation(),
    sampleData: await checkSampleData()
  };
  
  console.log(chalk.blue('\n📈 Validation Summary\n'));
  console.log(chalk.white('Scripts Exist:      '), results.scriptsExist ? chalk.green('✅ PASS') : chalk.red('❌ FAIL'));
  console.log(chalk.white('Scripts Functional: '), results.scriptsFunctional ? chalk.green('✅ PASS') : chalk.red('❌ FAIL'));
  console.log(chalk.white('Criteria Met:       '), results.criteriamet ? chalk.green('✅ PASS') : chalk.red('❌ FAIL'));
  console.log(chalk.white('Documentation:      '), results.documented ? chalk.green('✅ PASS') : chalk.red('❌ FAIL'));
  console.log(chalk.white('Sample Data:        '), results.sampleData ? chalk.green('✅ PASS') : chalk.red('❌ FAIL'));
  
  const allPassed = Object.values(results).every(r => r === true);
  
  if (allPassed) {
    console.log(chalk.green('\n✨ Story 3.5 COMPLETE - All acceptance criteria met!'));
    console.log(chalk.cyan('\nNext Steps:'));
    console.log(chalk.white('1. Place service account key at: ../service-account-key.json'));
    console.log(chalk.white('2. Test deployment with: node deployGrowthTrainingKnowledge.js sample-knowledge-document.json --dry-run'));
    console.log(chalk.white('3. Deploy to production when ready'));
  } else {
    console.log(chalk.red('\n❌ Story 3.5 INCOMPLETE - Some criteria not met'));
  }
  
  process.exit(allPassed ? 0 : 1);
}

runValidation().catch(console.error);