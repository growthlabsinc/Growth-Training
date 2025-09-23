#!/usr/bin/env node

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { program } from 'commander';
import chalk from 'chalk';
import readline from 'readline';

// Firebase Configuration
const PROJECT_ID = 'growth-training-app';
const COLLECTION_NAME = 'ai_coach_knowledge';
const BACKUP_COLLECTION = 'ai_coach_knowledge_backups';
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

// Create readline interface for user prompts
function createPrompt() {
  return readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
}

// Prompt for confirmation
async function confirmAction(message) {
  const rl = createPrompt();

  return new Promise((resolve) => {
    rl.question(chalk.yellow(`\n${message} (yes/no): `), (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y');
    });
  });
}

// List recent deployments
async function listRecentDeployments(db, limit = 10) {
  try {
    const deployments = await db
      .collection(DEPLOYMENTS_COLLECTION)
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();

    const deploymentList = [];

    console.log(chalk.cyan('\n📋 Recent Deployments:\n'));
    console.log(chalk.gray('Index | Date & Time                  | Script                        | Success/Failed'));
    console.log(chalk.gray('------|------------------------------|-------------------------------|---------------'));

    deployments.forEach((doc, index) => {
      const data = doc.data();
      const timestamp = data.timestamp ? data.timestamp.toDate() : new Date();
      const dateStr = timestamp.toISOString().replace('T', ' ').substring(0, 19);
      const scriptName = (data.scriptName || 'Unknown').padEnd(30);
      const stats = `${data.successful || 0}/${data.failed || 0}`;

      deploymentList.push({ id: doc.id, ...data, timestamp });

      console.log(
        chalk.white(`${(index + 1).toString().padStart(5)} | ${dateStr} | ${scriptName} | ${chalk.green(data.successful || 0)}/${chalk.red(data.failed || 0)}`)
      );
    });

    return deploymentList;
  } catch (error) {
    console.error(chalk.red('❌ Failed to list deployments:'), error.message);
    return [];
  }
}

// Get backup for specific deployment
async function getBackupForDeployment(db, deploymentId) {
  try {
    const backups = await db
      .collection(BACKUP_COLLECTION)
      .where('deploymentId', '==', deploymentId)
      .get();

    if (backups.empty) {
      return null;
    }

    const backupData = [];
    backups.forEach(doc => {
      backupData.push({ id: doc.id, ...doc.data() });
    });

    return backupData;
  } catch (error) {
    console.error(chalk.red('❌ Failed to retrieve backup:'), error.message);
    return null;
  }
}

// Create backup before deployment (called by deployment scripts)
async function createBackup(db, documents) {
  const backupBatch = db.batch();
  const backupTimestamp = admin.firestore.FieldValue.serverTimestamp();

  try {
    for (const doc of documents) {
      const backupRef = db.collection(BACKUP_COLLECTION).doc(`${doc.id}_${Date.now()}`);
      backupBatch.set(backupRef, {
        ...doc,
        backupTimestamp,
        originalId: doc.id
      });
    }

    await backupBatch.commit();
    return true;
  } catch (error) {
    console.error(chalk.red('❌ Failed to create backup:'), error.message);
    return false;
  }
}

// Perform rollback
async function performRollback(db, deploymentIndex, deploymentList) {
  if (deploymentIndex < 1 || deploymentIndex > deploymentList.length) {
    console.error(chalk.red('❌ Invalid deployment index'));
    return;
  }

  const deployment = deploymentList[deploymentIndex - 1];
  const deploymentDate = deployment.timestamp.toISOString().replace('T', ' ').substring(0, 19);

  console.log(chalk.yellow(`\n⚠️  Preparing to rollback deployment:`));
  console.log(chalk.cyan(`   Script: ${deployment.scriptName}`));
  console.log(chalk.cyan(`   Date: ${deploymentDate}`));
  console.log(chalk.cyan(`   Documents: ${deployment.successful} successful`));

  // Get confirmation
  const confirmed = await confirmAction('Are you sure you want to rollback this deployment?');

  if (!confirmed) {
    console.log(chalk.yellow('❌ Rollback cancelled'));
    return;
  }

  console.log(chalk.blue('\n🔄 Starting rollback process...'));

  // Method 1: Restore from backup collection
  const backupData = await getBackupForDeployment(db, deployment.id);

  if (backupData && backupData.length > 0) {
    console.log(chalk.green(`✅ Found ${backupData.length} backup documents`));

    const batch = db.batch();
    let restored = 0;

    for (const backup of backupData) {
      const docRef = db.collection(COLLECTION_NAME).doc(backup.originalId);
      const { backupTimestamp, originalId, ...restoreData } = backup;
      batch.set(docRef, restoreData);
      restored++;

      if (restored % 500 === 0) {
        await batch.commit();
      }
    }

    if (restored % 500 !== 0) {
      await batch.commit();
    }

    console.log(chalk.green(`✅ Restored ${restored} documents from backup`));
  } else {
    console.log(chalk.yellow('⚠️  No backup found for this deployment'));

    // Method 2: Restore from version history
    console.log(chalk.blue('Attempting to restore from version history...'));

    const snapshot = await db.collection(COLLECTION_NAME).get();
    let reverted = 0;
    const batch = db.batch();

    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.deployedBy === deployment.scriptName &&
          data.version && data.version > 1) {
        // Decrement version
        batch.update(doc.ref, {
          version: data.version - 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          rollbackFrom: deployment.id,
          rollbackAt: admin.firestore.FieldValue.serverTimestamp()
        });
        reverted++;
      }
    });

    if (reverted > 0) {
      await batch.commit();
      console.log(chalk.green(`✅ Reverted ${reverted} documents to previous version`));
    } else {
      console.log(chalk.red('❌ Unable to rollback - no version history found'));
      return;
    }
  }

  // Record rollback
  await db.collection(DEPLOYMENTS_COLLECTION).add({
    type: 'rollback',
    rolledBackDeployment: deployment.id,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    scriptName: 'rollbackDeployment.js'
  });

  console.log(chalk.green('\n✅ Rollback completed successfully'));
}

// Create point-in-time backup
async function createPointInTimeBackup(db) {
  console.log(chalk.blue('\n📸 Creating point-in-time backup...'));

  const snapshot = await db.collection(COLLECTION_NAME).get();
  const documents = [];

  snapshot.forEach(doc => {
    documents.push({ id: doc.id, ...doc.data() });
  });

  console.log(chalk.cyan(`Found ${documents.length} documents to backup`));

  const backupId = `backup_${Date.now()}`;
  const backupPath = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'backups', `${backupId}.json`);

  // Ensure backup directory exists
  const backupDir = path.dirname(backupPath);
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  // Save to file
  fs.writeFileSync(backupPath, JSON.stringify(documents, null, 2));

  // Also save to Firestore
  const success = await createBackup(db, documents);

  if (success) {
    console.log(chalk.green(`✅ Backup created successfully`));
    console.log(chalk.cyan(`   File: ${backupPath}`));
    console.log(chalk.cyan(`   Documents: ${documents.length}`));
  } else {
    console.log(chalk.yellow('⚠️  Backup partially successful (file saved, Firestore failed)'));
  }

  return backupPath;
}

// Restore from file backup
async function restoreFromFile(db, backupFile) {
  if (!fs.existsSync(backupFile)) {
    console.error(chalk.red(`❌ Backup file not found: ${backupFile}`));
    return;
  }

  console.log(chalk.blue(`\n📂 Restoring from backup file: ${backupFile}`));

  try {
    const content = fs.readFileSync(backupFile, 'utf8');
    const documents = JSON.parse(content);

    console.log(chalk.cyan(`Found ${documents.length} documents to restore`));

    const confirmed = await confirmAction(
      `This will restore ${documents.length} documents. Continue?`
    );

    if (!confirmed) {
      console.log(chalk.yellow('❌ Restore cancelled'));
      return;
    }

    const batch = db.batch();
    let restored = 0;

    for (const doc of documents) {
      const docRef = db.collection(COLLECTION_NAME).doc(doc.id);
      batch.set(docRef, doc);
      restored++;

      if (restored % 500 === 0) {
        await batch.commit();
      }
    }

    if (restored % 500 !== 0) {
      await batch.commit();
    }

    console.log(chalk.green(`✅ Successfully restored ${restored} documents`));

    // Record restoration
    await db.collection(DEPLOYMENTS_COLLECTION).add({
      type: 'restore',
      source: backupFile,
      documentsRestored: restored,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      scriptName: 'rollbackDeployment.js'
    });

  } catch (error) {
    console.error(chalk.red('❌ Failed to restore from file:'), error.message);
  }
}

// Main function
async function main(options) {
  console.log(chalk.red('\n⏮️  Deployment Rollback Tool\n'));

  const db = initializeFirebase();

  if (options.backup) {
    // Create backup
    await createPointInTimeBackup(db);
  } else if (options.restore) {
    // Restore from file
    await restoreFromFile(db, options.restore);
  } else if (options.list) {
    // Just list deployments
    await listRecentDeployments(db, options.limit || 10);
  } else {
    // Interactive rollback
    const deployments = await listRecentDeployments(db, options.limit || 10);

    if (deployments.length === 0) {
      console.log(chalk.yellow('No deployments found'));
      return;
    }

    const rl = createPrompt();

    rl.question(chalk.cyan('\nEnter deployment index to rollback (or 0 to cancel): '), async (answer) => {
      rl.close();

      const index = parseInt(answer);

      if (index === 0) {
        console.log(chalk.yellow('❌ Rollback cancelled'));
        return;
      }

      await performRollback(db, index, deployments);
    });
  }
}

// CLI setup
program
  .name('rollbackDeployment')
  .description('Rollback knowledge base deployments')
  .version('1.0.0');

program
  .option('-l, --list', 'List recent deployments only')
  .option('-b, --backup', 'Create a point-in-time backup')
  .option('-r, --restore <file>', 'Restore from backup file')
  .option('-n, --limit <number>', 'Number of deployments to show', parseInt, 10)
  .action((options) => {
    main(options);
  });

program.parse();