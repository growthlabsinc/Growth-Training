const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK with service account
try {
  // Look for service account file in the same directory
  const serviceAccount = require('./service-account.json');
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  console.error('Make sure you have a valid service-account.json file in the scripts directory');
  process.exit(1);
}

// Get Firestore database reference
const db = admin.firestore();

// Helper function to read and parse JSON data files
const readJsonFile = (filePath) => {
  try {
    const fullPath = path.resolve(__dirname, '..', filePath);
    const fileContent = fs.readFileSync(fullPath, 'utf8');
    return JSON.parse(fileContent);
  } catch (error) {
    console.error(`Error reading ${filePath}:`, error);
    return null;
  }
};

// Helper: Validate a method entry for required fields and types
function validateMethod(method, idx) {
  const requiredFields = [
    'methodId',
    'stage',
    'title',
    'description',
    'instructions_text',
    'equipment_needed'
  ];
  for (const field of requiredFields) {
    if (!(field in method)) {
      return `Missing required field '${field}'`;
    }
    if (field === 'stage' && typeof method[field] !== 'number') {
      return `Field 'stage' must be a number`;
    }
    if (['methodId', 'title', 'description', 'instructions_text'].includes(field) && typeof method[field] !== 'string') {
      return `Field '${field}' must be a string`;
    }
    if (field === 'equipment_needed' && !Array.isArray(method[field])) {
      return `Field 'equipment_needed' must be an array`;
    }
  }
  return null;
}

/**
 * Field mapping for GrowthMethod seeding:
 * - methodId -> id (Firestore doc ID)
 * - description -> methodDescription
 * - instructions_text -> instructionsText
 * - visual_placeholder_url -> visualPlaceholderUrl
 * - equipment_needed -> equipmentNeeded
 * - estimatedTimeMinutes (optional, default 0)
 * - categories (optional, default [])
 * - isFeatured (optional, default false)
 * - safety_notes -> safetyNotes (optional)
 *
 * Any extra fields in the sample data are ignored.
 */
// Seed growth methods data
const seedGrowthMethods = async () => {
  const methodsData = readJsonFile('data/sample-methods.json');
  
  if (!methodsData) {
    console.error('Failed to read growth methods data.');
    return false;
  }
  
  let created = 0;
  let updated = 0;
  let skipped = 0;
  let invalid = 0;
  let invalidEntries = [];

  for (let i = 0; i < methodsData.length; i++) {
    const method = methodsData[i];
    const validationError = validateMethod(method, i);
    const methodId = method.methodId || `index_${i}`;
    if (validationError) {
      console.error(`[SKIP] Method ${methodId}: ${validationError}`);
      skipped++;
      invalid++;
      invalidEntries.push({ methodId, reason: validationError });
      continue;
    }
    const docId = method.methodId;
    const docRef = db.collection('growthMethods').doc(docId);
    const docSnap = await docRef.get();

    // Map fields to match GrowthMethod model
    const mapped = {
      id: docId,
      stage: method.stage,
      title: method.title,
      methodDescription: method.description,
      instructionsText: method.instructions_text,
      visualPlaceholderUrl: method.visual_placeholder_url || null,
      equipmentNeeded: method.equipment_needed || [],
      estimatedTimeMinutes: method.estimatedTimeMinutes || 0,
      categories: method.categories || [],
      isFeatured: method.isFeatured || false,
      safetyNotes: method.safety_notes || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      published: true
    };

    try {
      if (!docSnap.exists) {
        await docRef.set(mapped);
        console.log(`[CREATE] Method ${docId}`);
        created++;
      } else {
        await docRef.update(mapped);
        console.log(`[UPDATE] Method ${docId}`);
        updated++;
      }
    } catch (err) {
      console.error(`[ERROR] Method ${docId}: ${err.message}`);
      skipped++;
      invalid++;
      invalidEntries.push({ methodId: docId, reason: err.message });
    }
  }

  console.log(`\nGrowthMethods seeding complete. Created: ${created}, Updated: ${updated}, Skipped: ${skipped}`);
  if (invalid > 0) {
    console.error(`\n[FAIL] ${invalid} invalid entries found. See above for details.`);
    process.exit(1);
  }
  return true;
};

// Seed educational resources data
const seedEducationalResources = async () => {
  const resourcesData = readJsonFile('data/sample-resources.json');
  
  if (!resourcesData) {
    console.error('Failed to read educational resources data.');
    return false;
  }
  
  const batch = db.batch();
  
  resourcesData.forEach(resource => {
    const docRef = db.collection('educationalResources').doc(resource.resourceId);
    batch.set(docRef, {
      ...resource,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      publicationDate: admin.firestore.FieldValue.serverTimestamp(),
      published: true
    });
  });
  
  try {
    await batch.commit();
    console.log(`Successfully seeded ${resourcesData.length} educational resources.`);
    return true;
  } catch (error) {
    console.error('Error seeding educational resources:', error);
    return false;
  }
};

// Main function to run the seeding process
const seedAll = async () => {
  console.log('Starting data seeding process...');
  
  let successCount = 0;
  
  // Seed growth methods
  if (await seedGrowthMethods()) {
    successCount++;
  }
  
  // Seed educational resources
  if (await seedEducationalResources()) {
    successCount++;
  }
  
  if (successCount === 2) {
    console.log('All data seeded successfully!');
  } else {
    console.log(`Data seeding completed with some errors. ${successCount}/2 collections seeded.`);
  }
  
  // Exit the process
  process.exit(successCount === 2 ? 0 : 1);
};

// Run the seeding process
seedAll().catch(error => {
  console.error('Unhandled error during seeding:', error);
  process.exit(1);
}); 