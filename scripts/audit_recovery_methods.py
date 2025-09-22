#!/usr/bin/env python3
"""
Script to audit recovery and safety methods in Firestore
"""

import json
import sys
import requests
from typing import List, Dict

# Firebase project configuration
PROJECT_ID = "growth-training-app"
COLLECTION = "growth_exercises"

def get_firebase_token():
    """Get Firebase auth token using gcloud"""
    import subprocess
    try:
        result = subprocess.run(
            ["gcloud", "auth", "print-access-token"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        print("❌ Error: Failed to get auth token. Make sure you're logged in with:")
        print("   gcloud auth login")
        sys.exit(1)

def fetch_methods(token: str) -> List[Dict]:
    """Fetch all methods from Firestore"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        print(f"❌ Error fetching methods: {response.status_code}")
        print(response.text)
        sys.exit(1)

    data = response.json()
    methods = []

    if "documents" in data:
        for doc in data["documents"]:
            method_id = doc["name"].split("/")[-1]
            fields = doc.get("fields", {})

            # Extract all fields for recovery analysis
            title = ""
            category = ""
            description = ""
            difficulty = ""
            equipment = []
            steps_count = 0

            if "title" in fields and "stringValue" in fields["title"]:
                title = fields["title"]["stringValue"]

            if "category" in fields and "stringValue" in fields["category"]:
                category = fields["category"]["stringValue"]

            if "description" in fields and "stringValue" in fields["description"]:
                description = fields["description"]["stringValue"]

            if "difficulty" in fields and "stringValue" in fields["difficulty"]:
                difficulty = fields["difficulty"]["stringValue"]

            if "equipmentNeeded" in fields and "arrayValue" in fields["equipmentNeeded"]:
                equipment_values = fields["equipmentNeeded"]["arrayValue"].get("values", [])
                equipment = [e.get("stringValue", "") for e in equipment_values if "stringValue" in e]

            if "steps" in fields and "arrayValue" in fields["steps"]:
                steps_array = fields["steps"]["arrayValue"].get("values", [])
                steps_count = len(steps_array)

            methods.append({
                "id": method_id,
                "title": title,
                "category": category,
                "description": description,
                "difficulty": difficulty,
                "equipment": equipment,
                "steps_count": steps_count
            })

    return methods

def analyze_recovery_methods(methods: List[Dict]):
    """Analyze and categorize recovery methods"""

    # Keywords for recovery identification
    recovery_keywords = [
        'warm', 'heat', 'recovery', 'cool', 'safety', 'rest', 'injury', 'prevention',
        'disclaimer', 'medical', 'warning', 'caution', 'preparation', 'healing',
        'stretch', 'relaxation', 'first aid', 'stop signs'
    ]

    recovery_methods = []
    other_methods = []

    for method in methods:
        title_lower = method['title'].lower()
        desc_lower = method['description'].lower()

        # Check category first
        if method['category'] == 'recovery':
            recovery_methods.append(method)
        # If no category, check keywords
        elif any(keyword in title_lower or keyword in desc_lower for keyword in recovery_keywords):
            recovery_methods.append(method)
        else:
            other_methods.append(method)

    return recovery_methods, other_methods

def main():
    print("🔍 Recovery & Safety Methods Audit")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Fetch methods
    print("📊 Fetching methods from Firestore...")
    methods = fetch_methods(token)
    print(f"✅ Found {len(methods)} total methods")
    print()

    # Analyze
    recovery_methods, other_methods = analyze_recovery_methods(methods)

    # Display results
    print("🛡️ RECOVERY & SAFETY METHODS:")
    print("-" * 50)
    if recovery_methods:
        for method in recovery_methods:
            equipment_str = f" - Equipment: {', '.join(method['equipment'])}" if method['equipment'] else ""
            category_str = f" [{method['category']}]" if method['category'] else ""
            diff_str = f" ({method['difficulty']})" if method['difficulty'] else ""
            print(f"  • {method['title']}{diff_str}{category_str} - {method['steps_count']} steps{equipment_str}")
    else:
        print("  None found")

    print(f"\n📊 Total Recovery Methods: {len(recovery_methods)}")
    print(f"📊 Other Methods: {len(other_methods)}")

    # Check for specific gaps
    print("\n🔎 GAPS ANALYSIS:")
    print("-" * 50)

    # Check for specific exercise types
    has_warm_up = any('warm' in m['title'].lower() or 'heat' in m['title'].lower() for m in recovery_methods)
    has_cool_down = any('cool' in m['title'].lower() or 'recovery' in m['title'].lower() for m in recovery_methods)
    has_injury_prevention = any('injury' in m['title'].lower() or 'prevention' in m['title'].lower() for m in recovery_methods)
    has_safety_guidelines = any('safety' in m['title'].lower() or 'disclaimer' in m['title'].lower() for m in recovery_methods)
    has_rest_protocols = any('rest' in m['title'].lower() or 'break' in m['title'].lower() for m in recovery_methods)
    has_medical_warnings = any('medical' in m['description'].lower() or 'warning' in m['description'].lower() for m in recovery_methods)

    gaps = []
    if not has_warm_up:
        gaps.append("❌ Missing: Warm-up protocols")
    if not has_cool_down:
        gaps.append("❌ Missing: Cool-down procedures")
    if not has_injury_prevention:
        gaps.append("❌ Missing: Injury prevention content")
    if not has_safety_guidelines:
        gaps.append("❌ Missing: Safety guidelines")
    if not has_rest_protocols:
        gaps.append("❌ Missing: Rest day protocols")
    if not has_medical_warnings:
        gaps.append("❌ Missing: Medical disclaimers")

    if len(recovery_methods) < 8:
        gaps.append(f"❌ Need {8 - len(recovery_methods)} more recovery methods for comprehensive coverage")

    if gaps:
        for gap in gaps:
            print(f"  {gap}")
    else:
        print("  ✅ All requirements met!")

    print("\n📋 RECOMMENDATION:")
    print("-" * 50)
    if len(recovery_methods) >= 8:
        print("✅ Already have 8+ recovery methods")
        print("💡 Consider enhancing existing methods with better safety integration")
    else:
        print(f"📝 Need to add {8 - len(recovery_methods)} more recovery methods")
        print("💡 Focus on missing content types identified above")

    print("\n📝 DETAILED FINDINGS:")
    print("-" * 50)
    print("Existing Recovery Methods:")
    for method in recovery_methods:
        print(f"  • {method['title']} - {method['steps_count']} steps")

    # Identify which new methods need to be created
    needed_methods = []
    if not has_warm_up:
        needed_methods.append("Heat Application Warm-up")
        needed_methods.append("Preparatory Stretching Protocol")
    if not has_cool_down:
        needed_methods.append("Post-Exercise Recovery Routine")
        needed_methods.append("Healing Optimization Protocol")
    if not has_injury_prevention:
        needed_methods.append("Warning Signs Recognition")
        needed_methods.append("When to Stop Immediately")
    if not has_safety_guidelines:
        needed_methods.append("Pre-Exercise Safety Checklist")
        needed_methods.append("Medical Consultation Guidelines")

    if needed_methods:
        print(f"\n🎯 SUGGESTED NEW METHODS ({len(needed_methods)} needed):")
        print("-" * 50)
        for i, method in enumerate(needed_methods, 1):
            print(f"  {i}. {method}")

if __name__ == "__main__":
    main()