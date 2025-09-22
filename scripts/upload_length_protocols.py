#!/usr/bin/env python3
"""
Script to add new length training protocols to Firebase
Implements BTC, Straight-out, V-stretch, A-stretch, and JAI stretches
"""

import json
import sys
import requests
from typing import Dict

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

# Define new length protocols
NEW_LENGTH_PROTOCOLS = {
    "btc_stretch": {
        "title": "BTC (Behind The Cheeks) Stretch",
        "description": "An effective downward stretch performed behind the buttocks for targeting the suspensory ligament",
        "category": "length",
        "difficulty": "beginner",
        "estimatedDuration": 15,
        "equipmentNeeded": [],
        "steps": [
            {
                "order": 1,
                "instruction": "Warm up with 5-10 minutes of heat application or hot shower",
                "tips": ["Rice sock or heating pad works well", "Ensure complete privacy"],
                "cautions": ["Never skip warmup - cold tissue is injury-prone", "Temperature should be comfortably warm, not scalding"]
            },
            {
                "order": 2,
                "instruction": "Stand with feet shoulder-width apart, bend forward slightly",
                "tips": ["Keep knees slightly bent for comfort", "Back should be straight"],
                "cautions": ["Avoid if you have back problems", "Stop if dizzy from bending over"]
            },
            {
                "order": 3,
                "instruction": "Reach behind and grasp penis with overhand grip behind the glans",
                "tips": ["Use baby powder for better grip", "OK grip works best"],
                "cautions": ["Never grip the glans directly", "Grip should be firm but not painful"]
            },
            {
                "order": 4,
                "instruction": "Pull penis backward between legs toward buttocks",
                "tips": ["Start with gentle tension", "Should feel stretch at base"],
                "cautions": ["Stop if sharp pain occurs", "Don't pull beyond comfort level"]
            },
            {
                "order": 5,
                "instruction": "Hold stretch for 30-60 seconds",
                "tips": ["Breathe normally throughout", "Count seconds for consistency"],
                "cautions": ["Release if numbness occurs", "Maximum 60 seconds for beginners"]
            },
            {
                "order": 6,
                "instruction": "Release and rest for 30 seconds",
                "tips": ["Shake out to restore circulation", "Light massage helps"],
                "cautions": ["Don't skip rest periods", "Check for any discoloration"]
            },
            {
                "order": 7,
                "instruction": "Repeat for 5-10 sets total",
                "tips": ["Start with 5 sets if beginner", "Can increase gradually"],
                "cautions": ["Stop if fatigue affects form", "Maximum 10 sets initially"]
            },
            {
                "order": 8,
                "instruction": "Cool down with light massage",
                "tips": ["Apply moisturizer if needed", "Document session in log"],
                "cautions": ["Monitor for any unusual symptoms", "Take rest day if sore"]
            }
        ]
    },
    "straight_out_stretch": {
        "title": "Straight Out Stretch",
        "description": "Basic horizontal stretch performed straight forward, targeting overall length",
        "category": "length",
        "difficulty": "beginner",
        "estimatedDuration": 15,
        "equipmentNeeded": [],
        "steps": [
            {
                "order": 1,
                "instruction": "Warm up thoroughly with heat for 5-10 minutes",
                "tips": ["Hot shower or warm compress ideal", "Ensures tissue pliability"],
                "cautions": ["Never stretch cold", "Check skin temperature before starting"]
            },
            {
                "order": 2,
                "instruction": "Stand or sit in comfortable position",
                "tips": ["Standing allows better leverage", "Sitting is more relaxed"],
                "cautions": ["Ensure stable position", "Avoid slippery surfaces"]
            },
            {
                "order": 3,
                "instruction": "Grip penis with OK sign just behind glans",
                "tips": ["Thumb and forefinger form the OK", "Other fingers provide support"],
                "cautions": ["Don't grip glans directly", "Moderate pressure only"]
            },
            {
                "order": 4,
                "instruction": "Pull straight out parallel to floor",
                "tips": ["Maintain horizontal angle", "Should feel stretch at base"],
                "cautions": ["Stop if pain occurs", "Don't hyperextend"]
            },
            {
                "order": 5,
                "instruction": "Hold for 30-45 seconds",
                "tips": ["Count to maintain consistency", "Focus on steady tension"],
                "cautions": ["Release if tingling occurs", "Never exceed moderate tension"]
            },
            {
                "order": 6,
                "instruction": "Release and rest 30 seconds",
                "tips": ["Restore circulation with shaking", "Can do light jelqs"],
                "cautions": ["Full rest is important", "Check for normal color"]
            },
            {
                "order": 7,
                "instruction": "Rotate angles - up, down, left, right",
                "tips": ["30 seconds each direction", "Targets different areas"],
                "cautions": ["Avoid extreme angles", "Stop if uncomfortable"]
            },
            {
                "order": 8,
                "instruction": "Complete 2-3 full rotations",
                "tips": ["Total 10-15 minutes work", "Track progress weekly"],
                "cautions": ["Don't exceed time initially", "Quality over quantity"]
            }
        ]
    },
    "v_stretch": {
        "title": "V-Stretch",
        "description": "Advanced stretch using thumb as fulcrum to create a V-shape for enhanced tension",
        "category": "length",
        "difficulty": "intermediate",
        "estimatedDuration": 15,
        "equipmentNeeded": [],
        "steps": [
            {
                "order": 1,
                "instruction": "Complete warmup with 10 minutes of heat",
                "tips": ["Extra warmup for advanced technique", "Ensure fully relaxed"],
                "cautions": ["This is more intense - proper warmup critical", "Skip if new to PE"]
            },
            {
                "order": 2,
                "instruction": "Grip behind glans with dominant hand",
                "tips": ["Standard OK grip", "Keep grip consistent"],
                "cautions": ["Secure grip essential", "Don't grip too tightly"]
            },
            {
                "order": 3,
                "instruction": "Pull penis straight out",
                "tips": ["Moderate tension initially", "Should be comfortable"],
                "cautions": ["Not maximum stretch yet", "Build up gradually"]
            },
            {
                "order": 4,
                "instruction": "Place thumb of other hand on top of shaft midway",
                "tips": ["Thumb acts as fulcrum", "Press down gently"],
                "cautions": ["Don't press too hard", "Avoid pressing on glans"]
            },
            {
                "order": 5,
                "instruction": "Pull outward while pressing thumb down to create V shape",
                "tips": ["Creates dual stress points", "Should feel intense stretch"],
                "cautions": ["Stop if sharp pain", "This is advanced - go slowly"]
            },
            {
                "order": 6,
                "instruction": "Hold for 20-30 seconds",
                "tips": ["Shorter holds due to intensity", "Breathe normally"],
                "cautions": ["Don't exceed 30 seconds", "Release if numbness"]
            },
            {
                "order": 7,
                "instruction": "Release and massage for 30 seconds",
                "tips": ["Important to restore flow", "Light jelqs help"],
                "cautions": ["Check for any bruising", "Rest is critical"]
            },
            {
                "order": 8,
                "instruction": "Repeat 5-8 times, moving thumb position",
                "tips": ["Vary fulcrum point", "Work entire shaft"],
                "cautions": ["Maximum 8 reps initially", "Stop if fatigued"]
            }
        ]
    },
    "a_stretch": {
        "title": "A-Stretch (Advanced Fulcrum)",
        "description": "Intense fulcrum stretch creating an A-shape with both hands for maximum tension",
        "category": "length",
        "difficulty": "advanced",
        "estimatedDuration": 20,
        "equipmentNeeded": [],
        "steps": [
            {
                "order": 1,
                "instruction": "Extensive 10-15 minute warmup required",
                "tips": ["This is intense - warmup crucial", "Consider double warmup time"],
                "cautions": ["Only for experienced practitioners", "6+ months PE experience recommended"]
            },
            {
                "order": 2,
                "instruction": "Grip behind glans with right hand",
                "tips": ["Overhand grip works best", "Prepare for intense session"],
                "cautions": ["Must have perfect grip", "Any slipping is dangerous"]
            },
            {
                "order": 3,
                "instruction": "Pull penis straight out with moderate force",
                "tips": ["About 70% of max stretch", "Leave room to increase"],
                "cautions": ["Don't start at maximum", "Build intensity gradually"]
            },
            {
                "order": 4,
                "instruction": "Wrap other hand around shaft with underhand grip",
                "tips": ["Grip at midpoint", "Palm facing up"],
                "cautions": ["Not too tight", "This hand is the fulcrum"]
            },
            {
                "order": 5,
                "instruction": "Pull both hands apart while maintaining grips",
                "tips": ["Creates intense dual stretch", "Like stretching rubber band"],
                "cautions": ["This is very intense", "Stop immediately if pain"]
            },
            {
                "order": 6,
                "instruction": "Hold for 15-20 seconds only",
                "tips": ["Short duration due to intensity", "Focus on form"],
                "cautions": ["Never exceed 20 seconds", "Risk of injury if overdone"]
            },
            {
                "order": 7,
                "instruction": "Release completely and massage for 45 seconds",
                "tips": ["Longer rest due to intensity", "Essential recovery"],
                "cautions": ["Don't rush back into stretch", "Monitor for issues"]
            },
            {
                "order": 8,
                "instruction": "Repeat 3-5 times maximum",
                "tips": ["Quality over quantity", "Less is more with A-stretch"],
                "cautions": ["Never exceed 5 reps", "Take day off after"]
            }
        ]
    },
    "jai_stretches": {
        "title": "JAI Stretches",
        "description": "Quick, intense stretching intervals alternating between maximum stretch and complete relaxation",
        "category": "length",
        "difficulty": "intermediate",
        "estimatedDuration": 10,
        "equipmentNeeded": [],
        "steps": [
            {
                "order": 1,
                "instruction": "Standard 5-10 minute warmup",
                "tips": ["JAI requires good tissue preparation", "Heat is essential"],
                "cautions": ["Never do JAI cold", "Rapid stretching needs warmup"]
            },
            {
                "order": 2,
                "instruction": "Grip behind glans firmly",
                "tips": ["Need secure grip for quick movements", "OK grip ideal"],
                "cautions": ["Grip must not slip", "Safety depends on grip"]
            },
            {
                "order": 3,
                "instruction": "Perform quick 1-2 second maximum stretch",
                "tips": ["Fast pull to maximum", "Like a quick jerk"],
                "cautions": ["Not for beginners", "Can cause injury if too aggressive"]
            },
            {
                "order": 4,
                "instruction": "Immediately release completely",
                "tips": ["Full relaxation important", "No tension at all"],
                "cautions": ["Don't maintain any stretch", "Complete release required"]
            },
            {
                "order": 5,
                "instruction": "Rest 1-2 seconds",
                "tips": ["Very brief rest", "Just enough to reset"],
                "cautions": ["Don't rest too long", "Maintain rhythm"]
            },
            {
                "order": 6,
                "instruction": "Repeat rapid stretch-release cycle 30-50 times",
                "tips": ["Find your rhythm", "Like quick pulses"],
                "cautions": ["Stop if grip loosens", "Monitor for fatigue"]
            },
            {
                "order": 7,
                "instruction": "After set, rest 2-3 minutes",
                "tips": ["Full recovery between sets", "Massage helpful"],
                "cautions": ["Don't skip rest", "Tissue needs recovery"]
            },
            {
                "order": 8,
                "instruction": "Complete 2-3 total sets",
                "tips": ["Start with 2 sets", "Build to 3 over weeks"],
                "cautions": ["Maximum 3 sets", "Very fatiguing exercise"]
            }
        ]
    }
}

def create_method_document(method_id: str, method_data: Dict) -> Dict:
    """Convert method data to Firestore document format matching existing structure"""
    from datetime import datetime

    # Map difficulty to categories
    difficulty_map = {
        "beginner": "Beginner",
        "intermediate": "Intermediate",
        "advanced": "Advanced"
    }

    doc = {
        "fields": {
            "id": {"stringValue": method_id},
            "title": {"stringValue": method_data["title"]},
            "description": {"stringValue": method_data["description"]},
            "instructionsText": {"stringValue": method_data["description"]},
            "estimatedDurationMinutes": {"integerValue": str(method_data["estimatedDuration"])},
            "categories": {
                "arrayValue": {
                    "values": [
                        {"stringValue": "Length"},
                        {"stringValue": difficulty_map.get(method_data["difficulty"], "Intermediate")},
                        {"stringValue": "PE Training"}
                    ]
                }
            },
            "classification": {"stringValue": method_data["category"]},
            "stage": {"integerValue": "1" if method_data["difficulty"] == "beginner" else "2" if method_data["difficulty"] == "intermediate" else "3"},
            "equipmentNeeded": {
                "arrayValue": {
                    "values": [{"stringValue": item} for item in method_data["equipmentNeeded"]] if method_data.get("equipmentNeeded") else []
                }
            },
            "isFeatured": {"booleanValue": False},
            "version": {"integerValue": "2"},
            "sourceUrl": {"stringValue": "manual_entry"},
            "sourceType": {"stringValue": "community"},
            "createdAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"},
            "updatedAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"},
            "migratedFromPE": {"booleanValue": True},
            "safetyNotes": {"stringValue": "Always warm up before stretching. Stop if pain occurs. Consult a medical professional before starting any PE routine."},
            "benefits": {
                "arrayValue": {
                    "values": [
                        {"stringValue": "Length gains"},
                        {"stringValue": "Improved flexibility"},
                        {"stringValue": "Enhanced circulation"}
                    ]
                }
            },
            "relatedMethods": {
                "arrayValue": {
                    "values": [
                        {"stringValue": "basic_stretch"},
                        {"stringValue": "hanging_weight"}
                    ]
                }
            },
            "communityRating": {"doubleValue": 4.5},
            "progressionCriteria": {"stringValue": "Master basic form before advancing. Increase duration gradually."},
            "timerConfig": {
                "mapValue": {
                    "fields": {
                        "type": {"stringValue": "interval"},
                        "workDuration": {"integerValue": "30"},
                        "restDuration": {"integerValue": "30"},
                        "sets": {"integerValue": "5"}
                    }
                }
            },
            "steps": {
                "arrayValue": {
                    "values": [
                        {
                            "mapValue": {
                                "fields": {
                                    "stepNumber": {"integerValue": str(step["order"])},
                                    "title": {"stringValue": f"Step {step['order']}"},
                                    "description": {"stringValue": step["instruction"]},
                                    "duration": {"integerValue": "30"},
                                    "tips": {
                                        "arrayValue": {
                                            "values": [{"stringValue": tip} for tip in step.get("tips", [])]
                                        }
                                    },
                                    "cautions": {
                                        "arrayValue": {
                                            "values": [{"stringValue": caution} for caution in step.get("cautions", [])]
                                        }
                                    },
                                    "warnings": {
                                        "arrayValue": {
                                            "values": []
                                        }
                                    }
                                }
                            }
                        } for step in method_data["steps"]
                    ]
                }
            }
        }
    }
    return doc

def upload_method(token: str, method_id: str, method_data: Dict) -> bool:
    """Upload a single method to Firestore"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{method_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    document = create_method_document(method_id, method_data)

    # Try PATCH first (update), then POST (create) if it doesn't exist
    response = requests.patch(url, headers=headers, json=document)

    if response.status_code == 404:
        # Document doesn't exist, create it
        url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}"
        response = requests.post(url, headers=headers, json=document, params={"documentId": method_id})

    if response.status_code not in [200, 201]:
        print(f"   Error: {response.status_code} - {response.text[:200]}")

    return response.status_code in [200, 201]

def main():
    print("🚀 Uploading New Length Training Protocols")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Upload each new method
    success_count = 0
    fail_count = 0

    for method_id, method_data in NEW_LENGTH_PROTOCOLS.items():
        print(f"📤 Uploading: {method_data['title']}")
        if upload_method(token, method_id, method_data):
            print(f"   ✅ Successfully uploaded")
            success_count += 1
        else:
            print(f"   ❌ Failed to upload")
            fail_count += 1

    print()
    print("=" * 50)
    print(f"📊 Results:")
    print(f"   ✅ Successful: {success_count}")
    print(f"   ❌ Failed: {fail_count}")
    print()

    if success_count > 0:
        print("✨ New length training protocols added successfully!")
        print("   Total length methods should now be 14+")

if __name__ == "__main__":
    main()