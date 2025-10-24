#!/usr/bin/env node

/**
 * Deploy PE Training Knowledge Base to AI Coach
 *
 * Migrates knowledge base from Angion Method to PE Training using
 * 8 researched topics from Reddit community analysis:
 *
 * 1. Science of Tissue Expansion
 * 2. Understanding EQ & Blood Flow
 * 3. Injury Prevention & Recovery
 * 4. Beginner Fundamentals
 * 5. Heat Application Benefits
 * 6. Measuring & Tracking Progress
 * 7. Supplements & Nutrition
 * 8. Rest, Recovery & Deconditioning
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/deploy-pe-knowledge-base.js
 *
 * Prerequisites:
 *   - Firebase Admin SDK initialized
 *   - Application Default Credentials configured
 *   - educational_content_raw.json from Reddit scraper
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

// Load Reddit scraper data
const EDUCATIONAL_CONTENT_PATH = path.join(
  __dirname,
  'reddit-scraper',
  'extracted_data',
  'educational_content_raw.json'
);

// Standard medical disclaimer for all knowledge base content
const STANDARD_DISCLAIMER = `⚠️ MEDICAL DISCLAIMER

This information is for educational purposes only and does not constitute medical advice. Consult with a healthcare provider before beginning any exercise program.

Individual results may vary. This app does not guarantee specific outcomes or results from following the information provided.

Every individual's physiology is different. What works for one person may not work for another.

There are inherent risks associated with physical exercise programs. Stop immediately if you experience pain, discomfort, or unusual symptoms, and seek medical attention.

This app and its content are intended for adults 18 years of age and older only.`;

/**
 * Topic mapping configuration
 * Maps Reddit topics to knowledge base structure with metadata
 */
const TOPIC_CONFIG = {
  science_of_tissue_expansion: {
    title: 'Science of Tissue Expansion & Biomechanics',
    category: 'advanced',
    priority: 7,
    keywords: [
      'tissue', 'expansion', 'biomechanics', 'tunica', 'collagen',
      'stress', 'strain', 'hoop', 'vegf', 'lox', 'pde5i',
      'shear', 'blood pressure', 'penile pressure', 'advanced'
    ],
    type: 'knowledge',
    subcategories: ['biomechanics', 'tissue_science', 'advanced_techniques']
  },
  understanding_eq_blood_flow: {
    title: 'Understanding Erection Quality (EQ) & Blood Flow',
    category: 'health',
    priority: 9, // High priority for EQ content
    keywords: [
      'eq', 'erection', 'quality', 'blood', 'flow', 'cardiovascular',
      'health', 'pde5i', 'cialis', 'viagra', 'supplements', 'kegel',
      'pelvic', 'floor', 'circulation', 'vascular', 'beginner', 'health'
    ],
    type: 'knowledge',
    subcategories: ['erection_quality', 'cardiovascular_health', 'supplements']
  },
  injury_prevention_recovery: {
    title: 'Injury Prevention & Recovery',
    category: 'safety',
    priority: 10, // Highest priority for safety
    keywords: [
      'injury', 'prevention', 'recovery', 'safety', 'warning', 'signs',
      'pain', 'numbness', 'discoloration', 'rest', 'healing', 'medical',
      'hard', 'flaccid', 'ed', 'dysfunction', 'beginner', 'safety'
    ],
    type: 'knowledge',
    subcategories: ['safety', 'injury_prevention', 'recovery', 'warning_signs']
  },
  beginner_fundamentals: {
    title: 'PE Fundamentals for Beginners',
    category: 'beginner',
    priority: 10, // Highest priority for beginners
    keywords: [
      'beginner', 'newbie', 'start', 'basics', 'fundamentals', 'introduction',
      'first', 'routine', 'manual', 'jelq', 'stretch', 'guide', 'faq',
      'getting', 'started', 'beginner'
    ],
    type: 'knowledge',
    subcategories: ['beginner_guide', 'fundamentals', 'getting_started']
  },
  heat_application_benefits: {
    title: 'Heat Application & Warming Techniques',
    category: 'technique',
    priority: 6,
    keywords: [
      'heat', 'warm', 'warmup', 'temperature', 'therapy', 'heating',
      'pad', 'rice', 'sock', 'preparation', 'technique', 'safety'
    ],
    type: 'knowledge',
    subcategories: ['warmup', 'technique', 'preparation']
  },
  measuring_tracking_progress: {
    title: 'Measuring & Tracking Progress',
    category: 'progression',
    priority: 8,
    keywords: [
      'measure', 'measuring', 'track', 'tracking', 'progress', 'gains',
      'results', 'bpel', 'girth', 'mseg', 'base', 'length', 'record',
      'monthly', 'measurement', 'consistency'
    ],
    type: 'knowledge',
    subcategories: ['measurement', 'progress_tracking', 'data']
  },
  supplements_nutrition: {
    title: 'Supplements & Nutritional Support',
    category: 'supplements',
    priority: 5,
    keywords: [
      'supplement', 'supplements', 'nutrition', 'vitamin', 'mineral',
      'l-citrulline', 'l-arginine', 'nac', 'h2s', 'hydrogen', 'sulfide',
      'taurine', 'garlic', 'alcar', 'statin', 'eq', 'health'
    ],
    type: 'knowledge',
    subcategories: ['supplements', 'nutrition', 'biochemistry']
  },
  rest_recovery_decon: {
    title: 'Rest, Recovery & Deconditioning',
    category: 'recovery',
    priority: 9, // High priority for recovery
    keywords: [
      'rest', 'recovery', 'decon', 'deconditioning', 'break', 'healing',
      'schedule', 'on', 'off', 'days', 'overtraining', 'fatigue',
      'tissue', 'repair', 'beginner', 'safety'
    ],
    type: 'knowledge',
    subcategories: ['recovery', 'rest_days', 'deconditioning']
  }
};

/**
 * Extract and clean wiki content from Reddit data
 */
function extractWikiContent(topicData) {
  const wikiContent = [];

  if (topicData.wiki_content && Array.isArray(topicData.wiki_content)) {
    topicData.wiki_content.forEach(wiki => {
      if (wiki.excerpt) {
        wikiContent.push({
          source: wiki.source,
          content: wiki.excerpt.trim()
        });
      }
    });
  }

  return wikiContent;
}

/**
 * Create searchable content for Firestore
 * Combines title + all wiki content into searchable text
 */
function createSearchableContent(title, wikiContent) {
  const parts = [title];

  wikiContent.forEach(wiki => {
    // Remove markdown links but keep text
    const cleaned = wiki.content
      .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // [text](url) -> text
      .replace(/\*\*([^*]+)\*\*/g, '$1')       // **bold** -> bold
      .replace(/\*([^*]+)\*/g, '$1')           // *italic* -> italic
      .replace(/#+\s*/g, '')                   // ## headers -> headers
      .replace(/https?:\/\/[^\s]+/g, '')       // Remove URLs
      .replace(/\s+/g, ' ')                    // Normalize whitespace
      .trim();

    parts.push(cleaned);
  });

  return parts.join(' ').toLowerCase();
}

/**
 * Create comprehensive content text from wiki sources
 */
function createContentText(title, wikiContent, config) {
  const sections = [];

  // Add title
  sections.push(`# ${title}\n`);

  // Add category and priority metadata
  sections.push(`**Category:** ${config.category}`);
  sections.push(`**Priority:** ${config.priority}/10\n`);

  // Add wiki content from each source
  wikiContent.forEach((wiki, index) => {
    sections.push(`## Source: ${wiki.source}\n`);
    sections.push(wiki.content);
    sections.push(''); // Blank line between sources
  });

  // Add medical disclaimer
  sections.push('---\n');
  sections.push(STANDARD_DISCLAIMER);

  return sections.join('\n');
}

/**
 * Deploy knowledge base to Firestore
 */
async function deployKnowledgeBase() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Migrate AI Coach Knowledge Base from Angion to PE        ║');
  console.log('║  Using Reddit Community Research (8 Topics)                ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}`);
  console.log(`📁 Source: Reddit scraper educational content`);
  console.log(`📊 Topics: 8 researched PE topics\n`);

  try {
    // Load educational content
    if (!fs.existsSync(EDUCATIONAL_CONTENT_PATH)) {
      console.error(`❌ Educational content not found: ${EDUCATIONAL_CONTENT_PATH}`);
      console.error('Run the Reddit scraper first to generate this file.');
      process.exit(1);
    }

    const educationalContent = JSON.parse(
      fs.readFileSync(EDUCATIONAL_CONTENT_PATH, 'utf8')
    );

    console.log('✅ Loaded educational content from Reddit scraper\n');

    // Prepare knowledge base documents
    const knowledgeDocs = [];

    for (const [topicKey, topicData] of Object.entries(educationalContent)) {
      const config = TOPIC_CONFIG[topicKey];

      if (!config) {
        console.warn(`⚠️  Skipping unconfigured topic: ${topicKey}`);
        continue;
      }

      const wikiContent = extractWikiContent(topicData);

      if (wikiContent.length === 0) {
        console.warn(`⚠️  No wiki content for: ${config.title}`);
        continue;
      }

      const searchableContent = createSearchableContent(config.title, wikiContent);
      const contentText = createContentText(config.title, wikiContent, config);

      knowledgeDocs.push({
        id: topicKey,
        title: config.title,
        category: config.category,
        subcategories: config.subcategories,
        priority: config.priority,
        type: config.type,
        keywords: config.keywords,
        content: contentText,
        content_text: contentText,
        searchableContent: searchableContent,
        sources: wikiContent.map(w => w.source),
        source_count: wikiContent.length,
        medical_disclaimer: STANDARD_DISCLAIMER,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        version: '1.0.0',
        language: 'en'
      });

      console.log(`✅ ${config.title}`);
      console.log(`   📁 Category: ${config.category}`);
      console.log(`   ⭐ Priority: ${config.priority}/10`);
      console.log(`   📚 Sources: ${wikiContent.length}`);
      console.log(`   🔑 Keywords: ${config.keywords.length}`);
      console.log(`   📝 Content: ${contentText.length} characters\n`);
    }

    // Create Firestore batch
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📤 Deploying to Firestore...\n');

    const batch = db.batch();

    for (const doc of knowledgeDocs) {
      const docRef = db.collection('ai_coach_knowledge').doc(doc.id);
      const { id, ...docData } = doc;
      batch.set(docRef, docData);
      console.log(`📝 Prepared: ${doc.id}`);
    }

    // Commit batch
    console.log(`\n🚀 Committing batch write for ${knowledgeDocs.length} documents...`);
    await batch.commit();
    console.log('✅ Batch write successful!\n');

    // Summary
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 DEPLOYMENT SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Deployed:        ${knowledgeDocs.length} knowledge base articles`);
    console.log(`📚 Total Sources:   ${knowledgeDocs.reduce((sum, d) => sum + d.source_count, 0)}`);
    console.log(`🔑 Total Keywords:  ${knowledgeDocs.reduce((sum, d) => sum + d.keywords.length, 0)}`);
    console.log(`📝 Total Content:   ${knowledgeDocs.reduce((sum, d) => sum + d.content.length, 0).toLocaleString()} characters`);
    console.log(`⚠️  Disclaimers:    All articles include medical disclaimer`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Category breakdown
    const categories = {};
    knowledgeDocs.forEach(doc => {
      categories[doc.category] = (categories[doc.category] || 0) + 1;
    });

    console.log('📁 CATEGORY BREAKDOWN:');
    Object.entries(categories).forEach(([cat, count]) => {
      console.log(`   ${cat}: ${count} articles`);
    });
    console.log('');

    // Priority breakdown
    const priorities = {};
    knowledgeDocs.forEach(doc => {
      const p = doc.priority;
      priorities[p] = (priorities[p] || 0) + 1;
    });

    console.log('⭐ PRIORITY BREAKDOWN:');
    Object.keys(priorities).sort((a, b) => b - a).forEach(priority => {
      console.log(`   Priority ${priority}/10: ${priorities[priority]} articles`);
    });
    console.log('');

    return knowledgeDocs;

  } catch (error) {
    console.error('❌ Deployment failed:', error);
    throw error;
  }
}

/**
 * Verify deployment
 */
async function verifyDeployment() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🔍 Verifying deployment...\n');

  try {
    let verifiedCount = 0;
    let failedCount = 0;

    for (const topicKey of Object.keys(TOPIC_CONFIG)) {
      const docRef = db.collection('ai_coach_knowledge').doc(topicKey);
      const docSnap = await docRef.get();

      if (docSnap.exists) {
        const data = docSnap.data();
        const hasTitle = !!data.title;
        const hasContent = data.content && data.content.length > 100;
        const hasKeywords = data.keywords && data.keywords.length > 0;
        const hasDisclaimer = data.medical_disclaimer && data.medical_disclaimer.includes('MEDICAL DISCLAIMER');
        const hasPriority = data.priority >= 1 && data.priority <= 10;

        if (hasTitle && hasContent && hasKeywords && hasDisclaimer && hasPriority) {
          console.log(`✅ ${topicKey}: Complete`);
          console.log(`   ✓ Title: ${data.title}`);
          console.log(`   ✓ Content: ${data.content.length} characters`);
          console.log(`   ✓ Keywords: ${data.keywords.length}`);
          console.log(`   ✓ Priority: ${data.priority}/10`);
          console.log(`   ✓ Disclaimer: Present\n`);
          verifiedCount++;
        } else {
          console.log(`❌ ${topicKey}: Incomplete`);
          console.log(`   ${hasTitle ? '✓' : '✗'} Title`);
          console.log(`   ${hasContent ? '✓' : '✗'} Content`);
          console.log(`   ${hasKeywords ? '✓' : '✗'} Keywords`);
          console.log(`   ${hasPriority ? '✓' : '✗'} Priority`);
          console.log(`   ${hasDisclaimer ? '✓' : '✗'} Disclaimer\n`);
          failedCount++;
        }
      } else {
        console.log(`❌ ${topicKey}: Not found in Firestore\n`);
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
 * Test knowledge base search
 */
async function testKnowledgeSearch() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🧪 Testing Knowledge Base Search...\n');

  const testQueries = [
    'beginner routine',
    'injury prevention',
    'measuring gains',
    'eq supplements',
    'safety warnings'
  ];

  for (const query of testQueries) {
    console.log(`🔍 Query: "${query}"`);

    const queryTerms = query.toLowerCase().split(/\s+/);
    const snapshot = await db.collection('ai_coach_knowledge')
      .where('keywords', 'array-contains-any', queryTerms.slice(0, 10))
      .limit(3)
      .get();

    if (!snapshot.empty) {
      console.log(`   ✅ Found ${snapshot.size} results:`);
      snapshot.forEach(doc => {
        const data = doc.data();
        console.log(`      • ${data.title} (Priority: ${data.priority}/10)`);
      });
    } else {
      console.log(`   ⚠️  No results found`);
    }
    console.log('');
  }
}

/**
 * Main execution
 */
async function main() {
  try {
    // Step 1: Deploy knowledge base
    await deployKnowledgeBase();

    // Step 2: Verify deployment
    const verified = await verifyDeployment();

    if (!verified) {
      console.log('⚠️  Deployment completed with errors. Please review the output above.\n');
      process.exit(1);
    }

    // Step 3: Test search functionality
    await testKnowledgeSearch();

    console.log('🎉 Knowledge Base Migration Complete!');
    console.log('✅ All PE training knowledge deployed successfully');
    console.log('✅ Angion Method → PE Training migration complete\n');

    console.log('📚 Knowledge Base Ready For:');
    console.log('   • AI Coach responses');
    console.log('   • User questions about PE techniques');
    console.log('   • Safety and injury prevention guidance');
    console.log('   • Beginner education and onboarding');
    console.log('   • Progress tracking advice\n');

    process.exit(0);

  } catch (error) {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  }
}

// Run the script
main();
