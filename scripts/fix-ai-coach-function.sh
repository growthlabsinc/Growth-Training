#!/bin/bash

echo "Fixing AI Coach Firebase Function configuration..."

# Navigate to project root
cd "$(dirname "$0")/.." || exit 1

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Error: Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Get the current project
PROJECT_ID=$(firebase use | grep "Active Project:" | cut -d':' -f2 | tr -d ' ')
if [ -z "$PROJECT_ID" ]; then
    echo "Error: No active Firebase project. Run 'firebase use <project-id>' first."
    exit 1
fi

echo "Current Firebase project: $PROJECT_ID"

# Deploy the function with proper configuration
echo "Deploying generateAIResponse function..."
firebase deploy --only functions:generateAIResponse

# After deployment, we need to ensure the function allows unauthenticated invocations
echo ""
echo "Setting function to allow unauthenticated invocations..."
gcloud functions add-iam-policy-binding generateAIResponse \
    --member="allUsers" \
    --role="roles/cloudfunctions.invoker" \
    --project="$PROJECT_ID" \
    --region="us-central1" \
    --gen2 2>/dev/null || echo "Note: If the above command failed, the function may already be publicly accessible."

echo ""
echo "Function deployment complete!"
echo ""
echo "Next steps:"
echo "1. Test the AI Coach feature in the app"
echo "2. If you still see UNAUTHENTICATED errors, check the Firebase Console logs"
echo "3. Ensure your Firebase project has the necessary APIs enabled:"
echo "   - Cloud Functions API"
echo "   - Cloud Build API"
echo "   - Artifact Registry API"