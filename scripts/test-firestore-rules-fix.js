import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK
try {
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
    projectId: 'growth-70a85'
  });
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  process.exit(1);
}

const updateFirestoreRules = async () => {
  console.log('=== Updating Firestore Security Rules for Educational Resources ===\n');
  
  try {
    // Read the current rules file
    const rulesPath = path.resolve(__dirname, '../firestore.rules');
    const currentRules = fs.readFileSync(rulesPath, 'utf8');
    
    console.log('Current rules snippet for educationalResources:');
    const relevantLines = currentRules.split('\n').filter(line => 
      line.includes('educationalResources') || 
      (line.includes('allow read') && currentRules.indexOf(line) > currentRules.indexOf('educationalResources'))
    );
    relevantLines.forEach(line => console.log(`   ${line.trim()}`));
    
    // Create updated rules with public read access for educationalResources
    const updatedRules = currentRules.replace(
      /\/\/ Educational resources collection - authenticated users can read\s*\n\s*match \/educationalResources\/\{resourceId\} \{\s*\n\s*allow read: if request\.auth != null;/,
      `// Educational resources collection - public read access (temporary for debugging)
    match /educationalResources/{resourceId} {
      allow read: if true; // Temporarily allow public read for debugging`
    );
    
    if (updatedRules === currentRules) {
      console.log('\n❌ No changes made - pattern not found exactly as expected');
      console.log('Manual update required. Here\'s the recommended change:');
      console.log('\nFind this section:');
      console.log('    match /educationalResources/{resourceId} {');
      console.log('      allow read: if request.auth != null;');
      console.log('\nReplace with:');
      console.log('    match /educationalResources/{resourceId} {');
      console.log('      allow read: if true; // Temporarily allow public read for debugging');
      
      return false;
    }
    
    // Write the updated rules
    const backupPath = rulesPath + '.backup';
    fs.writeFileSync(backupPath, currentRules);
    console.log(`\n✅ Backup created: ${backupPath}`);
    
    fs.writeFileSync(rulesPath, updatedRules);
    console.log('✅ Updated firestore.rules with public read access for educationalResources');
    
    console.log('\n📝 Next steps:');
    console.log('1. Deploy the updated rules: firebase deploy --only firestore:rules');
    console.log('2. Test the iOS app to see if educational resources load');
    console.log('3. If successful, the issue is authentication-related');
    console.log('4. If still not working, the issue is elsewhere');
    console.log('5. Remember to revert the rules after debugging!');
    
    return true;
    
  } catch (error) {
    console.error('Error updating rules:', error);
    return false;
  }
};

// Main function
const main = async () => {
  try {
    const success = await updateFirestoreRules();
    process.exit(success ? 0 : 1);
  } catch (error) {
    console.error('Update failed:', error);
    process.exit(1);
  }
};

main();