#!/bin/bash

# Debug script to help diagnose Live Activity time display issues

echo "🔍 Debugging Live Activity Time Display Issue"
echo "============================================"

# Check for duration values in the code
echo -e "\n📊 Checking duration values in TimerService:"
grep -n "targetDuration" Growth/Features/Timer/Services/TimerService.swift | head -10

echo -e "\n📊 Checking LiveActivityManager duration handling:"
grep -n "duration" Growth/Features/Timer/Services/LiveActivityManager.swift | grep -E "(startTimerActivity|totalDuration)" | head -10

echo -e "\n📊 Checking time formatting in widget:"
grep -n "formatTime\|formatFullTime" GrowthTimerWidget/GrowthTimerWidgetLiveActivity.swift | head -10

echo -e "\n📊 Checking for potential multiplication issues:"
grep -rn "duration.*60\|60.*duration" Growth/Features/Timer/ | grep -v "comment" | head -10

echo -e "\n✅ Debug complete!"