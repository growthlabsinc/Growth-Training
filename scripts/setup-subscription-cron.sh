#!/bin/bash

# Script to set up a cron job for daily subscription routine checks
# This is a workaround for Firebase Functions deployment issues

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MANAGE_SCRIPT="$SCRIPT_DIR/manage-subscription-routines.js"

# Check if the management script exists
if [ ! -f "$MANAGE_SCRIPT" ]; then
    echo "❌ Management script not found at: $MANAGE_SCRIPT"
    exit 1
fi

# Check if service account key exists
if [ ! -f "$SCRIPT_DIR/service-account-key.json" ]; then
    echo "❌ Service account key not found at: $SCRIPT_DIR/service-account-key.json"
    echo "Please download it from Firebase Console > Project Settings > Service Accounts"
    exit 1
fi

# Create log directory if it doesn't exist
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "📋 Setting up daily subscription routine check..."

# Create the cron job script
CRON_SCRIPT="$SCRIPT_DIR/run-subscription-check.sh"
cat > "$CRON_SCRIPT" << EOF
#!/bin/bash
# Daily subscription routine check
cd "$SCRIPT_DIR"
LOG_FILE="$LOG_DIR/subscription-check-\$(date +\%Y\%m\%d).log"
echo "[\$(date)] Starting subscription check..." >> "\$LOG_FILE"
node manage-subscription-routines.js check >> "\$LOG_FILE" 2>&1
echo "[\$(date)] Subscription check completed" >> "\$LOG_FILE"
EOF

chmod +x "$CRON_SCRIPT"

# Add to crontab (runs daily at 2 AM)
CRON_LINE="0 2 * * * $CRON_SCRIPT"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$CRON_SCRIPT"; then
    echo "✅ Cron job already exists"
else
    # Add the cron job
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
    echo "✅ Added cron job to run daily at 2 AM"
fi

echo ""
echo "📌 Cron job setup complete!"
echo ""
echo "To view the cron job:"
echo "  crontab -l"
echo ""
echo "To run manually:"
echo "  $CRON_SCRIPT"
echo ""
echo "To check logs:"
echo "  ls -la $LOG_DIR"
echo ""
echo "To remove the cron job:"
echo "  crontab -e"
echo "  # Then delete the line containing: $CRON_SCRIPT"