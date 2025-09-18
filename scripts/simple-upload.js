// Simple direct upload using Firebase Admin SDK with application default credentials
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

async function uploadWithSDK() {
  try {
    // Use dynamic import for firebase-admin
    const admin = await import('firebase-admin');
    
    // Initialize with application default credentials
    const app = admin.default.initializeApp({
      projectId: 'growth-70a85'
    });
    
    const db = admin.default.firestore();
    
    // Read the data
    const resourcesPath = join(__dirname, '..', 'data', 'sample-resources.json');
    const resourcesData = JSON.parse(readFileSync(resourcesPath, 'utf8'));
    
    console.log(`Uploading ${resourcesData.length} resources...`);
    
    // Upload one by one to avoid timeouts
    for (let i = 0; i < resourcesData.length; i++) {
      const resource = resourcesData[i];
      
      try {
        await db.collection('educationalResources').doc(resource.resourceId).set({
          ...resource,
          published: true,
          createdAt: admin.default.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.default.firestore.FieldValue.serverTimestamp(),
          publicationDate: admin.default.firestore.FieldValue.serverTimestamp()
        });
        
        console.log(`✓ ${i+1}/${resourcesData.length}: ${resource.title.substring(0, 50)}...`);
      } catch (err) {
        console.error(`✗ Failed ${resource.resourceId}: ${err.message}`);
      }
      
      // Small delay to prevent rate limiting
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.log('Upload complete!');
    process.exit(0);
    
  } catch (error) {
    console.error('Upload failed:', error.message);
    process.exit(1);
  }
}

uploadWithSDK();