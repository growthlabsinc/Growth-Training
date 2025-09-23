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

// Safety content priorities
const SAFETY_PRIORITY = {
  CRITICAL: 10,  // Medical emergencies, stop signals
  HIGH: 9,       // Injury prevention, warning signs
  MEDIUM: 8      // General safety guidelines
};

// Required disclaimer text for safety documents
const REQUIRED_DISCLAIMERS = [
  'medical',
  'consult',
  'physician',
  'doctor',
  'professional'
];

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

// Validate safety-specific requirements
function validateSafetyDocument(doc) {
  const errors = [];

  // Basic validation
  const requiredFields = ['id', 'title', 'content', 'category', 'keywords', 'priority'];
  requiredFields.forEach(field => {
    if (!doc[field]) {
      errors.push(`Missing required field: ${field}`);
    }
  });

  // Safety documents must have high priority (8-10)
  if (doc.priority && doc.priority < 8) {
    errors.push(`Safety documents must have priority 8-10, got: ${doc.priority}`);
  }

  // Check for medical disclaimer
  const contentLower = (doc.content || '').toLowerCase();
  const hasDisclaimer = REQUIRED_DISCLAIMERS.some(term => contentLower.includes(term));

  if (!hasDisclaimer) {
    errors.push('Safety content must include medical disclaimer keywords');
  }

  // Ensure category is safety-related
  const safetyCategories = ['safety', 'recovery', 'medical'];
  if (doc.category && !safetyCategories.includes(doc.category)) {
    errors.push(`Safety document should have safety-related category, got: ${doc.category}`);
  }

  return errors;
}

// Generate default safety documents if none provided
function generateDefaultSafetyDocuments() {
  return [
    {
      id: 'safety-critical-stop-signals',
      category: 'safety',
      title: 'Critical Stop Signals - Immediate Action Required',
      content: `STOP IMMEDIATELY if you experience any of the following:

        1. Severe pain or sharp pain
        2. Numbness or complete loss of sensation
        3. Cold sensation or temperature change
        4. Discoloration (purple, blue, white)
        5. Bleeding or bruising
        6. Swelling that doesn't subside
        7. Difficulty urinating
        8. Any unusual discharge

        IMPORTANT: These symptoms require immediate cessation of all PE activities.
        Consult a medical professional or physician immediately if symptoms persist.
        Your safety is paramount - never push through severe warning signs.`,
      keywords: ['stop', 'emergency', 'pain', 'injury', 'warning', 'critical', 'immediate'],
      priority: SAFETY_PRIORITY.CRITICAL
    },
    {
      id: 'safety-injury-prevention',
      title: 'Injury Prevention Guidelines',
      category: 'safety',
      content: `Comprehensive injury prevention for PE training:

        BEFORE TRAINING:
        - Always warm up for 5-10 minutes
        - Check equipment condition
        - Ensure proper hygiene
        - Never train with existing injury

        DURING TRAINING:
        - Use proper technique at all times
        - Never exceed recommended time limits
        - Stop at first sign of discomfort
        - Maintain consistent pressure/tension
        - Take required rest breaks

        AFTER TRAINING:
        - Cool down properly
        - Monitor for delayed symptoms
        - Apply recommended recovery protocols
        - Track any unusual sensations

        Remember: Consult with a medical professional before beginning any PE program.
        These guidelines are educational only and not medical advice.`,
      keywords: ['prevention', 'injury', 'safety', 'guidelines', 'warm-up', 'technique'],
      priority: SAFETY_PRIORITY.HIGH
    },
    {
      id: 'safety-recovery-protocol',
      title: 'Recovery and Rest Protocol',
      category: 'recovery',
      content: `Essential recovery guidelines for PE training:

        MANDATORY REST DAYS:
        - Minimum 1-2 rest days per week
        - 48 hours between intense sessions
        - Full week off every 6-8 weeks

        RECOVERY INDICATORS:
        - Morning erectile quality
        - Flaccid hang improvement
        - Absence of soreness
        - Normal sensitivity

        RECOVERY METHODS:
        - Light massage
        - Heat application (moderate)
        - Adequate hydration
        - Quality sleep (7-9 hours)
        - Stress management

        WHEN TO EXTEND REST:
        - Any pain or discomfort
        - Decreased EQ
        - Unusual marks or spots
        - Fatigue or overtraining signs

        Medical Disclaimer: This information is for educational purposes only.
        Consult your physician for personalized medical advice.`,
      keywords: ['recovery', 'rest', 'healing', 'restoration', 'break', 'recuperation'],
      priority: SAFETY_PRIORITY.HIGH
    },
    {
      id: 'safety-medical-disclaimer',
      title: 'Medical Disclaimer and Professional Consultation',
      category: 'medical',
      content: `IMPORTANT MEDICAL DISCLAIMER:

        The information provided in this AI Coach system is for educational and informational purposes only.
        It is not intended as a substitute for professional medical advice, diagnosis, or treatment.

        YOU SHOULD:
        - Consult with a qualified physician before beginning any PE program
        - Seek immediate medical attention for any concerning symptoms
        - Disclose PE activities to your healthcare provider
        - Follow medical advice over any suggestions from this system

        WE DO NOT:
        - Provide medical diagnoses
        - Offer medical treatment advice
        - Replace professional medical consultation
        - Guarantee any specific results

        LIABILITY:
        You assume all risks associated with PE training. The creators and maintainers
        of this system are not liable for any injuries or health issues that may occur.

        By using this system, you acknowledge that you have read and understood this disclaimer.
        Always prioritize your health and safety above any training goals.`,
      keywords: ['medical', 'disclaimer', 'legal', 'consultation', 'physician', 'doctor'],
      priority: SAFETY_PRIORITY.CRITICAL
    }
  ];
}

// Deploy safety guidelines with enhanced validation
async function deploySafetyGuidelines(db, documents, options = {}) {
  const { dryRun = false, verbose = false } = options;

  console.log(chalk.yellow('\n⚠️  SAFETY CONTENT DEPLOYMENT - Enhanced Validation Active\n'));

  // Create progress bar
  const progressBar = new cliProgress.SingleBar({
    format: 'Deploying Safety |' + chalk.red('{bar}') + '| {percentage}% || {value}/{total} Documents',
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
    console.log(chalk.yellow('🔍 DRY RUN MODE - No actual changes will be made\n'));
  }

  progressBar.start(documents.length, 0);

  const batch = db.batch();

  for (let i = 0; i < documents.length; i++) {
    const doc = documents[i];
    progressBar.update(i + 1);

    // Validate safety document
    const validationErrors = validateSafetyDocument(doc);
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

    // Enhance document with safety metadata
    const enhancedDoc = {
      ...doc,
      isSafetyContent: true,
      priority: doc.priority || SAFETY_PRIORITY.HIGH,
      version: doc.version || 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      deployedBy: 'deployPESafetyGuidelines.js',
      validatedAt: new Date().toISOString()
    };

    if (!dryRun) {
      const docRef = db.collection(COLLECTION_NAME).doc(doc.id);
      batch.set(docRef, enhancedDoc, { merge: true });
    }

    results.successful++;

    // Commit batch every 500 documents
    if (results.successful % 500 === 0 && !dryRun) {
      await batch.commit();
    }
  }

  // Final batch commit
  if (!dryRun && results.successful % 500 !== 0) {
    await batch.commit();
  }

  progressBar.stop();

  return results;
}

// Main function
async function main(options) {
  console.log(chalk.red('\n🛡️  PE Safety Guidelines Deployment\n'));

  // Initialize Firebase
  const db = initializeFirebase();

  // Load or generate safety documents
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
    // Generate default safety documents
    console.log(chalk.cyan('📝 Generating default safety documents...'));
    documents = generateDefaultSafetyDocuments();
  } else {
    console.error(chalk.red('❌ No source specified. Use --source or --generate'));
    process.exit(1);
  }

  console.log(chalk.green(`✅ Preparing ${documents.length} safety documents\n`));

  // Sort by priority (highest first)
  documents.sort((a, b) => (b.priority || 0) - (a.priority || 0));

  // Deploy
  const results = await deploySafetyGuidelines(db, documents, options);

  // Display results
  console.log(chalk.blue('\n📊 Safety Deployment Summary:'));
  console.log(chalk.green(`✅ Successful: ${results.successful}`));
  if (results.failed > 0) {
    console.log(chalk.red(`❌ Failed: ${results.failed}`));

    if (options.verbose && results.errors.length > 0) {
      console.log(chalk.red('\n❌ Validation Errors:'));
      results.errors.forEach(err => {
        console.log(chalk.red(`  ${err.document}:`), err.errors);
      });
    }
  }

  // Record deployment
  if (!options.dryRun) {
    const deploymentRecord = {
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      type: 'safety_guidelines',
      successful: results.successful,
      failed: results.failed,
      scriptName: 'deployPESafetyGuidelines.js'
    };

    await db.collection('deployments').add(deploymentRecord);
    console.log(chalk.green('\n✅ Deployment recorded'));
  }

  process.exit(results.failed > 0 ? 1 : 0);
}

// CLI setup
program
  .name('deployPESafetyGuidelines')
  .description('Deploy PE safety guidelines with enhanced validation')
  .version('1.0.0');

program
  .option('-s, --source <file>', 'JSON file containing safety documents')
  .option('-g, --generate', 'Generate and deploy default safety documents')
  .option('-d, --dry-run', 'Run without making actual changes')
  .option('-v, --verbose', 'Show detailed error messages')
  .action((options) => {
    main(options);
  });

program.parse();