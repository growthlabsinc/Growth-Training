#!/bin/bash

echo "=== Removing Duplicate Files ==="
echo ""
echo "This script will remove duplicate files, keeping the most appropriate version."
echo ""

# Function to safely remove a file
remove_if_exists() {
    if [ -f "$1" ]; then
        echo "Removing duplicate: $1"
        rm "$1"
    fi
}

# 1. NotificationPreferencesView - Keep the one in Settings
echo "1. Fixing NotificationPreferencesView duplicates..."
remove_if_exists "/Users/tradeflowj/Desktop/Growth/Growth/Features/Notifications/Views/NotificationPreferencesView.swift"
echo "   Keeping: /Users/tradeflowj/Desktop/Growth/Growth/Features/Settings/NotificationPreferencesView.swift"

# 2. PendingConsents - Keep the one in Core/Models
echo ""
echo "2. Fixing PendingConsents duplicates..."
remove_if_exists "/Users/tradeflowj/Desktop/Growth/Growth/Features/Onboarding/Models/PendingConsents.swift"
echo "   Keeping: /Users/tradeflowj/Desktop/Growth/Growth/Core/Models/PendingConsents.swift"

# 3. ConsentRecord - Keep the one in Core/Models
echo ""
echo "3. Fixing ConsentRecord duplicates..."
remove_if_exists "/Users/tradeflowj/Desktop/Growth/Growth/Features/Onboarding/Models/ConsentRecord.swift"
echo "   Keeping: /Users/tradeflowj/Desktop/Growth/Growth/Core/Models/ConsentRecord.swift"

# 4. RoutineProgress - Keep the one in Core/Models
echo ""
echo "4. Fixing RoutineProgress duplicates..."
remove_if_exists "/Users/tradeflowj/Desktop/Growth/Growth/Models/RoutineProgress.swift"
echo "   Keeping: /Users/tradeflowj/Desktop/Growth/Growth/Core/Models/RoutineProgress.swift"

# 5. InsightGenerationService - Keep the one in Core/Services
echo ""
echo "5. Fixing InsightGenerationService duplicates..."
remove_if_exists "/Users/tradeflowj/Desktop/Growth/Growth/Features/Progress/Services/InsightGenerationService.swift"
echo "   Keeping: /Users/tradeflowj/Desktop/Growth/Growth/Core/Services/InsightGenerationService.swift"

echo ""
echo "=== Duplicate files removed ==="
echo ""
echo "Now you need to:"
echo "1. Open Xcode"
echo "2. Remove the red (missing) file references from the project navigator"
echo "3. Clean Build Folder (Cmd+Shift+K)"
echo "4. Build again (Cmd+B)"
echo ""
echo "For the Info.plist issue:"
echo "- Go to Project Settings > Build Phases > Copy Bundle Resources"
echo "- Remove any duplicate Info.plist entries"
echo "- Ensure Build Settings > Packaging > Info.plist File points to: Growth/Resources/Plist/App/Info.plist"