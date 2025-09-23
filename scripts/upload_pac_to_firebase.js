#!/usr/bin/env node
/**
 * Upload PAC (Pump Assisted Clamping) Exercise to Firebase
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

// Create comprehensive PAC exercise document
function createPACDocument() {
    const pacExercise = {
        // Core identifiers
        id: 'pump_assisted_clamping_pac',
        title: 'Pump Assisted Clamping (PAC)',
        description: 'Advanced girth technique combining vacuum pumping with clamping for maximum expansion. PAC alternates between pump-induced expansion and clamp-restricted blood flow to promote significant girth gains through progressive tissue expansion.',
        classification: 'Advanced',
        stage: 3, // Advanced = stage 3

        // Instructions
        instructionsText: `1. Warm up with 5-10 minutes of hot wrap or warm shower
2. Start with pump at low pressure (3-5 Hg) for 5 minutes
3. Achieve 80-90% erection level
4. Release pump and immediately apply cable clamp at base
5. Use padding under clamp to prevent injury
6. Tighten clamp to restrict outflow but maintain some inflow
7. Perform light jelqs or squeezes while clamped (optional)
8. Hold clamp for 5-7 minutes maximum for beginners
9. Release clamp and massage thoroughly
10. Return to pump for another 5 minute session at low pressure
11. Alternate pump and clamp for 2-3 sets maximum
12. Cool down with light massage and warm wrap`,

        // Structured steps
        steps: [
            {
                stepNumber: 1,
                title: 'Warm-up Phase',
                description: 'Warm up with 5-10 minutes of hot wrap or warm shower to prepare tissues',
                duration: 300,
                tips: ['Use as warm as comfortable', 'Can also use heating pad'],
                warnings: []
            },
            {
                stepNumber: 2,
                title: 'Initial Pump Session',
                description: 'Start with pump at low pressure (3-5 Hg) for 5 minutes. Achieve 80-90% erection level.',
                duration: 300,
                tips: ['Start with lower pressure if new to pumping', 'Use water-based lube for better seal'],
                warnings: ['Monitor for red spots or discoloration']
            },
            {
                stepNumber: 3,
                title: 'Clamp Application',
                description: 'Release pump and immediately apply cable clamp at base with padding. Tighten to restrict outflow but maintain some inflow.',
                duration: 60,
                tips: ['Use mousepad or cloth for padding', 'Should feel tight but not painful'],
                warnings: ['Never clamp without padding']
            },
            {
                stepNumber: 4,
                title: 'Clamped Hold',
                description: 'Hold clamp for 5-7 minutes maximum for beginners. Perform light jelqs or squeezes while clamped (optional).',
                duration: 420,
                tips: ['Check glans color every 2 minutes', 'Light movements only'],
                warnings: ['Release immediately if numbness occurs', 'Never exceed 10 minutes']
            },
            {
                stepNumber: 5,
                title: 'Release and Massage',
                description: 'Release clamp and massage thoroughly to restore circulation',
                duration: 120,
                tips: ['Focus on base and shaft', 'Use circular motions'],
                warnings: []
            },
            {
                stepNumber: 6,
                title: 'Second Pump Session',
                description: 'Return to pump for another 5 minute session at low pressure',
                duration: 300,
                tips: ['May use slightly higher pressure if comfortable', 'Monitor expansion'],
                warnings: ['Stop if pain occurs']
            },
            {
                stepNumber: 7,
                title: 'Cool-down',
                description: 'Cool down with light massage and warm wrap',
                duration: 300,
                tips: ['Gentle stretches can help', 'Apply moisturizer'],
                warnings: []
            }
        ],

        // Benefits
        benefits: [
            'Combines synergistic effects of pumping and clamping',
            'Enhanced girth gains through dual expansion methods',
            'Improved vascularity and blood flow capacity',
            'Progressive tissue expansion for permanent gains',
            'Better tissue conditioning than single method',
            'Potential for faster girth development'
        ],

        // Categories
        categories: ['Girth', 'Advanced', 'PE Training', 'Combination Method'],

        // Equipment
        equipmentNeeded: [
            'Penis pump with pressure gauge',
            'Cable clamp',
            'Padding material (cloth or mousepad)',
            'Lubricant for pumping',
            'Warm wrap or heating pad',
            'Timer'
        ],

        // Duration
        estimatedDurationMinutes: 25,

        // Safety
        safetyNotes: `Never exceed 10 minutes of continuous clamping. Stop immediately if numbness or coldness occurs. Monitor for signs of injury including spots or discoloration. Beginners should start with very low pressure and short durations. Never sleep with clamp on. Check circulation every few minutes. Avoid if you have vascular issues.`,

        // Progression criteria
        progressionCriteria: {
            minimumSessions: 30,
            consistencyDays: 21,
            keyIndicators: [
                'Can handle 7-10 Hg pump pressure comfortably',
                'Can maintain clamp for 10 minutes without discomfort',
                'No adverse reactions or injury signs',
                'Visible temporary expansion after sessions'
            ],
            readinessMarkers: [
                'Mastered basic pumping technique',
                'Experienced with clamping safely',
                'Good understanding of personal limits',
                'Consistent girth improvements noted'
            ]
        },

        // Related methods
        relatedMethods: [
            'bfr_clamping',
            'bathmate_pump',
            'manual_girth_squeezes',
            'wet_jelq',
            'cock_ring_training'
        ],

        // Timer configuration
        timerConfig: {
            totalDuration: 1500, // 25 minutes
            hasRest: true,
            restBetweenSets: 120,
            intervals: [
                { name: 'Warm-up', duration: 300, type: 'prep' },
                { name: 'Pump Session 1', duration: 300, type: 'work' },
                { name: 'Clamp Application', duration: 60, type: 'transition' },
                { name: 'Clamped Hold', duration: 420, type: 'work' },
                { name: 'Release & Massage', duration: 120, type: 'rest' },
                { name: 'Pump Session 2', duration: 300, type: 'work' },
                { name: 'Cool-down', duration: 300, type: 'rest' }
            ]
        },

        // Metadata
        isFeatured: true,
        communityRating: 85,
        sourceType: 'reddit',
        sourceUrl: 'https://reddit.com/r/thescienceofpe',

        // Timestamps
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        extractedDate: new Date().toISOString(),

        // Flags
        migratedFromPE: true,
        version: 2
    };

    return pacExercise;
}

// Upload to Firebase
async function uploadPACExercise() {
    console.log('🚀 Starting PAC exercise upload to Firebase...\n');

    const db = initializeFirebase();
    const collection = db.collection('growth_exercises');

    try {
        const pacDoc = createPACDocument();
        const docId = 'pump_assisted_clamping_pac';

        // Check if it already exists
        const existing = await collection.doc(docId).get();
        if (existing.exists) {
            console.log('⚠️ PAC exercise already exists, updating...');
        }

        // Upload the document
        await collection.doc(docId).set(pacDoc, { merge: true });

        console.log('✅ PAC exercise uploaded successfully!');
        console.log('\n📋 Exercise Details:');
        console.log(`  ID: ${docId}`);
        console.log(`  Title: ${pacDoc.title}`);
        console.log(`  Category: Girth (Advanced)`);
        console.log(`  Duration: ${pacDoc.estimatedDurationMinutes} minutes`);
        console.log(`  Steps: ${pacDoc.steps.length}`);
        console.log(`  Equipment: ${pacDoc.equipmentNeeded.length} items`);
        console.log(`  Timer intervals: ${pacDoc.timerConfig.intervals.length}`);

        // Verify upload
        console.log('\n🔍 Verifying upload...');
        const verification = await collection.doc(docId).get();
        if (verification.exists) {
            console.log('✅ Verification successful - PAC exercise is in Firebase!');
            console.log(`🔗 Document path: growth_exercises/${docId}`);
        }

    } catch (error) {
        console.error('❌ Error uploading PAC exercise:', error);
        process.exit(1);
    }
}

// Run the upload
uploadPACExercise()
    .then(() => {
        console.log('\n🎉 PAC exercise successfully added to Growth Training app!');
        process.exit(0);
    })
    .catch(error => {
        console.error('Failed:', error);
        process.exit(1);
    });