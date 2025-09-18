#!/bin/bash

# Deploy Firestore rules that include legal documents access

echo "Deploying Firestore rules with legal documents support..."

# Change to project root
cd "$(dirname "$0")/.."

# Deploy the firestore rules
firebase deploy --only firestore:rules

echo "Firestore rules deployed successfully!"