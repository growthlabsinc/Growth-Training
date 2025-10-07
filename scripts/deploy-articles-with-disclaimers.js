#!/usr/bin/env node

/**
 * Deploy Educational Articles with Medical Disclaimers to Firestore
 *
 * This script parses markdown article files and deploys them to Firestore with:
 * - Proper document IDs matching markdown filenames
 * - Full article content from markdown
 * - Standard 5-point medical disclaimer
 * - Metadata from frontmatter (category, citations, etc.)
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/deploy-articles-with-disclaimers.js
 *
 * Prerequisites:
 *   - Firebase Admin SDK initialized
 *   - Application Default Credentials configured
 *   - Article markdown files in docs/content-research/articles/
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin (uses Application Default Credentials)
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

// Standard 5-point medical disclaimer (plain text for Firestore)
const STANDARD_DISCLAIMER = `⚠️ MEDICAL DISCLAIMER

This information is for educational purposes only and does not constitute medical advice. Consult with a healthcare provider before beginning any exercise program.

Individual results may vary. This app does not guarantee specific outcomes or results from following the information provided.

Every individual's physiology is different. What works for one person may not work for another.

There are inherent risks associated with physical exercise programs. Stop immediately if you experience pain, discomfort, or unusual symptoms, and seek medical attention.

This app and its content are intended for adults 18 years of age and older only.`;

// Article files to deploy
const ARTICLES_DIR = path.join(__dirname, '..', 'docs', 'content-research', 'articles');
const ARTICLE_FILES = [
  'article-1-tissue-expansion-biomechanics.md',
  'article-2-vascular-health-blood-flow.md',
  'article-3-injury-prevention-recovery.md',
  'article-4-anatomical-fundamentals.md',
  'article-5-temperature-therapy.md',
  'article-6-measurement-methodology.md',
  'article-7-nutritional-support.md',
  'article-8-recovery-physiology.md'
];

/**
 * Parse frontmatter and content from markdown file
 */
function parseMarkdown(filepath) {
  const content = fs.readFileSync(filepath, 'utf8');

  // Extract frontmatter
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!frontmatterMatch) {
    throw new Error(`Invalid markdown format: ${filepath}`);
  }

  const [, frontmatter, markdownContent] = frontmatterMatch;

  // Parse frontmatter
  const metadata = {};
  frontmatter.split('\n').forEach(line => {
    const match = line.match(/^([^:]+):\s*(.+)$/);
    if (match) {
      const [, key, value] = match;
      // Remove quotes if present
      metadata[key.trim()] = value.trim().replace(/^["']|["']$/g, '');
    }
  });

  return {
    title: metadata.title,
    category: metadata.category,
    subcategories: metadata.subcategories ? JSON.parse(metadata.subcategories) : [],
    readingLevel: metadata.reading_level,
    wordCount: parseInt(metadata.word_count) || 0,
    citationCount: parseInt(metadata.citations) || 0,
    lastUpdated: metadata.last_updated,
    medicalReviewStatus: metadata.medical_review_status || 'Pending',
    legalReviewStatus: metadata.legal_review_status || 'Pending',
    contentText: markdownContent.trim()
  };
}

/**
 * Deploy articles to Firestore
 */
async function deployArticles() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Deploy Educational Articles with Medical Disclaimers     ║');
  console.log('║  Story 7.5: Medical & Legal Review Process                ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}`);
  console.log(`📁 Articles directory: ${ARTICLES_DIR}`);
  console.log(`📝 Articles to deploy: ${ARTICLE_FILES.length}\n`);

  try {
    const batch = db.batch();
    const articles = [];

    // Parse all markdown files
    console.log('📖 Parsing markdown files...\n');
    for (const filename of ARTICLE_FILES) {
      const filepath = path.join(ARTICLES_DIR, filename);

      if (!fs.existsSync(filepath)) {
        console.error(`❌ File not found: ${filename}`);
        process.exit(1);
      }

      try {
        const article = parseMarkdown(filepath);
        const documentId = filename.replace('.md', '');

        articles.push({
          id: documentId,
          filename,
          ...article
        });

        console.log(`✅ ${filename}`);
        console.log(`   📌 Document ID: ${documentId}`);
        console.log(`   📖 Title: ${article.title}`);
        console.log(`   📁 Category: ${article.category}`);
        console.log(`   📊 Word Count: ${article.wordCount}`);
        console.log(`   📚 Citations: ${article.citationCount}\n`);

      } catch (error) {
        console.error(`❌ Failed to parse ${filename}:`, error.message);
        process.exit(1);
      }
    }

    // Create Firestore batch
    console.log('📤 Preparing Firestore batch write...\n');
    for (const article of articles) {
      const docRef = db.collection('educational_resources').doc(article.id);

      batch.set(docRef, {
        title: article.title,
        content_text: article.contentText,
        category: article.category,
        subcategories: article.subcategories,
        reading_level: article.readingLevel,
        word_count: article.wordCount,
        citation_count: article.citationCount,
        medical_disclaimer: STANDARD_DISCLAIMER,  // Add standard disclaimer
        medical_review_status: article.medicalReviewStatus,
        legal_review_status: article.legalReviewStatus,
        last_updated: article.lastUpdated,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log(`📝 Prepared: ${article.id}`);
    }

    // Commit batch
    console.log(`\n🚀 Committing batch write for ${articles.length} documents...`);
    await batch.commit();
    console.log('✅ Batch write successful!\n');

    // Summary
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 DEPLOYMENT SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Deployed:     ${articles.length} articles`);
    console.log(`📝 Total Words:  ${articles.reduce((sum, a) => sum + a.wordCount, 0).toLocaleString()}`);
    console.log(`📚 Total Cites:  ${articles.reduce((sum, a) => sum + a.citationCount, 0)}`);
    console.log(`⚠️  Disclaimers: All articles include standard 5-point medical disclaimer`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  } catch (error) {
    console.error('❌ Deployment failed:', error);
    process.exit(1);
  }
}

/**
 * Verify deployment
 */
async function verifyDeployment() {
  console.log('🔍 Verifying deployment...\n');

  try {
    let verifiedCount = 0;
    let failedCount = 0;

    for (const filename of ARTICLE_FILES) {
      const documentId = filename.replace('.md', '');
      const docRef = db.collection('educational_resources').doc(documentId);
      const docSnap = await docRef.get();

      if (docSnap.exists) {
        const data = docSnap.data();
        const hasDisclaimer = data.medical_disclaimer && data.medical_disclaimer.includes('MEDICAL DISCLAIMER');
        const hasTitle = !!data.title;
        const hasContent = data.content_text && data.content_text.length > 100;

        if (hasDisclaimer && hasTitle && hasContent) {
          console.log(`✅ ${documentId}: Complete`);
          console.log(`   ✓ Title: ${data.title.substring(0, 50)}...`);
          console.log(`   ✓ Content: ${data.content_text.length} characters`);
          console.log(`   ✓ Disclaimer: Present\n`);
          verifiedCount++;
        } else {
          console.log(`❌ ${documentId}: Incomplete`);
          console.log(`   ${hasTitle ? '✓' : '✗'} Title`);
          console.log(`   ${hasContent ? '✓' : '✗'} Content`);
          console.log(`   ${hasDisclaimer ? '✓' : '✗'} Disclaimer\n`);
          failedCount++;
        }
      } else {
        console.log(`❌ ${documentId}: Not found in Firestore\n`);
        failedCount++;
      }
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 VERIFICATION SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Verified:  ${verifiedCount} documents`);
    console.log(`❌ Failed:    ${failedCount} documents`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    return failedCount === 0;

  } catch (error) {
    console.error('❌ Verification failed:', error);
    return false;
  }
}

/**
 * Main execution
 */
async function main() {
  try {
    // Step 1: Deploy articles
    await deployArticles();

    // Step 2: Verify deployment
    const verified = await verifyDeployment();

    if (verified) {
      console.log('🎉 Deployment completed successfully!');
      console.log('✅ All articles deployed with medical disclaimers\n');
      process.exit(0);
    } else {
      console.log('⚠️  Deployment completed with errors. Please review the output above.\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  }
}

// Run the script
main();
