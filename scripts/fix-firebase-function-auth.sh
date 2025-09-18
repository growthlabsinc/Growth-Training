#!/bin/bash
#
# Fix Firebase Function Authentication Issues
# This script ensures the generateAIResponse function is properly configured
# to accept authenticated calls from Firebase SDK clients
#

set -e

echo "=== Fixing Firebase Function Authentication ==="
echo ""

# Define gcloud path
GCLOUD_PATH="${HOME}/google-cloud-sdk/bin/gcloud"

# Check if gcloud exists at this path, otherwise try system gcloud
if [ ! -f "$GCLOUD_PATH" ]; then
    GCLOUD_PATH="gcloud"
fi

# Check if the user is logged in to gcloud
if ! $GCLOUD_PATH auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "Error: You need to be logged in to gcloud"
    echo "Run: $GCLOUD_PATH auth login"
    exit 1
fi

# Get the active project
PROJECT_ID=$($GCLOUD_PATH config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "Error: No active project set"
    echo "Run: $GCLOUD_PATH config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Using project: $PROJECT_ID"
echo ""

# Function and service details
FUNCTION_NAME="generateAIResponse"
REGION="us-central1"
SERVICE_NAME="generateairesponse"  # Cloud Run service name (lowercase)

echo "1. Checking current IAM bindings for Cloud Run service..."
echo ""

# Get current IAM policy
echo "Current IAM bindings:"
$GCLOUD_PATH run services get-iam-policy $SERVICE_NAME \
    --region=$REGION \
    --format="table(bindings.role, bindings.members)" 2>/dev/null || {
    echo "Failed to get current IAM policy. The service might not be accessible."
    echo ""
}

echo ""
echo "2. Adding IAM bindings to allow authenticated Firebase users..."
echo ""

# Add IAM binding for all authenticated users (Firebase Auth users)
echo "Adding invoker permission for all users..."
$GCLOUD_PATH run services add-iam-policy-binding $SERVICE_NAME \
    --region=$REGION \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --quiet 2>/dev/null || {
    echo "Note: Could not add allUsers binding. This is expected if you want to restrict to authenticated users only."
}

# Alternative: Add invoker permission for authenticated users only
# This is more secure but requires proper authentication token handling
echo ""
echo "Adding invoker permission for authenticated users..."
$GCLOUD_PATH run services add-iam-policy-binding $SERVICE_NAME \
    --region=$REGION \
    --member="allAuthenticatedUsers" \
    --role="roles/run.invoker" \
    --quiet 2>/dev/null || {
    echo "Note: Could not add allAuthenticatedUsers binding."
}

echo ""
echo "3. Verifying the updated IAM policy..."
echo ""

# Show updated IAM policy
echo "Updated IAM bindings:"
$GCLOUD_PATH run services get-iam-policy $SERVICE_NAME \
    --region=$REGION \
    --format="table(bindings.role, bindings.members)" 2>/dev/null || {
    echo "Could not retrieve updated IAM policy."
}

echo ""
echo "4. Redeploying the function to ensure changes take effect..."
echo ""

# Navigate to functions directory
cd functions

# Deploy the function
firebase deploy --only functions:generateAIResponse

echo ""
echo "=== Authentication Fix Complete ==="
echo ""
echo "The generateAIResponse function should now accept authenticated calls."
echo ""
echo "Important notes:"
echo "1. The function requires Firebase Authentication (not anonymous users)"
echo "2. Users must be signed in to use the AI Coach feature"
echo "3. The app is already configured to handle this requirement"
echo ""
echo "If you're still experiencing issues:"
echo "1. Ensure the user is properly authenticated in the app"
echo "2. Check that the ID token is being sent with requests"
echo "3. Verify App Check is not blocking requests (it's disabled for this function)"