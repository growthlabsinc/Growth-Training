#!/bin/bash

echo "🔑 Setting Up Development APNs Key (55LZB28UY2)"
echo "=============================================="
echo ""

# Check if the key file already exists
if [ -f "./functions/AuthKey_55LZB28UY2.p8" ]; then
    echo "✅ Key file already exists at ./functions/AuthKey_55LZB28UY2.p8"
else
    echo "❌ Key file not found: ./functions/AuthKey_55LZB28UY2.p8"
    echo ""
    echo "📋 Please download the key:"
    echo "1. Go to: https://developer.apple.com/account/resources/authkeys/list"
    echo "2. Find key ID: 55LZB28UY2"
    echo "3. Download the .p8 file"
    echo "4. Save it as: ./functions/AuthKey_55LZB28UY2.p8"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "📊 Current Secret Configuration:"
CURRENT_KEY_ID=$(gcloud secrets versions access latest --secret="APNS_KEY_ID" 2>/dev/null || echo "Error")
echo "Current APNS_KEY_ID: $CURRENT_KEY_ID"
echo ""

if [ "$CURRENT_KEY_ID" == "55LZB28UY2" ]; then
    echo "✅ APNS_KEY_ID is already set to 55LZB28UY2"
else
    echo "🔄 Updating APNS_KEY_ID to 55LZB28UY2..."
    echo -n "55LZB28UY2" | gcloud secrets versions add APNS_KEY_ID --data-file=-
    echo "✅ APNS_KEY_ID updated"
fi

echo ""
echo "🔄 Updating APNS_AUTH_KEY with key content..."
gcloud secrets versions add APNS_AUTH_KEY --data-file=./functions/AuthKey_55LZB28UY2.p8
echo "✅ APNS_AUTH_KEY updated"

echo ""
echo "🔄 Redeploying updateLiveActivitySimplified function..."
firebase deploy --only functions:updateLiveActivitySimplified

echo ""
echo "✅ Development APNs key setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Check Firebase logs: firebase functions:log --only updateLiveActivitySimplified"
echo "2. Test Live Activity updates in the app"