#!/bin/bash

# Fix Firebase Deployment Issues
# Handles HTTP 409 and other common deployment problems

echo "=========================================="
echo "Firebase Deployment Fix"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check current deployment status
echo "Checking Firebase project status..."
firebase functions:list 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Not logged in to Firebase${NC}"
    echo "Running: firebase login"
    firebase login
fi

echo ""
echo -e "${YELLOW}Current deployment issue: HTTP 409 - Operation already in queue${NC}"
echo "This means another deployment is in progress."
echo ""

# Options for fixing
echo "Choose an option:"
echo "1. Wait and retry (recommended)"
echo "2. Deploy functions individually"
echo "3. Cancel pending operations and force deploy"
echo "4. Check function logs"
echo "5. Exit"
echo ""
read -p "Enter option (1-5): " option

case $option in
    1)
        echo -e "${YELLOW}Waiting 30 seconds before retry...${NC}"
        sleep 30
        echo "Retrying deployment..."
        cd functions
        firebase deploy --only functions:updateLiveActivity,functions:registerLiveActivityToken
        ;;
    
    2)
        echo "Deploying functions individually..."
        echo ""
        echo -e "${YELLOW}Deploying updateLiveActivity...${NC}"
        firebase deploy --only functions:updateLiveActivity
        sleep 5
        
        echo ""
        echo -e "${YELLOW}Deploying registerLiveActivityToken...${NC}"
        firebase deploy --only functions:registerLiveActivityToken
        sleep 5
        
        echo ""
        echo -e "${YELLOW}Deploying getLiveActivityPushToken...${NC}"
        firebase deploy --only functions:getLiveActivityPushToken
        ;;
    
    3)
        echo -e "${RED}⚠️  Force deployment (may cause issues)${NC}"
        echo "This will delete and recreate functions"
        read -p "Are you sure? (y/n): " confirm
        
        if [ "$confirm" = "y" ]; then
            echo "Deleting existing functions..."
            firebase functions:delete updateLiveActivity --force
            firebase functions:delete registerLiveActivityToken --force
            
            echo "Waiting for deletion to complete..."
            sleep 10
            
            echo "Redeploying functions..."
            firebase deploy --only functions
        else
            echo "Cancelled"
        fi
        ;;
    
    4)
        echo "Fetching recent function logs..."
        firebase functions:log --lines 50
        ;;
    
    5)
        echo "Exiting..."
        exit 0
        ;;
    
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Deployment Fix Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check Firebase Console for function status"
echo "2. Test Live Activity updates in the app"
echo "3. Monitor logs: firebase functions:log --only updateLiveActivity"
echo ""