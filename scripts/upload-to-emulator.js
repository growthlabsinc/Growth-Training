import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK for emulator
const app = admin.initializeApp({
  projectId: 'growth-70a85'
});

// Connect to emulator
const db = admin.firestore();
db.settings({
  host: 'localhost:8082',
  ssl: false
});

// Read educational resources
const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
const resourcesData = JSON.parse(fs.readFileSync(resourcesPath, 'utf8'));

console.log(`Uploading ${resourcesData.length} educational resources to Firestore emulator...`);

async function uploadResources() {
  let successful = 0;
  let failed = 0;
  
  for (const resource of resourcesData) {
    try {
      await db.collection('educationalResources').doc(resource.resourceId).set({
        ...resource,
        published: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        publicationDate: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`✓ ${resource.resourceId}: ${resource.title}`);
      successful++;
    } catch (error) {
      console.error(`✗ Failed ${resource.resourceId}: ${error.message}`);
      failed++;
    }
  }
  
  console.log(`\nUpload complete: ${successful} successful, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

uploadResources();