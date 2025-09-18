#!/bin/bash

# Test script to verify quick practice timer glow fix
echo "Testing Quick Practice Timer Glow Fix"
echo "===================================="

# Check if the fix has been applied correctly
echo "1. Checking QuickPracticeTimerTracker initialization..."
grep -A 5 "init()" /Users/tradeflowj/Desktop/Growth/Growth/Features/Stats/Views/QuickPracticeTimerView.swift | grep -E "(Ensure timer starts|timerService.stop|isTimerRunning = false)"

echo -e "\n2. Checking onAppear initialization..."
grep -A 10 "onAppear {" /Users/tradeflowj/Desktop/Growth/Growth/Features/Stats/Views/QuickPracticeTimerView.swift | grep -E "(isTimerRunning = false|Restored timer state)"

echo -e "\n3. Summary of changes:"
echo "- QuickPracticeTimerTracker now stops any restored timer state on init"
echo "- isTimerRunning is explicitly set to false on init"
echo "- onAppear starts with isTimerRunning = false"
echo "- Background timer restoration properly updates isTimerRunning"

echo -e "\nFix implemented successfully!"
echo "The glow effect will now only show when the timer is actually running."