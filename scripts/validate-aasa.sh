#!/bin/bash

# Validate Apple App Site Association Setup
# Usage: ./validate-aasa.sh [domain]

DOMAIN="${1:-growthlabs.coach}"

echo "🔍 Validating Apple App Site Association for: $DOMAIN"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check URL
check_url() {
    local url=$1
    local description=$2
    
    echo -e "\n📍 Checking: $description"
    echo "   URL: $url"
    
    # Check HTTP status
    status=$(curl -s -o /dev/null -w "%{http_code}" -L "$url")
    if [ "$status" = "200" ]; then
        echo -e "   ${GREEN}✓ HTTP Status: $status${NC}"
    else
        echo -e "   ${RED}✗ HTTP Status: $status${NC}"
        return 1
    fi
    
    # Check content type
    content_type=$(curl -s -I "$url" | grep -i "content-type" | cut -d' ' -f2 | tr -d '\r\n')
    if [[ "$content_type" == *"application/json"* ]]; then
        echo -e "   ${GREEN}✓ Content-Type: $content_type${NC}"
    else
        echo -e "   ${RED}✗ Content-Type: $content_type (should be application/json)${NC}"
    fi
    
    # Check for redirects
    redirect_count=$(curl -s -o /dev/null -w "%{redirect_url}" "$url" | wc -c)
    if [ "$redirect_count" -eq 0 ]; then
        echo -e "   ${GREEN}✓ No redirects${NC}"
    else
        echo -e "   ${RED}✗ Redirects detected (not allowed)${NC}"
    fi
    
    # Validate JSON
    content=$(curl -s "$url")
    if echo "$content" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓ Valid JSON${NC}"
        
        # Check for required fields
        if echo "$content" | grep -q '"applinks"'; then
            echo -e "   ${GREEN}✓ Contains applinks${NC}"
        else
            echo -e "   ${RED}✗ Missing applinks${NC}"
        fi
        
        # Check for Team ID placeholder
        if echo "$content" | grep -q 'YOUR_TEAM_ID'; then
            echo -e "   ${YELLOW}⚠️  Team ID placeholder found - remember to replace!${NC}"
        fi
    else
        echo -e "   ${RED}✗ Invalid JSON${NC}"
    fi
}

# Check both possible locations
check_url "https://$DOMAIN/apple-app-site-association" "Root path"
check_url "https://$DOMAIN/.well-known/apple-app-site-association" "Well-known path"

# Check with www subdomain
echo -e "\n📍 Checking www subdomain..."
check_url "https://www.$DOMAIN/apple-app-site-association" "WWW root path"
check_url "https://www.$DOMAIN/.well-known/apple-app-site-association" "WWW well-known path"

# Check SSL certificate
echo -e "\n🔒 Checking SSL Certificate..."
if curl -s -I "https://$DOMAIN" > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓ SSL certificate valid${NC}"
else
    echo -e "   ${RED}✗ SSL certificate issue${NC}"
fi

# Provide summary
echo -e "\n=================================================="
echo "📋 Summary:"
echo "- Replace YOUR_TEAM_ID with your actual Apple Developer Team ID"
echo "- Upload the file to at least one of the checked locations"
echo "- Ensure Content-Type is set to application/json"
echo "- No redirects should be present on the AASA file URL"
echo "- Delete and reinstall your app after uploading to test"

# Additional tips
echo -e "\n💡 Tips:"
echo "- Find your Team ID at https://developer.apple.com/account"
echo "- Or in Xcode: Project → Signing & Capabilities → Team"
echo "- Test links work by pasting in Notes app on physical device"
echo "- Use 'xcrun swcutil dl -d $DOMAIN' on macOS 11+ to debug"