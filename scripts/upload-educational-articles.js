#!/usr/bin/env node

/**
 * Upload Educational Articles to Firestore
 *
 * This script uploads the 8 generated article JSON files from
 * scripts/reddit-scraper/generated_articles/ to the Firestore
 * educational_resources collection.
 *
 * Usage:
 *   node scripts/upload-educational-articles.js
 *
 * Environment:
 *   - GOOGLE_APPLICATION_CREDENTIALS: Path to service account key (optional if using gcloud auth)
 *   - FIREBASE_PROJECT: Firebase project ID (defaults to 'growth-training')
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: process.env.FIREBASE_PROJECT || 'growth-training-app'
    });
    console.log('✅ Firebase Admin SDK initialized');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    process.exit(1);
  }
}

const db = admin.firestore();
const articlesDir = path.join(__dirname, 'reddit-scraper', 'generated_articles');

// Article files to upload
const articleFiles = [
  'science_of_tissue_expansion.json',
  'understanding_eq_blood_flow.json',
  'injury_prevention_recovery.json',
  'beginner_fundamentals.json',
  'heat_application_benefits.json',
  'measuring_tracking_progress.json',
  'supplements_nutrition.json',
  'rest_recovery_decon.json'
];

/**
 * Load and parse JSON file
 */
function loadArticle(filename) {
  const filePath = path.join(articlesDir, filename);

  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  const content = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(content);
}

/**
 * Upload articles to Firestore using batch write
 */
async function uploadArticles() {
  console.log('\n📤 Starting article upload to Firestore...\n');

  const batch = db.batch();
  const articlesData = [];

  // Load all articles
  for (const filename of articleFiles) {
    try {
      const article = loadArticle(filename);
      articlesData.push({ filename, article });
      console.log(`✅ Loaded: ${filename} - "${article.title}"`);
    } catch (error) {
      console.error(`❌ Failed to load ${filename}:`, error.message);
      process.exit(1);
    }
  }

  console.log(`\n📋 Loaded ${articlesData.length} articles\n`);

  // Add each article to batch
  for (const { filename, article } of articlesData) {
    const docRef = db.collection('educational_resources').doc(); // Auto-generate ID

    batch.set(docRef, {
      title: article.title,
      content_text: article.content_text,
      category: article.category,
      citations: article.citations || [],
      medical_disclaimer: article.medical_disclaimer || null,
      local_image_name: article.local_image_name || null,
      visual_placeholder_url: article.visual_placeholder_url || null,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`📝 Prepared for upload: ${article.title} (${article.category})`);
    console.log(`   - Citations: ${article.citations?.length || 0}`);
    console.log(`   - Document ID: ${docRef.id}\n`);
  }

  // Commit batch
  try {
    await batch.commit();
    console.log('✅ Successfully uploaded all articles to Firestore!\n');
    console.log(`📊 Upload Summary:`);
    console.log(`   - Total articles: ${articlesData.length}`);
    console.log(`   - Total citations: ${articlesData.reduce((sum, { article }) => sum + (article.citations?.length || 0), 0)}`);
    console.log(`   - Collection: educational_resources\n`);
  } catch (error) {
    console.error('❌ Failed to commit batch:', error.message);
    process.exit(1);
  }
}

/**
 * Main execution
 */
async function main() {
  try {
    await uploadArticles();
    console.log('🎉 Upload complete!\n');
    process.exit(0);
  } catch (error) {
    console.error('❌ Upload failed:', error);
    process.exit(1);
  }
}

main();
