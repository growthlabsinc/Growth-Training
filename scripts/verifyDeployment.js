#!/usr/bin/env node

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { program } from 'commander';
import chalk from 'chalk';

// Firebase Configuration
const PROJECT_ID = 'growth-training-app';
const COLLECTION_NAME = 'ai_coach_knowledge';
const DEPLOYMENTS_COLLECTION = 'deployments';
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'service-account-key.json');

// Initialize Firebase Admin
function initializeFirebase() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(chalk.red(`❌ Service account key not found at: ${SERVICE_ACCOUNT_PATH}`));
    console.error(chalk.yellow('Please ensure you have a service account key file.'));
    console.error(chalk.yellow('Download from Firebase Console > Project Settings > Service Accounts'));
    process.exit(1);
  }

  try {
    const serviceAccount = JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8'));

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID
    });

    console.log(chalk.green(`✅ Firebase Admin initialized for project: ${PROJECT_ID}`));
    return admin.firestore();
  } catch (error) {
    console.error(chalk.red('❌ Failed to initialize Firebase Admin:'), error.message);
    process.exit(1);
  }
}

// Verify deployment success
async function verifyDeployment(db, deploymentId) {
  console.log(chalk.blue('\n🔍 Verifying Deployment\n'));

  // Get deployment record
  const deploymentDoc = await db.collection(DEPLOYMENTS_COLLECTION).doc(deploymentId).get();
  
  if (!deploymentDoc.exists) {
    console.error(chalk.red(`❌ Deployment record not found: ${deploymentId}`));
    return { success: false, errors: ['Deployment record not found'] };
  }

  const deployment = deploymentDoc.data();
  console.log(chalk.cyan('📄 Deployment Details:'));
  console.log(chalk.white(`   ID: ${deploymentId}`));
  console.log(chalk.white(`   Script: ${deployment.scriptName}`));
  console.log(chalk.white(`   Timestamp: ${deployment.timestamp?.toDate?.().toISOString() || 'N/A'}`));
  console.log(chalk.white(`   Documents: ${deployment.successful} successful, ${deployment.failed} failed\n`));

  const verification = {
    deploymentId,
    success: true,
    checks: [],
    errors: [],
    warnings: []
  };

  // Check 1: Verify document count
  console.log(chalk.cyan('✓ Checking document count...'));
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('deployedBy', '==', deployment.scriptName)
    .get();
  
  const actualCount = snapshot.size;
  const expectedCount = deployment.successful || 0;
  
  if (actualCount === expectedCount) {
    verification.checks.push({
      name: 'Document Count',
      status: 'PASSED',
      message: `Found ${actualCount} documents as expected`
    });
    console.log(chalk.green(`   ✅ Document count matches: ${actualCount}`));
  } else {
    verification.errors.push(`Document count mismatch: expected ${expectedCount}, found ${actualCount}`);
    verification.checks.push({
      name: 'Document Count',
      status: 'FAILED',
      message: `Expected ${expectedCount}, found ${actualCount}`
    });
    console.log(chalk.red(`   ❌ Document count mismatch: expected ${expectedCount}, found ${actualCount}`));
  }

  // Check 2: Verify document integrity
  console.log(chalk.cyan('\n✓ Checking document integrity...'));
  let integrityErrors = 0;
  const requiredFields = ['title', 'content', 'category', 'keywords', 'priority'];
  
  snapshot.forEach(doc => {
    const data = doc.data();
    const missingFields = requiredFields.filter(field => !data[field]);
    
    if (missingFields.length > 0) {
      integrityErrors++;
      verification.errors.push(`Document ${doc.id} missing fields: ${missingFields.join(', ')}`);
    }
  });

  if (integrityErrors === 0) {
    verification.checks.push({
      name: 'Document Integrity',
      status: 'PASSED',
      message: 'All documents have required fields'
    });
    console.log(chalk.green('   ✅ All documents have required fields'));
  } else {
    verification.checks.push({
      name: 'Document Integrity',
      status: 'FAILED',
      message: `${integrityErrors} documents have missing fields`
    });
    console.log(chalk.red(`   ❌ ${integrityErrors} documents have missing fields`));
  }

  // Check 3: Verify version consistency
  console.log(chalk.cyan('\n✓ Checking version consistency...'));
  let versionIssues = 0;
  
  snapshot.forEach(doc => {
    const data = doc.data();
    if (!data.version) {
      versionIssues++;
      verification.warnings.push(`Document ${doc.id} missing version field`);
    }
  });

  if (versionIssues === 0) {
    verification.checks.push({
      name: 'Version Tracking',
      status: 'PASSED',
      message: 'All documents have version information'
    });
    console.log(chalk.green('   ✅ All documents have version information'));
  } else {
    verification.checks.push({
      name: 'Version Tracking',
      status: 'WARNING',
      message: `${versionIssues} documents missing version`
    });
    console.log(chalk.yellow(`   ⚠️  ${versionIssues} documents missing version information`));
  }

  // Check 4: Verify priority ranges
  console.log(chalk.cyan('\n✓ Checking priority values...'));
  let priorityIssues = 0;
  
  snapshot.forEach(doc => {
    const data = doc.data();
    if (data.priority && (data.priority < 1 || data.priority > 10)) {
      priorityIssues++;
      verification.errors.push(`Document ${doc.id} has invalid priority: ${data.priority}`);
    }
  });

  if (priorityIssues === 0) {
    verification.checks.push({
      name: 'Priority Validation',
      status: 'PASSED',
      message: 'All priorities within valid range (1-10)'
    });
    console.log(chalk.green('   ✅ All priorities within valid range'));
  } else {
    verification.checks.push({
      name: 'Priority Validation',
      status: 'FAILED',
      message: `${priorityIssues} documents have invalid priorities`
    });
    console.log(chalk.red(`   ❌ ${priorityIssues} documents have invalid priorities`));
  }

  // Check 5: Verify safety content
  console.log(chalk.cyan('\n✓ Checking safety content...'));
  const safetyDocs = await db.collection(COLLECTION_NAME)
    .where('category', '==', 'safety')
    .where('deployedBy', '==', deployment.scriptName)
    .get();
  
  let safetyIssues = 0;
  safetyDocs.forEach(doc => {
    const data = doc.data();
    const contentLower = (data.content || '').toLowerCase();
    
    // Safety docs should have high priority
    if (data.priority < 8) {
      safetyIssues++;
      verification.warnings.push(`Safety document ${doc.id} has low priority: ${data.priority}`);
    }
    
    // Check for disclaimer
    if (!contentLower.includes('medical') && !contentLower.includes('physician')) {
      safetyIssues++;
      verification.warnings.push(`Safety document ${doc.id} missing medical disclaimer`);
    }
  });

  if (safetyDocs.size === 0) {
    console.log(chalk.gray('   − No safety documents in this deployment'));
  } else if (safetyIssues === 0) {
    verification.checks.push({
      name: 'Safety Content',
      status: 'PASSED',
      message: `All ${safetyDocs.size} safety documents properly configured`
    });
    console.log(chalk.green(`   ✅ All ${safetyDocs.size} safety documents properly configured`));
  } else {
    verification.checks.push({
      name: 'Safety Content',
      status: 'WARNING',
      message: `${safetyIssues} issues in safety documents`
    });
    console.log(chalk.yellow(`   ⚠️  ${safetyIssues} issues in safety documents`));
  }

  // Determine overall success
  verification.success = verification.errors.length === 0;

  return verification;
}

// Verify latest deployment
async function verifyLatestDeployment(db) {
  const deployments = await db.collection(DEPLOYMENTS_COLLECTION)
    .orderBy('timestamp', 'desc')
    .limit(1)
    .get();

  if (deployments.empty) {
    console.error(chalk.red('❌ No deployments found'));
    return null;
  }

  const latestDeployment = deployments.docs[0];
  return verifyDeployment(db, latestDeployment.id);
}

// Verify all recent deployments
async function verifyRecentDeployments(db, limit = 5) {
  console.log(chalk.blue(`\n🔍 Verifying ${limit} Recent Deployments\n`));

  const deployments = await db.collection(DEPLOYMENTS_COLLECTION)
    .orderBy('timestamp', 'desc')
    .limit(limit)
    .get();

  const results = [];
  
  for (const doc of deployments.docs) {
    console.log(chalk.gray('\n' + '─'.repeat(60)));
    const verification = await verifyDeployment(db, doc.id);
    results.push(verification);
  }

  return results;
}

// Generate verification report
function generateReport(verification) {
  console.log(chalk.blue('\n📄 Verification Report\n'));
  console.log(chalk.gray('═'.repeat(60)));
  
  // Summary
  const passedChecks = verification.checks.filter(c => c.status === 'PASSED').length;
  const failedChecks = verification.checks.filter(c => c.status === 'FAILED').length;
  const warningChecks = verification.checks.filter(c => c.status === 'WARNING').length;
  
  console.log(chalk.cyan('SUMMARY'));
  console.log(chalk.white(`   Deployment ID: ${verification.deploymentId}`));
  console.log(chalk.white(`   Overall Status: ${verification.success ? chalk.green('SUCCESS') : chalk.red('FAILED')}`));
  console.log(chalk.white(`   Checks: ${chalk.green(passedChecks + ' passed')}, ${chalk.red(failedChecks + ' failed')}, ${chalk.yellow(warningChecks + ' warnings')}`));
  
  // Check details
  console.log(chalk.cyan('\nCHECK DETAILS'));
  verification.checks.forEach(check => {
    const statusColor = check.status === 'PASSED' ? chalk.green : 
                       check.status === 'FAILED' ? chalk.red : chalk.yellow;
    const statusIcon = check.status === 'PASSED' ? '✅' : 
                       check.status === 'FAILED' ? '❌' : '⚠️';
    console.log(`   ${statusIcon} ${check.name.padEnd(20)} ${statusColor(check.status.padEnd(8))} ${check.message}`);
  });
  
  // Errors
  if (verification.errors.length > 0) {
    console.log(chalk.red('\nERRORS'));
    verification.errors.forEach(error => {
      console.log(chalk.red(`   • ${error}`));
    });
  }
  
  // Warnings
  if (verification.warnings.length > 0) {
    console.log(chalk.yellow('\nWARNINGS'));
    verification.warnings.forEach(warning => {
      console.log(chalk.yellow(`   • ${warning}`));
    });
  }
  
  console.log(chalk.gray('\n' + '═'.repeat(60)));
  
  // Recommendations
  if (!verification.success) {
    console.log(chalk.cyan('\nRECOMMENDATIONS'));
    console.log(chalk.white('   1. Review deployment logs for errors'));
    console.log(chalk.white('   2. Run audit script to identify specific issues'));
    console.log(chalk.white('   3. Consider rolling back if critical errors persist'));
    console.log(chalk.white('   4. Re-deploy after fixing identified issues'));
  }
}

// Main function
async function main(options) {
  console.log(chalk.blue('\n✔️  Deployment Verification Tool\n'));

  const db = initializeFirebase();

  let verification;

  if (options.deployment) {
    // Verify specific deployment
    verification = await verifyDeployment(db, options.deployment);
  } else if (options.all) {
    // Verify multiple deployments
    const results = await verifyRecentDeployments(db, parseInt(options.all));
    
    // Summary of all verifications
    console.log(chalk.blue('\n📋 Overall Summary\n'));
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    
    console.log(chalk.white(`   Total Verified: ${results.length}`));
    console.log(chalk.green(`   Successful: ${successful}`));
    if (failed > 0) {
      console.log(chalk.red(`   Failed: ${failed}`));
    }
    
    return;
  } else {
    // Verify latest deployment
    verification = await verifyLatestDeployment(db);
  }

  if (verification) {
    generateReport(verification);
    
    // Export report if requested
    if (options.export) {
      const reportPath = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'reports', `verification_${verification.deploymentId}.json`);
      const reportDir = path.dirname(reportPath);
      
      if (!fs.existsSync(reportDir)) {
        fs.mkdirSync(reportDir, { recursive: true });
      }
      
      fs.writeFileSync(reportPath, JSON.stringify(verification, null, 2));
      console.log(chalk.green(`\n📄 Report exported to: ${reportPath}`));
    }
    
    // Exit with appropriate code
    process.exit(verification.success ? 0 : 1);
  }
}

// CLI setup
program
  .name('verifyDeployment')
  .description('Verify knowledge base deployments')
  .version('1.0.0');

program
  .option('-d, --deployment <id>', 'Verify specific deployment by ID')
  .option('-a, --all <number>', 'Verify multiple recent deployments', '5')
  .option('-e, --export', 'Export verification report to file')
  .action((options) => {
    main(options);
  });

program.parse();