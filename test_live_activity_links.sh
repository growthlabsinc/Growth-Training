#!/bin/bash

echo "🧪 Testing Live Activity Deep Links"
echo "==================================="
echo ""
echo "This script helps test deep link handling on the simulator"
echo ""

# Function to test a URL
test_url() {
    local url=$1
    echo "Testing: $url"
    xcrun simctl openurl booted "$url"
    echo "✅ Sent to simulator"
    echo ""
}

echo "Make sure you have:"
echo "1. A simulator running with your app installed"
echo "2. A timer active with a Live Activity showing"
echo ""
echo "Press Enter to continue..."
read

echo "🔗 Testing pause link..."
test_url "growth://timer/pause/test-activity-id"

echo "Wait 2 seconds..."
sleep 2

echo "🔗 Testing resume link..."
test_url "growth://timer/resume/test-activity-id"

echo "Wait 2 seconds..."
sleep 2

echo "🔗 Testing stop link..."
test_url "growth://timer/stop/test-activity-id"

echo ""
echo "✅ Test complete!"
echo ""
echo "Check your app to see if the timer responded to the commands."
echo "Look for log messages starting with '🔗' in the console."