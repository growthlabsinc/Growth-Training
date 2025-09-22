#!/usr/bin/env python3
"""
Audit PE Knowledge Base
Story 3.2: Deploy PE Knowledge Base - Maintenance Script

Comprehensive audit of deployed PE knowledge for quality and completeness.
"""

import json
import subprocess
import sys
import requests
import re
from datetime import datetime

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

def fetch_all_knowledge(token):
    """Fetch all knowledge documents from Firestore"""
    url = "https://firestore.googleapis.com/v1/projects/growth-training-app/databases/(default)/documents/ai_coach_knowledge"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        return data.get('documents', [])
    except Exception as e:
        print(f"❌ Error fetching knowledge: {e}")
        return []

def audit_content_quality(documents):
    """Audit content quality and completeness"""
    print("📝 Content Quality Audit")
    print("-" * 40)

    issues = []
    total_docs = len(documents)

    # Check each document
    for doc in documents:
        fields = doc.get('fields', {})
        doc_id = fields.get('id', {}).get('stringValue', 'unknown')
        title = fields.get('title', {}).get('stringValue', '')
        content = fields.get('content', {}).get('stringValue', '')
        category = fields.get('category', {}).get('stringValue', '')
        keywords = [kw.get('stringValue', '') for kw in fields.get('keywords', {}).get('arrayValue', {}).get('values', [])]
        priority = fields.get('priority', {}).get('integerValue', 0)

        # Quality checks
        doc_issues = []

        # 1. Content length check
        if len(content) < 500:
            doc_issues.append("Content too short (< 500 chars)")

        # 2. Medical disclaimer check
        if 'medical' not in content.lower() and 'disclaimer' not in content.lower():
            if category in ['safety', 'girth', 'length']:  # Categories that need disclaimers
                doc_issues.append("Missing medical disclaimer")

        # 3. Safety emphasis check
        safety_keywords = ['safety', 'safe', 'warning', 'caution', 'stop', 'pain', 'injury']
        if not any(keyword in content.lower() for keyword in safety_keywords):
            if category != 'progression':  # Progression docs may not need explicit safety warnings
                doc_issues.append("Insufficient safety emphasis")

        # 4. Keywords coverage
        if len(keywords) < 3:
            doc_issues.append("Too few keywords (< 3)")

        # 5. Priority assignment
        if category == 'safety' and int(priority) < 8:
            doc_issues.append("Safety content should have priority >= 8")

        # 6. Prohibited content check
        prohibited_terms = ['angion', 'am1', 'am2', 'am3', 'sabre', 'vascion']
        for term in prohibited_terms:
            if term.lower() in content.lower() or term.lower() in title.lower():
                doc_issues.append(f"Contains prohibited term: {term}")

        # 7. Progressive approach check
        aggressive_terms = ['aggressive', 'extreme', 'maximum', 'harder', 'faster']
        aggressive_count = sum(1 for term in aggressive_terms if term in content.lower())
        if aggressive_count > 2:
            doc_issues.append("May promote overly aggressive approach")

        if doc_issues:
            issues.append({
                'id': doc_id,
                'title': title,
                'category': category,
                'issues': doc_issues
            })

    # Summary
    if issues:
        print(f"  ⚠️ Found issues in {len(issues)}/{total_docs} documents:")
        for issue_doc in issues:
            print(f"\n  📄 {issue_doc['title']} ({issue_doc['id']})")
            for issue in issue_doc['issues']:
                print(f"     - {issue}")
    else:
        print(f"  ✅ All {total_docs} documents passed quality checks")

    return len(issues) == 0

def audit_category_coverage(documents):
    """Audit category coverage and balance"""
    print("\n📁 Category Coverage Audit")
    print("-" * 40)

    expected_categories = {
        'safety': {'min': 3, 'max': 5},
        'length': {'min': 3, 'max': 5},
        'girth': {'min': 3, 'max': 5},
        'eq': {'min': 3, 'max': 5},
        'equipment': {'min': 1, 'max': 3},
        'progression': {'min': 1, 'max': 3}
    }

    # Count documents per category
    category_counts = {}
    for doc in documents:
        fields = doc.get('fields', {})
        category = fields.get('category', {}).get('stringValue', 'unknown')
        category_counts[category] = category_counts.get(category, 0) + 1

    all_good = True

    print("  📊 Category Distribution:")
    for category, requirements in expected_categories.items():
        count = category_counts.get(category, 0)
        min_req = requirements['min']
        max_req = requirements['max']

        if count < min_req:
            print(f"    ❌ {category}: {count} (needs {min_req}-{max_req})")
            all_good = False
        elif count > max_req:
            print(f"    ⚠️ {category}: {count} (recommended {min_req}-{max_req})")
        else:
            print(f"    ✅ {category}: {count}")

    # Check for unexpected categories
    unexpected = set(category_counts.keys()) - set(expected_categories.keys())
    if unexpected:
        print(f"\n  ⚠️ Unexpected categories: {', '.join(unexpected)}")

    return all_good

def audit_search_keywords(documents):
    """Audit keyword coverage for search functionality"""
    print("\n🔍 Search Keywords Audit")
    print("-" * 40)

    # Collect all keywords
    all_keywords = set()
    category_keywords = {}

    for doc in documents:
        fields = doc.get('fields', {})
        category = fields.get('category', {}).get('stringValue', '')
        keywords = [kw.get('stringValue', '') for kw in fields.get('keywords', {}).get('arrayValue', {}).get('values', [])]

        all_keywords.update(keywords)
        if category not in category_keywords:
            category_keywords[category] = set()
        category_keywords[category].update(keywords)

    print(f"  📊 Total unique keywords: {len(all_keywords)}")

    # Check essential keywords are present
    essential_keywords = {
        'safety': ['safety', 'injury', 'prevention'],
        'length': ['length', 'stretching', 'hanging'],
        'girth': ['girth', 'pumping', 'jelqing'],
        'eq': ['eq', 'kegel', 'erection'],
        'equipment': ['equipment', 'device'],
        'progression': ['progression', 'timeline', 'results']
    }

    missing_keywords = []
    for category, required in essential_keywords.items():
        if category in category_keywords:
            category_kws = category_keywords[category]
            missing = [kw for kw in required if kw not in category_kws]
            if missing:
                missing_keywords.append(f"{category}: {', '.join(missing)}")

    if missing_keywords:
        print(f"  ⚠️ Missing essential keywords:")
        for missing in missing_keywords:
            print(f"     - {missing}")
        return False
    else:
        print(f"  ✅ All essential keywords present")
        return True

def audit_safety_priority(documents):
    """Audit safety content prioritization"""
    print("\n🛡️ Safety Priority Audit")
    print("-" * 40)

    safety_docs = []
    other_docs = []

    for doc in documents:
        fields = doc.get('fields', {})
        category = fields.get('category', {}).get('stringValue', '')
        priority = int(fields.get('priority', {}).get('integerValue', 0))
        title = fields.get('title', {}).get('stringValue', '')

        if category == 'safety':
            safety_docs.append({'title': title, 'priority': priority})
        else:
            other_docs.append({'title': title, 'priority': priority, 'category': category})

    # Check safety docs have high priority
    low_priority_safety = [doc for doc in safety_docs if doc['priority'] < 8]
    if low_priority_safety:
        print(f"  ❌ Safety docs with low priority:")
        for doc in low_priority_safety:
            print(f"     - {doc['title']}: {doc['priority']}")
        return False

    # Check priority distribution
    avg_safety_priority = sum(doc['priority'] for doc in safety_docs) / len(safety_docs) if safety_docs else 0
    avg_other_priority = sum(doc['priority'] for doc in other_docs) / len(other_docs) if other_docs else 0

    print(f"  📊 Average priority - Safety: {avg_safety_priority:.1f}, Others: {avg_other_priority:.1f}")

    if avg_safety_priority >= avg_other_priority:
        print(f"  ✅ Safety content properly prioritized")
        return True
    else:
        print(f"  ⚠️ Safety content priority could be higher")
        return False

def audit_content_freshness(documents):
    """Audit content freshness and timestamps"""
    print("\n📅 Content Freshness Audit")
    print("-" * 40)

    now = datetime.now()
    old_docs = []
    no_timestamp_docs = []

    for doc in documents:
        fields = doc.get('fields', {})
        title = fields.get('title', {}).get('stringValue', '')

        updated_at = fields.get('updatedAt', {}).get('timestampValue')
        created_at = fields.get('createdAt', {}).get('timestampValue')

        if not updated_at and not created_at:
            no_timestamp_docs.append(title)
            continue

        # Use the latest timestamp
        timestamp_str = updated_at or created_at
        if timestamp_str:
            try:
                # Parse Firebase timestamp
                doc_date = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
                days_old = (now - doc_date.replace(tzinfo=None)).days

                if days_old > 90:  # Older than 3 months
                    old_docs.append({'title': title, 'days_old': days_old})
            except:
                no_timestamp_docs.append(title)

    if no_timestamp_docs:
        print(f"  ⚠️ {len(no_timestamp_docs)} documents missing timestamps")

    if old_docs:
        print(f"  📊 {len(old_docs)} documents older than 3 months:")
        for doc in old_docs[:5]:  # Show first 5
            print(f"     - {doc['title']}: {doc['days_old']} days")
        if len(old_docs) > 5:
            print(f"     ... and {len(old_docs) - 5} more")

    if not old_docs and not no_timestamp_docs:
        print(f"  ✅ All content is fresh with proper timestamps")
        return True
    else:
        return len(old_docs) == 0  # OK if just missing timestamps

def main():
    print("🔍 PE Knowledge Base Audit")
    print("=" * 50)
    print()

    # Get access token
    print("📝 Getting Firebase access token...")
    token = get_access_token()
    print("  ✅ Token obtained")
    print()

    # Fetch all documents
    print("📚 Fetching knowledge documents...")
    documents = fetch_all_knowledge(token)
    if not documents:
        print("❌ No documents found")
        sys.exit(1)
    print(f"  ✅ Found {len(documents)} documents")
    print()

    # Run all audits
    results = []

    results.append(audit_content_quality(documents))
    results.append(audit_category_coverage(documents))
    results.append(audit_search_keywords(documents))
    results.append(audit_safety_priority(documents))
    results.append(audit_content_freshness(documents))

    # Final summary
    print("\n" + "=" * 50)
    print("📊 AUDIT SUMMARY")
    print("=" * 50)

    passed_audits = sum(results)
    total_audits = len(results)

    if passed_audits == total_audits:
        print("✅ ALL AUDITS PASSED")
        print()
        print("Knowledge base is in excellent condition:")
        print("• Content quality meets standards")
        print("• Category coverage is balanced")
        print("• Search keywords are comprehensive")
        print("• Safety content is prioritized")
        print("• Content timestamps are current")
        print()
        print("✅ No action required")
    else:
        print(f"⚠️ {passed_audits}/{total_audits} AUDITS PASSED")
        print()
        print("Areas needing attention:")

        audit_names = [
            "Content Quality",
            "Category Coverage",
            "Search Keywords",
            "Safety Priority",
            "Content Freshness"
        ]

        for i, passed in enumerate(results):
            if not passed:
                print(f"• {audit_names[i]}")

        print()
        print("📋 Recommended actions:")
        print("• Review failed audit sections above")
        print("• Update content using updatePEKnowledge.js")
        print("• Re-run audit after corrections")

        if passed_audits < total_audits * 0.6:  # Less than 60% passed
            sys.exit(1)

if __name__ == "__main__":
    main()