#!/bin/bash

# Deploy AI Coach function with increased token limit and updated prompts

echo "🚀 Deploying AI Coach function with:"
echo "   - Increased token limit (4096)"
echo "   - Brief initial responses with follow-up offers"
echo "   - Medical question handling with Angion Method context"

# Navigate to functions directory
cd "$(dirname "$0")/../functions" || exit 1

# Deploy only the generateAIResponse function
echo "📦 Deploying generateAIResponse function..."
firebase deploy --only functions:generateAIResponse

if [ $? -eq 0 ]; then
    echo "✅ AI Coach function deployed successfully!"
    echo "📝 Changes deployed:"
    echo "   - Token limit increased to 4096 (from 1024)"
    echo "   - AI Coach now provides brief initial responses"
    echo "   - Medical questions handled with Angion Method context when available"
    echo ""
    echo "🧪 Run ./scripts/test-ai-coach-brief-responses.js to test the new behavior"
else
    echo "❌ Failed to deploy AI Coach function"
    exit 1
fi