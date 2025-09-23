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

// Equipment categories
const EQUIPMENT_TYPES = {
  PUMPS: 'pumps',
  HANGERS: 'hangers',
  EXTENDERS: 'extenders',
  CLAMPS: 'clamps',
  RINGS: 'rings',
  STRETCHERS: 'stretchers',
  ACCESSORIES: 'accessories'
};

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

// Validate equipment document
function validateEquipmentDocument(doc) {
  const errors = [];

  // Required fields
  const requiredFields = ['id', 'title', 'content', 'category', 'keywords', 'priority', 'equipmentType'];
  requiredFields.forEach(field => {
    if (!doc[field]) {
      errors.push(`Missing required field: ${field}`);
    }
  });

  // Validate equipment type
  const validTypes = Object.values(EQUIPMENT_TYPES);
  if (doc.equipmentType && !validTypes.includes(doc.equipmentType)) {
    errors.push(`Invalid equipment type: ${doc.equipmentType}. Must be one of: ${validTypes.join(', ')}`);
  }

  // Equipment guides should have 'equipment' category
  if (doc.category !== 'equipment') {
    errors.push(`Equipment guides must have category: 'equipment', got: ${doc.category}`);
  }

  // Check for safety warnings
  const contentLower = (doc.content || '').toLowerCase();
  const hasSafetyWarning = ['warning', 'caution', 'safety', 'careful'].some(term => contentLower.includes(term));

  if (!hasSafetyWarning) {
    errors.push('Equipment guides must include safety warnings');
  }

  return errors;
}

// Generate sample equipment guides
function generateSampleEquipmentGuides() {
  return [
    {
      id: 'equipment-pumps-basics',
      title: 'Penis Pumps - Complete Usage Guide',
      category: 'equipment',
      equipmentType: EQUIPMENT_TYPES.PUMPS,
      content: `Complete guide to penis pump usage for PE training:

        TYPES OF PUMPS:
        1. Water pumps (Bathmate style) - Uses water for even pressure
        2. Air pumps - Traditional vacuum pumps with gauge
        3. Electric pumps - Automated pressure control

        SAFETY WARNINGS:
        - Never exceed 5-7 HG pressure for beginners
        - Maximum 10-15 minutes per session initially
        - Stop immediately if you see spots or discoloration
        - Always use proper cylinder size (1/4" larger than erect girth)

        PROPER USAGE:
        1. Warm up thoroughly (5-10 minutes)
        2. Achieve 60-80% erection
        3. Apply lubricant to base
        4. Insert and create seal
        5. Pump slowly to desired pressure
        6. Hold for 3-5 minute sets
        7. Release pressure between sets
        8. Cool down after session

        PROGRESSION:
        - Week 1-2: 5 HG, 3x3 minutes
        - Week 3-4: 5-7 HG, 3x5 minutes
        - Month 2: 7 HG, 3x5-7 minutes
        - Advanced: Up to 10 HG, multiple sets

        MAINTENANCE:
        - Clean after every use
        - Check seals regularly
        - Replace gauge if damaged
        - Store in clean, dry place`,
      keywords: ['pump', 'vacuum', 'bathmate', 'pressure', 'water pump', 'air pump'],
      priority: 7,
      safetyNotes: 'Never exceed recommended pressure. Stop if pain or unusual discoloration occurs.'
    },
    {
      id: 'equipment-hangers-guide',
      title: 'Penis Hangers - Safe Weight Training',
      category: 'equipment',
      equipmentType: EQUIPMENT_TYPES.HANGERS,
      content: `Comprehensive guide to penis hanging for length gains:

        TYPES OF HANGERS:
        1. Compression hangers (Bib style)
        2. Vacuum hangers
        3. Noose style (NOT recommended)
        4. Hybrid designs

        CRITICAL SAFETY:
        ⚠️ WARNING: Hanging is advanced - minimum 6 months PE experience required
        - Start with 2.5 lbs maximum
        - Never hang for more than 20 minutes without break
        - Check circulation every 5 minutes
        - Stop if numbness occurs

        SETUP PROCESS:
        1. Thorough warm-up (10+ minutes heat)
        2. Apply protective wrap
        3. Attach hanger behind glans
        4. Start with minimal weight
        5. Find comfortable angle (BTC, SD, SO)
        6. Time your sets precisely
        7. Remove and restore circulation

        WEIGHT PROGRESSION:
        - Month 1: 2.5-5 lbs
        - Month 2-3: 5-7.5 lbs
        - Month 4-6: 7.5-10 lbs
        - Advanced: 10-15+ lbs (with caution)

        HANGING ANGLES:
        - BTC (Behind The Cheeks): Targets ligaments
        - SD (Straight Down): Balanced stretch
        - SO (Straight Out): Tunica focus
        - OTS (Over The Shoulder): Advanced upper angle

        REST & RECOVERY:
        - Minimum 2 rest days per week
        - Decon break every 3-4 months
        - Monitor for fatigue indicators`,
      keywords: ['hanger', 'weight', 'hanging', 'bib', 'vacuum hanger', 'compression'],
      priority: 6,
      safetyNotes: 'Advanced technique requiring experience. Never rush weight increases.'
    },
    {
      id: 'equipment-extenders-usage',
      title: 'Penis Extenders - Traction Device Guide',
      category: 'equipment',
      equipmentType: EQUIPMENT_TYPES.EXTENDERS,
      content: `Penis extender usage for consistent traction therapy:

        DEVICE TYPES:
        1. Rod-based extenders
        2. Belt/strap systems
        3. Vacuum cap extenders
        4. All-day stretchers (ADS)

        SAFETY GUIDELINES:
        ⚠️ CAUTION: Proper fit is crucial
        - Never over-tighten
        - Check circulation every 30 minutes
        - Build tolerance gradually
        - Use padding/sleeves for comfort

        WEARING PROTOCOL:
        1. Start with 1-2 hours daily
        2. Build up to 4-6 hours
        3. Take breaks every hour
        4. Adjust tension as needed
        5. Track hours consistently

        TENSION SETTINGS:
        - Week 1-2: 600-900g
        - Week 3-4: 900-1200g
        - Month 2: 1200-1500g
        - Advanced: 1500-1800g

        TIPS FOR SUCCESS:
        - Use under loose clothing
        - Sitting position often most comfortable
        - Keep spare parts available
        - Document measurements monthly
        - Combine with manual exercises

        TROUBLESHOOTING:
        - Slippage: Use better gripper/sleeve
        - Discomfort: Reduce tension, add padding
        - Circulation issues: Loosen immediately
        - Skin irritation: Use protective wrap`,
      keywords: ['extender', 'traction', 'stretcher', 'ads', 'all day stretcher'],
      priority: 7,
      safetyNotes: 'Consistent moderate tension is safer and more effective than aggressive stretching.'
    }
  ];
}

// Structure equipment knowledge by type
function structureByEquipmentType(documents) {
  const structured = {};

  Object.values(EQUIPMENT_TYPES).forEach(type => {
    structured[type] = [];
  });

  documents.forEach(doc => {
    const type = doc.equipmentType || EQUIPMENT_TYPES.ACCESSORIES;
    if (structured[type]) {
      structured[type].push(doc);
    } else {
      structured[EQUIPMENT_TYPES.ACCESSORIES].push(doc);
    }
  });

  return structured;
}

// Deploy equipment guides
async function deployEquipmentGuides(db, documents, options = {}) {
  const { dryRun = false, verbose = false, type = null } = options;

  console.log(chalk.blue('\n🔧 Deploying Equipment Guides\n'));

  // Filter by type if specified
  let deployDocs = documents;
  if (type) {
    deployDocs = documents.filter(doc => doc.equipmentType === type);
    console.log(chalk.cyan(`Filtering for equipment type: ${type}`));
  }

  // Structure by equipment type
  const structured = structureByEquipmentType(deployDocs);

  // Display structure
  console.log(chalk.cyan('📦 Equipment Document Structure:'));
  Object.entries(structured).forEach(([type, docs]) => {
    if (docs.length > 0) {
      console.log(chalk.yellow(`  ${type}: ${docs.length} documents`));
    }
  });

  const progressBar = new cliProgress.SingleBar({
    format: 'Deploying |' + chalk.blue('{bar}') + '| {percentage}% || {value}/{total} Equipment Guides',
    barCompleteChar: '\u2588',
    barIncompleteChar: '\u2591',
    hideCursor: true
  });

  const results = {
    successful: 0,
    failed: 0,
    errors: [],
    byType: {}
  };

  if (dryRun) {
    console.log(chalk.yellow('\n🔍 DRY RUN MODE - No actual changes will be made\n'));
  }

  progressBar.start(deployDocs.length, 0);

  // Process all documents
  const batch = db.batch();
  let processedCount = 0;

  for (const [equipType, docs] of Object.entries(structured)) {
    results.byType[equipType] = { successful: 0, failed: 0 };

    for (const doc of docs) {
      processedCount++;
      progressBar.update(processedCount);

      // Validate
      const errors = validateEquipmentDocument(doc);
      if (errors.length > 0) {
        results.failed++;
        results.byType[equipType].failed++;
        results.errors.push({ document: doc.id, errors });

        if (verbose) {
          console.error(chalk.red(`\n❌ Validation failed for ${doc.id}:`), errors);
        }
        continue;
      }

      // Enhance document
      const enhancedDoc = {
        ...doc,
        category: 'equipment',
        equipmentType: doc.equipmentType || EQUIPMENT_TYPES.ACCESSORIES,
        version: doc.version || 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        deployedBy: 'deployEquipmentGuides.js'
      };

      if (!dryRun) {
        const docRef = db.collection(COLLECTION_NAME).doc(doc.id);
        batch.set(docRef, enhancedDoc, { merge: true });
      }

      results.successful++;
      results.byType[equipType].successful++;

      // Commit batch every 500 documents
      if (results.successful % 500 === 0 && !dryRun) {
        await batch.commit();
      }
    }
  }

  // Final commit
  if (!dryRun && results.successful % 500 !== 0) {
    await batch.commit();
  }

  progressBar.stop();

  return results;
}

// Main function
async function main(options) {
  console.log(chalk.blue('\n⚙️  Equipment Guides Deployment\n'));

  // Initialize Firebase
  const db = initializeFirebase();

  // Load or generate documents
  let documents = [];

  if (options.source) {
    // Load from file
    if (!fs.existsSync(options.source)) {
      console.error(chalk.red(`❌ Source file not found: ${options.source}`));
      process.exit(1);
    }

    try {
      const content = fs.readFileSync(options.source, 'utf8');
      const data = JSON.parse(content);
      documents = Array.isArray(data) ? data : [data];
    } catch (error) {
      console.error(chalk.red('❌ Failed to load source file:'), error.message);
      process.exit(1);
    }
  } else if (options.generate) {
    // Generate sample equipment guides
    console.log(chalk.cyan('📝 Generating sample equipment guides...'));
    documents = generateSampleEquipmentGuides();
  } else {
    console.error(chalk.red('❌ No source specified. Use --source or --generate'));
    process.exit(1);
  }

  console.log(chalk.green(`✅ Loaded ${documents.length} equipment documents\n`));

  // Deploy
  const results = await deployEquipmentGuides(db, documents, options);

  // Display results
  console.log(chalk.blue('\n📊 Equipment Deployment Summary:'));
  console.log(chalk.green(`✅ Total Successful: ${results.successful}`));
  if (results.failed > 0) {
    console.log(chalk.red(`❌ Total Failed: ${results.failed}`));
  }

  // Show results by type
  console.log(chalk.cyan('\n📦 Results by Equipment Type:'));
  Object.entries(results.byType).forEach(([type, stats]) => {
    if (stats.successful > 0 || stats.failed > 0) {
      console.log(chalk.yellow(`  ${type}:`),
        chalk.green(`✅ ${stats.successful}`),
        stats.failed > 0 ? chalk.red(`❌ ${stats.failed}`) : '');
    }
  });

  if (options.verbose && results.errors.length > 0) {
    console.log(chalk.red('\n❌ Errors:'));
    results.errors.forEach(err => {
      console.log(chalk.red(`  ${err.document}:`), err.errors);
    });
  }

  // Record deployment
  if (!options.dryRun) {
    const deploymentRecord = {
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      type: 'equipment_guides',
      successful: results.successful,
      failed: results.failed,
      byType: results.byType,
      scriptName: 'deployEquipmentGuides.js'
    };

    await db.collection('deployments').add(deploymentRecord);
    console.log(chalk.green('\n✅ Deployment recorded'));
  }

  process.exit(results.failed > 0 ? 1 : 0);
}

// CLI setup
program
  .name('deployEquipmentGuides')
  .description('Deploy PE equipment guides with categorization')
  .version('1.0.0');

program
  .option('-s, --source <file>', 'JSON file containing equipment guides')
  .option('-g, --generate', 'Generate and deploy sample equipment guides')
  .option('-t, --type <type>', `Filter by equipment type (${Object.values(EQUIPMENT_TYPES).join(', ')})`)
  .option('-d, --dry-run', 'Run without making actual changes')
  .option('-v, --verbose', 'Show detailed error messages')
  .action((options) => {
    main(options);
  });

program.parse();