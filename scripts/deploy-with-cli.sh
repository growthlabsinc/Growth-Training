#!/bin/bash

echo "🚀 Deploying Angion Methods to Firebase Firestore..."
echo ""

# Change to scripts directory
cd /Users/tradeflowj/Desktop/Dev/growth-fresh/scripts

# Deploy each method
echo "📝 Deploying Angion Method 1.0..."
cat angion-method-1-0-multistep.json | firebase firestore:set growthMethods/angion_method_1_0 --yes

echo "📝 Deploying Angio Pumping..."
cat angion-methods-multistep/angio-pumping.json | firebase firestore:set growthMethods/angio_pumping --yes

echo "📝 Deploying Angion Method 2.0..."
cat angion-methods-multistep/angion-method-2-0.json | firebase firestore:set growthMethods/angion_method_2_0 --yes

echo "📝 Deploying Jelq 2.0..."
cat angion-methods-multistep/jelq-2-0.json | firebase firestore:set growthMethods/jelq_2_0 --yes

echo "📝 Deploying Vascion..."
cat angion-methods-multistep/vascion.json | firebase firestore:set growthMethods/vascion --yes

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📱 Next steps:"
echo "  1. Open the Growth app"
echo "  2. Check Methods section for updated Angion Methods"
echo "  3. Verify multi-step format is working"