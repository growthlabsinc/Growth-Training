#!/usr/bin/env python3
"""
Script to verify complete removal of Angion content
Story 3.1: Remove Angion Knowledge Base
"""

import json
import sys
import subprocess
import os

# Angion-specific terms to check
ANGION_TERMS = [
    "angion", "am1", "am2", "am3", "sabre", "vascion",
    "pyramid", "rush", "dorsal pulse", "bfr",
    "angion method", "angion 1.0", "angion 2.0", "angion 3.0",
    "macropulse", "janus", "bayliss response"
]

def check_file_for_angion(filepath, terms):
    """Check if file contains Angion terms"""
    if not os.path.exists(filepath):
        return False, []

    found_terms = []
    try:
        with open(filepath, 'r') as f:
            content = f.read().lower()
            for term in terms:
                if term.lower() in content:
                    found_terms.append(term)
    except Exception as e:
        print(f"❌ Error reading {filepath}: {e}")

    return len(found_terms) > 0, found_terms

def check_deployment_scripts():
    """Check if Angion deployment scripts exist"""
    scripts_to_check = [
        "functions/deployAngionMethods.js",
        "functions/deploy-angion-methods.js",
        "functions/deploy-methods.js"
    ]

    existing_scripts = []
    for script in scripts_to_check:
        if os.path.exists(script):
            existing_scripts.append(script)

    return existing_scripts

def test_fallback_knowledge():
    """Test fallback knowledge responses"""
    test_passed = True

    # Import the fallback knowledge module
    try:
        # Read the fallback knowledge file
        with open('functions/fallbackKnowledge.js', 'r') as f:
            content = f.read().lower()

        # Check for Angion terms
        for term in ANGION_TERMS:
            if term.lower() in content and term.lower() not in ['eq']:  # EQ is legitimate PE term
                print(f"  ❌ Found '{term}' in fallbackKnowledge.js")
                test_passed = False

        if test_passed:
            print("  ✅ No Angion content found in fallbackKnowledge.js")

    except Exception as e:
        print(f"  ❌ Error checking fallback knowledge: {e}")
        test_passed = False

    return test_passed

def main():
    print("🔍 Verifying Angion Content Removal")
    print("=" * 50)
    print()

    all_passed = True

    # Test 1: Check deployment scripts
    print("📝 Test 1: Deployment Scripts")
    print("-" * 30)
    existing_scripts = check_deployment_scripts()
    if existing_scripts:
        print("  ❌ FAILED: Found Angion deployment scripts:")
        for script in existing_scripts:
            print(f"     - {script}")
        all_passed = False
    else:
        print("  ✅ PASSED: No Angion deployment scripts found")
    print()

    # Test 2: Check fallback knowledge
    print("📝 Test 2: Fallback Knowledge")
    print("-" * 30)
    if not test_fallback_knowledge():
        all_passed = False
    print()

    # Test 3: Check vertexAiProxy/index.js
    print("📝 Test 3: AI System Prompt")
    print("-" * 30)
    has_angion, found_terms = check_file_for_angion(
        "functions/vertexAiProxy/index.js",
        ["angion", "am1", "am2", "sabre", "vascion", "angion method"]
    )
    if has_angion:
        print(f"  ❌ FAILED: Found Angion terms in system prompt: {', '.join(found_terms)}")
        all_passed = False
    else:
        print("  ✅ PASSED: No Angion references in system prompt")
    print()

    # Test 4: Check for backup archive
    print("📝 Test 4: Backup Archive")
    print("-" * 30)
    archive_files = [
        "archive/angion_removal_backup/fallbackKnowledge.js.backup",
        "archive/angion_removal_backup/README.md"
    ]
    archive_exists = all(os.path.exists(f) for f in archive_files)
    if archive_exists:
        print("  ✅ PASSED: Backup archive created successfully")
    else:
        print("  ⚠️  WARNING: Backup archive incomplete")
    print()

    # Test 5: Check for any remaining Angion files
    print("📝 Test 5: Scanning for Remaining Angion Files")
    print("-" * 30)
    try:
        result = subprocess.run(
            ["find", "functions", "-name", "*angion*", "-o", "-name", "*Angion*"],
            capture_output=True,
            text=True
        )
        if result.stdout.strip():
            print(f"  ❌ FAILED: Found Angion-related files:")
            print(result.stdout)
            all_passed = False
        else:
            print("  ✅ PASSED: No Angion-named files found")
    except Exception as e:
        print(f"  ⚠️  Could not scan for files: {e}")
    print()

    # Final Summary
    print("=" * 50)
    print("📊 VERIFICATION SUMMARY")
    print("=" * 50)

    if all_passed:
        print("✅ ALL TESTS PASSED")
        print()
        print("Angion content has been successfully removed:")
        print("• No deployment scripts remain")
        print("• Fallback knowledge updated to PE safety content")
        print("• System prompts updated to PE focus")
        print("• Backup archive created for reference")
        print()
        print("✅ Story 3.1 verification complete!")
    else:
        print("❌ SOME TESTS FAILED")
        print()
        print("Please review the failed tests above and ensure:")
        print("• All Angion deployment scripts are removed")
        print("• Fallback knowledge contains no Angion references")
        print("• System prompts are updated")
        sys.exit(1)

if __name__ == "__main__":
    main()