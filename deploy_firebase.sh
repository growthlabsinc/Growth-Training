#!/bin/bash

echo "🚀 Deploying manageLiveActivityUpdates function..."

# Navigate to project directory
cd /Users/tradeflowj/Desktop/Dev/growth-fresh

# Deploy the specific function
firebase deploy --only functions:manageLiveActivityUpdates

echo "✅ Deployment complete!"