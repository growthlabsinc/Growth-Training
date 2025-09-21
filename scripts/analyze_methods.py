#!/usr/bin/env python3
"""
Script to analyze and optionally remove single-step methods from Firestore
Preserves ADS (All Day Stretching) methods regardless of step count
"""

import json
import sys
import requests
from typing import List, Dict, Tuple

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

            # Extract title
            title = "Untitled"
            if "title" in fields and "stringValue" in fields["title"]:
                title = fields["title"]["stringValue"]

            # Extract steps array
            steps = []
            if "steps" in fields and "arrayValue" in fields["steps"]:
                steps_array = fields["steps"]["arrayValue"].get("values", [])
                steps = [s for s in steps_array]

            methods.append({
                "id": method_id,
                "title": title,
                "step_count": len(steps),
                "full_path": doc["name"]
            })

    return methods

def analyze_methods(methods: List[Dict]) -> Tuple[List[Dict], List[Dict]]:
    """Categorize methods into keep and delete lists"""
    to_keep = []
    to_delete = []

    for method in methods:
        # Check if this is ADS
        is_ads = (
            "ads" in method["id"].lower() or
            "ads" in method["title"].lower() or
            "all day" in method["title"].lower() or
            "all-day" in method["title"].lower()
        )

        # Keep if: multi-step OR is ADS
        if method["step_count"] > 1 or is_ads:
            reason = "ADS method" if is_ads else f"{method['step_count']} steps"
            to_keep.append({**method, "reason": reason})
        else:
            to_delete.append(method)

    return to_keep, to_delete

def delete_methods(token: str, methods: List[Dict]):
    """Delete specified methods from Firestore"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    for method in methods:
        url = f"https://firestore.googleapis.com/v1/{method['full_path']}"
        response = requests.delete(url, headers=headers)

        if response.status_code in [200, 204]:
            print(f"  ✅ Deleted: {method['title']}")
        else:
            print(f"  ❌ Failed to delete {method['title']}: {response.status_code}")

def main():
    print("🔥 Single-Step Method Analyzer")
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
    to_keep, to_delete = analyze_methods(methods)

    # Display results
    print("✅ Methods to KEEP:")
    print("-" * 50)
    for method in to_keep:
        print(f"  • {method['title']} ({method['reason']})")

    print()
    print("🗑️  Methods to DELETE (single-step):")
    print("-" * 50)
    if not to_delete:
        print("  None - all methods have multiple steps or are ADS")
    else:
        for method in to_delete:
            print(f"  • {method['title']} ({method['step_count']} step)")

    print()
    print("=" * 50)
    print(f"Summary: {len(to_delete)} to delete, {len(to_keep)} to keep")
    print()

    # Ask for confirmation if there are methods to delete
    if to_delete and len(sys.argv) > 1 and sys.argv[1] == "--delete":
        response = input("⚠️  Type 'DELETE' to confirm deletion: ")
        if response == "DELETE":
            print("\n🔥 Deleting single-step methods...")
            delete_methods(token, to_delete)
            print(f"\n✅ Successfully deleted {len(to_delete)} methods")
        else:
            print("❌ Deletion cancelled")
    elif to_delete:
        print("To delete these methods, run:")
        print(f"  python3 {sys.argv[0]} --delete")

if __name__ == "__main__":
    main()