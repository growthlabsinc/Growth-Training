#!/bin/bash

echo "Opening Xcode project safely..."

# Kill any existing Xcode processes
pkill -9 Xcode 2>/dev/null || true

# Wait a moment
sleep 2

# Open Xcode without opening any project
open -a Xcode

# Wait for Xcode to fully launch
sleep 5

echo "Xcode is now open. To open the project:"
echo "1. Go to File > Open"
echo "2. Navigate to: $(pwd)"
echo "3. Select Growth.xcodeproj"
echo "4. Click Open"
echo ""
echo "If Xcode still hangs, try:"
echo "- Hold Shift while clicking Open to disable restoration"
echo "- Or use: open -a Xcode --args -ApplePersistenceIgnoreState YES"