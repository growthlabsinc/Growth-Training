#!/bin/bash

echo "🔍 Checking certificates..."
echo ""

# Show current certificates
echo "Current Apple Distribution certificates:"
security find-identity -v -p codesigning | grep "Apple Distribution"

echo ""
echo "The certificate in your provisioning profile is: 93ACE079DBB37C8362E80B87EDD6D385BF7DF52E"
echo ""

echo "To fix the issue, you need to:"
echo "1. Open Keychain Access app"
echo "2. In the left sidebar, select 'login' keychain"
echo "3. Click on 'My Certificates'"
echo "4. Find the TWO 'Apple Distribution: Growth Labs, Inc' certificates"
echo "5. Right-click on the one that is NOT 93ACE079... and delete it"
echo "   (You can see the SHA-1 fingerprint in the certificate details)"
echo "6. Keep only: 93ACE079DBB37C8362E80B87EDD6D385BF7DF52E"
echo ""
echo "Alternative automated removal (BE CAREFUL):"
echo "Run this command to delete the wrong certificate:"
echo ""
echo "security delete-certificate -Z BE2DE471FA30BB53322F5E5D813322BC9AC9C32D"
echo ""
echo "After removing the duplicate, close and reopen Xcode."