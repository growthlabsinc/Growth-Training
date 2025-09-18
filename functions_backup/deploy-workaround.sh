#!/bin/bash

echo "🔧 Firebase Functions Deployment Workaround"
echo "=========================================="

# 1. Set environment variable to skip admin initialization during discovery
export FUNCTIONS_EMULATOR=true

# 2. Try deployment with the environment variable
echo "📦 Attempting deployment with initialization skip..."
cd ..
firebase deploy --only functions --force

# If that fails, try with explicit timeout
if [ $? -ne 0 ]; then
    echo "⚠️ Standard deployment failed, trying with extended timeout..."
    export FUNCTIONS_DISCOVERY_TIMEOUT=30000
    firebase deploy --only functions --force
fi

echo "✅ Deployment attempt complete"