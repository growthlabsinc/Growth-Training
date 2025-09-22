#!/usr/bin/env python3
"""
Script to audit existing training progressions and routines in Firestore
"""

import json
import sys
import requests
from typing import List, Dict

# Firebase project configuration
PROJECT_ID = "growth-training-app"
ROUTINES_COLLECTION = "routines"
EXERCISES_COLLECTION = "growth_exercises"

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

def fetch_collection(token: str, collection: str) -> List[Dict]:
    """Fetch all documents from a Firestore collection"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{collection}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        print(f"❌ Error fetching {collection}: {response.status_code}")
        print(response.text)
        return []

    data = response.json()
    documents = []

    if "documents" in data:
        for doc in data["documents"]:
            doc_id = doc["name"].split("/")[-1]
            fields = doc.get("fields", {})

            # Extract fields based on collection type
            if collection == ROUTINES_COLLECTION:
                documents.append(parse_routine_document(doc_id, fields))
            elif collection == EXERCISES_COLLECTION:
                documents.append(parse_exercise_document(doc_id, fields))

    return documents

def parse_routine_document(doc_id: str, fields: Dict) -> Dict:
    """Parse routine document fields"""
    def get_string_value(field_name: str) -> str:
        return fields.get(field_name, {}).get("stringValue", "")

    def get_int_value(field_name: str) -> int:
        return int(fields.get(field_name, {}).get("integerValue", "0"))

    def get_array_value(field_name: str) -> List[str]:
        array_field = fields.get(field_name, {}).get("arrayValue", {})
        values = array_field.get("values", [])
        return [v.get("stringValue", "") for v in values if "stringValue" in v]

    return {
        "id": doc_id,
        "title": get_string_value("title"),
        "description": get_string_value("description"),
        "difficulty": get_string_value("difficulty"),
        "category": get_string_value("category"),
        "duration": get_int_value("duration"),
        "exerciseIds": get_array_value("exerciseIds"),
        "daysPerWeek": get_int_value("daysPerWeek"),
        "weeksInProgram": get_int_value("weeksInProgram"),
        "timeCommitment": get_string_value("timeCommitment"),
        "progressionCriteria": get_array_value("progressionCriteria")
    }

def parse_exercise_document(doc_id: str, fields: Dict) -> Dict:
    """Parse exercise document fields"""
    def get_string_value(field_name: str) -> str:
        return fields.get(field_name, {}).get("stringValue", "")

    def get_int_value(field_name: str) -> int:
        return int(fields.get(field_name, {}).get("integerValue", "0"))

    return {
        "id": doc_id,
        "title": get_string_value("title"),
        "category": get_string_value("category"),
        "difficulty": get_string_value("difficulty"),
        "estimatedDuration": get_int_value("estimatedDuration")
    }

def analyze_progression_gaps(routines: List[Dict], exercises: List[Dict]):
    """Analyze gaps in training progressions"""

    # Categorize existing routines
    beginner_routines = [r for r in routines if r['difficulty'] == 'beginner']
    intermediate_routines = [r for r in routines if r['difficulty'] == 'intermediate']
    advanced_routines = [r for r in routines if r['difficulty'] == 'advanced']

    # Categorize exercises by category and difficulty
    exercises_by_category = {}
    for exercise in exercises:
        category = exercise['category'] or 'uncategorized'
        difficulty = exercise['difficulty'] or 'uncategorized'

        if category not in exercises_by_category:
            exercises_by_category[category] = {'beginner': [], 'intermediate': [], 'advanced': [], 'uncategorized': []}

        if difficulty not in exercises_by_category[category]:
            exercises_by_category[category][difficulty] = []

        exercises_by_category[category][difficulty].append(exercise)

    print("🎯 PROGRESSION ANALYSIS:")
    print("-" * 50)
    print(f"📊 Beginner Routines: {len(beginner_routines)}")
    print(f"📊 Intermediate Routines: {len(intermediate_routines)}")
    print(f"📊 Advanced Routines: {len(advanced_routines)}")
    print()

    print("🧩 AVAILABLE EXERCISES BY CATEGORY:")
    print("-" * 50)
    for category, exercises_dict in exercises_by_category.items():
        print(f"  📁 {category.upper()}:")
        for difficulty, exercise_list in exercises_dict.items():
            if exercise_list:  # Only show non-empty categories
                print(f"    • {difficulty.title()}: {len(exercise_list)} exercises")
    print()

    # Identify gaps
    gaps = []
    if len(beginner_routines) < 2:
        gaps.append("❌ Need newbie routines (3-month conditioning program)")
    if len(intermediate_routines) < 3:
        gaps.append("❌ Need intermediate routines with specialization options")
    if len(advanced_routines) < 3:
        gaps.append("❌ Need advanced high-intensity and maintenance routines")

    # Check for progression structure
    has_progression_criteria = any(r['progressionCriteria'] for r in routines)
    if not has_progression_criteria:
        gaps.append("❌ Missing progression criteria and advancement guidelines")

    # Check time commitments
    has_time_commitments = any(r['timeCommitment'] for r in routines)
    if not has_time_commitments:
        gaps.append("❌ Missing time commitment specifications")

    return gaps, exercises_by_category

def suggest_routine_structure(exercises_by_category: Dict):
    """Suggest routine structure based on available exercises"""

    print("💡 SUGGESTED ROUTINE STRUCTURE:")
    print("-" * 50)

    # Newbie routines (3-month program)
    print("🟢 NEWBIE LEVEL (3-month conditioning):")
    print("  Week 1-4: Foundation Building")
    length_beginners = len(exercises_by_category.get('length', {}).get('beginner', []))
    recovery_exercises = len(exercises_by_category.get('recovery', {}).get('beginner', []))
    print(f"    • 2-3 basic length exercises (available: {length_beginners})")
    print(f"    • Daily warm-up/cool-down protocols (available: {recovery_exercises})")
    print("    • 15-20 minutes, 3-4 days/week")
    print("  Week 5-8: Gentle Progression")
    print("    • Add basic EQ exercises")
    print("    • Increase session frequency to 5 days/week")
    print("  Week 9-12: Pre-Intermediate Preparation")
    print("    • Introduce light girth work")
    print("    • 20-25 minutes sessions")
    print()

    # Intermediate routines
    print("🟠 INTERMEDIATE LEVEL (6-month specialization):")
    intermediate_length = len(exercises_by_category.get('length', {}).get('intermediate', []))
    intermediate_girth = len(exercises_by_category.get('girth', {}).get('intermediate', []))
    intermediate_eq = len(exercises_by_category.get('eq', {}).get('intermediate', []))
    print(f"  Length Focus Routine (available exercises: {intermediate_length})")
    print(f"  Girth Focus Routine (available exercises: {intermediate_girth})")
    print(f"  EQ Focus Routine (available exercises: {intermediate_eq})")
    print("  Combined Approach Routine")
    print("  25-40 minutes, 5-6 days/week")
    print()

    # Advanced routines
    print("🔴 ADVANCED LEVEL (maintenance & optimization):")
    advanced_length = len(exercises_by_category.get('length', {}).get('advanced', []))
    advanced_girth = len(exercises_by_category.get('girth', {}).get('advanced', []))
    advanced_eq = len(exercises_by_category.get('eq', {}).get('advanced', []))
    print(f"  High-Intensity Protocol (length: {advanced_length}, girth: {advanced_girth}, eq: {advanced_eq})")
    print("  Maintenance Program (2-3 days/week)")
    print("  Plateau Breaking Routine")
    print("  40-60 minutes, 4-6 days/week")

def main():
    print("🎯 Training Progressions Audit")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Fetch routines and exercises
    print("📊 Fetching existing routines...")
    routines = fetch_collection(token, ROUTINES_COLLECTION)
    print(f"✅ Found {len(routines)} existing routines")

    print("📊 Fetching available exercises...")
    exercises = fetch_collection(token, EXERCISES_COLLECTION)
    print(f"✅ Found {len(exercises)} available exercises")
    print()

    # Display existing routines
    if routines:
        print("📋 EXISTING ROUTINES:")
        print("-" * 50)
        for routine in routines:
            exercise_count = len(routine['exerciseIds'])
            time_str = f" - {routine['timeCommitment']}" if routine['timeCommitment'] else ""
            category_str = f" [{routine['category']}]" if routine['category'] else ""
            print(f"  • {routine['title']} ({routine['difficulty']}){category_str}")
            print(f"    {exercise_count} exercises, {routine['duration']} min{time_str}")
        print()
    else:
        print("📋 No existing routines found")
        print()

    # Analyze gaps and suggest structure
    gaps, exercises_by_category = analyze_progression_gaps(routines, exercises)

    print("🔎 GAPS ANALYSIS:")
    print("-" * 50)
    if gaps:
        for gap in gaps:
            print(f"  {gap}")
    else:
        print("  ✅ All progression requirements met!")
    print()

    suggest_routine_structure(exercises_by_category)

    print("\n📝 IMPLEMENTATION PRIORITY:")
    print("-" * 50)
    print("1. Create newbie 3-month conditioning program (2-3 routines)")
    print("2. Develop intermediate specialization routines (3-4 routines)")
    print("3. Build advanced protocols and maintenance (2-3 routines)")
    print("4. Define progression criteria for each level")
    print("5. Specify realistic time commitments and expectations")

if __name__ == "__main__":
    main()