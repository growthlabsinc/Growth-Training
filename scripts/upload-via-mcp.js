import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Read the educational resources data
const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
const resourcesData = JSON.parse(fs.readFileSync(resourcesPath, 'utf8'));

console.log(`Found ${resourcesData.length} educational resources to upload`);
console.log('Resources to upload:');

resourcesData.forEach((resource, index) => {
  console.log(`${index + 1}. ${resource.resourceId}: ${resource.title}`);
});

console.log('\nYou can now use the Firebase MCP to add these documents to the educationalResources collection.');
console.log('Use the document ID as the resourceId and add all the fields including:');
console.log('- title');
console.log('- content_text (as contentText in the app)');
console.log('- category');  
console.log('- visual_placeholder_url (as visualPlaceholderUrl in the app)');
console.log('- published: true');
console.log('- createdAt: current timestamp');
console.log('- updatedAt: current timestamp');
console.log('- publicationDate: current timestamp');