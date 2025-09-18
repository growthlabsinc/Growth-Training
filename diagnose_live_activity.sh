#!/bin/bash

# Live Activity Diagnostic Script
# This script helps diagnose Live Activity issues from Xcode logs

echo "========================================="
echo "Live Activity Diagnostic Tool"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check Live Activity logs
check_live_activity_logs() {
    echo -e "${BLUE}[1] Checking Live Activity Logs...${NC}"
    echo "----------------------------------------"
    
    # Stream logs for Live Activity
    log stream --predicate 'subsystem == "com.apple.ActivityKit" OR category == "LiveActivity" OR eventMessage CONTAINS "Live Activity" OR eventMessage CONTAINS "push token" OR eventMessage CONTAINS "ActivityKit"' --style compact --info --debug 2>&1 | while read line; do
        if [[ $line == *"error"* ]] || [[ $line == *"Error"* ]] || [[ $line == *"failed"* ]]; then
            echo -e "${RED}❌ $line${NC}"
        elif [[ $line == *"token"* ]] || [[ $line == *"Token"* ]]; then
            echo -e "${GREEN}🔑 $line${NC}"
        elif [[ $line == *"push"* ]] || [[ $line == *"Push"* ]]; then
            echo -e "${YELLOW}📤 $line${NC}"
        elif [[ $line == *"started"* ]] || [[ $line == *"Started"* ]]; then
            echo -e "${GREEN}✅ $line${NC}"
        else
            echo "$line"
        fi
    done &
    
    # Store the PID to kill later
    LOG_PID=$!
    
    # Let it run for 30 seconds
    sleep 30
    
    # Kill the log stream
    kill $LOG_PID 2>/dev/null
    
    echo ""
    echo -e "${GREEN}Log monitoring complete.${NC}"
}

# Function to check push notification logs
check_push_logs() {
    echo ""
    echo -e "${BLUE}[2] Checking Push Notification Logs...${NC}"
    echo "----------------------------------------"
    
    log stream --predicate 'subsystem == "com.apple.pushkit" OR subsystem == "com.apple.apsd" OR eventMessage CONTAINS "APNs" OR eventMessage CONTAINS "push notification"' --style compact --info --debug 2>&1 | head -50
}

# Function to check widget logs
check_widget_logs() {
    echo ""
    echo -e "${BLUE}[3] Checking Widget Extension Logs...${NC}"
    echo "----------------------------------------"
    
    log stream --predicate 'subsystem == "com.growthlabs.growthmethod.widget" OR process == "GrowthTimerWidget"' --style compact --info --debug 2>&1 | head -50
}

# Function to check Darwin notifications
check_darwin_notifications() {
    echo ""
    echo -e "${BLUE}[4] Checking Darwin Notifications...${NC}"
    echo "----------------------------------------"
    
    log stream --predicate 'eventMessage CONTAINS "Darwin" OR eventMessage CONTAINS "CFNotification"' --style compact --info --debug 2>&1 | head -20
}

# Function to verify Info.plist configuration
check_info_plist() {
    echo ""
    echo -e "${BLUE}[5] Checking Info.plist Configuration...${NC}"
    echo "----------------------------------------"
    
    MAIN_PLIST="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth/Resources/Plist/App/Info.plist"
    WIDGET_PLIST="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth/Resources/Plist/Widget/Info.plist"
    
    echo "Main App Info.plist:"
    if [ -f "$MAIN_PLIST" ]; then
        grep -A 1 "NSSupportsLiveActivities" "$MAIN_PLIST" | sed 's/^/  /'
        if grep -q "NSSupportsLiveActivitiesFrequentUpdates" "$MAIN_PLIST"; then
            echo -e "  ${GREEN}✅ Frequent updates enabled${NC}"
        else
            echo -e "  ${RED}❌ Frequent updates not configured${NC}"
        fi
    else
        echo -e "  ${RED}❌ Info.plist not found${NC}"
    fi
    
    echo ""
    echo "Widget Extension Info.plist:"
    if [ -f "$WIDGET_PLIST" ]; then
        grep -A 1 "NSSupportsLiveActivities" "$WIDGET_PLIST" | sed 's/^/  /'
        if grep -q "NSSupportsLiveActivitiesFrequentUpdates" "$WIDGET_PLIST"; then
            echo -e "  ${GREEN}✅ Frequent updates enabled${NC}"
        else
            echo -e "  ${RED}❌ Frequent updates not configured${NC}"
        fi
    else
        echo -e "  ${RED}❌ Info.plist not found${NC}"
    fi
}

# Function to check Firebase configuration
check_firebase_config() {
    echo ""
    echo -e "${BLUE}[6] Checking Firebase Configuration...${NC}"
    echo "----------------------------------------"
    
    # Check for development key
    DEV_KEY="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/functions/AuthKey_55LZB28UY2.p8"
    PROD_KEY="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/functions/AuthKey_DQ46FN4PQU.p8"
    
    if [ -f "$DEV_KEY" ]; then
        echo -e "  ${GREEN}✅ Development APNS key found (55LZB28UY2)${NC}"
    else
        echo -e "  ${RED}❌ Development APNS key not found${NC}"
    fi
    
    if [ -f "$PROD_KEY" ]; then
        echo -e "  ${GREEN}✅ Production APNS key found (DQ46FN4PQU)${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Production APNS key not found${NC}"
    fi
    
    # Check Firebase functions logs
    echo ""
    echo "Recent Firebase function errors:"
    cd /Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/functions 2>/dev/null
    firebase functions:log --lines 10 2>/dev/null | grep -E "error|ERROR|failed|Failed" | head -5 || echo "  No recent errors found"
}

# Function to test Live Activity
test_live_activity() {
    echo ""
    echo -e "${BLUE}[7] Live Activity Test Instructions:${NC}"
    echo "----------------------------------------"
    echo "1. Start a timer in the app"
    echo "2. Check if Live Activity appears on Lock Screen"
    echo "3. Try pause/resume from Live Activity"
    echo "4. Monitor the logs above for any errors"
    echo ""
    echo -e "${YELLOW}Common Issues:${NC}"
    echo "  • Push token not synced with Firebase"
    echo "  • Wrong APNS environment (dev vs prod)"
    echo "  • Missing entitlements"
    echo "  • Firebase function timeouts"
}

# Main execution
echo "Starting Live Activity diagnostics..."
echo ""

# Run diagnostics
check_info_plist
check_firebase_config
echo ""
echo -e "${YELLOW}Starting live log monitoring (30 seconds)...${NC}"
echo -e "${YELLOW}Please start a timer in the app now!${NC}"
echo ""
check_live_activity_logs
test_live_activity

echo ""
echo "========================================="
echo "Diagnostic complete!"
echo "========================================="
echo ""
echo "To monitor Live Activity logs continuously, run:"
echo "log stream --predicate 'subsystem == \"com.apple.ActivityKit\" OR category == \"LiveActivity\"' --style compact --info --debug"