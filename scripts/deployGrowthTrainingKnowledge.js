#!/usr/bin/env node

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { program } from 'commander';
import cliProgress from 'cli-progress';
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

// Validation function
function validateKnowledgeDocument(doc) {
  const errors = [];

  // Required fields
  const requiredFields = ['id', 'title', 'content', 'category', 'keywords', 'priority'];
  requiredFields.forEach(field => {
    if (!doc[field]) {
      errors.push(`Missing required field: ${field}`);
    }
  });

  // Validate priority (1-10 scale)
  if (doc.priority && (doc.priority < 1 || doc.priority > 10)) {
    errors.push(`Priority must be between 1-10, got: ${doc.priority}`);
  }

  // Validate keywords is array
  if (doc.keywords && !Array.isArray(doc.keywords)) {
    errors.push('Keywords must be an array');
  }

  // Validate category
  const validCategories = ['safety', 'length', 'girth', 'eq', 'equipment', 'recovery', 'general'];
  if (doc.category && !validCategories.includes(doc.category)) {
    errors.push(`Invalid category: ${doc.category}. Must be one of: ${validCategories.join(', ')}`);
  }

  return errors;
}

// Batch upload function with progress tracking
async function batchUploadDocuments(db, documents, options = {}) {
  const { dryRun = false, verbose = false } = options;

  // Create progress bar
  const progressBar = new cliProgress.SingleBar({
    format: 'Uploading |' + chalk.cyan('{bar}') + '| {percentage}% || {value}/{total} Documents || {document}',
    barCompleteChar: '\u2588',
    barIncompleteChar: '\u2591',
    hideCursor: true
  });

  const results = {
    successful: 0,
    failed: 0,
    errors: []
  };

  if (dryRun) {
    console.log(chalk.yellow('\n🔍 DRY RUN MODE - No actual changes will be made\n'));
  }

  progressBar.start(documents.length, 0, { document: 'Starting...' });

  // Process in batches of 500 (Firestore limit)
  const batchSize = 500;
  for (let i = 0; i < documents.length; i += batchSize) {
    const batch = db.batch();
    const batchDocs = documents.slice(i, Math.min(i + batchSize, documents.length));

    for (const doc of batchDocs) {
      progressBar.update(i + batchDocs.indexOf(doc) + 1, { document: doc.title || doc.id });

      // Validate document
      const validationErrors = validateKnowledgeDocument(doc);
      if (validationErrors.length > 0) {
        results.failed++;
        results.errors.push({
          document: doc.id,
          errors: validationErrors
        });

        if (verbose) {
          console.error(chalk.red(`\n❌ Validation failed for ${doc.id}:`), validationErrors);
        }
        continue;
      }

      // Add metadata
      const enrichedDoc = {
        ...doc,
        version: doc.version || 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        deployedBy: 'deployGrowthTrainingKnowledge.js'
      };

      if (!dryRun) {
        const docRef = db.collection(COLLECTION_NAME).doc(doc.id);
        batch.set(docRef, enrichedDoc, { merge: true });
      }

      results.successful++;
    }

    // Commit batch
    if (!dryRun && batchDocs.length > 0) {
      try {
        await batch.commit();
      } catch (error) {
        console.error(chalk.red('\n❌ Batch commit failed:'), error.message);
        results.failed += batchDocs.length;
        results.successful -= batchDocs.length;
      }
    }
  }

  progressBar.stop();

  return results;
}

// Load knowledge documents from file or directory
function loadKnowledgeDocuments(sourcePath) {
  const documents = [];

  if (!fs.existsSync(sourcePath)) {
    console.error(chalk.red(`❌ Source path not found: ${sourcePath}`));
    return documents;
  }

  const stats = fs.statSync(sourcePath);

  if (stats.isFile()) {
    // Load single file
    if (sourcePath.endsWith('.json')) {
      try {
        const content = fs.readFileSync(sourcePath, 'utf8');
        const data = JSON.parse(content);
        documents.push(...(Array.isArray(data) ? data : [data]));
      } catch (error) {
        console.error(chalk.red(`❌ Failed to load file ${sourcePath}:`), error.message);
      }
    }
  } else if (stats.isDirectory()) {
    // Load all JSON files from directory
    const files = fs.readdirSync(sourcePath)
      .filter(file => file.endsWith('.json'));

    files.forEach(file => {
      const filePath = path.join(sourcePath, file);
      try {
        const content = fs.readFileSync(filePath, 'utf8');
        const data = JSON.parse(content);
        documents.push(...(Array.isArray(data) ? data : [data]));
      } catch (error) {
        console.error(chalk.red(`❌ Failed to load file ${filePath}:`), error.message);
      }
    });
  }

  return documents;
}

// Create deployment metadata
async function recordDeployment(db, results, options = {}) {
  const deploymentRecord = {
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    successful: results.successful,
    failed: results.failed,
    errors: results.errors,
    scriptName: 'deployGrowthTrainingKnowledge.js',
    options: options
  };

  try {
    await db.collection('deployments').add(deploymentRecord);
    console.log(chalk.green('✅ Deployment recorded'));
  } catch (error) {
    console.error(chalk.red('❌ Failed to record deployment:'), error.message);
  }
}

// Main deployment function
async function deploy(source, options) {
  console.log(chalk.blue('\n🚀 Growth Training Knowledge Deployment\n'));

  // Initialize Firebase
  const db = initializeFirebase();

  // Load knowledge documents
  console.log(chalk.cyan('📚 Loading knowledge documents...'));
  const documents = loadKnowledgeDocuments(source);

  if (documents.length === 0) {
    console.error(chalk.red('❌ No documents found to deploy'));
    process.exit(1);
  }

  console.log(chalk.green(`✅ Loaded ${documents.length} documents\n`));

  // Sort by priority (safety content first)
  documents.sort((a, b) => (b.priority || 0) - (a.priority || 0));

  // Deploy documents
  const results = await batchUploadDocuments(db, documents, options);

  // Display results
  console.log(chalk.blue('\n📊 Deployment Summary:'));
  console.log(chalk.green(`✅ Successful: ${results.successful}`));
  if (results.failed > 0) {
    console.log(chalk.red(`❌ Failed: ${results.failed}`));

    if (options.verbose && results.errors.length > 0) {
      console.log(chalk.red('\n❌ Errors:'));
      results.errors.forEach(err => {
        console.log(chalk.red(`  ${err.document}:`), err.errors);
      });
    }
  }

  // Record deployment (unless dry run)
  if (!options.dryRun) {
    await recordDeployment(db, results, options);
  }

  // Exit with appropriate code
  process.exit(results.failed > 0 ? 1 : 0);
}

// CLI setup
program
  .name('deployGrowthTrainingKnowledge')
  .description('Deploy Growth Training knowledge documents to Firebase')
  .version('1.0.0');

program
  .argument('<source>', 'Path to JSON file or directory containing knowledge documents')
  .option('-d, --dry-run', 'Run without making actual changes')
  .option('-v, --verbose', 'Show detailed error messages')
  .option('-c, --category <category>', 'Deploy only specific category')
  .option('-p, --priority <priority>', 'Deploy only documents with minimum priority', parseInt)
  .action((source, options) => {
    deploy(source, options);
  });

program.parse();