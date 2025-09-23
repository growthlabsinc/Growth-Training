#!/usr/bin/env python3
"""
Generate PEMethodsService.swift from enhanced PE database
"""

import json
from pathlib import Path

def load_database():
    """Load enhanced PE database"""
    db_file = Path('extracted_data/pe_methods_database_enhanced.json')
    with open(db_file, 'r') as f:
        return json.load(f)

def sanitize_string(s):
    """Sanitize string for Swift"""
    if not s:
        return ""
    # Escape quotes and newlines
    s = s.replace('"', '\\"')
    s = s.replace('\n', '\\n')
    # Remove image URLs and weird formatting
    import re
    s = re.sub(r'https?://[^\s]+', '', s)
    s = re.sub(r'\d+\.jpg\?[^\s]+', '', s)
    s = re.sub(r'\s+', ' ', s)
    return s.strip()

def format_array(items):
    """Format array for Swift"""
    if not items:
        return "[]"
    clean_items = [f'"{sanitize_string(str(item))}"' for item in items if item]
    if not clean_items:
        return "[]"
    return "[" + ", ".join(clean_items) + "]"

def generate_exercise_swift(exercise):
    """Generate Swift code for an exercise"""
    # Determine stage based on difficulty
    stage = 1 if exercise.get('difficulty') == 'Beginner' else 2 if exercise.get('difficulty') == 'Intermediate' else 3

    # Clean up instructions
    instructions = exercise.get('instructions', 'Follow standard protocol')
    if len(instructions) > 500:
        instructions = instructions[:497] + "..."

    # Clean up description
    description = exercise.get('description', '')
    if len(description) > 200:
        description = description[:197] + "..."

    # Format equipment
    equipment = format_array(exercise.get('equipment', []))

    # Format warnings
    warnings = exercise.get('warnings', [])
    if warnings:
        safety = sanitize_string('. '.join(warnings))
    else:
        safety = "Always monitor for discomfort"

    # Format prerequisites - not part of GrowthMethod init
    prereqs = exercise.get('prerequisites', [])
    prereq_str = ''  # Prerequisites removed from model

    # Duration
    duration_str = exercise.get('duration', '10-15 minutes')
    try:
        # Extract number from duration string
        import re
        nums = re.findall(r'\d+', duration_str)
        if nums:
            duration = int(nums[0])
        else:
            duration = 15
    except:
        duration = 15

    swift_code = f'''
            GrowthMethod(
                id: "{exercise['id']}",
                stage: {stage},
                classification: "{exercise.get('difficulty', 'Beginner')}",
                title: "{sanitize_string(exercise['name'])}",
                methodDescription: "{sanitize_string(description)}",
                instructionsText: """
{sanitize_string(instructions)}
                """,
                equipmentNeeded: {equipment},
                estimatedDurationMinutes: {duration},
                categories: ["{exercise['category']}", "{exercise.get('difficulty', 'Beginner')}"],
                isFeatured: false,
                safetyNotes: "{safety}"{prereq_str}
            )'''

    return swift_code

def generate_service(database):
    """Generate complete PEMethodsService.swift"""

    # Group exercises by category
    length_exercises = [ex for ex in database['exercises'] if ex['category'] == 'Length']
    girth_exercises = [ex for ex in database['exercises'] if ex['category'] == 'Girth']
    eq_exercises = [ex for ex in database['exercises'] if ex['category'] == 'EQ']
    stamina_exercises = [ex for ex in database['exercises'] if ex['category'] == 'Stamina']

    # Generate Swift code
    swift = '''//
//  PEMethodsService.swift
//  Growth
//
//  Created for PE Methods Integration - All 33 Exercises
//

import Foundation

/// Service for providing PE (Penis Enlargement) exercise methods from enhanced database
class PEMethodsService {

    static let shared = PEMethodsService()

    private init() {}

    /// Returns all PE methods organized by category (33 total exercises)
    func getAllPEMethods() -> [GrowthMethod] {
        return lengthMethods + girthMethods + eqMethods + staminaMethods
    }

    /// PE Length Methods (''' + str(len(length_exercises)) + ''' exercises)
    private var lengthMethods: [GrowthMethod] {
        return ['''

    # Add length exercises
    for i, ex in enumerate(length_exercises):
        swift += generate_exercise_swift(ex)
        if i < len(length_exercises) - 1:
            swift += ','

    swift += '''
        ]
    }

    /// PE Girth Methods (''' + str(len(girth_exercises)) + ''' exercises)
    private var girthMethods: [GrowthMethod] {
        return ['''

    # Add girth exercises
    for i, ex in enumerate(girth_exercises):
        swift += generate_exercise_swift(ex)
        if i < len(girth_exercises) - 1:
            swift += ','

    swift += '''
        ]
    }

    /// PE EQ (Erection Quality) Methods (''' + str(len(eq_exercises)) + ''' exercises)
    private var eqMethods: [GrowthMethod] {
        return ['''

    # Add EQ exercises
    for i, ex in enumerate(eq_exercises):
        swift += generate_exercise_swift(ex)
        if i < len(eq_exercises) - 1:
            swift += ','

    swift += '''
        ]
    }

    /// PE Stamina Methods (''' + str(len(stamina_exercises)) + ''' exercise)
    private var staminaMethods: [GrowthMethod] {
        return ['''

    # Add stamina exercises
    for i, ex in enumerate(stamina_exercises):
        swift += generate_exercise_swift(ex)
        if i < len(stamina_exercises) - 1:
            swift += ','

    swift += '''
        ]
    }

    /// Get methods by category
    func getMethods(for category: String) -> [GrowthMethod] {
        switch category.lowercased() {
        case "length":
            return lengthMethods
        case "girth":
            return girthMethods
        case "eq":
            return eqMethods
        case "stamina":
            return staminaMethods
        default:
            return getAllPEMethods()
        }
    }

    /// Get method by ID
    func getMethod(byId id: String) -> GrowthMethod? {
        return getAllPEMethods().first { $0.id == id }
    }

    /// Get beginner methods
    func getBeginnerMethods() -> [GrowthMethod] {
        return getAllPEMethods().filter { $0.classification == "Beginner" }
    }

    /// Get intermediate methods
    func getInterMediateMethods() -> [GrowthMethod] {
        return getAllPEMethods().filter { $0.classification == "Intermediate" }
    }

    /// Get advanced methods
    func getAdvancedMethods() -> [GrowthMethod] {
        return getAllPEMethods().filter { $0.classification == "Advanced" }
    }

    /// Get featured methods
    func getFeaturedMethods() -> [GrowthMethod] {
        return getAllPEMethods().filter { $0.isFeatured }
    }

    /// Get total exercise count
    func getTotalExerciseCount() -> Int {
        return getAllPEMethods().count // Should return 33
    }

    /// Get category distribution
    func getCategoryDistribution() -> [String: Int] {
        return [
            "Length": lengthMethods.count,    // ''' + str(len(length_exercises)) + '''
            "Girth": girthMethods.count,      // ''' + str(len(girth_exercises)) + '''
            "EQ": eqMethods.count,             // ''' + str(len(eq_exercises)) + '''
            "Stamina": staminaMethods.count    // ''' + str(len(stamina_exercises)) + '''
        ]
    }
}'''

    return swift

def main():
    print("Generating PEMethodsService.swift with all 33 exercises...")

    # Load database
    db = load_database()
    print(f"Loaded {len(db['exercises'])} exercises")

    # Generate Swift service
    swift_code = generate_service(db)

    # Save to file
    output_file = Path('../Growth/Core/Services/PEMethodsService.swift')
    with open(output_file, 'w') as f:
        f.write(swift_code)

    print(f"✅ Generated PEMethodsService.swift with {len(db['exercises'])} exercises")
    print(f"   Length: {db['metadata']['categories']['Length']}")
    print(f"   Girth: {db['metadata']['categories']['Girth']}")
    print(f"   EQ: {db['metadata']['categories']['EQ']}")
    print(f"   Stamina: {db['metadata']['categories']['Stamina']}")

if __name__ == "__main__":
    main()