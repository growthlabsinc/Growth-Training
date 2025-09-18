import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK
try {
  // Try service account first, then fall back to application default credentials
  let credential;
  try {
    const serviceAccountPath = path.join(__dirname, 'service-account.json');
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    credential = admin.credential.cert(serviceAccount);
    console.log('Using service account credentials');
  } catch (serviceError) {
    credential = admin.credential.applicationDefault();
    console.log('Using application default credentials');
  }

  admin.initializeApp({
    credential: credential,
    projectId: 'growth-70a85' // Set project ID explicitly
  });
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
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

// Seed educational resources data
const seedEducationalResources = async () => {
  console.log('Starting educational resources upload...');
  
  const resourcesData = readJsonFile('data/sample-resources.json');
  
  if (!resourcesData) {
    console.error('Failed to read educational resources data.');
    return false;
  }
  
  console.log(`Found ${resourcesData.length} educational resources to upload`);
  
  let uploaded = 0;
  let errors = 0;
  
  // Use individual writes instead of batch to handle large data better
  for (const resource of resourcesData) {
    try {
      const docRef = db.collection('educationalResources').doc(resource.resourceId);
      await docRef.set({
        ...resource,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        publicationDate: admin.firestore.FieldValue.serverTimestamp(),
        published: true
      });
      
      console.log(`✓ Uploaded: ${resource.title}`);
      uploaded++;
    } catch (error) {
      console.error(`✗ Failed to upload ${resource.resourceId}:`, error.message);
      errors++;
    }
  }
  
  console.log(`\nUpload complete: ${uploaded} successful, ${errors} errors`);
  return errors === 0;
};

// Main function
const main = async () => {
  try {
    const success = await seedEducationalResources();
    if (success) {
      console.log('All educational resources uploaded successfully!');
      process.exit(0);
    } else {
      console.error('Some resources failed to upload');
      process.exit(1);
    }
  } catch (error) {
    console.error('Upload failed:', error);
    process.exit(1);
  }
};

main();