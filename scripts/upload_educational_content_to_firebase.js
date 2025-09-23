#!/usr/bin/env node
/**
 * Upload Educational Articles and Citations to Firebase
 */

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const { readFileSync } = fs;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK
function initializeFirebase() {
    const serviceAccountPath = path.join(__dirname, 'service-account-key.json');

    if (!fs.existsSync(serviceAccountPath)) {
        console.error('❌ Service account key not found!');
        console.log('Please ensure service-account-key.json is in the scripts directory');
        process.exit(1);
    }

    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });

    return admin.firestore();
}

// Upload educational articles
async function uploadArticles(db) {
    console.log('\n📚 Uploading Educational Articles...\n');

    const articlesPath = path.join(__dirname, 'extracted_data', 'educational_articles.json');
    const articles = JSON.parse(readFileSync(articlesPath, 'utf8'));

    const articlesCollection = db.collection('educational_articles');
    const batch = db.batch();

    for (const article of articles) {
        const docRef = articlesCollection.doc(article.id);

        // Prepare document data
        const docData = {
            ...article,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            views: 0,
            helpful: 0,
            notHelpful: 0,
            isPublished: true,
            searchTerms: [
                ...article.title.toLowerCase().split(' '),
                ...article.category.toLowerCase().split(' '),
                article.difficulty.toLowerCase()
            ]
        };

        batch.set(docRef, docData, { merge: true });
        console.log(`  ✅ ${article.title}`);
    }

    await batch.commit();
    console.log(`\n✅ Successfully uploaded ${articles.length} educational articles`);

    return articles.length;
}

// Upload medical citations
async function uploadCitations(db) {
    console.log('\n📑 Uploading Medical Citations...\n');

    const citationsPath = path.join(__dirname, 'extracted_data', 'medical_citations.json');
    const citations = JSON.parse(readFileSync(citationsPath, 'utf8'));

    const citationsCollection = db.collection('medical_citations');
    const batch = db.batch();

    for (const citation of citations) {
        const docRef = citationsCollection.doc(citation.id);

        // Prepare citation data
        const docData = {
            ...citation,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            timesReferenced: 0,
            isVerified: true
        };

        batch.set(docRef, docData, { merge: true });
        console.log(`  ✅ ${citation.title.substring(0, 60)}...`);
    }

    await batch.commit();
    console.log(`\n✅ Successfully uploaded ${citations.length} medical citations`);

    return citations.length;
}

// Create article metadata collection for easy searching
async function createArticleMetadata(db) {
    console.log('\n📋 Creating Article Metadata...\n');

    const articlesPath = path.join(__dirname, 'extracted_data', 'educational_articles.json');
    const articles = JSON.parse(readFileSync(articlesPath, 'utf8'));

    const metadataDoc = db.collection('app_metadata').doc('educational_content');

    const metadata = {
        totalArticles: articles.length,
        categories: [...new Set(articles.map(a => a.category))],
        articles: articles.map(a => ({
            id: a.id,
            title: a.title,
            subtitle: a.subtitle,
            category: a.category,
            readingTime: a.readingTime,
            difficulty: a.difficulty
        })),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    };

    await metadataDoc.set(metadata, { merge: true });
    console.log('✅ Article metadata created');

    return metadata;
}

// Main upload function
async function uploadEducationalContent() {
    console.log('🚀 Starting Educational Content Upload to Firebase...');
    console.log('='.repeat(50));

    const db = initializeFirebase();

    try {
        // Upload articles
        const articleCount = await uploadArticles(db);

        // Upload citations
        const citationCount = await uploadCitations(db);

        // Create metadata
        const metadata = await createArticleMetadata(db);

        // Create summary
        console.log('\n' + '='.repeat(50));
        console.log('📊 Upload Summary');
        console.log('='.repeat(50));
        console.log(`✅ Articles uploaded: ${articleCount}`);
        console.log(`✅ Citations uploaded: ${citationCount}`);
        console.log(`✅ Categories: ${metadata.categories.join(', ')}`);

        // Verify uploads
        console.log('\n🔍 Verifying uploads...');

        const articleSnapshot = await db.collection('educational_articles').limit(1).get();
        const citationSnapshot = await db.collection('medical_citations').limit(1).get();

        if (!articleSnapshot.empty && !citationSnapshot.empty) {
            console.log('✅ Verification successful - Content is in Firebase!');
            console.log('\n🎉 Educational content successfully uploaded!');
            console.log('\nCollections created:');
            console.log('  📚 educational_articles');
            console.log('  📑 medical_citations');
            console.log('  📋 app_metadata/educational_content');
        } else {
            console.error('⚠️ Verification failed - please check Firebase console');
        }

    } catch (error) {
        console.error('❌ Error uploading content:', error);
        process.exit(1);
    }
}

// Run the upload
uploadEducationalContent()
    .then(() => {
        console.log('\n✅ All educational content successfully uploaded to Firebase!');
        process.exit(0);
    })
    .catch(error => {
        console.error('Failed:', error);
        process.exit(1);
    });