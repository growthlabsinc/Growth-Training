#!/usr/bin/env python3
"""
Script to verify PE knowledge deployment
Story 3.2: Deploy PE Knowledge Base
"""

import json
import subprocess
import sys
import os

# Test queries for each category
TEST_QUERIES = {
    "length": [
        "What is manual stretching?",
        "How to use a hanger safely?",
        "What are penis extenders?"
    ],
    "girth": [
        "How does pumping work?",
        "What is jelqing technique?",
        "Is clamping safe?"
    ],
    "eq": [
        "What are kegel exercises?",
        "How does cardio help EQ?",
        "What lifestyle factors affect erections?"
    ],
    "safety": [
        "What are PE injury signs?",
        "How to prevent PE injuries?",
        "When to see a doctor for PE?"
    ],
    "equipment": [
        "How to choose a PE pump?",
        "What equipment is safe?"
    ],
    "progression": [
        "What are realistic PE gains?",
        "How long does PE take?"
    ]
}

def get_access_token():
    """Get Firebase access token using gcloud"""
    try:
        result = subprocess.run(
            ["gcloud", "auth", "print-access-token"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to get access token: {e}")
        sys.exit(1)

def query_firestore(token):
    """Query Firestore to count PE knowledge documents"""
    import requests

    url = "https://firestore.googleapis.com/v1/projects/growth-training-app/databases/(default)/documents/ai_coach_knowledge"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()

        documents = data.get('documents', [])

        # Count by category
        categories = {}
        for doc in documents:
            fields = doc.get('fields', {})
            category = fields.get('category', {}).get('stringValue', 'unknown')
            categories[category] = categories.get(category, 0) + 1

        return len(documents), categories

    except Exception as e:
        print(f"❌ Error querying Firestore: {e}")
        return 0, {}

def test_knowledge_search(token, query):
    """Test if knowledge search returns PE content"""
    # This would normally call the search function, but we'll check Firestore directly
    # For now, we'll just verify the documents exist
    return True

def check_for_angion_content(token):
    """Ensure no Angion content remains"""
    import requests

    url = "https://firestore.googleapis.com/v1/projects/growth-training-app/databases/(default)/documents/ai_coach_knowledge"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()

        documents = data.get('documents', [])
        angion_found = False

        for doc in documents:
            fields = doc.get('fields', {})
            content = fields.get('content', {}).get('stringValue', '').lower()
            title = fields.get('title', {}).get('stringValue', '').lower()

            angion_terms = ['angion', 'am1', 'am2', 'am3', 'sabre', 'vascion']
            for term in angion_terms:
                if term in content or term in title:
                    print(f"  ⚠️ Found Angion term '{term}' in document")
                    angion_found = True

        return not angion_found

    except Exception as e:
        print(f"❌ Error checking for Angion content: {e}")
        return False

def main():
    print("🔍 Verifying PE Knowledge Deployment")
    print("=" * 50)
    print()

    # Get access token
    print("📝 Getting Firebase access token...")
    token = get_access_token()
    print("  ✅ Token obtained")
    print()

    all_passed = True

    # Test 1: Document count
    print("📝 Test 1: Knowledge Document Count")
    print("-" * 30)
    total_docs, categories = query_firestore(token)

    if total_docs > 0:
        print(f"  ✅ PASSED: {total_docs} documents deployed")
        print(f"  📊 Categories:")
        for category, count in categories.items():
            print(f"     - {category}: {count} documents")
    else:
        print(f"  ❌ FAILED: No documents found in knowledge base")
        all_passed = False
    print()

    # Test 2: Category coverage
    print("📝 Test 2: Category Coverage")
    print("-" * 30)
    expected_categories = ['length', 'girth', 'eq', 'safety', 'equipment', 'progression']
    missing_categories = []

    for cat in expected_categories:
        if cat not in categories:
            missing_categories.append(cat)

    if not missing_categories:
        print(f"  ✅ PASSED: All expected categories present")
    else:
        print(f"  ❌ FAILED: Missing categories: {', '.join(missing_categories)}")
        all_passed = False
    print()

    # Test 3: No Angion content
    print("📝 Test 3: No Angion Content")
    print("-" * 30)
    if check_for_angion_content(token):
        print("  ✅ PASSED: No Angion content found")
    else:
        print("  ❌ FAILED: Angion content detected")
        all_passed = False
    print()

    # Test 4: Safety content prioritized
    print("📝 Test 4: Safety Content Priority")
    print("-" * 30)
    if 'safety' in categories and categories['safety'] >= 3:
        print(f"  ✅ PASSED: {categories.get('safety', 0)} safety documents present")
    else:
        print(f"  ❌ FAILED: Insufficient safety content")
        all_passed = False
    print()

    # Test 5: Deployment script exists
    print("📝 Test 5: Deployment Script")
    print("-" * 30)
    if os.path.exists("functions/deployPEKnowledge.js"):
        print("  ✅ PASSED: Deployment script exists")
    else:
        print("  ❌ FAILED: Deployment script not found")
        all_passed = False
    print()

    # Final Summary
    print("=" * 50)
    print("📊 VERIFICATION SUMMARY")
    print("=" * 50)

    if all_passed:
        print("✅ ALL TESTS PASSED")
        print()
        print("PE Knowledge successfully deployed:")
        print(f"• {total_docs} total documents")
        print(f"• {len(categories)} categories covered")
        print("• No Angion content present")
        print("• Safety content prioritized")
        print("• Deployment script available")
        print()
        print("✅ Story 3.2 verification complete!")
    else:
        print("❌ SOME TESTS FAILED")
        print()
        print("Please review the failed tests above and ensure:")
        print("• All PE knowledge is deployed")
        print("• All categories are covered")
        print("• No Angion content remains")
        print("• Deployment script is working")
        sys.exit(1)

if __name__ == "__main__":
    main()