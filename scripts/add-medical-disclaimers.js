#!/usr/bin/env node

/**
 * Add Medical Disclaimers to Educational Resources in Firestore
 *
 * This script adds the standard 5-point medical disclaimer to all 8 educational
 * articles in Firestore. Uses batched writes for efficiency.
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/add-medical-disclaimers.js
 *
 * Prerequisites:
 *   - Firebase Admin SDK initialized
 *   - Application Default Credentials configured
 *   - Firestore collection 'educational_resources' exists
 */

const admin = require('firebase-admin');

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

// Article IDs from Story 7.3
const ARTICLE_IDS = [
  'article-1-tissue-expansion-biomechanics',
  'article-2-vascular-health-blood-flow',
  'article-3-injury-prevention-recovery',
  'article-4-anatomical-fundamentals',
  'article-5-temperature-therapy',
  'article-6-measurement-methodology',
  'article-7-nutritional-support',
  'article-8-recovery-physiology'
];

/**
 * Add medical disclaimers to all educational resources
 */
async function addMedicalDisclaimers() {
  console.log('🔍 Starting medical disclaimer update process...\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}`);
  console.log(`📝 Articles to update: ${ARTICLE_IDS.length}\n`);

  try {
    // Create batched write (Firestore batch supports up to 500 operations)
    const batch = db.batch();
    let updatedCount = 0;
    let notFoundCount = 0;

    // Process each article
    for (const articleId of ARTICLE_IDS) {
      const docRef = db.collection('educational_resources').doc(articleId);
      const docSnap = await docRef.get();

      if (docSnap.exists) {
        const currentData = docSnap.data();

        // Check if disclaimer already exists
        if (currentData.medical_disclaimer) {
          console.log(`⚠️  ${articleId}: Disclaimer already exists, updating...`);
        } else {
          console.log(`✅ ${articleId}: Adding disclaimer...`);
        }

        // Add/update medical_disclaimer field
        batch.update(docRef, {
          medical_disclaimer: STANDARD_DISCLAIMER,
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        updatedCount++;
      } else {
        console.log(`❌ ${articleId}: Document not found in Firestore`);
        notFoundCount++;
      }
    }

    // Commit the batch
    if (updatedCount > 0) {
      console.log(`\n📤 Committing batch write for ${updatedCount} documents...`);
      await batch.commit();
      console.log('✅ Batch write successful!\n');
    }

    // Summary
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Updated:   ${updatedCount} documents`);
    console.log(`❌ Not Found: ${notFoundCount} documents`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    if (updatedCount === ARTICLE_IDS.length) {
      console.log('🎉 All educational resources successfully updated with medical disclaimers!');
    } else if (notFoundCount > 0) {
      console.log('⚠️  Some documents were not found. Please verify they exist in Firestore.');
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Error updating disclaimers:', error);
    process.exit(1);
  }
}

/**
 * Verify disclaimers were added correctly
 */
async function verifyDisclaimers() {
  console.log('\n🔍 Verifying disclaimers...\n');

  try {
    let verifiedCount = 0;
    let missingCount = 0;

    for (const articleId of ARTICLE_IDS) {
      const docRef = db.collection('educational_resources').doc(articleId);
      const docSnap = await docRef.get();

      if (docSnap.exists) {
        const data = docSnap.data();
        if (data.medical_disclaimer && data.medical_disclaimer.includes('MEDICAL DISCLAIMER')) {
          console.log(`✅ ${articleId}: Disclaimer verified`);
          verifiedCount++;
        } else {
          console.log(`❌ ${articleId}: Disclaimer missing or invalid`);
          missingCount++;
        }
      } else {
        console.log(`❌ ${articleId}: Document not found`);
        missingCount++;
      }
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 VERIFICATION SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Verified:  ${verifiedCount} documents`);
    console.log(`❌ Missing:   ${missingCount} documents`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    if (verifiedCount === ARTICLE_IDS.length) {
      console.log('🎉 All disclaimers verified successfully!');
      return true;
    } else {
      console.log('⚠️  Verification failed. Some disclaimers are missing.');
      return false;
    }

  } catch (error) {
    console.error('❌ Error verifying disclaimers:', error);
    return false;
  }
}

/**
 * Main execution
 */
async function main() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Medical Disclaimer Update Script for Firestore           ║');
  console.log('║  Story 7.5: Medical & Legal Review Process                ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  try {
    // Step 1: Add/update disclaimers
    await addMedicalDisclaimers();

    // Step 2: Verify disclaimers
    const verified = await verifyDisclaimers();

    if (verified) {
      console.log('\n✅ Script completed successfully!');
      process.exit(0);
    } else {
      console.log('\n❌ Script completed with errors. Please review the output above.');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  }
}

// Run the script
main();
