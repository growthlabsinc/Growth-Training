#!/usr/bin/env python3
"""
Enhanced PE Database Builder
Merges manual exercises with scraped content and fixes categorization
"""

import json
import re
from datetime import datetime
from pathlib import Path
from manual_pe_exercises import get_manual_exercises

# Proper categorization keywords
CATEGORY_KEYWORDS = {
    'Length': [
        'stretch', 'stretching', 'length', 'hanging', 'hanger', 'extender',
        'ads', 'all day stretcher', 'traction', 'ligament', 'bundled',
        'fulcrum', 'mem', 'firegoat'
    ],
    'Girth': [
        'jelq', 'jelqing', 'girth', 'pump', 'pumping', 'clamp', 'clamping',
        'squeeze', 'squeezes', 'expansion', 'uli', 'horse', 'cock ring',
        'ring', 'bfr', 'bathmate', 'vacuum'
    ],
    'EQ': [
        'kegel', 'kegels', 'reverse kegel', 'erection quality', 'eq',
        'pelvic floor', 'pc muscle', 'ballooning', 'erection angle'
    ],
    'Stamina': [
        'edging', 'edge', 'stamina', 'lasting', 'control', 'premature',
        'arousal', 'endurance'
    ]
}

# Equipment standardization
EQUIPMENT_MAPPING = {
    'pump': 'Vacuum pump',
    'pumps': 'Vacuum pump',
    'clamp': 'Cable clamp',
    'clamps': 'Cable clamp',
    'hanger': 'Hanger device',
    'hangers': 'Hanger device',
    'extender': 'Penis extender',
    'weight': 'Weights',
    'weights': 'Weights',
    'ring': 'Cock ring',
    'rings': 'Cock ring',
    'cock ring': 'Cock ring',
    'cylinder': 'Pump cylinder',
    'gauge': 'Pressure gauge',
    'lubricant': 'Lubricant',
    'lube': 'Lubricant'
}

def categorize_exercise(name, description, instructions):
    """Properly categorize an exercise based on content analysis"""
    content = f"{name} {description} {instructions}".lower()

    scores = {}
    for category, keywords in CATEGORY_KEYWORDS.items():
        score = sum(1 for keyword in keywords if keyword in content)
        if score > 0:
            scores[category] = score

    # Default to Girth if no clear category
    if not scores:
        # Check for jelq as special case
        if 'jelq' in content:
            return 'Girth'
        return 'General'

    # Return category with highest score
    return max(scores.items(), key=lambda x: x[1])[0]

def determine_difficulty(description, instructions, warnings):
    """Determine exercise difficulty based on content"""
    content = f"{description} {instructions} {' '.join(warnings or [])}".lower()

    advanced_indicators = [
        'advanced', 'extreme', 'high risk', 'experienced', 'plateau',
        '6 months', '1 year', 'dangerous', 'injury risk'
    ]

    intermediate_indicators = [
        'intermediate', 'moderate', '3 months', '4 weeks', 'some experience',
        'conditioned', 'build up'
    ]

    beginner_indicators = [
        'beginner', 'basic', 'fundamental', 'simple', 'easy', 'first',
        'introduction', 'starter'
    ]

    advanced_score = sum(1 for ind in advanced_indicators if ind in content)
    intermediate_score = sum(1 for ind in intermediate_indicators if ind in content)
    beginner_score = sum(1 for ind in beginner_indicators if ind in content)

    if advanced_score > intermediate_score and advanced_score > beginner_score:
        return 'Advanced'
    elif intermediate_score > beginner_score:
        return 'Intermediate'
    else:
        return 'Beginner'

def standardize_equipment(equipment_list):
    """Standardize equipment names"""
    if not equipment_list:
        return []

    standardized = set()
    for item in equipment_list:
        item_lower = item.lower().strip()
        standardized.add(EQUIPMENT_MAPPING.get(item_lower, item))

    return sorted(list(standardized))

def enhance_exercise(exercise):
    """Enhance a scraped exercise with proper categorization and data"""
    # Fix categorization
    exercise['category'] = categorize_exercise(
        exercise.get('name', ''),
        exercise.get('description', ''),
        exercise.get('instructions', '')
    )

    # Fix difficulty
    exercise['difficulty'] = determine_difficulty(
        exercise.get('description', ''),
        exercise.get('instructions', ''),
        exercise.get('warnings', [])
    )

    # Standardize equipment
    exercise['equipment'] = standardize_equipment(exercise.get('equipment', []))

    # Generate better instructions if current ones are poor
    if not exercise.get('instructions') or len(exercise.get('instructions', '')) < 50:
        exercise['instructions'] = generate_basic_instructions(exercise)

    # Clean up description
    if exercise.get('description'):
        # Remove image URLs and clean up
        desc = re.sub(r'https?://[^\s]+', '', exercise['description'])
        desc = re.sub(r'jpg\?[^\s]+', '', desc)
        desc = re.sub(r'\s+', ' ', desc).strip()
        exercise['description'] = desc if len(desc) > 20 else generate_basic_description(exercise)

    # Ensure duration format
    if not exercise.get('duration'):
        exercise['duration'] = estimate_duration(exercise)

    return exercise

def generate_basic_instructions(exercise):
    """Generate basic instructions based on exercise name and category"""
    name = exercise.get('name', '').lower()
    category = exercise.get('category', '')

    if category == 'Length':
        return """1. Start in flaccid state
2. Apply technique as described
3. Hold for recommended duration
4. Release and rest
5. Repeat for prescribed sets
6. Monitor for discomfort"""
    elif category == 'Girth':
        return """1. Achieve appropriate erection level
2. Apply technique with proper pressure
3. Perform prescribed repetitions
4. Rest between sets
5. Monitor for signs of overwork
6. Massage after completion"""
    elif category == 'EQ':
        return """1. Find comfortable position
2. Focus on muscle control
3. Perform contractions as described
4. Maintain proper breathing
5. Rest between sets
6. Practice regularly for best results"""
    else:
        return """1. Follow safety guidelines
2. Start conservatively
3. Progress gradually
4. Monitor body's response
5. Stop if pain occurs
6. Track progress over time"""

def generate_basic_description(exercise):
    """Generate basic description based on exercise name"""
    name = exercise.get('name', '')
    category = exercise.get('category', '')
    return f"A {category.lower()} exercise for PE development. {name} is practiced in the PE community."

def estimate_duration(exercise):
    """Estimate duration based on exercise type"""
    category = exercise.get('category', '')
    difficulty = exercise.get('difficulty', '')

    if category == 'Length':
        return "10-20 minutes" if difficulty == 'Beginner' else "20-30 minutes"
    elif category == 'Girth':
        return "10-15 minutes" if difficulty == 'Beginner' else "15-20 minutes"
    elif category == 'EQ':
        return "5-10 minutes"
    elif category == 'Stamina':
        return "15-30 minutes"
    else:
        return "10-15 minutes"

def filter_invalid_exercises(exercises):
    """Remove invalid or non-exercise entries"""
    filtered = []

    invalid_patterns = [
        'this is not',
        'discussion group',
        'do not promote',
        'warning',
        'disclaimer',
        'growth signs'
    ]

    for exercise in exercises:
        name = exercise.get('name', '').lower()
        desc = exercise.get('description', '').lower()

        # Check if it's actually an exercise
        is_invalid = any(pattern in name or pattern in desc for pattern in invalid_patterns)

        # Check if it has minimal required fields
        has_content = (
            len(exercise.get('name', '')) > 3 and
            (len(exercise.get('description', '')) > 20 or
             len(exercise.get('instructions', '')) > 20)
        )

        if not is_invalid and has_content:
            filtered.append(exercise)

    return filtered

def merge_exercises(manual_exercises, scraped_exercises):
    """Merge manual and scraped exercises, removing duplicates"""
    # Create a dict to track exercises by ID
    all_exercises = {}

    # Add manual exercises first (they're higher quality)
    for exercise in manual_exercises:
        exercise_id = exercise.get('id', '').lower()
        all_exercises[exercise_id] = exercise

    # Add scraped exercises if they're unique
    for exercise in scraped_exercises:
        exercise_id = exercise.get('id', '').lower()

        # Check for similar names to avoid duplicates
        exercise_name = exercise.get('name', '').lower()
        is_duplicate = False

        for existing_id, existing_exercise in all_exercises.items():
            existing_name = existing_exercise.get('name', '').lower()
            # Check for similar names
            if (exercise_id == existing_id or
                exercise_name == existing_name or
                (len(exercise_name) > 5 and exercise_name in existing_name) or
                (len(existing_name) > 5 and existing_name in exercise_name)):
                is_duplicate = True
                break

        if not is_duplicate:
            all_exercises[exercise_id] = exercise

    return list(all_exercises.values())

def main():
    """Build enhanced PE database"""
    print("Building Enhanced PE Database")
    print("=" * 50)

    # Load manual exercises
    print("\n📚 Loading manual exercises...")
    manual_exercises = get_manual_exercises()
    print(f"   Loaded {len(manual_exercises)} manual exercises")

    # Load scraped exercises
    scraped_file = Path('extracted_data/pe_methods_database.json')
    scraped_exercises = []

    if scraped_file.exists():
        print("\n🌐 Loading scraped exercises...")
        with open(scraped_file, 'r') as f:
            data = json.load(f)
            scraped_exercises = data.get('exercises', [])
        print(f"   Loaded {len(scraped_exercises)} scraped exercises")

        # Filter out invalid entries
        print("\n🧹 Filtering invalid entries...")
        scraped_exercises = filter_invalid_exercises(scraped_exercises)
        print(f"   {len(scraped_exercises)} valid exercises remaining")

        # Enhance scraped exercises
        print("\n✨ Enhancing scraped exercises...")
        scraped_exercises = [enhance_exercise(ex) for ex in scraped_exercises]
        print("   Categorization and data enhancement complete")

    # Merge exercises
    print("\n🔀 Merging exercise databases...")
    all_exercises = merge_exercises(manual_exercises, scraped_exercises)
    print(f"   Total unique exercises: {len(all_exercises)}")

    # Sort by category and difficulty
    all_exercises.sort(key=lambda x: (x.get('category', ''), x.get('difficulty', ''), x.get('name', '')))

    # Add extraction metadata
    for exercise in all_exercises:
        if 'extracted_date' not in exercise:
            exercise['extracted_date'] = datetime.now().isoformat()
        if 'community_rating' not in exercise:
            exercise['community_rating'] = 0
        if 'source_url' not in exercise:
            exercise['source_url'] = 'manual_entry'
        if 'source_type' not in exercise:
            exercise['source_type'] = 'manual'

    # Build final database
    final_database = {
        "metadata": {
            "extraction_date": datetime.now().isoformat(),
            "total_exercises": len(all_exercises),
            "sources": ["manual", "gettingbigger", "ajelqforyou"],
            "categories": {
                category: len([e for e in all_exercises if e.get('category') == category])
                for category in ['Length', 'Girth', 'EQ', 'Stamina']
            },
            "difficulties": {
                difficulty: len([e for e in all_exercises if e.get('difficulty') == difficulty])
                for difficulty in ['Beginner', 'Intermediate', 'Advanced']
            }
        },
        "exercises": all_exercises
    }

    # Save enhanced database
    output_dir = Path('extracted_data')
    output_dir.mkdir(exist_ok=True)

    # Save as primary database
    output_file = output_dir / 'pe_methods_database_enhanced.json'
    with open(output_file, 'w') as f:
        json.dump(final_database, f, indent=2)

    print(f"\n✅ Enhanced database saved to: {output_file}")

    # Generate summary report
    print("\n" + "=" * 50)
    print("ENHANCED DATABASE SUMMARY")
    print("=" * 50)
    print(f"Total Exercises: {len(all_exercises)}")
    print("\nBy Category:")
    for category, count in final_database['metadata']['categories'].items():
        print(f"  - {category}: {count}")
    print("\nBy Difficulty:")
    for difficulty, count in final_database['metadata']['difficulties'].items():
        print(f"  - {difficulty}: {count}")

    # List all exercises
    print("\nExercise List:")
    for exercise in all_exercises:
        rating = exercise.get('community_rating', 0)
        print(f"  • {exercise['name']} ({exercise['category']}) - {exercise['difficulty']} - Rating: {rating}")

    # Validation
    print("\n" + "=" * 50)
    if len(all_exercises) >= 20:
        print("✅ VALIDATION PASSED: Database has 20+ exercises")
    else:
        print(f"❌ VALIDATION FAILED: Only {len(all_exercises)} exercises (need 20+)")

    # Check category distribution
    has_all_categories = all(
        final_database['metadata']['categories'].get(cat, 0) > 0
        for cat in ['Length', 'Girth', 'EQ']
    )
    if has_all_categories:
        print("✅ VALIDATION PASSED: All main categories represented")
    else:
        print("❌ VALIDATION FAILED: Missing exercises in some categories")

    return len(all_exercises) >= 20

if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)