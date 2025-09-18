#!/bin/bash

# Simple deployment script for support page
# Usage: ./deploy-support-page.sh

DROPLET_IP="167.71.248.185"
DROPLET_USER="root"  # Change this if you use a different user
WEB_ROOT="/var/www/html"  # Standard Nginx web root

echo "🚀 Deploying support page to DigitalOcean droplet..."

# Upload the support.html file
echo "📤 Uploading support.html to ${DROPLET_IP}..."
scp support.html ${DROPLET_USER}@${DROPLET_IP}:${WEB_ROOT}/support.html

if [ $? -eq 0 ]; then
    echo "✅ Support page deployed successfully!"
    echo "🌐 View it at: https://growthlabs.coach/support.html"
else
    echo "❌ Deployment failed. Please check your SSH access."
    echo ""
    echo "To set up SSH access:"
    echo "1. Add your SSH key to the droplet:"
    echo "   ssh-copy-id ${DROPLET_USER}@${DROPLET_IP}"
    echo ""
    echo "2. Or manually copy the file after SSH login:"
    echo "   ssh ${DROPLET_USER}@${DROPLET_IP}"
    echo "   Then use SFTP or create the file directly on the server"
fi