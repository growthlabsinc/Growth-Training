#!/bin/bash
# Deployment script for the Vertex AI Search Cloud Function

# Check if required environment variables are set
if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
  echo "Error: GOOGLE_CLOUD_PROJECT environment variable is not set"
  exit 1
fi

LOCATION=${VERTEX_AI_SEARCH_LOCATION:-eu}
DATASTORE_ID=${VERTEX_AI_SEARCH_DATASTORE_ID}

if [ -z "$DATASTORE_ID" ]; then
  echo "Warning: VERTEX_AI_SEARCH_DATASTORE_ID environment variable is not set"
  echo "The Cloud Function will not work without a valid datastore ID"
  echo "Run the setup script first or set this environment variable manually"
fi

# Navigate to the cloud function directory
cd "$(dirname "$0")/../cloud-functions/vertex-ai-integration"

# Install dependencies
echo "Installing dependencies..."
npm install

# Deploy the Cloud Function
echo "Deploying searchVertexAI function to project $GOOGLE_CLOUD_PROJECT in $LOCATION..."
gcloud functions deploy searchVertexAI \
  --project="$GOOGLE_CLOUD_PROJECT" \
  --region="$LOCATION" \
  --runtime=nodejs16 \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars="GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,VERTEX_AI_SEARCH_LOCATION=$LOCATION,VERTEX_AI_SEARCH_DATASTORE_ID=$DATASTORE_ID"

# Check if deployment was successful
if [ $? -eq 0 ]; then
  echo "Cloud Function deployed successfully!"
  echo "You can now call the function at:"
  echo "https://$LOCATION-$GOOGLE_CLOUD_PROJECT.cloudfunctions.net/searchVertexAI"
else
  echo "Error deploying Cloud Function."
  exit 1
fi 