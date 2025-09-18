#!/bin/bash

# Growth App - Webhook Configuration Verification Script
# This script helps verify App Store webhook setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WEBHOOK_URL="https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification"
FIREBASE_PROJECT="growth-70a85"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if Firebase CLI is installed
check_firebase_cli() {
    print_status "Checking Firebase CLI..."
    if command -v firebase &> /dev/null; then
        print_success "Firebase CLI installed"
        firebase --version
    else
        print_error "Firebase CLI not installed"
        echo "Install with: npm install -g firebase-tools"
        exit 1
    fi
}

# Check current Firebase project
check_firebase_project() {
    print_status "Checking Firebase project..."
    local current_project=$(firebase use 2>/dev/null | grep "Active Project:" | awk '{print $3}')
    
    if [ "$current_project" = "$FIREBASE_PROJECT" ]; then
        print_success "Correct Firebase project active: $current_project"
    else
        print_warning "Different project active: $current_project"
        print_status "Switching to $FIREBASE_PROJECT..."
        firebase use $FIREBASE_PROJECT
    fi
}

# Verify function is deployed
check_function_deployed() {
    print_status "Checking if handleAppStoreNotification function is deployed..."
    
    local functions=$(firebase functions:list 2>/dev/null | grep handleAppStoreNotification || true)
    
    if [ -n "$functions" ]; then
        print_success "Function is deployed"
        echo "$functions"
    else
        print_error "Function not found!"
        print_status "Deploy with: firebase deploy --only functions:handleAppStoreNotification"
        return 1
    fi
}

# Test webhook URL accessibility
test_webhook_url() {
    print_status "Testing webhook URL accessibility..."
    
    # Send a simple GET request (function should reject it, but we'll get a response)
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$WEBHOOK_URL" 2>/dev/null)
    
    if [ "$response" = "405" ] || [ "$response" = "400" ]; then
        print_success "Webhook URL is accessible (got expected $response response)"
    elif [ "$response" = "200" ]; then
        print_warning "Webhook returned 200 for GET request (should only accept POST)"
    elif [ "$response" = "404" ]; then
        print_error "Webhook returned 404 - Function may not be deployed"
    else
        print_error "Unexpected response code: $response"
    fi
}

# Check Firebase configuration
check_firebase_config() {
    print_status "Checking Firebase configuration..."
    
    # Check if shared secret is configured
    local config=$(firebase functions:config:get 2>/dev/null | grep -c "appstore.shared_secret" || true)
    
    if [ "$config" -gt 0 ]; then
        print_success "App Store shared secret is configured"
    else
        print_error "App Store shared secret not found in Firebase config"
        print_status "Set with: firebase functions:config:set appstore.shared_secret=\"YOUR_SECRET\""
    fi
}

# View recent function logs
check_function_logs() {
    print_status "Checking recent function logs..."
    
    echo "Last 10 invocations of handleAppStoreNotification:"
    firebase functions:log --only handleAppStoreNotification -n 10 2>/dev/null || {
        print_warning "No recent logs found"
    }
}

# Generate webhook test payload
generate_test_payload() {
    print_status "Generating sample webhook test payload..."
    
    cat > webhook_test_payload.json << 'EOF'
{
  "signedPayload": "eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUlFTURDQ0E3YWdBd0lCQWdJUWFQb1BsZHZwU29FSDBsQnJqRFB2OWpBS0JnZ3Foa2pPUFFRREF6QjFNVVF3UWdZRFZRUURERHRCY0hCc1pTQlhiM0pzWkhkcFpHVWdSR1YyWld4dmNHVnlJRkpsYkdGMGFXOXVjeUJEWlhKMGFXWnBZMkYwYVc5dUlFRjFkR2h2Y21sMGVURUxNQWtHQTFVRUN3d0NSell4RXpBUkJnTlZCQW9NQ2tGd2NHeGxJRWx1WXk0eEN6QUpCZ05WQkFZVEFsVlRNQjRYRFRJeE1Ea3dNakU1TlRZMU4xb1hEVEl6TVRBd01qRTVOVFkxTmxvd2daSXhRREErQmdOVkJBTU1OMUJ5YjJRZ1JVTkRJRTFoWXlCQmNIQWdVM1J2Y21VZ1lXNWtJR2xVZFc1bGN5QlRkRzl5WlNCU1pXTmxhWEIwSUZOcFoyNXBibWN4TERBcUJnTlZCQXNNSTBGd2NHeGxJRmR2Y214a2QybGtaU0JFWlhabGJHOXdaWElnVW1Wc1lYUnBiMjV6TVJNd0VRWURWUVFLREFwQmNIQnNaU0JKYm1NdU1Rc3dDUVlEVlFRR0V3SlZVekJaTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUFCT29UY2FQY3BFVXgrcUxIOGlwc1JlYzVCc2s1bGNWUm5nUUNnbmNOSmRiREx2OUIyaHIwYW5jVTVXMWVsS3BpUjNLWEU5WVBFN0h1QjBnVHBvbkZ1Z3FqZ2dJSU1JSUNCREFNQmdOVkhSTUJBZjhFQWpBQU1COEdBMVVkSXdRWU1CYUFGRDQ4dlJzUk0xVTFsNklLaVBwbm5Vd3Rsb2NmTUhBR0NDc0dBUVVGQndFQkJHUXdZakF0QmdnckJnRUZCUWN3QW9ZaGFIUjBjRG92TDJObGNuUnpMbUZ3Y0d4bExtTnZiUzkzZDJSeVp6WXVaR1Z5TURFR0NDc0dBUVVGQnpBQmhpVm9kSFJ3T2k4dmIyTnpjQzVoY0hCc1pTNWpiMjB2YjJOemNEQXpMWGQzWkhKbk5qQXlNSUlCSGdZRFZSMGdCSUlCRlRDQ0FSRXdnZ0VOQmdvcWhraUc5Mk5rQlFZQk1JSCtNSUhEQmdnckJnRUZCUWNDQWpDQnRneUJzMUpsYkdsaGJtTmxJRzl1SUhSb2FYTWdZMlZ5ZEdsbWFXTmhkR1VnWW5rZ1lXNTVJSEJoY25SNUlHRnpjM1Z0WlhNZ1lXTmpaWEIwWVc1alpTQnZaaUIwYUdVZ2RHaGxiaUJoY0hCc2FXTmhZbXhsSUhOMFlXNWtZWEprSUhSbGNtMXpJR0Z1WkNCamIyNWthWFJwYjI1eklHOW1JSFZ6WlN3Z1kyVnlkR2xtYVdOaGRHVWdjRzlzYVdONUlHRnVaQ0JqWlhKMGFXWnBZMkYwYVc5dUlIQnlZV04wYVdObElITjBZWFJsYldWdWRITXVNRFlHQ0NzR0FRVUZCd0lCRmlwb2RIUndPaTh2ZDNkM0xtRndjR3hsTG1OdmJTOWpaWEowYVdacFkyRjBaV0YxZEdodmNtbDBlUzh3SFFZRFZSME9CQllFRkFNcGJHeUJ6a2RLNjJDWUtyMjNuK1hGeTl5eU1BNEdBMVVkRHdFQi93UUVBd0lIZ0RBUUJnb3Foa2lHOTJOa0JnSUJCQUlGQURBS0JnZ3Foa2pPUFFRREF3Tm9BREJsQWpFQTBjNGhDeDQ0L0o3K2wzVjJYYnVKR0xSek0yU1hTWXkyaHlDdXZqeG9ZNHZJOUdjRHFvN291YlhIZ2RFRTV0d0FqQkdWMDNWRGtCT0VqUGZmZWlYZm1vL1VKcUpaT2R2WGd0VDBlaGx2V1JRSHBVMWdFSzNwOEFKdE5KZVB5aGI5az0iLCJNSUlER2pDQ0FxQ2dBd0lCQWdJSVZEMzg4WTNVdUVRd0NnWUlLb1pJemowRUF3TXdaekViTUJrR0ExVUVBd3dTUVhCd2JHVWdVbTl2ZENCRFFTQXRJRWN6TVNZd0pBWURWUVFMREIxQmNIQnNaU0JEWlhKMGFXWnBZMkYwYVc5dUlFRjFkR2h2Y21sMGVURVRNQkVHQTFVRUNnd0tRWEJ3YkdVZ1NXNWpMakVMTUFrR0ExVUVCaE1DVlZNd0hoY05NVFF3TkRNd01UZ3hPVEEyV2hjTk16a3dORE13TVRneE9UQTJXakIxTVVRd1FnWURWUVFEREQxQmNIQnNaU0JYYjNKc1pIZHBaR1VnUkdWMlpXeHZjR1Z5SUZKbGJHRjBhVzl1Y3lCRFpYSjBhV1pwWTJGMGFXOXVJRUYxZEdodmNtbDBlVEVMTUFrR0ExVUVDd3dDUnpZeEV6QVJCZ05WQkFvTUNrRndjR3hsSUVsdVl5NHhDekFKQmdOVkJBWVRBbFZUTUhZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUNJRFlnQUVic1FLQytJeWl3WlZ3Q0FpU0dyS3lLNTRHcnlyZUQ3bU16RVZVaXEydkhzbGtVcEF2UW9oTHJrTWhwQjRmOGZZQkFRTTJ4SXBoOFBtTWlQaHRqRFNQRUNDWHZoeU4ybDFGU3YxcjdWZW1qQmNJMXpYbWI3a3BTcTcxdEJyNGgybzJZd1pEQVNCZ05WSFRNQUF"
}
EOF
    
    print_success "Test payload saved to: webhook_test_payload.json"
    print_status "Note: This is a sample structure. Real notifications are signed by Apple."
}

# Provide setup instructions
show_setup_instructions() {
    echo ""
    print_status "📋 App Store Connect Webhook Setup Instructions:"
    echo ""
    echo "1. Log in to App Store Connect: https://appstoreconnect.apple.com"
    echo "2. Select your app: Growth: Method"
    echo "3. Go to 'App Information' in the sidebar"
    echo "4. Scroll to 'App Store Server Notifications' section"
    echo "5. Configure URLs:"
    echo "   - Production URL: $WEBHOOK_URL"
    echo "   - Sandbox URL: $WEBHOOK_URL (same URL)"
    echo "6. Select 'Version 2' for notification version"
    echo "7. Enable all notification types"
    echo "8. Click 'Save'"
    echo "9. Test using 'Send Test Notification' button"
    echo ""
}

# Main execution
main() {
    print_status "🪝 App Store Webhook Configuration Verifier"
    echo ""
    
    # Run all checks
    check_firebase_cli
    check_firebase_project
    check_function_deployed
    test_webhook_url
    check_firebase_config
    
    echo ""
    print_status "📊 Recent Activity:"
    check_function_logs
    
    echo ""
    generate_test_payload
    
    # Show setup instructions
    show_setup_instructions
    
    # Summary
    echo ""
    print_success "✅ Verification complete!"
    print_status "Webhook URL: $WEBHOOK_URL"
    print_status "Ready for App Store Connect configuration"
}

# Run main function
main