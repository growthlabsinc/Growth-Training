#!/bin/bash

echo "🔍 Checking APNs Configuration"
echo "=============================="
echo ""

# Check if the APNs key file exists
echo "📁 Checking APNs key files:"
ls -la functions/AuthKey_*.p8 2>/dev/null || echo "No APNs key files found"
echo ""

# Check which key ID is being used
echo "🔑 Key IDs found in code:"
grep -r "KEY_ID.*=" functions/*.js | grep -E "55LZB28UY2|66LQV834DU|3G84L8G52R" || echo "No key IDs found"
echo ""

# Check Team ID
echo "👥 Team IDs found in code:"
grep -r "TEAM_ID.*=" functions/*.js | grep -E "62T6J77P6R" || echo "No team IDs found"
echo ""

# Check secrets
echo "🔐 Checking configured secrets:"
gcloud secrets list | grep -E "APNS_|APP_STORE" || echo "No secrets found"
echo ""

# Check secret versions
echo "📋 Checking APNS secret versions:"
for SECRET in APNS_AUTH_KEY APNS_KEY_ID APNS_TEAM_ID; do
    echo -n "$SECRET: "
    gcloud secrets versions list $SECRET --limit=1 2>/dev/null | grep -v NAME | awk '{print "version", $1, "created", $2}' || echo "Not found"
done
echo ""

echo "💡 Notes:"
echo "- The APNs InvalidProviderToken error usually means:"
echo "  1. Wrong Team ID or Key ID"
echo "  2. Key not enabled for the correct app"
echo "  3. Key has been revoked"
echo "  4. Wrong environment (dev vs prod)"
echo ""
echo "- Current APNs host: api.development.push.apple.com (for Xcode builds)"