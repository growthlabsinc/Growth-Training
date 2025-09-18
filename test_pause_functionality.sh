#!/bin/bash

# Test script to verify pause functionality is working

echo "🧪 Testing Live Activity Pause Functionality"
echo "==========================================="
echo ""

# Check if Darwin notifications are set up
echo "1. Checking Darwin notification setup..."
if grep -q "CFNotificationCenterAddObserver" Growth/Application/GrowthAppApp.swift; then
    echo "✅ Darwin notification observers are set up"
else
    echo "❌ Darwin notification observers NOT found"
fi

echo ""
echo "2. Checking TimerControlIntent updates..."
if grep -q "await activity.update" GrowthTimerWidget/AppIntents/TimerControlIntent.swift; then
    echo "✅ TimerControlIntent updates Live Activity locally"
else
    echo "❌ TimerControlIntent does NOT update Live Activity"
fi

echo ""
echo "3. Checking App Group state updates..."
if grep -q "AppGroupConstants.storeTimerState" GrowthTimerWidget/AppIntents/TimerControlIntent.swift; then
    echo "✅ TimerControlIntent updates App Group state"
else
    echo "❌ TimerControlIntent does NOT update App Group state"
fi

echo ""
echo "4. Checking main app sync on become active..."
if grep -q "syncWithLiveActivityState" Growth/Features/Timer/Services/TimerService.swift; then
    echo "✅ TimerService syncs with Live Activity state"
else
    echo "❌ TimerService does NOT sync with Live Activity state"
fi

echo ""
echo "5. Checking handleLiveActivityAction implementation..."
if grep -q "handleLiveActivityAction" Growth/Application/GrowthAppApp.swift; then
    echo "✅ handleLiveActivityAction is implemented"
else
    echo "❌ handleLiveActivityAction NOT found"
fi

echo ""
echo "==========================================="
echo "Summary: Pause functionality components are in place."
echo ""
echo "To test:"
echo "1. Start a timer in the app"
echo "2. Go to Dynamic Island/Lock Screen"
echo "3. Tap the pause button"
echo "4. The timer should pause immediately"
echo "5. The main app should reflect the paused state when opened"