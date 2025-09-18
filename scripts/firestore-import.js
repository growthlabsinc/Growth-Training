import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Read the educational resources data
const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
const resourcesData = JSON.parse(fs.readFileSync(resourcesPath, 'utf8'));

// Create the import structure for Firebase CLI
const importData = {
  __collections__: {
    educationalResources: {}
  }
};

// Convert each resource to the Firebase import format
resourcesData.forEach(resource => {
  const docId = resource.resourceId;
  importData.__collections__.educationalResources[docId] = {
    ...resource,
    createdAt: { __datatype__: "timestamp", value: new Date().toISOString() },
    updatedAt: { __datatype__: "timestamp", value: new Date().toISOString() },
    publicationDate: { __datatype__: "timestamp", value: new Date().toISOString() },
    published: true
  };
});

// Write the import file
const outputPath = path.join(__dirname, 'firestore-import.json');
fs.writeFileSync(outputPath, JSON.stringify(importData, null, 2));

console.log(`Created import file: ${outputPath}`);
console.log(`Ready to import ${resourcesData.length} educational resources`);
console.log('Run: firebase firestore:import ./scripts/firestore-import.json');