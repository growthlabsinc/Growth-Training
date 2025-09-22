#!/usr/bin/env python3
"""
Script to upload enhanced EQ training exercises to Firebase
Following the exact document structure from Stories 2.2 and 2.3
"""

import json
import sys
import requests
from typing import Dict, List
from datetime import datetime

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

def create_eq_exercises() -> Dict:
    """Create all new/enhanced EQ training exercises"""
    return {
        "advanced_kegel_variations": {
            "title": "Advanced Kegel Variations",
            "description": "Progressive kegel exercise program with multiple hold patterns, pulses, and pyramid training for enhanced PC muscle strength and endurance",
            "category": "eq",
            "difficulty": "intermediate",
            "estimatedDuration": 15,
            "equipmentNeeded": ["Timer (optional)"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Identify and isolate PC muscle. Sit or lie comfortably. Contract the muscles you would use to stop urination mid-stream. Feel the lift and squeeze without tensing buttocks, abs, or thighs.",
                    "tips": ["Practice stopping urination to identify the correct muscle", "Start with gentle contractions", "Breathe normally throughout"],
                    "cautions": ["Don't hold your breath during contractions", "Avoid tensing other muscle groups", "Stop if you feel pain or cramping"]
                },
                {
                    "order": 2,
                    "instruction": "Basic hold pattern - 5-second holds. Contract PC muscle for 5 seconds, then relax for 5 seconds. Perform 10 repetitions. Focus on smooth, controlled contractions.",
                    "tips": ["Count slowly: one-thousand-one, one-thousand-two", "Quality over quantity", "Rest fully between contractions"],
                    "cautions": ["Don't rush the timing", "Ensure complete relaxation between holds", "Stop if muscle fatigues excessively"]
                },
                {
                    "order": 3,
                    "instruction": "Progressive hold training. Week 1-2: 5-second holds. Week 3-4: 7-second holds. Week 5-6: 10-second holds. Week 7-8: 15-second holds. Same rest periods.",
                    "tips": ["Only progress when current level is comfortable", "Track your progress in a journal", "Consistency is more important than duration"],
                    "cautions": ["Don't skip progression steps", "Back down if unable to maintain quality", "Never strain or force longer holds"]
                },
                {
                    "order": 4,
                    "instruction": "Pulse training for endurance. Perform rapid 1-second contractions and releases for 30 seconds. Rest 30 seconds. Repeat 3 sets. Focus on quick, sharp contractions.",
                    "tips": ["Think of it as muscle 'fluttering'", "Maintain rhythm throughout", "Use a timer or metronome"],
                    "cautions": ["Don't sacrifice quality for speed", "Stop if cramping occurs", "Ensure full relaxation between pulses"]
                },
                {
                    "order": 5,
                    "instruction": "Pyramid training for strength. Start with 1-second hold, then 2, 3, 4, 5, 4, 3, 2, 1. Rest 2 seconds between each. Complete 2-3 pyramid sets.",
                    "tips": ["Count out loud to maintain timing", "Visualize climbing then descending", "Rest longer between sets if needed"],
                    "cautions": ["Don't rush through the sequence", "Maintain quality throughout pyramid", "Stop if unable to complete proper contractions"]
                },
                {
                    "order": 6,
                    "instruction": "Endurance challenge. Contract and hold for maximum time (goal: 60+ seconds). Perform once per session. Track improvement over time.",
                    "tips": ["Build up gradually to longer holds", "Breathe steadily during long holds", "Use as progress measurement"],
                    "cautions": ["Only attempt after mastering basic holds", "Don't strain or cause pain", "Quality contraction more important than duration"]
                },
                {
                    "order": 7,
                    "instruction": "Benefits tracking and integration. Monitor improvements in erection hardness, control, and stamina. Practice during arousal for real-world application.",
                    "tips": ["Keep a progress log", "Notice improvements in daily life", "Practice during intimate moments"],
                    "cautions": ["Don't overdo exercises during arousal", "Gradual integration is key", "Consistency produces best results"]
                },
                {
                    "order": 8,
                    "instruction": "Advanced integration with breathing. Coordinate contractions with breath - contract on exhale, relax on inhale. Adds mindfulness and enhanced control.",
                    "tips": ["Start slowly with breath coordination", "Deep, controlled breathing", "Focus on mind-muscle connection"],
                    "cautions": ["Don't hold breath during contractions", "Stop if dizzy from breathing pattern", "Master basic kegels before adding breathing"]
                }
            ]
        },
        "towel_raises": {
            "title": "Towel Raises for EQ Strength",
            "description": "Progressive resistance training using towel weight to build PC muscle strength and improve erection firmness and control",
            "category": "eq",
            "difficulty": "intermediate",
            "estimatedDuration": 10,
            "equipmentNeeded": ["Hand towel", "Small washcloth (optional for progression)"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Prerequisites and preparation. Must have mastered basic kegels. Achieve 70-80% erection. Place lightweight towel on erect shaft near base (not on glans).",
                    "tips": ["Start with the lightest towel possible", "Ensure towel is clean and dry", "Practice basic position first"],
                    "cautions": ["Not for beginners - requires kegel mastery", "Never use heavy objects", "Remove towel if erection drops below 70%"]
                },
                {
                    "order": 2,
                    "instruction": "Basic towel lift technique. Contract PC muscle to lift towel upward. Hold for 2-3 seconds, then relax. The shaft should 'jump' or lift visibly.",
                    "tips": ["Focus on the upward lifting motion", "Use same muscle as stopping urination", "Start with very brief contractions"],
                    "cautions": ["Don't strain or force the movement", "Stop if any pain occurs", "Quality over quantity always"]
                },
                {
                    "order": 3,
                    "instruction": "Progressive repetition schedule. Week 1: 10 lifts. Week 2: 15 lifts. Week 3: 20 lifts. Week 4: 25 lifts. Rest 30 seconds between sets of 5.",
                    "tips": ["Track your progress", "Only progress when comfortable", "Break into sets to avoid fatigue"],
                    "cautions": ["Don't rush progression", "Back down if form deteriorates", "Stop session if muscle cramps"]
                },
                {
                    "order": 4,
                    "instruction": "Hold progression training. Week 1-2: 2-second holds. Week 3-4: 3-second holds. Week 5-6: 5-second holds. Maintain same rep count.",
                    "tips": ["Count slowly for accurate timing", "Focus on steady, controlled holds", "Quality contraction throughout hold"],
                    "cautions": ["Don't exceed comfortable hold times", "Ensure full relaxation between reps", "Stop if cramping occurs"]
                },
                {
                    "order": 5,
                    "instruction": "Weight progression (advanced only). Start with washcloth, progress to hand towel, then small face towel. Only increase weight when completing all reps easily.",
                    "tips": ["Very gradual weight increases", "Test new weight with just 5 reps first", "Most benefit comes from reps, not weight"],
                    "cautions": ["NEVER use excessive weight", "Stop immediately if sharp pain", "Heavier is not always better"]
                },
                {
                    "order": 6,
                    "instruction": "Performance benefits tracking. Monitor improvements in erection angle, firmness ratings (1-10), and control during arousal. Track weekly progress.",
                    "tips": ["Keep detailed progress notes", "Rate firmness consistently", "Notice improvements in real situations"],
                    "cautions": ["Progress is gradual - be patient", "Don't obsess over daily measurements", "Overall trend matters more than daily variance"]
                },
                {
                    "order": 7,
                    "instruction": "Integration with other exercises. Combine with basic kegels and edging practice. Towel raises 2-3 times per week maximum for recovery.",
                    "tips": ["Towel raises are intensive - allow recovery", "Combine with gentler EQ exercises", "Listen to your body's response"],
                    "cautions": ["Don't do towel raises daily", "Allow 48 hours between sessions", "Reduce frequency if soreness persists"]
                },
                {
                    "order": 8,
                    "instruction": "Troubleshooting and safety. If unable to lift towel, return to basic kegels. If erection quality decreases, reduce frequency. Focus on sustainable improvement.",
                    "tips": ["Step back if exercises become counterproductive", "Consistency over intensity", "Every body responds differently"],
                    "cautions": ["Never push through pain", "EQ exercises should improve, not harm function", "Consult healthcare provider if concerns arise"]
                }
            ]
        },
        "helicopter_rotation_exercises": {
            "title": "Helicopter Rotation Exercises",
            "description": "Flexibility and circulation exercises using controlled rotation movements to improve blood flow and maintain penile health",
            "category": "eq",
            "difficulty": "beginner",
            "estimatedDuration": 8,
            "equipmentNeeded": ["Lubricant (for comfort)"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Preparation and positioning. In flaccid state, apply small amount of lubricant to hands. Stand comfortably with feet shoulder-width apart. Ensure privacy and relaxation.",
                    "tips": ["Use minimal lubricant - just for comfort", "Warm hands before starting", "Choose comfortable, private environment"],
                    "cautions": ["Only perform when completely flaccid", "Stop if any pain or discomfort", "Gentle movements only"]
                },
                {
                    "order": 2,
                    "instruction": "Basic helicopter motion. Gently grasp near base with thumb and fingers. Move in circular motions - clockwise for 10 rotations, then counterclockwise for 10 rotations.",
                    "tips": ["Very gentle grip pressure", "Smooth, steady circular motions", "Think of it as gentle stretching"],
                    "cautions": ["No pulling or tugging motions", "Avoid excessive grip pressure", "Stop if redness or irritation occurs"]
                },
                {
                    "order": 3,
                    "instruction": "Gentle stretching rotations. While maintaining light grip, gently extend away from body while rotating. Small circles with light outward tension. 5 rotations each direction.",
                    "tips": ["Minimal extension - just light tension", "Combine rotation with gentle stretch", "Listen to tissue response"],
                    "cautions": ["Never force or strain", "Very light tension only", "Stop immediately if sharp sensations"]
                },
                {
                    "order": 4,
                    "instruction": "Flexibility enhancement routine. Move through different angles - up, down, left, right - while maintaining gentle rotation. 30 seconds in each direction.",
                    "tips": ["Explore natural range of motion", "No forced movements", "Focus on tissue flexibility"],
                    "cautions": ["Respect natural limits", "Don't force into uncomfortable positions", "Pain means stop immediately"]
                },
                {
                    "order": 5,
                    "instruction": "Circulation promotion technique. Alternate between gentle compression and rotation. Light squeeze for 2 seconds, then rotate, then release. Repeat 10 times.",
                    "tips": ["Very light compression only", "Think of encouraging blood flow", "Smooth transitions between movements"],
                    "cautions": ["Minimal compression force", "Never restrict blood flow", "Stop if numbness or discoloration"]
                },
                {
                    "order": 6,
                    "instruction": "Cool-down and assessment. Finish with gentle massage motions from base to tip. Check for any redness, soreness, or unusual sensations. Document response.",
                    "tips": ["Gentle massage helps circulation", "Normal to have slight warmth", "Track how tissues respond"],
                    "cautions": ["Significant redness indicates too much force", "Soreness means reduce intensity", "Any concerning changes should be evaluated"]
                },
                {
                    "order": 7,
                    "instruction": "Frequency and progression guidelines. Start with 2-3 times per week. Gradually increase to daily if well-tolerated. Each session 5-8 minutes maximum.",
                    "tips": ["Consistency more important than frequency", "Build tolerance gradually", "Quality over quantity approach"],
                    "cautions": ["Don't overdo frequency", "Daily sessions only if no irritation", "Less is more with flexibility work"]
                },
                {
                    "order": 8,
                    "instruction": "Benefits and integration. Improves tissue flexibility, circulation, and maintains penile health. Combine with other EQ exercises for comprehensive routine.",
                    "tips": ["Excellent warm-up for other exercises", "Promotes general penile health", "Good for circulation maintenance"],
                    "cautions": ["Supplement, don't replace other EQ work", "Results are gradual", "Focus on health, not size"]
                }
            ]
        },
        "stamina_focused_edging": {
            "title": "Stamina-Focused Edging Protocol",
            "description": "Advanced edging technique specifically designed to build stamina, improve ejaculatory control, and enhance erection quality through timed arousal management",
            "category": "eq",
            "difficulty": "intermediate",
            "estimatedDuration": 20,
            "equipmentNeeded": ["Timer", "Lubricant", "Towel"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Setup and mindset preparation. Set timer for 20 minutes. Apply lubricant. Focus on building stamina, not climax. Goal is arousal control and endurance training.",
                    "tips": ["Set clear intention for stamina building", "Remove performance pressure", "Focus on learning your arousal patterns"],
                    "cautions": ["This is training, not climax-focused", "Stop if frustrated or stressed", "Patience is essential for stamina building"]
                },
                {
                    "order": 2,
                    "instruction": "Gradual arousal building phase. Spend first 5 minutes slowly building to 6/10 arousal level. Use light, varied stimulation. Focus on maintaining steady 6/10.",
                    "tips": ["Use arousal scale 1-10 (10 = point of no return)", "Vary stimulation patterns", "Breathe deeply and slowly"],
                    "cautions": ["Don't rush to higher arousal", "If approaching 8/10, slow down immediately", "Focus on control, not intensity"]
                },
                {
                    "order": 3,
                    "instruction": "First edge training cycle. Build arousal to 7.5/10, then stop all stimulation. Use breathing and PC muscle relaxation to drop to 5/10. Resume when controlled.",
                    "tips": ["Stop stimulation completely at 7.5/10", "Deep breathing helps reduce arousal", "Gentle PC muscle contractions can help"],
                    "cautions": ["Don't try to edge at 9/10 as beginner", "If you go too far, stop and reset", "Practice makes perfect - be patient"]
                },
                {
                    "order": 4,
                    "instruction": "Multiple edge cycles for endurance. Repeat edge cycle 4-5 times: build to 7.5/10, stop, cool down to 5/10, resume. Track how long each cycle takes.",
                    "tips": ["Note how quickly you reach each edge", "Track recovery time between edges", "Look for patterns in your arousal"],
                    "cautions": ["Don't attempt more than 5 edges initially", "Stop if becoming too stimulated", "Quality over quantity"]
                },
                {
                    "order": 5,
                    "instruction": "Advanced arousal plateau training. Try to maintain 7/10 arousal for 2 minutes using minimal stimulation. This builds stamina and control simultaneously.",
                    "tips": ["Use just enough stimulation to maintain level", "Micro-adjustments in pressure/speed", "Focus on maintaining steady arousal"],
                    "cautions": ["Very advanced technique - master basic edging first", "Stop if unable to maintain control", "Don't force the plateau"]
                },
                {
                    "order": 6,
                    "instruction": "Breathing and PC muscle integration. During edges, practice breathing patterns and PC muscle relaxation. Exhale during high arousal, gentle contractions during cool-down.",
                    "tips": ["Coordinate breathing with arousal management", "PC muscles can help control arousal", "Practice these skills during edges"],
                    "cautions": ["Don't rely only on physical techniques", "Mental focus equally important", "Avoid excessive PC muscle tension"]
                },
                {
                    "order": 7,
                    "instruction": "Session conclusion and benefits tracking. End session in controlled manner at 15-18 minutes. Rate session difficulty (1-10), number of successful edges, and control level.",
                    "tips": ["Stop before timer expires", "Rate your control and stamina", "Note improvements over time"],
                    "cautions": ["Don't extend sessions beyond planned time", "Ending in control is success", "Progress tracking shows gradual improvement"]
                },
                {
                    "order": 8,
                    "instruction": "Progressive stamina building schedule. Week 1-2: 3 edges. Week 3-4: 4 edges. Week 5-6: 5 edges with plateau training. Track endurance improvements.",
                    "tips": ["Build complexity gradually", "Consistency more important than intensity", "Real-world application takes time"],
                    "cautions": ["Don't rush progression", "Some sessions will be better than others", "Focus on long-term stamina gains"]
                }
            ]
        },
        "vascular_health_exercise": {
            "title": "Vascular Health Enhancement",
            "description": "Comprehensive circulation and vascular health exercise combining gentle movements, breathing, and positioning to optimize blood flow for erection quality",
            "category": "eq",
            "difficulty": "beginner",
            "estimatedDuration": 12,
            "equipmentNeeded": ["Comfortable space for movement"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Cardiovascular warm-up preparation. Perform 2-3 minutes of light activity: marching in place, arm circles, or gentle stretching. Focus on increasing heart rate gradually.",
                    "tips": ["Start slowly and build intensity", "Focus on full-body circulation", "No vigorous exercise needed"],
                    "cautions": ["Don't overexert during warm-up", "Stop if chest pain or dizziness", "Adapt to your fitness level"]
                },
                {
                    "order": 2,
                    "instruction": "Pelvic circulation enhancement. Perform pelvic tilts: standing or lying, tilt pelvis forward and back smoothly. 10 tilts each direction. Promotes blood flow to pelvic region.",
                    "tips": ["Smooth, controlled movements", "Feel the circulation in pelvic area", "Coordinate with breathing"],
                    "cautions": ["Don't force range of motion", "Stop if back pain occurs", "Gentle movements only"]
                },
                {
                    "order": 3,
                    "instruction": "Deep breathing for circulation. Practice diaphragmatic breathing: breathe deeply into belly for 4 counts, hold for 4, exhale for 6. Repeat 10 cycles.",
                    "tips": ["Hand on chest, hand on belly - belly should rise more", "Focus on slow, controlled breathing", "This oxygenates blood effectively"],
                    "cautions": ["Don't hyperventilate", "Stop if dizzy", "Normal to feel relaxed"]
                },
                {
                    "order": 4,
                    "instruction": "Lower body circulation movements. Calf raises (20 reps), ankle circles (10 each direction), and gentle squats (10 reps). Promotes venous return and circulation.",
                    "tips": ["These movements help blood return to heart", "Focus on lower body activation", "Pace yourself appropriately"],
                    "cautions": ["Adapt to your fitness level", "Don't strain joints", "Stop if leg pain"]
                },
                {
                    "order": 5,
                    "instruction": "Stress reduction and relaxation. Practice progressive muscle relaxation: tense and release muscle groups for 5 seconds each. Start with feet, work up to face.",
                    "tips": ["Stress reduces blood flow", "Focus on releasing tension", "Pay attention to relaxation feeling"],
                    "cautions": ["Don't over-tense muscles", "Gentle tension and release", "Skip areas with injury"]
                },
                {
                    "order": 6,
                    "instruction": "Hydration and circulation check. Drink 8-12 oz of water. Check circulation by pressing fingernail - color should return in 2 seconds. Note energy and alertness levels.",
                    "tips": ["Proper hydration essential for circulation", "Nail bed test shows circulation quality", "Water helps blood viscosity"],
                    "cautions": ["Don't overhydrate", "Poor circulation needs medical evaluation", "Note any circulation concerns"]
                },
                {
                    "order": 7,
                    "instruction": "Gentle movement integration. Take 5-minute walk if possible, or march in place. Focus on how improved circulation feels throughout body, including pelvic region.",
                    "tips": ["Walking is excellent for circulation", "Note improved energy and blood flow", "Regular movement throughout day helps"],
                    "cautions": ["Don't overexert", "Listen to body's response", "Some benefit better than none"]
                },
                {
                    "order": 8,
                    "instruction": "Long-term vascular health habits. Plan for regular exercise, stress management, adequate sleep, and healthy diet. These exercises work best as part of overall health approach.",
                    "tips": ["EQ depends on overall cardiovascular health", "Consistency in healthy habits", "Small improvements compound over time"],
                    "cautions": ["Address underlying health issues", "Consult healthcare provider for concerns", "No single exercise is magic solution"]
                }
            ]
        },
        "pelvic_floor_relaxation": {
            "title": "Pelvic Floor Relaxation Techniques",
            "description": "Specialized relaxation techniques for the pelvic floor muscles to balance strengthening exercises and improve overall sexual function and comfort",
            "category": "eq",
            "difficulty": "beginner",
            "estimatedDuration": 15,
            "equipmentNeeded": ["Comfortable lying surface", "Pillow (optional)"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Positioning and preparation. Lie on back with knees bent, feet flat on floor. Place pillow under knees if comfortable. Close eyes and focus on pelvic area.",
                    "tips": ["Choose quiet, comfortable environment", "Support body as needed", "Focus attention on pelvic region"],
                    "cautions": ["Change position if uncomfortable", "Don't strain to maintain position", "Relaxation should feel good"]
                },
                {
                    "order": 2,
                    "instruction": "Identifying pelvic floor tension. Notice any holding or tension in PC muscles, anal sphincter, or deep pelvic muscles. Many people hold chronic tension here unconsciously.",
                    "tips": ["Scan for areas of holding or tightness", "Notice breathing patterns", "Tension often exists without awareness"],
                    "cautions": ["Don't judge or force awareness", "Tension is normal and common", "Simply notice without changing yet"]
                },
                {
                    "order": 3,
                    "instruction": "Breath-focused relaxation. On each exhale, consciously release and soften the pelvic floor. Think 'letting go' or 'melting' with each out-breath. Continue for 2 minutes.",
                    "tips": ["Use exhale as relaxation cue", "Visualize muscles softening", "Be patient with the process"],
                    "cautions": ["Don't force relaxation", "Some tension may remain - that's okay", "Focus on gradual softening"]
                },
                {
                    "order": 4,
                    "instruction": "Progressive pelvic release. Systematically relax: PC muscle, anal sphincter, deep pelvic muscles, inner thighs. Spend 30 seconds on each area.",
                    "tips": ["Work through each area methodically", "Use visualization of releasing", "Notice differences between areas"],
                    "cautions": ["Don't strain to relax", "Some areas may be easier than others", "Partial relaxation is success"]
                },
                {
                    "order": 5,
                    "instruction": "Gentle movement integration. While maintaining relaxation, slowly move knees side to side, gentle pelvic tilts. Movement should feel fluid and easy.",
                    "tips": ["Combine relaxation with gentle movement", "Movement should feel free and easy", "Notice how relaxation affects movement"],
                    "cautions": ["Keep movements small and gentle", "Don't lose focus on relaxation", "Stop if tension returns"]
                },
                {
                    "order": 6,
                    "instruction": "Visualization techniques. Imagine pelvic floor as a hammock gently swaying, or flower petals opening. Use imagery that promotes softness and release.",
                    "tips": ["Choose imagery that resonates with you", "Visualization enhances physical relaxation", "Be creative with helpful images"],
                    "cautions": ["Don't worry if visualization doesn't come easily", "Physical relaxation is primary goal", "Some people are more visual than others"]
                },
                {
                    "order": 7,
                    "instruction": "Integration with arousal response. Practice maintaining pelvic relaxation during gentle arousal. This improves blood flow and reduces performance anxiety.",
                    "tips": ["Relaxed pelvic floor enhances arousal", "Reduces anxiety-related tension", "Practice in low-pressure situations"],
                    "cautions": ["Start with minimal arousal", "Don't pressure for performance", "Focus on relaxation, not results"]
                },
                {
                    "order": 8,
                    "instruction": "Daily life integration and benefits. Practice brief pelvic relaxation throughout day: during stress, before intimacy, after strengthening exercises. Balances muscle tone.",
                    "tips": ["Brief practice sessions throughout day", "Excellent before sleep", "Balances strengthening exercises"],
                    "cautions": ["Both relaxation and strengthening are important", "Don't only focus on one approach", "Consistent practice produces best results"]
                }
            ]
        }
    }

def create_method_document(method_id: str, method_data: Dict) -> Dict:
    """Convert method data to Firestore document format matching existing structure"""
    from datetime import datetime

    doc = {
        "fields": {
            "id": {"stringValue": method_id},
            "title": {"stringValue": method_data["title"]},
            "description": {"stringValue": method_data["description"]},
            "category": {"stringValue": method_data["category"]},
            "difficulty": {"stringValue": method_data["difficulty"]},
            "estimatedDuration": {"integerValue": str(method_data["estimatedDuration"])},
            "equipmentNeeded": {
                "arrayValue": {
                    "values": [{"stringValue": item} for item in method_data["equipmentNeeded"]]
                }
            },
            "steps": {
                "arrayValue": {
                    "values": []
                }
            },
            "createdAt": {"timestampValue": datetime.now().isoformat() + "Z"},
            "updatedAt": {"timestampValue": datetime.now().isoformat() + "Z"}
        }
    }

    # Format steps with proper structure
    for step in method_data["steps"]:
        step_doc = {
            "mapValue": {
                "fields": {
                    "stepNumber": {"integerValue": str(step["order"])},
                    "title": {"stringValue": f"Step {step['order']}"},
                    "description": {"stringValue": step["instruction"]},
                    "tips": {
                        "arrayValue": {
                            "values": [{"stringValue": tip} for tip in step["tips"]]
                        }
                    },
                    "cautions": {
                        "arrayValue": {
                            "values": [{"stringValue": caution} for caution in step["cautions"]]
                        }
                    },
                    "warnings": {"arrayValue": {"values": []}}  # Empty array for warnings
                }
            }
        }
        doc["fields"]["steps"]["arrayValue"]["values"].append(step_doc)

    return doc

def upload_method(token: str, method_id: str, method_data: Dict):
    """Upload a single method to Firestore"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{method_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    document = create_method_document(method_id, method_data)

    # Use PATCH to update or create
    response = requests.patch(url, headers=headers, json=document)

    if response.status_code in [200, 201]:
        print(f"  ✅ Uploaded: {method_data['title']}")
        return True
    else:
        print(f"  ❌ Failed to upload {method_data['title']}: {response.status_code}")
        print(f"     Response: {response.text}")
        return False

def main():
    print("🚀 EQ Training Exercises Upload Script")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Create methods
    print("📝 Creating EQ training exercises...")
    methods = create_eq_exercises()
    print(f"✅ Created {len(methods)} EQ exercises")
    print()

    # Upload methods
    print("📤 Uploading to Firebase...")
    success_count = 0
    for method_id, method_data in methods.items():
        if upload_method(token, method_id, method_data):
            success_count += 1

    print()
    print("=" * 50)
    print(f"✅ Successfully uploaded {success_count}/{len(methods)} exercises")

    if success_count < len(methods):
        print("⚠️ Some uploads failed. Please check the errors above.")
        sys.exit(1)
    else:
        print("🎉 All EQ exercises uploaded successfully!")

if __name__ == "__main__":
    main()