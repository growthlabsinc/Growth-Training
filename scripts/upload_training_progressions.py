#!/usr/bin/env python3
"""
Script to upload training progression routines to Firestore
Creates structured progression routines from beginner to advanced levels
"""

import json
import sys
import requests
from typing import List, Dict

# Firebase project configuration
PROJECT_ID = "growth-training-app"
COLLECTION = "routines"

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

def create_firestore_document(data: Dict) -> Dict:
    """Convert Python dict to Firestore document format"""
    def convert_value(value):
        if isinstance(value, str):
            return {"stringValue": value}
        elif isinstance(value, int):
            return {"integerValue": str(value)}
        elif isinstance(value, list):
            return {"arrayValue": {"values": [convert_value(item) for item in value]}}
        elif isinstance(value, dict):
            return {"mapValue": {"fields": {k: convert_value(v) for k, v in value.items()}}}
        else:
            return {"stringValue": str(value)}

    return {"fields": {key: convert_value(value) for key, value in data.items()}}

def upload_routine(token: str, routine_id: str, routine_data: Dict) -> bool:
    """Upload a single routine to Firestore"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{routine_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    firestore_doc = create_firestore_document(routine_data)

    response = requests.patch(url, headers=headers, json=firestore_doc)
    if response.status_code in [200, 201]:
        print(f"✅ Successfully uploaded: {routine_data['title']}")
        return True
    else:
        print(f"❌ Failed to upload {routine_id}: {response.status_code}")
        print(response.text)
        return False

def get_training_progression_routines() -> List[Dict]:
    """Define all training progression routines"""

    routines = []

    # ==========================================
    # NEWBIE LEVEL (3-month conditioning program)
    # ==========================================

    # Week 1-4: Foundation Building Routine
    routines.append({
        "id": "newbie_foundation_weeks_1_4",
        "title": "Newbie Foundation (Weeks 1-4)",
        "description": "Conservative 4-week foundation building program for complete beginners. Focuses on tissue conditioning, safety habits, and proper form development. MEDICAL DISCLAIMER: Consult a healthcare provider before beginning any PE routine. This program is designed for healthy adults 18+ who have received medical clearance.",
        "difficulty": "beginner",
        "category": "progression",
        "duration": 18,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "basic_manual_stretch",
            "basic_jelq",
            "kegel_exercises",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 4,
        "weeksInProgram": 4,
        "restDayRequirements": "Minimum 1 rest day between sessions, 2 consecutive rest days per week",
        "timeCommitment": "15-20 minutes, 4 days per week",
        "progressionCriteria": [
            "Complete all 4 weeks without injury or excessive soreness",
            "Demonstrate proper form for all exercises",
            "Show consistent tissue conditioning response",
            "Successfully manage warm-up and recovery protocols"
        ],
        "safetyGuidelines": [
            "Stop immediately if experiencing pain, numbness, or discoloration",
            "Never skip warm-up or recovery phases",
            "Start with minimal intensity and gradually increase",
            "Maintain detailed training log"
        ],
        "expectedOutcomes": [
            "Improved tissue flexibility and conditioning",
            "Established safety habits and routines",
            "Basic understanding of PE principles",
            "Foundation for progression to Week 5-8 program"
        ]
    })

    # Week 5-8: Gentle Progression Routine
    routines.append({
        "id": "newbie_progression_weeks_5_8",
        "title": "Newbie Progression (Weeks 5-8)",
        "description": "4-week gentle progression program building on foundation skills. Introduces EQ-focused exercises and increased frequency. MEDICAL DISCLAIMER: Only proceed if Weeks 1-4 completed successfully without complications. Consult healthcare provider with any concerns.",
        "difficulty": "beginner",
        "category": "progression",
        "duration": 22,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "basic_manual_stretch",
            "basic_jelq",
            "kegel_exercises",
            "reverse_kegels",
            "edging_practice",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 5,
        "weeksInProgram": 4,
        "restDayRequirements": "Minimum 2 rest days per week, listen to body signals",
        "timeCommitment": "20-25 minutes, 5 days per week",
        "progressionCriteria": [
            "Successfully completed Weeks 1-4 foundation program",
            "Demonstrate improved exercise endurance and form",
            "Show positive tissue adaptation without overuse signs",
            "Ready for light girth work introduction"
        ],
        "safetyGuidelines": [
            "Monitor for any signs of overtraining or injury",
            "Reduce intensity or take extra rest days if needed",
            "Maintain strict form standards as intensity increases",
            "Document all sessions and body responses"
        ],
        "expectedOutcomes": [
            "Enhanced exercise capacity and endurance",
            "Improved EQ and pelvic floor strength",
            "Greater tissue conditioning and flexibility",
            "Preparation for pre-intermediate training"
        ]
    })

    # Week 9-12: Pre-Intermediate Preparation
    routines.append({
        "id": "newbie_preintermediate_weeks_9_12",
        "title": "Newbie Pre-Intermediate (Weeks 9-12)",
        "description": "Final 4-week newbie program introducing light girth work and preparing for intermediate training. Comprehensive conditioning completion. MEDICAL DISCLAIMER: Advanced newbie training requiring previous 8 weeks successful completion. Medical consultation recommended before proceeding to intermediate level.",
        "difficulty": "beginner",
        "category": "progression",
        "duration": 25,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "basic_manual_stretch",
            "fulcrum_stretches",
            "basic_jelq",
            "dry_jelq_technique",
            "kegel_exercises",
            "reverse_kegels",
            "edging_practice",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 5,
        "weeksInProgram": 4,
        "restDayRequirements": "2 rest days per week minimum, more if experiencing fatigue",
        "timeCommitment": "22-28 minutes, 5 days per week",
        "progressionCriteria": [
            "Successfully completed Weeks 5-8 progression program",
            "Demonstrate mastery of all basic techniques",
            "Show excellent recovery and tissue adaptation",
            "Ready for intermediate-level training intensity"
        ],
        "safetyGuidelines": [
            "Carefully monitor response to increased girth work",
            "Maintain conservative approach despite increased capacity",
            "Prepare body systematically for intermediate demands",
            "Complete medical check-in before advancing levels"
        ],
        "expectedOutcomes": [
            "Complete tissue conditioning and preparation",
            "Mastery of fundamental PE techniques",
            "Optimal recovery and adaptation patterns",
            "Readiness for intermediate specialization training"
        ]
    })

    # ==========================================
    # INTERMEDIATE LEVEL (6-month specialization)
    # ==========================================

    # Length Focus Intermediate Routine
    routines.append({
        "id": "intermediate_length_focus",
        "title": "Intermediate Length Focus",
        "description": "6-month specialized routine focusing on length gains through advanced stretching protocols and progressive techniques. MEDICAL DISCLAIMER: Intermediate-level training requiring successful completion of 3-month newbie program. Regular medical monitoring recommended.",
        "difficulty": "intermediate",
        "category": "specialization",
        "duration": 35,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "basic_manual_stretch",
            "fulcrum_stretches",
            "btc_stretch",
            "bundled_stretches",
            "a_stretch",
            "penis_extender_protocol",
            "ads_method",
            "basic_jelq",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 6,
        "weeksInProgram": 24,
        "restDayRequirements": "1 full rest day per week, deload week every 6 weeks",
        "timeCommitment": "30-40 minutes, 6 days per week",
        "progressionCriteria": [
            "Completed 3-month newbie conditioning program",
            "Demonstrate advanced stretching technique mastery",
            "Show consistent length-focused adaptations",
            "Maintain excellent recovery between sessions"
        ],
        "safetyGuidelines": [
            "Progressive intensity increase over 6-month period",
            "Monitor for overuse injuries with increased frequency",
            "Regular technique assessment and form correction",
            "Immediate cessation if experiencing concerning symptoms"
        ],
        "expectedOutcomes": [
            "Significant length gains over 6-month period",
            "Advanced PE technique proficiency",
            "Specialized length training expertise",
            "Option to progress to advanced protocols"
        ]
    })

    # Girth Focus Intermediate Routine
    routines.append({
        "id": "intermediate_girth_focus",
        "title": "Intermediate Girth Focus",
        "description": "6-month specialized routine emphasizing girth development through jelqing progressions and pump training. MEDICAL DISCLAIMER: Advanced girth training with increased cardiovascular demands. Medical clearance and blood pressure monitoring essential.",
        "difficulty": "intermediate",
        "category": "specialization",
        "duration": 38,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "basic_manual_stretch",
            "basic_jelq",
            "dry_jelq_technique",
            "firegoat_rolls",
            "bathmate_water_pump",
            "combination_pump_jelq",
            "uli_exercise",
            "horse_squeeze",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 5,
        "weeksInProgram": 24,
        "restDayRequirements": "2 rest days per week minimum due to intensity",
        "timeCommitment": "35-42 minutes, 5 days per week",
        "progressionCriteria": [
            "Completed 3-month newbie conditioning program",
            "Demonstrate safe jelqing and pump technique",
            "Show positive girth adaptation response",
            "Maintain cardiovascular fitness for training demands"
        ],
        "safetyGuidelines": [
            "Careful blood pressure and cardiovascular monitoring",
            "Progressive pump pressure increases only",
            "Watch for signs of excessive tissue stress",
            "Regular medical check-ins recommended"
        ],
        "expectedOutcomes": [
            "Notable girth increases over training period",
            "Advanced jelqing and pump proficiency",
            "Enhanced tissue expansion capacity",
            "Preparation for advanced girth protocols"
        ]
    })

    # EQ Focus Intermediate Routine
    routines.append({
        "id": "intermediate_eq_focus",
        "title": "Intermediate EQ Focus",
        "description": "6-month program dedicated to erection quality enhancement through advanced pelvic floor training and vascular optimization. MEDICAL DISCLAIMER: EQ training may affect cardiovascular function. Medical consultation required for those with heart conditions.",
        "difficulty": "intermediate",
        "category": "specialization",
        "duration": 32,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "kegel_exercises",
            "reverse_kegels",
            "advanced_kegel_variations",
            "edging_practice",
            "ballooning_technique",
            "towel_raises",
            "helicopter_exercise",
            "cock_ring_training",
            "pelvic_floor_relaxation",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 6,
        "weeksInProgram": 24,
        "restDayRequirements": "1 rest day per week, active recovery encouraged",
        "timeCommitment": "28-35 minutes, 6 days per week",
        "progressionCriteria": [
            "Completed 3-month newbie conditioning program",
            "Demonstrate advanced pelvic floor control",
            "Show improved erection quality metrics",
            "Master complex EQ training techniques"
        ],
        "safetyGuidelines": [
            "Monitor for any cardiovascular stress signs",
            "Gradual progression in edging and ballooning duration",
            "Maintain proper breathing patterns throughout",
            "Avoid overexertion in pelvic floor training"
        ],
        "expectedOutcomes": [
            "Dramatically improved erection quality and control",
            "Enhanced pelvic floor strength and coordination",
            "Better sexual performance and stamina",
            "Foundation for advanced EQ optimization"
        ]
    })

    # Combined Approach Intermediate Routine
    routines.append({
        "id": "intermediate_combined_approach",
        "title": "Intermediate Combined Approach",
        "description": "6-month balanced routine incorporating length, girth, and EQ training for comprehensive development. MEDICAL DISCLAIMER: Intensive combined training requiring excellent health status and previous PE experience.",
        "difficulty": "intermediate",
        "category": "progression",
        "duration": 45,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "basic_manual_stretch",
            "fulcrum_stretches",
            "basic_jelq",
            "dry_jelq_technique",
            "firegoat_rolls",
            "kegel_exercises",
            "advanced_kegel_variations",
            "edging_practice",
            "ballooning_technique",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 6,
        "weeksInProgram": 24,
        "restDayRequirements": "1 rest day per week, deload weeks every 8 weeks",
        "timeCommitment": "40-50 minutes, 6 days per week",
        "progressionCriteria": [
            "Completed 3-month newbie conditioning program",
            "Demonstrate competency in all three training areas",
            "Show balanced development across length, girth, and EQ",
            "Maintain consistent training adherence and recovery"
        ],
        "safetyGuidelines": [
            "Careful management of total training volume",
            "Rotate emphasis between length, girth, and EQ focus",
            "Monitor for signs of overtraining or burnout",
            "Maintain excellent recovery practices"
        ],
        "expectedOutcomes": [
            "Comprehensive development in all areas",
            "Well-rounded PE training expertise",
            "Balanced physical adaptations and improvements",
            "Preparation for advanced specialized training"
        ]
    })

    # ==========================================
    # ADVANCED LEVEL (maintenance & optimization)
    # ==========================================

    # High-Intensity Advanced Protocol
    routines.append({
        "id": "advanced_high_intensity",
        "title": "Advanced High-Intensity Protocol",
        "description": "Advanced protocol for experienced practitioners seeking maximum gains through high-intensity techniques. MEDICAL DISCLAIMER: Extreme training requiring extensive PE experience, excellent health, and regular medical supervision.",
        "difficulty": "advanced",
        "category": "progression",
        "duration": 55,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "fulcrum_stretches",
            "a_stretch",
            "bundled_stretches",
            "btc_stretch",
            "firegoat_rolls",
            "uli_exercise",
            "horse_squeeze",
            "advanced_clamping",
            "bfr_clamping",
            "combination_pump_jelq",
            "advanced_kegel_variations",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 5,
        "weeksInProgram": 12,
        "restDayRequirements": "2 rest days per week mandatory, extended recovery periods",
        "timeCommitment": "50-60 minutes, 5 days per week",
        "progressionCriteria": [
            "Minimum 18 months successful PE training experience",
            "Mastery of all intermediate-level techniques",
            "Excellent health status and medical clearance",
            "Demonstrated ability to handle high training volumes"
        ],
        "safetyGuidelines": [
            "Mandatory medical supervision and regular check-ups",
            "Immediate cessation for any concerning symptoms",
            "Conservative progression despite advanced techniques",
            "Comprehensive health monitoring throughout program"
        ],
        "expectedOutcomes": [
            "Maximum potential gains for experienced practitioners",
            "Mastery of most advanced PE techniques",
            "Peak physical conditioning and adaptation",
            "Transition readiness to maintenance protocols"
        ]
    })

    # Maintenance Program
    routines.append({
        "id": "advanced_maintenance",
        "title": "Advanced Maintenance Program",
        "description": "Sustainable maintenance routine for advanced practitioners focused on preserving gains and long-term health. MEDICAL DISCLAIMER: Designed for those who have achieved their PE goals and need sustainable long-term maintenance.",
        "difficulty": "advanced",
        "category": "maintenance",
        "duration": 30,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "basic_manual_stretch",
            "basic_jelq",
            "kegel_exercises",
            "edging_practice",
            "ads_method",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 3,
        "weeksInProgram": 52,  # Full year program
        "restDayRequirements": "4 rest days per week, focus on life balance",
        "timeCommitment": "25-35 minutes, 3 days per week",
        "progressionCriteria": [
            "Achieved desired PE goals from previous training",
            "Need for sustainable long-term maintenance approach",
            "Focus on health preservation over further gains",
            "Integration with normal lifestyle and activities"
        ],
        "safetyGuidelines": [
            "Emphasize injury prevention and long-term health",
            "Adjust frequency and intensity based on life demands",
            "Regular assessment of maintenance needs",
            "Preventive approach to potential issues"
        ],
        "expectedOutcomes": [
            "Preservation of previously achieved gains",
            "Long-term tissue health and function",
            "Sustainable integration with lifestyle",
            "Continued enjoyment of PE benefits"
        ]
    })

    # Plateau Breaking Routine
    routines.append({
        "id": "advanced_plateau_breaker",
        "title": "Advanced Plateau Breaking Routine",
        "description": "Specialized 8-week intensive routine designed to break through training plateaus using novel techniques and increased intensity. MEDICAL DISCLAIMER: Intensive plateau-breaking protocol requiring advanced experience and medical clearance.",
        "difficulty": "advanced",
        "category": "specialization",
        "duration": 50,  # minutes
        "exerciseIds": [
            "heat_application_warmup",
            "bundled_stretches",
            "a_stretch",
            "fulcrum_stretches",
            "firegoat_rolls",
            "uli_exercise",
            "horse_squeeze",
            "advanced_clamping",
            "combination_pump_jelq",
            "towel_raises",
            "ballooning_technique",
            "post_exercise_recovery"
        ],
        "daysPerWeek": 4,
        "weeksInProgram": 8,
        "restDayRequirements": "3 rest days per week, extended recovery focus",
        "timeCommitment": "45-55 minutes, 4 days per week",
        "progressionCriteria": [
            "Documented training plateau despite consistent effort",
            "Advanced technique mastery and experience",
            "Excellent recovery capacity and health status",
            "Commitment to intensive 8-week protocol"
        ],
        "safetyGuidelines": [
            "Intensive monitoring for overuse or injury signs",
            "Ready to reduce intensity or stop if needed",
            "Focus on technique perfection over force",
            "Medical consultation before and during program"
        ],
        "expectedOutcomes": [
            "Breakthrough of existing training plateaus",
            "Renewed progress and adaptation response",
            "Advanced technique refinement and mastery",
            "Transition to appropriate long-term routine"
        ]
    })

    return routines

def main():
    print("🚀 Training Progressions Upload")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Get routine definitions
    routines = get_training_progression_routines()
    print(f"📋 Prepared {len(routines)} training progression routines")
    print()

    # Upload each routine
    successful_uploads = 0
    failed_uploads = 0

    for routine in routines:
        routine_id = routine.pop("id")  # Remove ID from data before upload
        success = upload_routine(token, routine_id, routine)
        if success:
            successful_uploads += 1
        else:
            failed_uploads += 1

    print()
    print("📊 UPLOAD SUMMARY:")
    print("-" * 50)
    print(f"✅ Successful uploads: {successful_uploads}")
    print(f"❌ Failed uploads: {failed_uploads}")
    print(f"📁 Total routines: {len(routines)}")

    if failed_uploads > 0:
        print(f"\n⚠️  {failed_uploads} uploads failed. Check the errors above.")
        sys.exit(1)
    else:
        print("\n🎉 All training progression routines uploaded successfully!")
        print("\n📋 PROGRESSION STRUCTURE CREATED:")
        print("-" * 50)
        print("🟢 NEWBIE LEVEL (3 months):")
        print("  • Weeks 1-4: Foundation Building")
        print("  • Weeks 5-8: Gentle Progression")
        print("  • Weeks 9-12: Pre-Intermediate Preparation")
        print()
        print("🟠 INTERMEDIATE LEVEL (6 months):")
        print("  • Length Focus Specialization")
        print("  • Girth Focus Specialization")
        print("  • EQ Focus Specialization")
        print("  • Combined Approach Training")
        print()
        print("🔴 ADVANCED LEVEL (maintenance & optimization):")
        print("  • High-Intensity Protocol")
        print("  • Maintenance Program")
        print("  • Plateau Breaking Routine")
        print()
        print("✅ All progression criteria and time commitments defined!")

if __name__ == "__main__":
    main()