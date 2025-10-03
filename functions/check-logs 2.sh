#!/bin/bash

# Try to find firebase command
FIREBASE_CMD=""
if command -v firebase &> /dev/null; then
    FIREBASE_CMD="firebase"
elif [ -f "./node_modules/.bin/firebase" ]; then
    FIREBASE_CMD="./node_modules/.bin/firebase"
elif [ -f "../node_modules/.bin/firebase" ]; then
    FIREBASE_CMD="../node_modules/.bin/firebase"
else
    echo "Firebase CLI not found. Please install it with: npm install -g firebase-tools"
    exit 1
fi

echo "Using Firebase command: $FIREBASE_CMD"
echo "Fetching last 50 function logs..."

# Run the command
$FIREBASE_CMD functions:log --limit 50