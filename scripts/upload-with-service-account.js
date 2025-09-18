import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK with service account
const serviceAccountPath = '/Users/tradeflowj/Downloads/growth-70a85-firebase-adminsdk-fbsvc-854a45a4b3.json';
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'growth-70a85'
});

const db = admin.firestore();

// Read educational resources
const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
const resourcesData = JSON.parse(fs.readFileSync(resourcesPath, 'utf8'));

console.log(`Uploading ${resourcesData.length} educational resources to Firestore...`);

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