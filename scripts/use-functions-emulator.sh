#!/bin/bash

echo "=== Switching to Firebase Functions Emulator ==="
echo ""
echo "This is a temporary workaround for the authentication issue."
echo ""

# Navigate to project root
cd "$(dirname "$0")/.."

# Start the Firebase emulator
echo "Starting Firebase emulator..."
echo "This will run functions locally and bypass Cloud Run IAM issues."
echo ""

# Export the emulator settings
export FIRESTORE_EMULATOR_HOST="localhost:8082"
export FIREBASE_AUTH_EMULATOR_HOST="localhost:9092"

# Start emulators
firebase emulators:start --only auth,functions,firestore

echo ""
echo "=== Emulator Started ==="
echo ""
echo "To use the emulator in your app, uncomment these lines in AICoachService.swift:"
echo ""
echo "#if DEBUG"
echo "functions.useEmulator(withHost: \"localhost\", port: 5002)"
echo "#endif"
echo ""
echo "The emulator bypasses Cloud Run IAM restrictions while keeping authentication checks."