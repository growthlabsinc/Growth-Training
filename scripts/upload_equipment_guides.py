#!/usr/bin/env python3
"""
Script to upload equipment guides to Firestore
Creates educational content about PE equipment selection and usage
"""

import json
import sys
import requests
from typing import List, Dict

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

def upload_guide(token: str, guide_id: str, guide_data: Dict) -> bool:
    """Upload a single equipment guide to Firestore"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{guide_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    firestore_doc = create_firestore_document(guide_data)

    response = requests.patch(url, headers=headers, json=firestore_doc)
    if response.status_code in [200, 201]:
        print(f"✅ Successfully uploaded: {guide_data['title']}")
        return True
    else:
        print(f"❌ Failed to upload {guide_id}: {response.status_code}")
        print(response.text)
        return False

def get_equipment_guides() -> List[Dict]:
    """Define all equipment guides"""

    guides = []

    # ==========================================
    # VACUUM PUMP GUIDE
    # ==========================================
    guides.append({
        "id": "vacuum_pump_guide",
        "title": "Vacuum Pump Equipment Guide",
        "description": "Comprehensive guide to understanding vacuum pumps for PE training, including types, sizing, safety features, and budget considerations. MEDICAL DISCLAIMER: Consult a healthcare provider before using any PE equipment. This guide is for educational purposes only.",
        "category": "equipment",
        "difficulty": "beginner",
        "estimatedDuration": 10,  # reading time in minutes
        "equipmentNeeded": ["Vacuum pump", "Cylinder", "Pressure gauge", "Lubricant"],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Understanding Pump Types",
                "description": "Learn the differences between air pumps and water pumps. Air pumps use manual or electric mechanisms to create vacuum pressure within a cylinder. Water pumps (like Bathmate-style) use water displacement for more uniform pressure distribution. Air pumps offer more precise pressure control but may create uneven pressure. Water pumps provide more comfortable, even pressure but require shower/bath use.",
                "tips": [
                    "Air pumps are more portable and versatile",
                    "Water pumps generally feel more comfortable",
                    "Consider your living situation and privacy needs",
                    "Air pumps allow for easier pressure monitoring"
                ],
                "cautions": [
                    "Never exceed recommended pressure levels",
                    "Start with the lowest effective pressure",
                    "Both types require proper sizing for safety"
                ],
                "warnings": [
                    "Excessive vacuum pressure can cause injury",
                    "Never use damaged or cracked cylinders"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: Cylinder Sizing Guidelines",
                "description": "Proper cylinder sizing is crucial for both safety and effectiveness. Measure your erect length and girth before selecting. Choose a cylinder that is 1-2 inches longer than your erect length and 0.25-0.5 inches wider in diameter than your erect girth. Too large reduces effectiveness, too small causes discomfort and potential injury.",
                "tips": [
                    "Measure when fully erect for accurate sizing",
                    "Consider purchasing multiple sizes as you progress",
                    "Wide-mouth cylinders accommodate larger girth",
                    "Length should allow for expansion without hitting the end"
                ],
                "cautions": [
                    "Using wrong size reduces effectiveness",
                    "Too tight can cause bruising at base",
                    "Too loose won't create proper seal"
                ],
                "warnings": [
                    "Never force yourself into a too-small cylinder",
                    "Improper sizing increases injury risk significantly"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Essential Safety Features",
                "description": "Quality pumps must have certain safety features. Look for: pressure release valve for quick deflation, accurate pressure gauge (measured in HG), comfortable cushioned seal, clear cylinder for monitoring, and smooth hand pump action. These features are non-negotiable for safe practice.",
                "tips": [
                    "Digital gauges offer more precise readings",
                    "Quick-release valves are essential for emergencies",
                    "Silicone seals last longer than rubber",
                    "Clear cylinders help monitor for issues"
                ],
                "cautions": [
                    "Avoid pumps without pressure gauges",
                    "Check valve functionality before each use",
                    "Replace worn seals immediately"
                ],
                "warnings": [
                    "Never use pumps without pressure release valves",
                    "Faulty gauges can lead to dangerous over-pumping"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Quality Indicators",
                "description": "Identify quality equipment through these indicators: thick-walled cylinders (minimum 3mm), medical-grade materials, smooth edges with no sharp points, sturdy connection between pump and cylinder, reputable seller with return policy, and clear instructions included. Quality equipment costs more but is essential for safety.",
                "tips": [
                    "Medical-grade polycarbonate cylinders are ideal",
                    "Check for FDA-compliant materials when possible",
                    "Read reviews focusing on durability and safety",
                    "Quality pumps typically cost $50-200"
                ],
                "cautions": [
                    "Extremely cheap pumps often lack safety features",
                    "Thin cylinders can crack under pressure",
                    "Poor quality seals leak and reduce effectiveness"
                ],
                "warnings": [
                    "Avoid cylinders with visible cracks or defects",
                    "Never buy used equipment for hygiene and safety"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Budget Tier Options",
                "description": "Equipment available across price ranges. Budget tier ($30-60): Basic manual air pumps with gauge, adequate for beginners. Mid-tier ($60-120): Better materials, more sizes, electric pump options. Premium tier ($120-300): Medical-grade materials, precise digital gauges, complete systems. Choose based on commitment level and budget.",
                "tips": [
                    "Start with budget tier to test commitment",
                    "Mid-tier offers best value for regular users",
                    "Premium tier for serious long-term practitioners",
                    "Consider long-term cost per use"
                ],
                "cautions": [
                    "Don't sacrifice essential safety features for price",
                    "Very cheap equipment often breaks quickly",
                    "Factor in replacement parts availability"
                ],
                "warnings": [
                    "Never compromise safety to save money",
                    "Counterfeit products common in lowest price ranges"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Usage Protocols",
                "description": "Safe pumping requires strict protocols. Start with 5-minute sessions at low pressure (3-5 HG). Gradually increase to 10-15 minutes over weeks. Never exceed 7-10 HG pressure for beginners. Always warm up beforehand, use adequate lubrication for seal, and monitor for any discoloration or numbness. Rest days are mandatory.",
                "tips": [
                    "Keep sessions under 20 minutes maximum",
                    "2-3 sessions per week is sufficient",
                    "Track pressure and time for each session",
                    "Progress slowly over months, not days"
                ],
                "cautions": [
                    "Stop immediately if numbness occurs",
                    "Dark discoloration indicates excessive pressure",
                    "Never pump through pain or discomfort"
                ],
                "warnings": [
                    "Exceeding safe pressure causes permanent damage",
                    "Daily pumping without rest causes injury"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Maintenance and Hygiene",
                "description": "Proper maintenance ensures safety and longevity. Clean cylinder with antibacterial soap after each use. Dry completely before storage. Check seals and valves weekly for wear. Replace seals every 3-6 months with regular use. Store in cool, dry place away from direct sunlight. Never share equipment.",
                "tips": [
                    "Use isopropyl alcohol for deep cleaning monthly",
                    "Apply silicone lubricant to pump mechanism",
                    "Keep spare seals on hand",
                    "Document equipment age and usage"
                ],
                "cautions": [
                    "Moisture breeds bacteria - always dry thoroughly",
                    "Degraded seals reduce effectiveness and safety",
                    "Sun exposure degrades plastic cylinders"
                ],
                "warnings": [
                    "Never share equipment due to infection risk",
                    "Replace cracked cylinders immediately"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: When to Avoid or Stop",
                "description": "Certain conditions contraindicate pump use. Avoid if you have: blood disorders, active STIs, Peyronie's disease, or are on blood thinners. Stop immediately if experiencing: persistent pain, dark purple discoloration, blisters, bleeding, or loss of sensation. Consult a urologist if any concerns arise.",
                "tips": [
                    "Keep a log of any unusual symptoms",
                    "Take photos to track any changes",
                    "When in doubt, take extra rest days",
                    "Regular medical check-ups recommended"
                ],
                "cautions": [
                    "Pre-existing conditions increase risk",
                    "Some medications affect tissue response",
                    "Age and health status affect recovery"
                ],
                "warnings": [
                    "Ignoring warning signs causes permanent injury",
                    "Seek immediate medical help for severe symptoms"
                ]
            }
        ]
    })

    # ==========================================
    # HANGER COMPARISON GUIDE
    # ==========================================
    guides.append({
        "id": "hanger_comparison_guide",
        "title": "Penis Hanger Equipment Guide",
        "description": "Complete guide to understanding hanging devices for PE training, covering types, safety protocols, weight progression, and selection criteria. MEDICAL DISCLAIMER: Hanging carries significant risks. Medical consultation essential before beginning any hanging routine.",
        "category": "equipment",
        "difficulty": "intermediate",
        "estimatedDuration": 12,  # reading time in minutes
        "equipmentNeeded": ["Hanger device", "Weight plates", "Wrap material", "Timer"],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Hanger Types Overview",
                "description": "Three main hanger types exist. Vacuum hangers use suction to grip the glans, distributing force evenly but limiting weight. Compression hangers grip the shaft behind the glans using clamps or straps, allowing heavier weights but requiring careful wrapping. Noose-style hangers loop around the shaft but are generally considered unsafe due to circulation issues.",
                "tips": [
                    "Vacuum hangers best for beginners (safer)",
                    "Compression hangers for intermediate/advanced",
                    "Hybrid designs combine both approaches",
                    "Consider your experience level when choosing"
                ],
                "cautions": [
                    "Each type has specific risks to understand",
                    "Improper use of any type causes injury",
                    "Start with lightest weights regardless of type"
                ],
                "warnings": [
                    "Never use noose or loop-style hangers",
                    "All hanging can cause permanent injury if done incorrectly"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: Safety Considerations",
                "description": "Hanging safety requires extreme vigilance. Never exceed 20 minutes per session without break. Start with 2-5 lbs maximum for first month. Check circulation every 5 minutes - healthy pink color should remain. Use timer without exception. Proper wrapping prevents skin damage. Stop at any pain, numbness, or color change.",
                "tips": [
                    "Use cloth or silicone wrap for protection",
                    "Multiple short sets safer than single long set",
                    "Keep weight within arm's reach for quick removal",
                    "Document weight and time for each session"
                ],
                "cautions": [
                    "Nerve damage occurs without warning",
                    "Excessive weight causes ligament damage",
                    "Poor circulation leads to tissue death"
                ],
                "warnings": [
                    "Numbness requires immediate cessation",
                    "Purple/blue color indicates dangerous circulation loss"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Weight Progression Protocol",
                "description": "Conservative progression prevents injury. Month 1: 2-5 lbs, 10-minute sets. Month 2-3: 5-7.5 lbs, 15-minute sets. Month 4-6: 7.5-10 lbs if comfortable. Never increase more than 2.5 lbs at once. Reduce weight if form deteriorates. Maximum 20 lbs even for advanced users. Time under tension matters more than weight.",
                "tips": [
                    "Increase time before increasing weight",
                    "Consistency beats heavy weight",
                    "Deload weeks every month recommended",
                    "Track fatigue levels carefully"
                ],
                "cautions": [
                    "Rapid progression causes injury",
                    "Ego lifting has no place in hanging",
                    "Fatigue accumulates over weeks"
                ],
                "warnings": [
                    "Exceeding 20 lbs risks permanent damage",
                    "Never compete with others' weight claims"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Attachment Methods",
                "description": "Proper attachment prevents slippage and injury. For vacuum: ensure complete seal, use appropriate sleeve size, limit to 10 lbs maximum. For compression: wrap with cloth first, adjust tightness carefully, ensure even pressure distribution. Check attachment security before adding weight. Re-adjust if any slippage occurs.",
                "tips": [
                    "Practice attachment without weight first",
                    "Baby powder helps with vacuum seal",
                    "Theraband works well for wrapping",
                    "Mark optimal tightness settings"
                ],
                "cautions": [
                    "Too tight cuts circulation",
                    "Too loose causes dangerous slippage",
                    "Skin pinching leads to blisters"
                ],
                "warnings": [
                    "Slippage under weight causes severe injury",
                    "Never hang without proper secure attachment"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Budget Options By Tier",
                "description": "Hanging equipment spans wide price range. Budget tier ($40-80): Basic vacuum hangers, simple compression designs, requires careful monitoring. Mid-tier ($80-150): Better materials, comfort features, include accessories. Premium tier ($150-300): Advanced engineering, maximum comfort, complete systems. All tiers can be safe with proper use.",
                "tips": [
                    "Budget tier adequate for testing interest",
                    "Mid-tier best for regular practitioners",
                    "Premium offers convenience, not necessarily safety",
                    "DIY options exist but require extreme caution"
                ],
                "cautions": [
                    "Cheapest options often lack padding",
                    "Verify weight capacity before purchase",
                    "Check return policy given personal nature"
                ],
                "warnings": [
                    "Extremely cheap hangers often unsafe",
                    "Never attempt DIY without extensive research"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Comfort Modifications",
                "description": "Comfort modifications reduce injury risk. Use soft wrapping materials like flannel or silicone sleeves. Anti-slip tape prevents movement. Padding at pressure points essential. Adjust angle for natural hang. Take breaks every 10-15 minutes regardless of comfort. Never hang through discomfort.",
                "tips": [
                    "Experiment with different wrap materials",
                    "Slightly warm wrap increases comfort",
                    "Standing allows angle adjustment",
                    "Foam padding helps pressure points"
                ],
                "cautions": [
                    "Comfort doesn't mean safe to exceed limits",
                    "Numbness can occur despite comfort",
                    "Over-padding reduces device effectiveness"
                ],
                "warnings": [
                    "Pain always means stop immediately",
                    "Comfort modifications don't allow longer sessions"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Routine Integration",
                "description": "Integrate hanging carefully into PE routine. Hang maximum 4 days per week. Never hang consecutive days as beginner. Combine with stretching, not girth work. Morning sessions when tissues are relaxed. Keep detailed logs of weight, time, and sensations. Plan deload weeks monthly.",
                "tips": [
                    "Hang before other PE exercises",
                    "Consistent schedule improves results",
                    "Heat before hanging increases pliability",
                    "Light stretching after helps recovery"
                ],
                "cautions": [
                    "Overtraining prevents gains and causes injury",
                    "Combining with intense girth work dangerous",
                    "Fatigue accumulates without proper rest"
                ],
                "warnings": [
                    "Daily hanging causes permanent damage",
                    "Never hang when tissues feel fatigued"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Red Flags and Discontinuation",
                "description": "Recognize when to stop immediately. Red flags: persistent numbness, sharp pains, skin tears or blisters, extreme discoloration, cold sensation, loss of morning erections, or decreased sensation. Take minimum 1-week break for minor issues, seek medical attention for severe symptoms. Prevention better than treatment.",
                "tips": [
                    "Document any unusual symptoms",
                    "Take progress photos for comparison",
                    "Trust your instincts about safety",
                    "Regular breaks prevent most issues"
                ],
                "cautions": [
                    "Minor symptoms can indicate major problems",
                    "Pushing through warning signs causes permanent damage",
                    "Recovery takes longer than you expect"
                ],
                "warnings": [
                    "Nerve damage may be permanent",
                    "Seek urologist consultation for persistent issues"
                ]
            }
        ]
    })

    # ==========================================
    # EXTENDER GUIDE
    # ==========================================
    guides.append({
        "id": "extender_guide",
        "title": "Penis Extender Equipment Guide",
        "description": "Detailed guide to penis extenders including types, usage protocols, comfort modifications, and realistic expectations. MEDICAL DISCLAIMER: Extended use requires medical supervision. Not suitable for all anatomies or conditions.",
        "category": "equipment",
        "difficulty": "beginner",
        "estimatedDuration": 10,  # reading time in minutes
        "equipmentNeeded": ["Extender device", "Comfort accessories", "Measuring tape"],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Extender Mechanism Types",
                "description": "Two primary mechanisms exist. Spring-loaded extenders use metal springs to create tension, offering precise force adjustment but can be bulky. Vacuum extenders use suction for attachment with straps providing tension, more comfortable but limited force. Belt systems wrap around waist for all-day wear. Each has distinct advantages for different users.",
                "tips": [
                    "Spring extenders better for home use",
                    "Vacuum extenders more discreet under clothing",
                    "Belt systems for maximum wearing time",
                    "Consider lifestyle when choosing type"
                ],
                "cautions": [
                    "Each type requires different skills to master",
                    "Improper use of any type causes injury",
                    "Start with minimum tension regardless"
                ],
                "warnings": [
                    "Never exceed manufacturer's tension limits",
                    "All types can cause injury if misused"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: Proper Fitting and Sizing",
                "description": "Correct fit essential for safety and results. Measure flaccid length and girth accurately. Base ring should fit snugly without restricting blood flow. Rod length should accommodate erect length plus 2-3 cm. Glans attachment must be secure but not tight. Most extenders adjust for 4-10 inch lengths.",
                "tips": [
                    "Measure multiple times for accuracy",
                    "Order extra comfort accessories immediately",
                    "Adjustable models accommodate gains",
                    "Keep adjustment tools accessible"
                ],
                "cautions": [
                    "Too tight causes circulation problems",
                    "Too loose results in slippage",
                    "One size doesn't fit all anatomies"
                ],
                "warnings": [
                    "Forcing fit causes immediate injury",
                    "Never modify device structure for fit"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Usage Time Protocols",
                "description": "Build tolerance gradually over months. Week 1-2: 1-2 hours daily. Week 3-4: 2-4 hours daily. Month 2: 4-6 hours if comfortable. Maximum 8-10 hours for advanced users. Take hourly breaks for circulation. Never wear while sleeping. Consistency matters more than duration.",
                "tips": [
                    "Use timer for accurate tracking",
                    "Break sessions into smaller periods",
                    "Morning use when tissues are relaxed",
                    "Track total weekly hours, not daily"
                ],
                "cautions": [
                    "Rushing progression causes setbacks",
                    "Numbness requires immediate removal",
                    "Quality hours beat quantity"
                ],
                "warnings": [
                    "Never wear continuously over 2 hours without break",
                    "Overnight use causes permanent damage"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Comfort Modifications",
                "description": "Comfort enables longer wear times. Use silicone cushions at all contact points. Foam strips prevent pinching. Fabric sleeves reduce friction. Adjust tension throughout day as tissues adapt. Rotate attachment points slightly between sessions. Powder prevents moisture buildup. Comfort doesn't mean you can exceed safe limits.",
                "tips": [
                    "Buy extra comfort straps and cushions",
                    "Medical tape protects sensitive areas",
                    "Loose clothing reduces visibility",
                    "Standing desk allows easier adjustment"
                ],
                "cautions": [
                    "Over-padding reduces device effectiveness",
                    "Moisture leads to skin problems",
                    "Comfort can mask dangerous pressure"
                ],
                "warnings": [
                    "Pain means stop regardless of padding",
                    "Numbness occurs even with comfort mods"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Tension Settings Guide",
                "description": "Proper tension crucial for safety and gains. Start at 600-900g (1.3-2 lbs) for first month. Increase by 200-300g monthly if comfortable. Most gains occur at 900-1500g (2-3.3 lbs). Maximum 2500g (5.5 lbs) for advanced users. Use device's indicator for accurate measurement. Less tension for longer periods beats high tension briefly.",
                "tips": [
                    "Mark your comfort settings on device",
                    "Morning requires less tension than evening",
                    "Reduce tension if taking break days",
                    "Log tension settings with hours worn"
                ],
                "cautions": [
                    "High tension doesn't mean faster gains",
                    "Tissue needs time to adapt",
                    "Excessive force causes toughening, not growth"
                ],
                "warnings": [
                    "Over 2500g risks permanent injury",
                    "Sharp pain means tension too high"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Budget Tier Analysis",
                "description": "Extenders vary widely in price and quality. Budget tier ($50-100): Basic spring models, minimal accessories, requires modification for comfort. Mid-tier ($100-250): Better materials, comfort features included, proven designs. Premium tier ($250-500): Medical-grade materials, complete comfort systems, best warranties. All can work with proper use.",
                "tips": [
                    "Budget models need aftermarket accessories",
                    "Mid-tier offers best value for most",
                    "Premium justified for daily long-term use",
                    "Check warranty and return policies"
                ],
                "cautions": [
                    "Extremely cheap models break easily",
                    "Comfort accessories add to budget tier cost",
                    "Some budget models have sharp edges"
                ],
                "warnings": [
                    "Counterfeit devices common online",
                    "Poor quality increases injury risk"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Maintenance and Hygiene",
                "description": "Regular maintenance ensures safety and longevity. Clean all parts daily with antibacterial soap. Check springs/straps for wear weekly. Replace comfort accessories every 2-3 months. Lubricate adjustment mechanisms monthly. Store in provided case to prevent damage. Never share devices. Document part replacements.",
                "tips": [
                    "Keep spare parts readily available",
                    "Isopropyl alcohol for deep cleaning",
                    "Silicone spray for smooth adjustments",
                    "Date all accessories for replacement schedule"
                ],
                "cautions": [
                    "Worn parts reduce safety and effectiveness",
                    "Bacteria buildup causes infections",
                    "Damaged parts fail without warning"
                ],
                "warnings": [
                    "Never use with damaged components",
                    "Replace device if frame shows wear"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Realistic Expectations",
                "description": "Set evidence-based expectations. Typical gains: 0.5-1.5 inches over 6-12 months with consistent use. Requires 4-6 hours daily minimum. Results vary by genetics, age, and consistency. Initial gains often from improved erection quality. Permanent gains require 12+ months. Maintenance needed after reaching goals. Not everyone responds equally.",
                "tips": [
                    "Take monthly measurements only",
                    "Photo documentation helps track progress",
                    "Focus on process, not outcome",
                    "Combine with overall health improvements"
                ],
                "cautions": [
                    "Marketing claims often exaggerated",
                    "Faster gains usually temporary",
                    "Unrealistic expectations lead to overuse"
                ],
                "warnings": [
                    "Forcing faster results causes injury",
                    "Some men are non-responders despite perfect use"
                ]
            }
        ]
    })

    # ==========================================
    # GENERAL EQUIPMENT SAFETY GUIDE
    # ==========================================
    guides.append({
        "id": "equipment_safety_guide",
        "title": "General PE Equipment Safety Guide",
        "description": "Universal safety protocols for all PE equipment use. Essential reading before using any devices. Covers safety checklists, red flags, maintenance, and injury prevention. MEDICAL DISCLAIMER: This guide supplements but doesn't replace medical consultation.",
        "category": "equipment",
        "difficulty": "beginner",
        "estimatedDuration": 8,  # reading time in minutes
        "equipmentNeeded": [],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Pre-Purchase Safety Check",
                "description": "Before buying any PE equipment, verify: seller reputation and reviews, medical-grade material claims, clear return policy, complete instructions included, safety certifications if claimed, and realistic marketing (avoid 'gain 3 inches in weeks' claims). Research thoroughly - your health depends on quality equipment.",
                "tips": [
                    "Read negative reviews carefully",
                    "Verify seller contact information",
                    "Ask questions before purchasing",
                    "Check forums for user experiences"
                ],
                "cautions": [
                    "Unrealistic claims indicate scams",
                    "No instructions means unsafe product",
                    "Extremely low prices suggest counterfeits"
                ],
                "warnings": [
                    "Never buy used PE equipment",
                    "Avoid sellers with no return policy"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: Universal Safety Checklist",
                "description": "Before each equipment use: inspect for damage (cracks, wear, sharp edges), verify all parts present and secure, clean and dry equipment, check safety mechanisms function, have removal method ready, set timer for session limits, ensure privacy for focus, warm up tissues first. This checklist prevents most accidents.",
                "tips": [
                    "Keep checklist posted near equipment",
                    "Never skip steps when rushed",
                    "Replace worn parts immediately",
                    "Have backup timer method"
                ],
                "cautions": [
                    "Rushing leads to forgotten safety steps",
                    "Small damage becomes catastrophic under stress",
                    "Distraction during use causes injury"
                ],
                "warnings": [
                    "Never use damaged equipment 'just once more'",
                    "Skipping warm-up dramatically increases injury risk"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Red Flags for Equipment",
                "description": "Stop using equipment showing: visible cracks or stress marks, worn or degraded materials, malfunctioning safety features, sharp edges or points, loose connections, discoloration from age/use, missing parts, or unusual noises during use. When in doubt, replace equipment. Your safety worth more than equipment cost.",
                "tips": [
                    "Inspect under bright light regularly",
                    "Document equipment age and usage",
                    "Keep photos of new condition for comparison",
                    "Mark replacement dates on calendar"
                ],
                "cautions": [
                    "Gradual degradation easy to miss",
                    "Materials weaken before visible damage",
                    "Safety features fail without warning"
                ],
                "warnings": [
                    "Using degraded equipment guarantees injury",
                    "Never attempt repairs on safety components"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Body Warning Signs",
                "description": "Stop immediately if experiencing: numbness or tingling, color change (purple, blue, white), sharp or burning pain, cold sensation, blisters or skin tears, excessive swelling, spots or dots appearing, or reduced sensation lasting over 30 minutes post-session. These indicate dangerous stress levels requiring immediate cessation.",
                "tips": [
                    "Check color every 5 minutes",
                    "Test sensation regularly during use",
                    "Keep log of any unusual symptoms",
                    "Have phone accessible for emergencies"
                ],
                "cautions": [
                    "Numbness can become permanent",
                    "Color changes indicate circulation loss",
                    "Pain always means stop"
                ],
                "warnings": [
                    "Ignoring warning signs causes permanent damage",
                    "Seek immediate medical help for severe symptoms"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Hygiene Protocols",
                "description": "Proper hygiene prevents infections and equipment degradation. Before use: wash hands and equipment, dry completely, inspect for cleanliness. After use: clean with antibacterial soap, rinse thoroughly, dry completely, store properly. Weekly: deep clean with isopropyl alcohol, check for buildup, replace consumables. Never share equipment.",
                "tips": [
                    "Dedicate cleaning supplies to PE equipment",
                    "Air dry in clean area",
                    "Date hygiene supplies for freshness",
                    "Clean immediately after use"
                ],
                "cautions": [
                    "Moisture breeds dangerous bacteria",
                    "Soap residue causes skin irritation",
                    "Improper storage degrades materials"
                ],
                "warnings": [
                    "Infections from poor hygiene can be serious",
                    "Never share personal equipment"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Safe Storage Practices",
                "description": "Proper storage extends equipment life and maintains safety. Store in cool, dry place away from sunlight. Use original cases when provided. Keep away from extreme temperatures. Separate different materials to prevent reaction. Lock away from children or visitors. Label with last cleaning date. Never store wet or dirty.",
                "tips": [
                    "Silica gel packets prevent moisture",
                    "Padded cases prevent impact damage",
                    "Label storage with equipment age",
                    "Climate-controlled storage ideal"
                ],
                "cautions": [
                    "Heat degrades plastics and rubber",
                    "Sunlight weakens materials",
                    "Improper storage voids warranties"
                ],
                "warnings": [
                    "Children accessing PE equipment is dangerous",
                    "Degraded storage conditions create hazards"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Emergency Procedures",
                "description": "Know emergency procedures before starting. For circulation loss: remove equipment immediately, massage gently, apply warmth. For stuck equipment: stay calm, use lubrication, seek help if needed. For injury: stop all PE activity, document symptoms, seek medical attention. Keep emergency supplies nearby: scissors for straps, lubricant, phone.",
                "tips": [
                    "Practice emergency removal when not under stress",
                    "Keep emergency kit in PE area",
                    "Have trusted person aware of your PE practice",
                    "Know nearest emergency room location"
                ],
                "cautions": [
                    "Panic worsens most situations",
                    "Forcing stuck equipment causes tears",
                    "Delayed medical care worsens outcomes"
                ],
                "warnings": [
                    "Some injuries require immediate medical attention",
                    "Never be embarrassed to seek emergency help"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Medical Consultation Guide",
                "description": "Medical consultation recommended before starting and if issues arise. Be honest with healthcare providers - they've seen it before. Discuss: current medications, cardiovascular health, diabetes status, blood disorders, previous injuries. Warning signs requiring immediate consultation: persistent numbness, erectile dysfunction, unusual discharge, severe pain, visible injury.",
                "tips": [
                    "Find PE-friendly urologist if possible",
                    "Document symptoms with photos if appropriate",
                    "Bring equipment information to appointments",
                    "Annual check-ups recommended for active users"
                ],
                "cautions": [
                    "Some conditions contraindicate all PE",
                    "Medications affect tissue response",
                    "Embarrassment delays necessary treatment"
                ],
                "warnings": [
                    "Hiding PE use from doctors risks health",
                    "Some symptoms indicate serious conditions"
                ]
            }
        ]
    })

    # ==========================================
    # EQUIPMENT SELECTION DECISION TREE
    # ==========================================
    guides.append({
        "id": "equipment_selection_guide",
        "title": "PE Equipment Selection Decision Guide",
        "description": "Strategic guide for choosing appropriate PE equipment based on experience, goals, budget, and lifestyle factors. Includes equipment-free alternatives. MEDICAL DISCLAIMER: Equipment selection should consider individual health status and medical history.",
        "category": "equipment",
        "difficulty": "beginner",
        "estimatedDuration": 8,  # reading time in minutes
        "equipmentNeeded": [],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Experience Level Assessment",
                "description": "Your PE experience determines safe equipment options. Complete Beginners (0-3 months): manual exercises only, no equipment yet. Beginners (3-6 months): basic pumps or extenders. Intermediate (6-18 months): can add hanging or advanced pumping. Advanced (18+ months): all equipment options if progressed safely. Never skip levels for safety.",
                "tips": [
                    "Be honest about your true experience",
                    "Manual exercises build necessary conditioning",
                    "Equipment amplifies forces - requires preparation",
                    "Track your PE journey duration accurately"
                ],
                "cautions": [
                    "Jumping to advanced equipment causes injury",
                    "YouTube experience doesn't count as practice",
                    "Equipment requires conditioned tissues"
                ],
                "warnings": [
                    "Using advanced equipment as beginner guarantees injury",
                    "No equipment replaces foundational conditioning"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: Primary Goal Identification",
                "description": "Match equipment to specific goals for best results. Length goals: extenders (primary), hangers (intermediate/advanced), manual stretching (always). Girth goals: pumps (all levels), clamping (advanced only), jelqing devices (intermediate). Erection quality: pumps (moderate use), cock rings (with caution), kegel exercisers. General improvement: combine approaches carefully.",
                "tips": [
                    "Focus on one primary goal initially",
                    "Length and girth require different approaches",
                    "EQ improvements often happen naturally",
                    "Document goals for appropriate equipment selection"
                ],
                "cautions": [
                    "Pursuing all goals simultaneously reduces results",
                    "Wrong equipment for goal wastes time and money",
                    "Some goals conflict (heavy hanging vs girth work)"
                ],
                "warnings": [
                    "Unrealistic goals lead to dangerous practices",
                    "Equipment can't overcome genetic limits"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Budget Categories Defined",
                "description": "Understand true costs across budget tiers. Low budget ($0-100): manual only or single basic device, requires more time investment. Medium budget ($100-300): quality device with accessories, better comfort and safety. High budget ($300+): multiple devices or premium systems, maximum comfort and convenience. Factor in recurring costs: replacement parts, lubricants, wraps.",
                "tips": [
                    "Budget for accessories and replacements",
                    "Quality saves money long-term",
                    "Start small to test commitment",
                    "Used equipment never worth savings"
                ],
                "cautions": [
                    "Cheap equipment costs more in injuries",
                    "Hidden costs add up quickly",
                    "Premium price doesn't guarantee safety"
                ],
                "warnings": [
                    "Never sacrifice safety for budget",
                    "Medical costs exceed equipment savings"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Lifestyle Compatibility",
                "description": "Choose equipment matching your life situation. Privacy available: all equipment options viable. Limited privacy: extenders, bath pumps, discrete devices. Travel frequently: portable manual devices, compact extenders. Time restricted: extenders for passive use, avoid hanging. Relationship status affects equipment visibility and storage needs. Consider daily routine integration.",
                "tips": [
                    "Realistic about available time and privacy",
                    "Discrete devices for shared living spaces",
                    "Portable options for travelers",
                    "Consider partner's awareness and comfort"
                ],
                "cautions": [
                    "Lack of privacy increases accident risk",
                    "Rushed sessions due to time constraints dangerous",
                    "Hidden equipment may be discovered"
                ],
                "warnings": [
                    "Never use equipment without secure privacy",
                    "Distracted use causes serious injury"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Equipment-Free Alternatives",
                "description": "Manual exercises provide gains without equipment investment or risk. Length: manual stretching (basic, V, A-stretch), JAI stretches. Girth: jelqing, squeezes, Uli exercises. Erection quality: kegels, reverse kegels, edging. These foundational exercises should precede equipment use and continue alongside. Free, safe when done correctly, and build necessary conditioning.",
                "tips": [
                    "Master manuals before adding equipment",
                    "Manuals travel anywhere discretely",
                    "No equipment to hide or maintain",
                    "Progress tracking still essential"
                ],
                "cautions": [
                    "Manuals still require proper technique",
                    "Overenthusiasm causes injury even without equipment",
                    "Progress slower but safer than equipment"
                ],
                "warnings": [
                    "Poor manual technique creates bad habits",
                    "Never skip warm-up even for manuals"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Risk Tolerance Evaluation",
                "description": "Honestly assess your risk tolerance for informed decisions. Low risk tolerance: stick to manuals and basic pumping, avoid hanging. Moderate risk: add extenders or moderate pumping, careful progression. High risk acceptance: all equipment options with strict safety protocols. Consider: health status, injury recovery ability, career/relationship impacts of potential injury, and psychological readiness for setbacks.",
                "tips": [
                    "Lower risk still provides gains",
                    "Risk compounds with multiple devices",
                    "Age affects recovery from injuries",
                    "Consider life impact of worst-case scenario"
                ],
                "cautions": [
                    "Risk tolerance changes with experience",
                    "Peer pressure increases risk-taking",
                    "Success can lead to overconfidence"
                ],
                "warnings": [
                    "High risk means accepting possibility of permanent injury",
                    "No gains worth permanent damage"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Progression Pathway Planning",
                "description": "Plan equipment progression over years, not weeks. Year 1: manual exercises, basic pump or extender. Year 2: add second device type, increase intensity. Year 3+: consider advanced options if needed. Each stage builds on previous success. Document what works before adding complexity. Many achieve goals with minimal equipment.",
                "tips": [
                    "Write out 2-year equipment plan",
                    "Budget for gradual acquisition",
                    "Master each device before adding another",
                    "Re-evaluate goals annually"
                ],
                "cautions": [
                    "Rapid equipment accumulation wastes money",
                    "Too many devices dilute focus",
                    "Advanced equipment may never be needed"
                ],
                "warnings": [
                    "Skipping progression stages causes injury",
                    "Equipment addiction real psychological issue"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Making the Final Decision",
                "description": "Synthesize all factors for equipment decision. Start with: experience level match, single device for primary goal, middle budget tier for quality, lifestyle-compatible choice, manual exercises regardless, and conservative risk approach. Buy from reputable sellers only. Read instructions completely. Start below recommended levels. Track results objectively. Be willing to stop if not working.",
                "tips": [
                    "Sleep on decision before purchasing",
                    "Research specific models thoroughly",
                    "Have realistic 6-month expectations",
                    "Keep receipts and warranties"
                ],
                "cautions": [
                    "Impulse buying leads to poor choices",
                    "Marketing exploits insecurities",
                    "Perfect equipment doesn't exist"
                ],
                "warnings": [
                    "If unsure, choose safer option",
                    "No equipment fixes underlying issues"
                ]
            }
        ]
    })

    return guides

def main():
    print("🚀 Equipment Guides Upload")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Get guide definitions
    guides = get_equipment_guides()
    print(f"📋 Prepared {len(guides)} equipment guides")
    print()

    # Upload each guide
    successful_uploads = 0
    failed_uploads = 0

    for guide in guides:
        guide_id = guide.pop("id")  # Remove ID from data before upload
        success = upload_guide(token, guide_id, guide)
        if success:
            successful_uploads += 1
        else:
            failed_uploads += 1

    print()
    print("📊 UPLOAD SUMMARY:")
    print("-" * 50)
    print(f"✅ Successful uploads: {successful_uploads}")
    print(f"❌ Failed uploads: {failed_uploads}")
    print(f"📁 Total guides: {len(guides)}")

    if failed_uploads > 0:
        print(f"\n⚠️  {failed_uploads} uploads failed. Check the errors above.")
        sys.exit(1)
    else:
        print("\n🎉 All equipment guides uploaded successfully!")
        print("\n📋 EQUIPMENT GUIDES CREATED:")
        print("-" * 50)
        print("✅ Vacuum Pump Guide - Types, sizing, safety, usage")
        print("✅ Hanger Comparison Guide - Types, progression, safety")
        print("✅ Extender Guide - Mechanisms, protocols, expectations")
        print("✅ Equipment Safety Guide - Universal safety protocols")
        print("✅ Selection Decision Guide - Choosing appropriate equipment")
        print()
        print("All guides emphasize safety and avoid brand endorsements!")

if __name__ == "__main__":
    main()