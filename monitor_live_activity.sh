#!/bin/bash

# Real-time Live Activity Monitor for Development
# This script provides comprehensive monitoring of Live Activity in development

echo "========================================="
echo "Live Activity Real-Time Monitor"
echo "Development Environment"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to parse and colorize logs
colorize_log() {
    while IFS= read -r line; do
        # Errors
        if [[ $line == *"error"* ]] || [[ $line == *"Error"* ]] || [[ $line == *"ERROR"* ]] || [[ $line == *"failed"* ]] || [[ $line == *"Failed"* ]]; then
            echo -e "${RED}❌ $line${NC}"
        # Success
        elif [[ $line == *"success"* ]] || [[ $line == *"Success"* ]] || [[ $line == *"started"* ]] || [[ $line == *"Started"* ]] || [[ $line == *"✅"* ]]; then
            echo -e "${GREEN}✅ $line${NC}"
        # Push tokens
        elif [[ $line == *"token"* ]] || [[ $line == *"Token"* ]] || [[ $line == *"pushToken"* ]]; then
            echo -e "${CYAN}🔑 $line${NC}"
        # Push notifications
        elif [[ $line == *"push"* ]] || [[ $line == *"Push"* ]] || [[ $line == *"APNs"* ]] || [[ $line == *"notification"* ]]; then
            echo -e "${YELLOW}📤 $line${NC}"
        # Live Activity specific
        elif [[ $line == *"Live Activity"* ]] || [[ $line == *"LiveActivity"* ]] || [[ $line == *"ActivityKit"* ]]; then
            echo -e "${MAGENTA}📱 $line${NC}"
        # Timer actions
        elif [[ $line == *"pause"* ]] || [[ $line == *"Pause"* ]] || [[ $line == *"resume"* ]] || [[ $line == *"Resume"* ]] || [[ $line == *"stop"* ]] || [[ $line == *"Stop"* ]]; then
            echo -e "${BLUE}⏱️ $line${NC}"
        # Darwin notifications
        elif [[ $line == *"Darwin"* ]] || [[ $line == *"CFNotification"* ]]; then
            echo -e "${CYAN}🔔 $line${NC}"
        # Development/Debug
        elif [[ $line == *"DEBUG"* ]] || [[ $line == *"development"* ]] || [[ $line == *"Development"* ]]; then
            echo -e "${YELLOW}🔧 $line${NC}"
        # Default
        else
            echo "$line"
        fi
    done
}

# Check environment
echo -e "${BLUE}Environment Check:${NC}"
echo "----------------------------------------"

# Check for development key
DEV_KEY="/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/functions/AuthKey_55LZB28UY2.p8"
if [ -f "$DEV_KEY" ]; then
    echo -e "${GREEN}✅ Development APNS key: 55LZB28UY2${NC}"
else
    echo -e "${RED}❌ Development APNS key not found${NC}"
fi

# Check build configuration
echo -e "${BLUE}Build Configuration: DEBUG${NC}"
echo -e "${BLUE}APNS Server: api.development.push.apple.com${NC}"
echo ""

# Main monitoring
echo -e "${YELLOW}Starting Live Activity Monitor...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""
echo "Monitoring for:"
echo "  • Live Activity lifecycle events"
echo "  • Push token registration"
echo "  • Push notification delivery"
echo "  • Timer control actions (pause/resume/stop)"
echo "  • Darwin notifications"
echo "  • Errors and failures"
echo ""
echo "========================================="
echo ""

# Create a combined predicate for all relevant logs
PREDICATE='subsystem == "com.apple.ActivityKit" 
    OR category == "LiveActivity" 
    OR subsystem == "com.growthlabs.growthmethod" 
    OR subsystem == "com.growthlabs.growthmethod.widget"
    OR process == "Growth"
    OR process == "GrowthTimerWidget"
    OR eventMessage CONTAINS "Live Activity" 
    OR eventMessage CONTAINS "LiveActivity"
    OR eventMessage CONTAINS "push token" 
    OR eventMessage CONTAINS "pushToken"
    OR eventMessage CONTAINS "ActivityKit"
    OR eventMessage CONTAINS "APNs"
    OR eventMessage CONTAINS "Darwin"
    OR eventMessage CONTAINS "pause"
    OR eventMessage CONTAINS "resume"
    OR eventMessage CONTAINS "timer"
    OR eventMessage CONTAINS "55LZB28UY2"
    OR eventMessage CONTAINS "development"'

# Start monitoring with color coding
log stream --predicate "$PREDICATE" --style compact --info --debug 2>&1 | colorize_log

# Cleanup on exit
trap "echo ''; echo 'Monitoring stopped.'; exit 0" INT TERM