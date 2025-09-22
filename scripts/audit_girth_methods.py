#!/usr/bin/env python3
"""
Script to audit girth-specific methods in Firestore
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

            # Extract all fields for girth analysis
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

def analyze_girth_methods(methods: List[Dict]):
    """Analyze and categorize girth methods"""

    # Keywords for girth identification
    girth_keywords = [
        'jelq', 'girth', 'pump', 'clamp', 'squeeze', 'uli', 'horse',
        'bathmate', 'cock ring', 'bfr', 'firegoat', 'ballooning', 'pac'
    ]

    girth_methods = []
    length_methods = []
    eq_methods = []
    other_methods = []

    for method in methods:
        title_lower = method['title'].lower()
        desc_lower = method['description'].lower()

        # Check category first
        if method['category'] == 'girth':
            girth_methods.append(method)
        elif method['category'] == 'length':
            length_methods.append(method)
        elif method['category'] == 'eq':
            eq_methods.append(method)
        # If no category, check keywords
        elif any(keyword in title_lower or keyword in desc_lower for keyword in girth_keywords):
            girth_methods.append(method)
        else:
            other_methods.append(method)

    return girth_methods, length_methods, eq_methods, other_methods

def main():
    print("🔍 Girth Methods Audit")
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
    girth_methods, length_methods, eq_methods, other_methods = analyze_girth_methods(methods)

    # Display results
    print("💪 GIRTH METHODS:")
    print("-" * 50)
    if girth_methods:
        for method in girth_methods:
            equipment_str = f" - Equipment: {', '.join(method['equipment'])}" if method['equipment'] else ""
            print(f"  • {method['title']} ({method['difficulty']}) - {method['steps_count']} steps{equipment_str}")
    else:
        print("  None found")

    print(f"\n📊 Total Girth Methods: {len(girth_methods)}")

    print("\n📏 LENGTH METHODS: {} total".format(len(length_methods)))
    print("⚡ EQ METHODS: {} total".format(len(eq_methods)))
    print("❓ UNCATEGORIZED: {} total".format(len(other_methods)))

    # Check for specific gaps
    print("\n🔎 GAPS ANALYSIS:")
    print("-" * 50)

    # Check for specific exercise types
    has_vacuum_pump = any('vacuum' in m['title'].lower() or 'vacuum' in m['description'].lower() for m in girth_methods)
    has_dry_jelq = any('dry jelq' in m['title'].lower() or 'dry jelq' in m['description'].lower() for m in girth_methods)
    has_advanced_clamp = sum(1 for m in girth_methods if 'clamp' in m['title'].lower()) > 1

    gaps = []
    if not has_vacuum_pump:
        gaps.append("❌ Missing: Detailed vacuum pumping progression")
    if not has_dry_jelq:
        gaps.append("❌ Missing: Dry jelq variation")
    if not has_advanced_clamp:
        gaps.append("❌ Missing: Additional clamping protocols")

    if len(girth_methods) < 8:
        gaps.append(f"❌ Need {8 - len(girth_methods)} more girth methods to meet AC (8+ required)")

    if gaps:
        for gap in gaps:
            print(f"  {gap}")
    else:
        print("  ✅ All requirements met!")

    print("\n📋 RECOMMENDATION:")
    print("-" * 50)
    if len(girth_methods) >= 8:
        print("✅ Already have 8+ girth methods")
        print("💡 Consider enhancing existing methods with better safety/progression")
    else:
        print(f"📝 Need to add {8 - len(girth_methods)} more girth methods")
        print("💡 Focus on: vacuum pumping, dry jelq, advanced clamping")

if __name__ == "__main__":
    main()