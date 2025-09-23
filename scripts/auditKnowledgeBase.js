#!/usr/bin/env node

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { program } from 'commander';
import chalk from 'chalk';

// Firebase Configuration
const PROJECT_ID = 'growth-training-app';
const COLLECTION_NAME = 'ai_coach_knowledge';
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

// Audit knowledge base for integrity issues
async function auditKnowledgeBase(db, options = {}) {
  console.log(chalk.blue('\n🔍 Knowledge Base Audit\n'));

  const snapshot = await db.collection(COLLECTION_NAME).get();
  const documents = [];
  const issues = {
    missingFields: [],
    invalidPriority: [],
    missingKeywords: [],
    shortContent: [],
    duplicateIds: new Set(),
    missingCategory: [],
    noVersion: [],
    noTimestamp: []
  };

  const stats = {
    total: 0,
    byCategory: {},
    byPriority: {},
    averageContentLength: 0,
    averageKeywords: 0
  };

  // Collect all documents
  snapshot.forEach(doc => {
    const data = doc.data();
    documents.push({ id: doc.id, ...data });
    stats.total++;
  });

  // Analyze each document
  for (const doc of documents) {
    // Check required fields
    const requiredFields = ['title', 'content', 'category', 'keywords', 'priority'];
    const missingFields = requiredFields.filter(field => !doc[field]);

    if (missingFields.length > 0) {
      issues.missingFields.push({
        id: doc.id,
        missing: missingFields
      });
    }

    // Check priority range
    if (doc.priority && (doc.priority < 1 || doc.priority > 10)) {
      issues.invalidPriority.push({
        id: doc.id,
        priority: doc.priority
      });
    }

    // Check keywords
    if (!doc.keywords || doc.keywords.length === 0) {
      issues.missingKeywords.push(doc.id);
    }

    // Check content length
    if (doc.content && doc.content.length < 100) {
      issues.shortContent.push({
        id: doc.id,
        length: doc.content.length
      });
    }

    // Check for category
    if (!doc.category) {
      issues.missingCategory.push(doc.id);
    }

    // Check version
    if (!doc.version) {
      issues.noVersion.push(doc.id);
    }

    // Check timestamp
    if (!doc.updatedAt) {
      issues.noTimestamp.push(doc.id);
    }

    // Collect stats
    stats.byCategory[doc.category] = (stats.byCategory[doc.category] || 0) + 1;
    stats.byPriority[doc.priority] = (stats.byPriority[doc.priority] || 0) + 1;
    stats.averageContentLength += (doc.content || '').length;
    stats.averageKeywords += (doc.keywords || []).length;
  }

  // Calculate averages
  stats.averageContentLength = Math.round(stats.averageContentLength / stats.total);
  stats.averageKeywords = Math.round(stats.averageKeywords / stats.total);

  // Display results
  console.log(chalk.cyan('📊 Knowledge Base Statistics:'));
  console.log(chalk.white(`   Total Documents: ${stats.total}`));
  console.log(chalk.white(`   Average Content Length: ${stats.averageContentLength} characters`));
  console.log(chalk.white(`   Average Keywords: ${stats.averageKeywords}`));

  console.log(chalk.cyan('\n📂 Documents by Category:'));
  Object.entries(stats.byCategory).sort((a, b) => b[1] - a[1]).forEach(([category, count]) => {
    const percentage = ((count / stats.total) * 100).toFixed(1);
    console.log(chalk.white(`   ${category}: ${count} (${percentage}%)`));
  });

  console.log(chalk.cyan('\n⭐ Documents by Priority:'));
  for (let i = 10; i >= 1; i--) {
    if (stats.byPriority[i]) {
      const bar = '█'.repeat(Math.round(stats.byPriority[i] / 2));
      console.log(chalk.white(`   Priority ${i}: ${stats.byPriority[i]} ${chalk.gray(bar)}`));
    }
  }

  // Display issues
  let hasIssues = false;

  if (issues.missingFields.length > 0) {
    hasIssues = true;
    console.log(chalk.red('\n❌ Documents with Missing Fields:'));
    issues.missingFields.forEach(item => {
      console.log(chalk.red(`   ${item.id}: Missing ${item.missing.join(', ')}`));
    });
  }

  if (issues.invalidPriority.length > 0) {
    hasIssues = true;
    console.log(chalk.red('\n❌ Documents with Invalid Priority:'));
    issues.invalidPriority.forEach(item => {
      console.log(chalk.red(`   ${item.id}: Priority ${item.priority}`));
    });
  }

  if (issues.missingKeywords.length > 0) {
    hasIssues = true;
    console.log(chalk.yellow('\n⚠️  Documents Missing Keywords:'));
    console.log(chalk.yellow(`   ${issues.missingKeywords.join(', ')}`));
  }

  if (issues.shortContent.length > 0) {
    hasIssues = true;
    console.log(chalk.yellow('\n⚠️  Documents with Short Content (<100 chars):'));
    issues.shortContent.forEach(item => {
      console.log(chalk.yellow(`   ${item.id}: ${item.length} characters`));
    });
  }

  if (issues.noVersion.length > 0 && options.verbose) {
    console.log(chalk.yellow('\n⚠️  Documents without Version:'));
    console.log(chalk.yellow(`   ${issues.noVersion.join(', ')}`));
  }

  if (!hasIssues) {
    console.log(chalk.green('\n✅ No integrity issues found!'));
  } else {
    console.log(chalk.yellow(`\n⚠️  Found issues in ${
      issues.missingFields.length +
      issues.invalidPriority.length +
      issues.missingKeywords.length +
      issues.shortContent.length
    } documents`));
  }

  // Export report if requested
  if (options.export) {
    const report = {
      timestamp: new Date().toISOString(),
      stats,
      issues,
      documents: options.includeContent ? documents : undefined
    };

    const reportPath = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'reports', `audit_${Date.now()}.json`);
    const reportDir = path.dirname(reportPath);

    if (!fs.existsSync(reportDir)) {
      fs.mkdirSync(reportDir, { recursive: true });
    }

    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    console.log(chalk.green(`\n📄 Report exported to: ${reportPath}`));
  }

  return { stats, issues };
}

// Check for duplicate content
async function checkDuplicates(db) {
  console.log(chalk.blue('\n🔍 Checking for Duplicate Content...\n'));

  const snapshot = await db.collection(COLLECTION_NAME).get();
  const contentHashes = new Map();
  const titleMap = new Map();
  const duplicates = {
    content: [],
    titles: []
  };

  snapshot.forEach(doc => {
    const data = doc.data();

    // Check content duplicates
    if (data.content) {
      const contentHash = data.content.substring(0, 100).toLowerCase();
      if (contentHashes.has(contentHash)) {
        duplicates.content.push({
          id1: contentHashes.get(contentHash),
          id2: doc.id,
          preview: contentHash.substring(0, 50) + '...'
        });
      } else {
        contentHashes.set(contentHash, doc.id);
      }
    }

    // Check title duplicates
    if (data.title) {
      const titleLower = data.title.toLowerCase();
      if (titleMap.has(titleLower)) {
        duplicates.titles.push({
          title: data.title,
          ids: [titleMap.get(titleLower), doc.id]
        });
      } else {
        titleMap.set(titleLower, doc.id);
      }
    }
  });

  // Display duplicates
  if (duplicates.content.length > 0) {
    console.log(chalk.yellow('⚠️  Potential Content Duplicates:'));
    duplicates.content.forEach(dup => {
      console.log(chalk.yellow(`   ${dup.id1} ↔ ${dup.id2}`));
      console.log(chalk.gray(`      "${dup.preview}"`));
    });
  }

  if (duplicates.titles.length > 0) {
    console.log(chalk.yellow('\n⚠️  Duplicate Titles:'));
    duplicates.titles.forEach(dup => {
      console.log(chalk.yellow(`   "${dup.title}": ${dup.ids.join(', ')}`));
    });
  }

  if (duplicates.content.length === 0 && duplicates.titles.length === 0) {
    console.log(chalk.green('✅ No duplicates found'));
  }

  return duplicates;
}

// Verify search functionality
async function verifySearch(db, testQueries) {
  console.log(chalk.blue('\n🔍 Verifying Search Functionality...\n'));

  const queries = testQueries || [
    'safety',
    'pump',
    'beginner',
    'injury',
    'equipment'
  ];

  for (const query of queries) {
    const results = await db.collection(COLLECTION_NAME)
      .where('keywords', 'array-contains', query)
      .limit(5)
      .get();

    console.log(chalk.cyan(`Query: "${query}"`));
    if (results.empty) {
      console.log(chalk.yellow('   No results found'));
    } else {
      console.log(chalk.green(`   Found ${results.size} results:`));
      results.forEach(doc => {
        const data = doc.data();
        console.log(chalk.white(`     - ${data.title} (Priority: ${data.priority})`));
      });
    }
    console.log();
  }
}

// Main function
async function main(options) {
  console.log(chalk.blue('\n🔍 Knowledge Base Audit Tool\n'));

  const db = initializeFirebase();

  // Run audit
  const { stats, issues } = await auditKnowledgeBase(db, options);

  // Check duplicates if requested
  if (options.duplicates) {
    await checkDuplicates(db);
  }

  // Verify search if requested
  if (options.search) {
    const queries = options.search === true ? null : options.search.split(',');
    await verifySearch(db, queries);
  }

  // Determine exit code based on issues
  const hasIssues =
    issues.missingFields.length > 0 ||
    issues.invalidPriority.length > 0 ||
    (options.strict && (
      issues.missingKeywords.length > 0 ||
      issues.shortContent.length > 0
    ));

  process.exit(hasIssues ? 1 : 0);
}

// CLI setup
program
  .name('auditKnowledgeBase')
  .description('Audit knowledge base for integrity and quality issues')
  .version('1.0.0');

program
  .option('-e, --export', 'Export audit report to JSON file')
  .option('-c, --include-content', 'Include document content in export')
  .option('-d, --duplicates', 'Check for duplicate content')
  .option('-s, --search [queries]', 'Verify search with test queries')
  .option('-v, --verbose', 'Show all warnings')
  .option('--strict', 'Treat warnings as errors')
  .action((options) => {
    main(options);
  });

program.parse();