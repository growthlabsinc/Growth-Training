#!/usr/bin/env python3
"""
Script to audit AI Coach knowledge base for Angion-related content
Story 3.1: Remove Angion Knowledge Base
"""

import json
import sys
import requests
from typing import List, Dict
import subprocess
from datetime import datetime

# Firebase project configuration
PROJECT_ID = "growth-training-app"
COLLECTION = "ai_coach_knowledge"

# Angion-specific terms to search for
ANGION_KEYWORDS = [
    "angion", "am1", "am2", "am3", "sabre", "janus",
    "pyramid", "rush", "dorsal", "bfr", "blood flow restriction",
    "angion method", "angion 1.0", "angion 2.0", "angion 3.0",
    "vascion", "apdravya", "ampallang", "macropulse"
]

def get_firebase_token():
    """Get Firebase auth token using gcloud"""
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

def fetch_all_knowledge_docs(token: str) -> List[Dict]:
    """Fetch all documents from ai_coach_knowledge collection"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    all_documents = []
    next_page_token = None

    while True:
        params = {}
        if next_page_token:
            params["pageToken"] = next_page_token

        response = requests.get(url, headers=headers, params=params)

        if response.status_code != 200:
            print(f"❌ Error fetching documents: {response.status_code}")
            print(response.text)
            break

        data = response.json()

        if "documents" in data:
            all_documents.extend(data["documents"])

        # Check for next page
        next_page_token = data.get("nextPageToken")
        if not next_page_token:
            break

    return all_documents

def extract_document_data(doc: Dict) -> Dict:
    """Extract relevant data from Firestore document"""
    doc_id = doc["name"].split("/")[-1]
    fields = doc.get("fields", {})

    return {
        "id": doc_id,
        "title": fields.get("title", {}).get("stringValue", ""),
        "category": fields.get("category", {}).get("stringValue", ""),
        "content": fields.get("content", {}).get("stringValue", ""),
        "keywords": extract_array_field(fields.get("keywords", {})),
        "priority": fields.get("priority", {}).get("stringValue", "")
    }

def extract_array_field(field: Dict) -> List[str]:
    """Extract array values from Firestore field"""
    if "arrayValue" in field and "values" in field["arrayValue"]:
        return [v.get("stringValue", "") for v in field["arrayValue"]["values"]]
    return []

def is_angion_related(doc: Dict) -> bool:
    """Check if document contains Angion-related content"""
    # Combine all text fields for searching
    searchable_text = " ".join([
        doc.get("title", ""),
        doc.get("content", ""),
        doc.get("category", ""),
        " ".join(doc.get("keywords", []))
    ]).lower()

    # Check for any Angion keywords
    for keyword in ANGION_KEYWORDS:
        if keyword.lower() in searchable_text:
            return True

    return False

def create_backup(documents: List[Dict], filename: str):
    """Create JSON backup of documents"""
    backup_data = {
        "timestamp": datetime.now().isoformat(),
        "collection": COLLECTION,
        "document_count": len(documents),
        "documents": documents
    }

    with open(filename, 'w') as f:
        json.dump(backup_data, f, indent=2)

    print(f"✅ Backup created: {filename}")

def main():
    print("🔍 AI Coach Knowledge Base Audit")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Fetch all knowledge documents
    print(f"📊 Fetching all documents from {COLLECTION} collection...")
    raw_documents = fetch_all_knowledge_docs(token)
    print(f"✅ Found {len(raw_documents)} total documents")
    print()

    if not raw_documents:
        print("⚠️  No documents found in collection")
        return

    # Process documents
    all_documents = []
    angion_documents = []

    for raw_doc in raw_documents:
        doc = extract_document_data(raw_doc)
        all_documents.append(doc)

        if is_angion_related(doc):
            angion_documents.append(doc)

    # Display results
    print("📋 AUDIT RESULTS:")
    print("-" * 50)
    print(f"Total documents: {len(all_documents)}")
    print(f"Angion-related documents: {len(angion_documents)}")
    print()

    if angion_documents:
        print("🚨 ANGION CONTENT FOUND:")
        print("-" * 50)
        for doc in angion_documents:
            print(f"\n📄 Document: {doc['id']}")
            print(f"   Title: {doc['title']}")
            print(f"   Category: {doc['category']}")
            print(f"   Priority: {doc['priority']}")

            # Show which keywords matched
            matched_keywords = []
            searchable = f"{doc['title']} {doc['content']} {' '.join(doc['keywords'])}".lower()
            for keyword in ANGION_KEYWORDS:
                if keyword.lower() in searchable:
                    matched_keywords.append(keyword)
            print(f"   Matched terms: {', '.join(matched_keywords)}")

        print()
        print("-" * 50)
        print("📝 DOCUMENTS TO DELETE:")
        print("-" * 50)
        for doc in angion_documents:
            print(f"   - {doc['id']}")
    else:
        print("✅ No Angion-related content found in knowledge base")

    # Create backups
    print()
    print("💾 Creating backups...")

    # Full backup
    if all_documents:
        full_backup_file = f"archive/ai_knowledge_full_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        create_backup(all_documents, full_backup_file)

    # Angion-specific backup
    if angion_documents:
        angion_backup_file = f"archive/ai_knowledge_angion_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        create_backup(angion_documents, angion_backup_file)

        # Also create a simple list of IDs to delete
        with open("archive/angion_document_ids.txt", 'w') as f:
            for doc in angion_documents:
                f.write(f"{doc['id']}\n")
        print("✅ Document ID list created: archive/angion_document_ids.txt")

    # Summary
    print()
    print("📈 SUMMARY:")
    print("-" * 50)
    print(f"✅ Audit complete")
    print(f"📊 Total documents: {len(all_documents)}")
    print(f"🚨 Angion documents to remove: {len(angion_documents)}")

    if angion_documents:
        print()
        print("⚠️  Next step: Review the identified documents and run delete script if correct")

if __name__ == "__main__":
    # Create archive directory if it doesn't exist
    import os
    os.makedirs("archive", exist_ok=True)

    main()