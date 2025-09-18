#!/bin/bash

# Setup script for Direct APNs Server
# This script sets up the APNs server for Live Activity updates

echo "=========================================="
echo "Direct APNs Server Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"

# Check if the APNs key exists
APNS_KEY="AuthKey_DQ46FN4PQU.p8"
if [ ! -f "$APNS_KEY" ]; then
    echo -e "${YELLOW}⚠️  APNs key not found: $APNS_KEY${NC}"
    echo "Please ensure your .p8 key file is in the project root"
    echo "You can download it from Apple Developer Portal"
else
    echo -e "${GREEN}✅ APNs key found: $APNS_KEY${NC}"
fi

# Navigate to server directory
cd apns-server || {
    echo -e "${RED}❌ apns-server directory not found${NC}"
    exit 1
}

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo ""
    echo "Creating .env file..."
    cp .env.example .env
    echo -e "${GREEN}✅ Created .env file${NC}"
    echo -e "${YELLOW}⚠️  Please edit apns-server/.env with your configuration${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Create logs directory
mkdir -p logs
echo -e "${GREEN}✅ Created logs directory${NC}"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit apns-server/.env with your configuration"
echo "2. Ensure $APNS_KEY is in the project root"
echo "3. Start the server:"
echo "   cd apns-server"
echo "   npm start          # Production mode"
echo "   npm run dev        # Development mode with auto-reload"
echo ""
echo "Test endpoints:"
echo "   curl http://localhost:3000/health"
echo ""
echo "For iOS integration:"
echo "1. Update APNsService.swift with your server URL"
echo "2. Build and run the app"
echo "3. Monitor server logs for push token registrations"
echo ""