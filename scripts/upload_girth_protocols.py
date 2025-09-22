#!/usr/bin/env python3
"""
Script to upload enhanced girth training protocols to Firebase
Following the exact document structure from Story 2.2
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

def create_girth_methods() -> Dict:
    """Create all new/enhanced girth training protocols"""
    return {
        "vacuum_pumping_progression": {
            "title": "Vacuum Pumping Progression",
            "description": "Progressive vacuum pumping protocol for safe girth gains with detailed pressure and time guidelines",
            "category": "girth",
            "difficulty": "intermediate",
            "estimatedDuration": 20,
            "equipmentNeeded": ["Vacuum pump with gauge", "Quality cylinder (proper size)", "Lubricant", "Warm water", "Timer"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Pre-pump preparation and warm-up. Take a hot shower or apply warm compress for 5-10 minutes to increase blood flow. Ensure complete flaccidity before starting.",
                    "tips": ["Water temperature should be comfortably warm, not scalding", "Focus warm water on the area for better blood flow", "Pat dry thoroughly before pumping"],
                    "cautions": ["Never pump with a full erection", "Avoid if you have any cuts or injuries", "Check cylinder for cracks or damage"]
                },
                {
                    "order": 2,
                    "instruction": "Apply lubricant and create seal. Use water-based lubricant around the base and on the cylinder rim. Insert flaccid and create an airtight seal at the base.",
                    "tips": ["Trim pubic hair for better seal", "Use generous lubricant to prevent friction", "Press cylinder firmly against pubic bone"],
                    "cautions": ["Avoid petroleum-based lubes that damage equipment", "Don't force if seal isn't working", "Stop if you feel pinching at the base"]
                },
                {
                    "order": 3,
                    "instruction": "Begin with low pressure (3 HG). Pump slowly to 3 HG (inches of mercury) and hold for 3-5 minutes for beginners. Watch the gauge constantly.",
                    "tips": ["Pump in slow, controlled movements", "It should feel like mild stretching, not pain", "Release pressure immediately if numbness occurs"],
                    "cautions": ["NEVER exceed 5 HG as a beginner", "Stop immediately if you see spots or discoloration", "Numbness means too much pressure"]
                },
                {
                    "order": 4,
                    "instruction": "Progressive pressure increases. Week 1-2: 3 HG for 5 min. Week 3-4: 3-4 HG for 7 min. Week 5-6: 4 HG for 10 min. Week 7-8: 4-5 HG for 10 min.",
                    "tips": ["Keep a log of pressure and time", "Only increase when completely comfortable", "Take rest days between sessions"],
                    "cautions": ["Don't rush progression", "More pressure doesn't mean better gains", "Listen to your body's signals"]
                },
                {
                    "order": 5,
                    "instruction": "Cylinder sizing guidelines. Cylinder should be 0.25-0.5 inches larger than your erect girth. Length should accommodate full erection plus 1-2 inches.",
                    "tips": ["Measure erect girth with tape measure", "Start with smaller cylinder if between sizes", "Upgrade cylinder as you gain"],
                    "cautions": ["Too large cylinder reduces effectiveness", "Too small causes discomfort and injury", "Wrong size can cause uneven expansion"]
                },
                {
                    "order": 6,
                    "instruction": "Release technique and breaks. Release pressure slowly over 10-15 seconds. Take 2-3 minute breaks between sets. Massage gently during breaks.",
                    "tips": ["Release valve gradually, not all at once", "Light jelqs during breaks help circulation", "Maximum 3 sets per session"],
                    "cautions": ["Rapid pressure release can cause injury", "Don't exceed 20 minutes total pump time", "Watch for fluid buildup (edema)"]
                },
                {
                    "order": 7,
                    "instruction": "Post-pump recovery protocol. After final set, massage gently for 5 minutes. Apply warm compress. Avoid intense activity for 2-3 hours.",
                    "tips": ["Coconut oil massage helps recovery", "Light stretching can help", "Stay hydrated after session"],
                    "cautions": ["Swelling should subside within hours", "Bruising indicates too much pressure", "Skip next session if not fully recovered"]
                },
                {
                    "order": 8,
                    "instruction": "Safety monitoring and progression tracking. Keep detailed log of sessions. Monitor for negative indicators. Progress only when consistently comfortable.",
                    "tips": ["Photo documentation helps track progress", "Note any discomfort or issues", "Consistency beats intensity"],
                    "cautions": ["Stop if erection quality decreases", "Persistent numbness requires break", "Consult physician if concerns arise"]
                }
            ]
        },
        "dry_jelq_technique": {
            "title": "Dry Jelq Technique",
            "description": "Modified jelqing technique performed without lubricant, requiring careful attention to grip and skin movement",
            "category": "girth",
            "difficulty": "intermediate",
            "estimatedDuration": 15,
            "equipmentNeeded": ["Baby powder (optional)", "Timer"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Warm-up thoroughly for 10 minutes. Use warm compress or shower. This is CRITICAL for dry jelqing to prevent injury.",
                    "tips": ["Warmup is even more important for dry jelq", "Ensure skin is completely dry after warmup", "Do light stretches during warmup"],
                    "cautions": ["Never skip warmup for dry jelq", "Skin must be pliable and warm", "Stop if skin feels tight or painful"]
                },
                {
                    "order": 2,
                    "instruction": "Achieve 40-60% erection level. Too soft won't be effective, too hard risks injury. Find the sweet spot for your body.",
                    "tips": ["40-60% means partially firm but bendable", "If you get too hard, pause and let it subside", "Consistency in erection level is key"],
                    "cautions": ["Never dry jelq above 70% erection", "Full erection dry jelqing causes injury", "Stop if erection won't subside"]
                },
                {
                    "order": 3,
                    "instruction": "Form proper OK grip at base. Use thumb and index finger to form ring. Grip should be firm but not painful. Retract skin toward base.",
                    "tips": ["Grip with the pads, not fingernails", "Switch hands every 10 reps to prevent fatigue", "Baby powder can help with grip"],
                    "cautions": ["Don't squeeze too hard", "Avoid gripping the same spot repeatedly", "Stop if you see bruising"]
                },
                {
                    "order": 4,
                    "instruction": "Execute the dry jelq stroke. Move hand from base to just below glans in 2-3 seconds. Move skin with the stroke, don't slide over it.",
                    "tips": ["The skin should move with your hand", "Focus on pushing blood forward", "Maintain consistent pressure throughout"],
                    "cautions": ["Never jelq the glans directly", "Stop if skin burns from friction", "Don't rush the movement"]
                },
                {
                    "order": 5,
                    "instruction": "Establish proper rhythm and count. Perform 50-100 strokes for beginners. Each stroke 2-3 seconds. Rest every 25 strokes.",
                    "tips": ["Count helps maintain consistency", "Start with 50 and build up slowly", "Quality over quantity always"],
                    "cautions": ["Don't exceed 200 strokes as beginner", "Stop if you lose proper form", "Pain means stop immediately"]
                },
                {
                    "order": 6,
                    "instruction": "Monitor skin condition constantly. Check for irritation, redness, or spots. Skin should feel warm but not painful or burning.",
                    "tips": ["Normal to have some redness", "Moisturize between sessions", "Take rest days for skin recovery"],
                    "cautions": ["Spots or dots mean too much pressure", "Raw skin requires several days rest", "Blisters are serious - stop immediately"]
                },
                {
                    "order": 7,
                    "instruction": "Cool-down and recovery. Gentle massage for 5 minutes. Apply moisturizer or healing balm. No intense activity for several hours.",
                    "tips": ["Aloe vera gel helps healing", "Light stretches during cooldown", "Warm bath can help recovery"],
                    "cautions": ["Don't apply ice directly", "Avoid sex/masturbation same day", "Rest if any discomfort persists"]
                },
                {
                    "order": 8,
                    "instruction": "Progression schedule for dry jelq. Week 1-2: 50 strokes. Week 3-4: 75 strokes. Week 5-6: 100 strokes. Add 25 per 2 weeks maximum.",
                    "tips": ["Log your sessions", "Progress only when comfortable", "Mix with wet jelq for variety"],
                    "cautions": ["Never double session volume suddenly", "Regression is fine if needed", "Consistency beats intensity"]
                }
            ]
        },
        "advanced_clamping_progression": {
            "title": "Advanced Clamping Progression",
            "description": "Progressive clamping protocol with strict safety guidelines and time limits for advanced practitioners",
            "category": "girth",
            "difficulty": "advanced",
            "estimatedDuration": 15,
            "equipmentNeeded": ["Cable clamp or cock clamp", "Protective wrap (cloth/mousepad)", "Timer", "Lubricant"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Prerequisites and safety check. Must have 6+ months PE experience. Check for any injuries or soreness. Have all equipment ready.",
                    "tips": ["Start clamping only after mastering jelqing", "Always have quick-release mechanism", "Never clamp if not fully healed"],
                    "cautions": ["NOT for beginners", "Dangerous if done incorrectly", "Can cause permanent damage if overdone"]
                },
                {
                    "order": 2,
                    "instruction": "Achieve 80-90% erection and apply wrap. Get nearly full erection. Wrap base with protective material to prevent pinching.",
                    "tips": ["Cloth or mousepad piece works well", "Wrap should be snug but not tight", "Leave gap for clamp placement"],
                    "cautions": ["Don't clamp at 100% erection", "Wrap prevents nerve damage", "Skip if can't maintain erection"]
                },
                {
                    "order": 3,
                    "instruction": "Apply clamp at base with moderate pressure. Position clamp over wrap at base. Click 2-3 notches only for beginners. Should feel full, not painful.",
                    "tips": ["Start with minimal tightness", "You should still have some circulation", "Adjust if too tight or loose"],
                    "cautions": ["Never fully tighten clamp", "Numbness means too tight", "Purple color is danger sign"]
                },
                {
                    "order": 4,
                    "instruction": "Strict timing protocol - 5 minutes maximum for beginners. Set timer for 5 minutes. Monitor constantly. Remove immediately at timer.",
                    "tips": ["Use phone timer with alarm", "5 minutes feels longer than expected", "Don't get distracted while clamped"],
                    "cautions": ["NEVER exceed 10 minutes even if advanced", "5 minutes maximum for first month", "Remove if any numbness before timer"]
                },
                {
                    "order": 5,
                    "instruction": "Monitor for danger signs during session. Check color - should be red, not purple/blue. Check sensation - stop if numb. Check temperature - shouldn't be cold.",
                    "tips": ["Keep checking every minute", "Light stimulation maintains erection", "Have release plan ready"],
                    "cautions": ["Purple/blue means remove immediately", "Cold means circulation cut off", "Numbness can cause nerve damage"]
                },
                {
                    "order": 6,
                    "instruction": "Proper removal technique. Release clamp slowly, one notch at a time. Massage immediately after removal. Wait 5+ minutes before next set.",
                    "tips": ["Gradual release prevents injury", "Massage restores circulation", "Maximum 2-3 sets per session"],
                    "cautions": ["Don't rip clamp off quickly", "Sudden release can damage vessels", "Don't re-clamp if any discomfort"]
                },
                {
                    "order": 7,
                    "instruction": "Recovery requirements - 48-72 hours minimum. No PE for 2-3 days after clamping. Monitor for negative indicators. Light massage daily.",
                    "tips": ["Clamping is intense - respect recovery", "Vitamin E oil helps healing", "Stay hydrated for recovery"],
                    "cautions": ["Don't clamp consecutive days", "Bruising means too intense", "Loss of erection quality means overtraining"]
                },
                {
                    "order": 8,
                    "instruction": "Advanced progression schedule. Month 1: 5 min x 1 set. Month 2: 5 min x 2 sets. Month 3: 7 min x 2 sets. Never exceed 10 min per set.",
                    "tips": ["Progress very slowly with clamping", "Quality over quantity", "Keep detailed log"],
                    "cautions": ["Aggressive progression causes injury", "10 minutes is absolute maximum", "Back off if negative indicators"]
                }
            ]
        },
        "combination_pump_jelq": {
            "title": "Combination Pump and Jelq Protocol",
            "description": "Synergistic protocol combining pumping with jelqing for enhanced girth gains",
            "category": "girth",
            "difficulty": "intermediate",
            "estimatedDuration": 25,
            "equipmentNeeded": ["Vacuum pump with gauge", "Cylinder", "Lubricant", "Timer"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Initial warm-up phase. 10 minute warm-up with heat. Start with warm shower or compress. Get tissues pliable and ready.",
                    "tips": ["Combine with light stretches", "Focus heat on entire area", "Warmup is crucial for combination work"],
                    "cautions": ["Never skip warmup for combo work", "Cold tissue doesn't respond well", "Check for any soreness first"]
                },
                {
                    "order": 2,
                    "instruction": "First pump set - 5 minutes at 3-4 HG. Enter pump flaccid. Build to 3-4 HG slowly. Hold for exactly 5 minutes.",
                    "tips": ["Watch gauge constantly", "Should feel expansion not pain", "Stay relaxed during pumping"],
                    "cautions": ["Don't exceed 5 HG", "Stop if numbness occurs", "Monitor for discoloration"]
                },
                {
                    "order": 3,
                    "instruction": "Transition to jelqing - 50 wet jelqs. Exit pump slowly. Apply lubricant immediately. Perform 50 controlled wet jelqs at 60-70% erection.",
                    "tips": ["Jelq immediately after pumping", "Maintain moderate erection level", "3 second strokes work best"],
                    "cautions": ["Tissue is sensitive post-pump", "Don't jelq too hard", "Stop if pain occurs"]
                },
                {
                    "order": 4,
                    "instruction": "Second pump set - 5 minutes at same pressure. Re-enter pump after jelqing. Same pressure as first set. Another 5 minute hold.",
                    "tips": ["May need to reapply lube to cylinder", "Expansion should be greater than set 1", "Stay consistent with pressure"],
                    "cautions": ["Don't increase pressure in set 2", "Watch for fluid buildup", "Exit if discomfort increases"]
                },
                {
                    "order": 5,
                    "instruction": "Second jelq set - 75 wet jelqs. Exit pump gradually. More lubricant as needed. 75 jelqs at slightly lower erection (50-60%).",
                    "tips": ["Second set jelqs are lighter", "Focus on form over intensity", "Can break into mini-sets if needed"],
                    "cautions": ["Tissue is very expanded now", "Be extra gentle", "Stop if you see spots"]
                },
                {
                    "order": 6,
                    "instruction": "Optional third pump set (advanced only). Only if comfortable. 3-5 minutes maximum. Same or slightly less pressure.",
                    "tips": ["Third set is optional", "Many stop after 2 sets", "Listen to your body"],
                    "cautions": ["Beginners skip third set", "Never force third set", "Exit if any negative signs"]
                },
                {
                    "order": 7,
                    "instruction": "Cool-down and recovery massage. 5-10 minute gentle massage. Focus on base to glans strokes. Apply healing balm or oil.",
                    "tips": ["Massage helps prevent fluid buildup", "Be very gentle post-session", "Elevate if edema present"],
                    "cautions": ["Don't massage too vigorously", "Ice only if swelling persists", "Monitor overnight recovery"]
                },
                {
                    "order": 8,
                    "instruction": "Recovery protocol - 48 hour minimum rest. No PE for at least 2 days. Monitor erection quality. Return only when fully recovered.",
                    "tips": ["Combination work needs more recovery", "Light stretching okay on off days", "Hydration helps recovery"],
                    "cautions": ["Don't do combo work consecutive days", "Reduced EQ means overtraining", "Take week off if not recovering"]
                }
            ]
        },
        "girth_recovery_protocol": {
            "title": "Girth-Specific Recovery Protocol",
            "description": "Comprehensive recovery protocol specifically designed for intense girth training sessions",
            "category": "girth",
            "difficulty": "beginner",
            "estimatedDuration": 20,
            "equipmentNeeded": ["Warm compress", "Massage oil or balm", "Ice pack (emergency only)"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Immediate post-session assessment. Check for any unusual discoloration, spots, or excessive swelling. Document any concerns.",
                    "tips": ["Some redness is normal", "Take photos for comparison", "Note any areas of concern"],
                    "cautions": ["Purple/blue needs immediate attention", "Spots indicate burst capillaries", "Hard lumps require rest"]
                },
                {
                    "order": 2,
                    "instruction": "Gentle drainage massage. Using oil, massage from glans toward base. Light pressure only. 5 minutes total. Helps prevent fluid buildup.",
                    "tips": ["Use coconut or vitamin E oil", "Always stroke toward body", "Can do in shower with warm water"],
                    "cautions": ["Don't massage if very sore", "Never massage bruised areas", "Stop if pain increases"]
                },
                {
                    "order": 3,
                    "instruction": "Heat therapy application. Apply warm (not hot) compress for 5-10 minutes. Helps circulation and healing. Promotes nutrient delivery.",
                    "tips": ["Rewarm compress as needed", "Rice sock works well", "Can use warm shower instead"],
                    "cautions": ["Not too hot - can damage tissue", "Skip if excessive swelling", "Don't fall asleep with heat on"]
                },
                {
                    "order": 4,
                    "instruction": "Elevation technique for edema. If fluid buildup (edema) present, elevate for 10-15 minutes. Lie down, prop up with pillows.",
                    "tips": ["Elevation helps drain fluid", "Can combine with gentle massage", "Do several times if needed"],
                    "cautions": ["See doctor if edema persists 24hrs", "Don't over-elevate", "Ice only if severe swelling"]
                },
                {
                    "order": 5,
                    "instruction": "Supplement protocol for recovery. Consider: L-arginine (blood flow), Vitamin E (healing), Vitamin C (collagen), plenty of water.",
                    "tips": ["Consult doctor before supplements", "Stay well hydrated", "Good nutrition aids recovery"],
                    "cautions": ["Don't exceed recommended doses", "Some supplements interact with meds", "Natural recovery is often enough"]
                },
                {
                    "order": 6,
                    "instruction": "Sleep and rest requirements. Get 7-9 hours quality sleep. No PE for 48-72 hours minimum. Avoid tight clothing.",
                    "tips": ["Sleep is when healing happens", "Loose underwear is better", "No sex/masturbation for 24 hours"],
                    "cautions": ["Don't shortchange sleep", "Rushing back causes setbacks", "Listen to your body"]
                },
                {
                    "order": 7,
                    "instruction": "Next session readiness check. Before next girth session: No soreness, normal appearance, good erection quality, at least 48 hours rest.",
                    "tips": ["When in doubt, rest more", "Track recovery time patterns", "Adjust intensity if slow recovery"],
                    "cautions": ["Don't train if not recovered", "Overtraining reduces gains", "Chronic soreness means reduce intensity"]
                },
                {
                    "order": 8,
                    "instruction": "Emergency protocols. Severe bruising: Rest 1 week minimum. Loss of sensation: Stop all PE, see doctor. Severe pain: Seek medical attention.",
                    "tips": ["Have doctor you trust", "Don't panic but act quickly", "Document issues with photos"],
                    "cautions": ["Some injuries need medical care", "Nerve damage can be permanent", "Don't ignore serious symptoms"]
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
    print("🚀 Girth Training Protocols Upload Script")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Create methods
    print("📝 Creating girth training protocols...")
    methods = create_girth_methods()
    print(f"✅ Created {len(methods)} girth protocols")
    print()

    # Upload methods
    print("📤 Uploading to Firebase...")
    success_count = 0
    for method_id, method_data in methods.items():
        if upload_method(token, method_id, method_data):
            success_count += 1

    print()
    print("=" * 50)
    print(f"✅ Successfully uploaded {success_count}/{len(methods)} methods")

    if success_count < len(methods):
        print("⚠️ Some uploads failed. Please check the errors above.")
        sys.exit(1)
    else:
        print("🎉 All girth protocols uploaded successfully!")

if __name__ == "__main__":
    main()