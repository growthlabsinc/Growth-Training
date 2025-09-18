#!/usr/bin/env python3
"""
Replace all onChange(of:initial:_:) calls with onChangeCompatWithInitial
"""

import os
import re

files_to_fix = [
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Core/Services/SubscriptionStateManager.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Core/UI/Components/Markdown/MarkdownRenderer.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Core/UI/Components/Markdown/MarkdownTableOfContents.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Core/UI/Components/AppleIntelligenceGlowEffect.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Core/UI/Theme/ThemeManager.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Authentication/Views/Components/AuthTextField.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Authentication/Views/LoginView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Dashboard/Views/DashboardView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Onboarding/Views/ProfileSetupView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Practice/Views/PracticeTabView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Progress/Views/DetailedProgressCalendarView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Progress/Views/ProgressView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Routines/Components/RoutineAdherenceView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Routines/Views/CurrentRoutineView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Routines/Views/DailyRoutineView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Routines/Views/PremiumCreateCustomRoutineView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Settings/AccountView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Settings/BiometricSettingsView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Settings/NotificationPreferencesView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Stats/Views/QuickPracticeTimerView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/Features/Timer/Views/TimerView.swift",
    "/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth/MainView.swift",
]

def fix_file(file_path):
    """Fix onChange calls in a single file"""
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return False
        
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Replace .onChange(of: value, initial: bool) patterns
    # Pattern 1: with { _, newValue in
    content = re.sub(
        r'\.onChange\(of:\s*([^,]+),\s*initial:\s*(\w+)\)\s*\{\s*_,\s*(\w+)\s*in',
        r'.onChangeCompatWithInitial(of: \1, initial: \2) { \3 in',
        content
    )
    
    # Pattern 2: simple replacement
    content = re.sub(
        r'\.onChange\(of:\s*([^,]+),\s*initial:\s*(\w+)\)\s*\{',
        r'.onChangeCompatWithInitial(of: \1, initial: \2) {',
        content
    )
    
    if content != original_content:
        # Make sure we have the import
        if 'import SwiftUI' in content and 'View+OnChange' not in content:
            # No need to import, extension is global
            pass
            
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    return False

if __name__ == '__main__':
    print("Replacing onChange calls...")
    fixed_count = 0
    
    for file_path in files_to_fix:
        if fix_file(file_path):
            print(f"✓ Fixed: {os.path.basename(file_path)}")
            fixed_count += 1
        else:
            print(f"  No changes: {os.path.basename(file_path)}")
    
    print(f"\nFixed {fixed_count} files")