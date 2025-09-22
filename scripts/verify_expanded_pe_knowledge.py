#!/usr/bin/env python3
"""
Verify Expanded PE Knowledge Deployment
Story 3.3: Develop Training Protocol Knowledge

This script verifies that all 50+ PE knowledge documents are properly deployed
and meet the requirements specified in Epic 3.
"""

import json
import subprocess
from typing import Dict, List, Tuple
from collections import defaultdict

def run_firebase_command(query: str) -> str:
    """Execute a Firebase query using gcloud."""
    try:
        cmd = f"""
        gcloud firestore documents list \
            --collection-path=ai_coach_knowledge \
            --project=growth-training-app \
            --format=json
        """
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error running Firebase command: {result.stderr}")
            return ""
        return result.stdout
    except Exception as e:
        print(f"Error executing command: {e}")
        return ""

def analyze_knowledge_base() -> Tuple[Dict, List, Dict]:
    """Analyze the deployed knowledge base."""
    print("📊 Fetching PE knowledge documents from Firestore...")

    # Get all documents
    docs_json = run_firebase_command("ai_coach_knowledge")
    if not docs_json:
        print("❌ Failed to fetch documents")
        return {}, [], {}

    try:
        documents = json.loads(docs_json)
    except json.JSONDecodeError:
        print("❌ Failed to parse JSON response")
        return {}, [], {}

    # Analyze documents
    category_counts = defaultdict(int)
    priority_distribution = defaultdict(int)
    issues = []

    for doc in documents:
        fields = doc.get('fields', {})

        # Check category
        category = fields.get('category', {}).get('stringValue', 'unknown')
        category_counts[category] += 1

        # Check priority
        priority = fields.get('priority', {}).get('integerValue', 5)
        priority_distribution[priority] += 1

        # Check for required fields
        doc_id = fields.get('id', {}).get('stringValue', 'unknown')
        title = fields.get('title', {}).get('stringValue', '')
        content = fields.get('content', {}).get('stringValue', '')
        keywords = fields.get('keywords', {}).get('arrayValue', {}).get('values', [])

        # Validate content
        if not title:
            issues.append(f"Document {doc_id}: Missing title")

        if len(content) < 500:
            issues.append(f"Document {doc_id}: Content too short ({len(content)} chars)")

        if len(keywords) < 3:
            issues.append(f"Document {doc_id}: Insufficient keywords ({len(keywords)})")

        # Check for medical disclaimer
        if "Medical Disclaimer" not in content:
            issues.append(f"Document {doc_id}: Missing medical disclaimer")

        # Check for safety content in appropriate categories
        if category in ['length', 'girth', 'equipment'] and "safety" not in content.lower():
            issues.append(f"Document {doc_id}: Missing safety warnings")

    return dict(category_counts), issues, dict(priority_distribution)

def verify_requirements(category_counts: Dict) -> List[str]:
    """Verify Epic 3 requirements are met."""
    requirements_met = []
    requirements_failed = []

    # Check document count requirements
    requirements = {
        'length': (15, 'Length training techniques'),
        'girth': (12, 'Girth training techniques'),
        'eq': (8, 'EQ improvement content'),
        'equipment': (10, 'Equipment usage guides'),
        'progression': (5, 'Progression guidelines'),
        'safety': (3, 'Safety documents')
    }

    for category, (required, description) in requirements.items():
        actual = category_counts.get(category, 0)
        if actual >= required:
            requirements_met.append(f"✅ {description}: {actual}/{required}")
        else:
            requirements_failed.append(f"❌ {description}: {actual}/{required}")

    # Check total count
    total = sum(category_counts.values())
    if total >= 50:
        requirements_met.append(f"✅ Total documents: {total}/50+")
    else:
        requirements_failed.append(f"❌ Total documents: {total}/50+")

    return requirements_met + requirements_failed

def print_report(category_counts: Dict, issues: List, priority_dist: Dict, requirements: List):
    """Print comprehensive verification report."""
    print("\n" + "="*60)
    print("📋 EXPANDED PE KNOWLEDGE VERIFICATION REPORT")
    print("="*60)

    # Document counts by category
    print("\n📊 Document Counts by Category:")
    total = 0
    for category, count in sorted(category_counts.items()):
        print(f"  {category.capitalize()}: {count} documents")
        total += count
    print(f"  TOTAL: {total} documents")

    # Priority distribution
    print("\n🎯 Priority Distribution:")
    for priority in sorted(priority_dist.keys()):
        print(f"  Priority {priority}: {priority_dist[priority]} documents")

    # Requirements verification
    print("\n✔️  Requirements Verification:")
    for req in requirements:
        print(f"  {req}")

    # Issues found
    if issues:
        print(f"\n⚠️  Issues Found ({len(issues)}):")
        for issue in issues[:10]:  # Show first 10 issues
            print(f"  - {issue}")
        if len(issues) > 10:
            print(f"  ... and {len(issues) - 10} more issues")
    else:
        print("\n✅ No issues found!")

    # Summary
    print("\n" + "="*60)
    if total >= 50 and len(issues) == 0:
        print("🎉 SUCCESS: All requirements met!")
    elif total >= 50:
        print("⚠️  PARTIAL SUCCESS: Document count met but issues found")
    else:
        print("❌ FAILED: Requirements not met")
    print("="*60)

def main():
    """Main verification function."""
    print("🔍 Verifying Expanded PE Knowledge Deployment")
    print("Story 3.3: Develop Training Protocol Knowledge\n")

    # Analyze knowledge base
    category_counts, issues, priority_dist = analyze_knowledge_base()

    if not category_counts:
        print("❌ Unable to verify knowledge base - no data retrieved")
        return

    # Verify requirements
    requirements_status = verify_requirements(category_counts)

    # Print report
    print_report(category_counts, issues, priority_dist, requirements_status)

if __name__ == "__main__":
    main()