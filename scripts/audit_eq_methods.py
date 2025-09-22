#!/usr/bin/env python3
"""
Script to audit EQ-specific methods in Firestore
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

            # Extract all fields for EQ analysis
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

def analyze_eq_methods(methods: List[Dict]):
    """Analyze and categorize EQ methods"""

    # Keywords for EQ identification
    eq_keywords = [
        'kegel', 'eq', 'erection', 'edging', 'pc muscle', 'pelvic floor',
        'ballooning', 'stamina', 'control', 'towel', 'helicopter', 'reverse kegel'
    ]

    eq_methods = []
    other_methods = []

    for method in methods:
        title_lower = method['title'].lower()
        desc_lower = method['description'].lower()

        # Check category first
        if method['category'] == 'eq':
            eq_methods.append(method)
        # If no category, check keywords
        elif any(keyword in title_lower or keyword in desc_lower for keyword in eq_keywords):
            eq_methods.append(method)
        else:
            other_methods.append(method)

    return eq_methods, other_methods

def main():
    print("🔍 EQ Methods Audit")
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
    eq_methods, other_methods = analyze_eq_methods(methods)

    # Display results
    print("⚡ EQ METHODS:")
    print("-" * 50)
    if eq_methods:
        for method in eq_methods:
            equipment_str = f" - Equipment: {', '.join(method['equipment'])}" if method['equipment'] else ""
            category_str = f" [{method['category']}]" if method['category'] else ""
            diff_str = f" ({method['difficulty']})" if method['difficulty'] else ""
            print(f"  • {method['title']}{diff_str}{category_str} - {method['steps_count']} steps{equipment_str}")
    else:
        print("  None found")

    print(f"\n📊 Total EQ Methods: {len(eq_methods)}")
    print(f"📊 Other Methods: {len(other_methods)}")

    # Check for specific gaps
    print("\n🔎 GAPS ANALYSIS:")
    print("-" * 50)

    # Check for specific exercise types
    has_basic_kegel = any('kegel' in m['title'].lower() and 'reverse' not in m['title'].lower() for m in eq_methods)
    has_reverse_kegel = any('reverse kegel' in m['title'].lower() for m in eq_methods)
    has_edging = any('edging' in m['title'].lower() for m in eq_methods)
    has_ballooning = any('ballooning' in m['title'].lower() for m in eq_methods)
    has_towel_raises = any('towel' in m['title'].lower() for m in eq_methods)
    has_helicopter = any('helicopter' in m['title'].lower() or 'rotation' in m['title'].lower() for m in eq_methods)

    gaps = []
    if not has_basic_kegel:
        gaps.append("❌ Missing: Basic Kegel exercises")
    if not has_reverse_kegel:
        gaps.append("❌ Missing: Reverse Kegel exercises")
    if not has_edging:
        gaps.append("❌ Missing: Edging exercises")
    if not has_ballooning:
        gaps.append("❌ Missing: Ballooning technique")
    if not has_towel_raises:
        gaps.append("❌ Missing: Towel raises/strength exercises")
    if not has_helicopter:
        gaps.append("❌ Missing: Helicopter/rotation exercises")

    if len(eq_methods) < 6:
        gaps.append(f"❌ Need {6 - len(eq_methods)} more EQ methods to meet AC (6+ required)")

    if gaps:
        for gap in gaps:
            print(f"  {gap}")
    else:
        print("  ✅ All requirements met!")

    print("\n📋 RECOMMENDATION:")
    print("-" * 50)
    if len(eq_methods) >= 6:
        print("✅ Already have 6+ EQ methods")
        print("💡 Consider enhancing existing methods with better progression tracking")
    else:
        print(f"📝 Need to add {6 - len(eq_methods)} more EQ methods")
        print("💡 Focus on missing exercise types identified above")

    print("\n📝 DETAILED FINDINGS:")
    print("-" * 50)
    print("Existing EQ Methods:")
    for method in eq_methods:
        print(f"  • {method['title']} - {method['steps_count']} steps")

    # Identify which new methods need to be created
    needed_methods = []
    if not has_basic_kegel:
        needed_methods.append("Advanced Kegel Variations")
    if not has_towel_raises:
        needed_methods.append("Towel Raises")
    if not has_helicopter:
        needed_methods.append("Helicopter Exercises")
    if len([m for m in eq_methods if 'edging' in m['title'].lower()]) < 2:
        needed_methods.append("Stamina-Focused Edging")

    # Always add vascular health if missing
    has_vascular = any('vascular' in m['title'].lower() or 'circulation' in m['title'].lower() for m in eq_methods)
    if not has_vascular:
        needed_methods.append("Vascular Health Exercise")

    # Add relaxation techniques
    has_relaxation = any('relaxation' in m['title'].lower() or 'pelvic floor' in m['description'].lower() for m in eq_methods)
    if not has_relaxation:
        needed_methods.append("Pelvic Floor Relaxation")

    if needed_methods:
        print(f"\n🎯 SUGGESTED NEW METHODS ({len(needed_methods)} needed):")
        print("-" * 50)
        for i, method in enumerate(needed_methods, 1):
            print(f"  {i}. {method}")

if __name__ == "__main__":
    main()