#!/bin/bash

echo "🚀 Firestore Knowledge Base Import via Firebase CLI"
echo "================================================"
echo ""

# Check if we have the export file
if [ ! -f "ai_coach_knowledge_export.json" ]; then
    echo "❌ Export file not found: ai_coach_knowledge_export.json"
    echo "Please run: node export-knowledge-base-for-import.js first"
    exit 1
fi

# Create a temporary file for Firestore import format
echo "📝 Preparing data for import..."

# Convert the export to Firestore CLI format
node -e '
const fs = require("fs");
const data = JSON.parse(fs.readFileSync("ai_coach_knowledge_export.json", "utf8"));

// Create documents in Firestore import format
const documents = [];
for (const [docId, docData] of Object.entries(data)) {
    documents.push({
        __name__: `projects/growth-70a85/databases/(default)/documents/ai_coach_knowledge/${docId}`,
        fields: convertToFirestoreFormat(docData)
    });
}

function convertToFirestoreFormat(obj) {
    const fields = {};
    for (const [key, value] of Object.entries(obj)) {
        if (typeof value === "string") {
            fields[key] = { stringValue: value };
        } else if (typeof value === "number") {
            fields[key] = { integerValue: value };
        } else if (Array.isArray(value)) {
            fields[key] = { 
                arrayValue: { 
                    values: value.map(v => ({ stringValue: String(v) })) 
                } 
            };
        } else if (typeof value === "object" && value !== null) {
            fields[key] = { 
                mapValue: { 
                    fields: convertToFirestoreFormat(value) 
                } 
            };
        }
    }
    return fields;
}

// Write to file
fs.writeFileSync("firestore_import.json", JSON.stringify(documents, null, 2));
console.log("✅ Created firestore_import.json");
'

if [ ! -f "firestore_import.json" ]; then
    echo "❌ Failed to create import file"
    exit 1
fi

echo ""
echo "📤 Importing to Firestore..."
echo ""

# Use Firebase CLI to import
# Note: This requires gcloud to be installed
if command -v gcloud &> /dev/null; then
    # Get access token
    ACCESS_TOKEN=$(gcloud auth application-default print-access-token 2>/dev/null)
    
    if [ -z "$ACCESS_TOKEN" ]; then
        echo "⚠️  Could not get access token automatically"
        echo ""
        echo "Manual import required:"
        echo "1. Go to: https://console.firebase.google.com/project/growth-70a85/firestore"
        echo "2. Create collection: ai_coach_knowledge"
        echo "3. Use the import feature with: ai_coach_knowledge_export.json"
    else
        echo "✅ Got access token"
        # Import using REST API would go here
        echo "⚠️  Automated import not fully implemented"
        echo ""
        echo "Please import manually:"
        echo "1. Go to: https://console.firebase.google.com/project/growth-70a85/firestore"
        echo "2. Create collection: ai_coach_knowledge"
        echo "3. Use the import feature with the prepared file"
    fi
else
    echo "ℹ️  gcloud CLI not found"
    echo ""
    echo "📋 Manual Import Instructions:"
    echo "================================"
    echo ""
    echo "1. Open Firebase Console:"
    echo "   https://console.firebase.google.com/project/growth-70a85/firestore"
    echo ""
    echo "2. Create new collection:"
    echo "   - Click 'Start collection'"
    echo "   - Collection ID: ai_coach_knowledge"
    echo "   - Click 'Next'"
    echo ""
    echo "3. Import the data:"
    echo "   You can either:"
    echo "   a) Use the Firebase Console import feature with: ai_coach_knowledge_export.json"
    echo "   b) Or use Firestore REST API with the commands in: firestore-import-commands.sh"
    echo ""
fi

# Clean up temporary file
rm -f firestore_import.json

echo ""
echo "🎯 Next Steps:"
echo "============="
echo ""
echo "After importing the data:"
echo "1. Deploy the updated functions:"
echo "   firebase deploy --only functions:generateAIResponse"
echo ""
echo "2. Test the AI Coach with questions like:"
echo '   - "What is AM1?"'
echo '   - "How do I perform Angion Method 1.0?"'
echo '   - "What are SABRE techniques?"'
echo ""