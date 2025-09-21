#!/usr/bin/env python3
"""
Script to add community-sourced tips and cautions to PE methods
Based on r/TheScienceOfPE and community wisdom
"""

import json
import sys
import requests
from typing import Dict, List

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
        print("❌ Error: Failed to get auth token")
        sys.exit(1)

# Community-sourced tips and cautions based on Reddit PE communities
METHOD_ENHANCEMENTS = {
    "Pump Assisted Clamping (PAC)": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Heat is crucial - tissues expand better when warm", "Use rice sock or heating pad for 10+ minutes"], "cautions": ["Never skip warmup - cold tissue tears easily"]},
            {"step": 2, "tips": ["3-5 Hg is the sweet spot for beginners", "Water-based lube creates better seal"], "cautions": ["Red dots mean too much pressure - reduce immediately"]},
            {"step": 3, "tips": ["Toe shields under clamp prevent pinching", "Cable clamp is community favorite"], "cautions": ["If numbness or coldness occurs, remove immediately"]},
            {"step": 4, "tips": ["This creates extreme expansion", "Feel for the 'pump'"], "cautions": ["Maximum 10 minutes for beginners", "Never exceed 20 minutes even when advanced"]},
            {"step": 5, "tips": ["Light massage helps recovery", "Expect temporary discoloration"], "cautions": ["Monitor for lasting discoloration or bruising"]},
            {"step": 6, "tips": ["Track expansion measurements", "Take progress photos"], "cautions": ["Rest day required between sessions"]},
            {"step": 7, "tips": ["Vitamin E oil helps with discoloration", "Moisturize regularly"], "cautions": ["See doctor if pain persists"]}
        ]
    },
    "Weight Hanging": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Vacuum hangers safer than compression", "Baby powder prevents slipping"], "cautions": ["Never attach directly to glans - tissue damage risk"]},
            {"step": 2, "tips": ["Start with 2.5 lbs maximum", "Less is more - focus on time not weight"], "cautions": ["Community reports injuries above 5 lbs for beginners"]},
            {"step": 3, "tips": ["20 minutes is standard set", "Can read or work during hanging"], "cautions": ["Stop immediately if glans gets cold or numb"]},
            {"step": 4, "tips": ["Massage during rest restores circulation", "Heat helps recovery"], "cautions": ["Never skip rest periods - tissue needs oxygen"]},
            {"step": 5, "tips": ["2-3 sets is plenty", "Consistency beats intensity"], "cautions": ["More than 3 sets increases injury risk"]},
            {"step": 6, "tips": ["Only increase when current weight feels too easy", "1 lb increments maximum"], "cautions": ["Rapid weight increases cause ligament damage"]},
            {"step": 7, "tips": ["Heat essential for recovery", "Light stretching helps"], "cautions": ["Soreness next day means reduce weight"]},
            {"step": 8, "tips": ["Log every session", "Measure monthly not weekly"], "cautions": ["Take decon breaks every 3-4 months"]}
        ]
    },
    "Basic Jelq": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Coconut oil is community favorite", "Reapply as needed to prevent friction"], "cautions": ["Never use soap - causes irritation"]},
            {"step": 2, "tips": ["40-70% erection is crucial", "Too soft = no effect, too hard = injury"], "cautions": ["NEVER jelq at 100% - serious injury risk"]},
            {"step": 3, "tips": ["2-3 second strokes", "OK grip behind glans"], "cautions": ["Stop if sharp pain or unusual bending"]},
            {"step": 4, "tips": ["Start with 50-100 for beginners", "Build up slowly over weeks"], "cautions": ["Red spots mean too intense - reduce immediately"]},
            {"step": 5, "tips": ["Warm down as important as warm up", "Light massage helps"], "cautions": ["Monitor for thrombosed veins or hard lumps"]}
        ]
    },
    "Bathmate Water Pump": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Trim pubic hair for seal", "Shower is ideal location"], "cautions": ["Check for cuts or irritation first"]},
            {"step": 2, "tips": ["Hotter water = better expansion", "Refill with hot water as needed"], "cautions": ["Not scalding - tissue damage risk"]},
            {"step": 3, "tips": ["Push pubic bone for seal", "Lean back helps positioning"], "cautions": ["Don't force - adjust comfort pad if needed"]},
            {"step": 4, "tips": ["Count pumps for consistency", "3-4 pumps usually enough"], "cautions": ["Gauge red zone = danger zone"]},
            {"step": 5, "tips": ["5 minutes for beginners", "Can work up to 15-20 minutes"], "cautions": ["Fluid retention (edema) if too long"]},
            {"step": 6, "tips": ["Release valve slowly", "Expect temporary expansion"], "cautions": ["Rapid release can cause injury"]},
            {"step": 7, "tips": ["Green zone on gauge is safe", "Yellow zone for advanced"], "cautions": ["Never enter red zone - tissue damage"]},
            {"step": 8, "tips": ["Clean with antibacterial soap", "Replace gaiter every 6 months"], "cautions": ["Mold risk if not dried properly"]},
            {"step": 9, "tips": ["Measure after rest, not immediately", "Weekly measurements sufficient"], "cautions": ["Temporary expansion isn't real gain"]}
        ]
    },
    "BFR Clamping": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Cable clamps from hardware store work", "Toe shields or wrap for padding"], "cautions": ["Never use rigid metal clamps"]},
            {"step": 2, "tips": ["Must be 100% erect", "Use whatever stimulation works"], "cautions": ["Soft clamping causes injury"]},
            {"step": 3, "tips": ["Behind glans, not on shaft", "Tight but not painful"], "cautions": ["Should still have some sensation"]},
            {"step": 4, "tips": ["Kegels increase expansion", "Stay stimulated"], "cautions": ["Remove if numbness or coldness"]},
            {"step": 5, "tips": ["10 minutes max for beginners", "Use timer"], "cautions": ["Hypoxia damage after 20 minutes"]},
            {"step": 6, "tips": ["Release slowly", "Massage immediately"], "cautions": ["Temporary ED common after session"]},
            {"step": 7, "tips": ["Light jelqing restores flow", "Heat helps"], "cautions": ["No sex immediately after"]},
            {"step": 8, "tips": ["Purple color fades quickly", "Expansion is temporary"], "cautions": ["Seek help if discoloration persists hours later"]}
        ]
    },
    "Penis Extender Protocol": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Quality matters - cheap breaks", "Vacuum cup better than noose"], "cautions": ["Knockoffs can cause permanent damage"]},
            {"step": 2, "tips": ["Practice assembly before wearing", "Watch manufacturer videos"], "cautions": ["Incorrect setup = injury"]},
            {"step": 3, "tips": ["Behind glans attachment", "Use protective wrap"], "cautions": ["Never attach to glans tip"]},
            {"step": 4, "tips": ["Start with minimal tension", "Should feel stretch not pain"], "cautions": ["Pain = too much tension"]},
            {"step": 5, "tips": ["Build up from 1 hour daily", "Can wear under baggy pants"], "cautions": ["Remove every hour initially for circulation"]},
            {"step": 6, "tips": ["4-6 hours daily optimal", "Consistency is key"], "cautions": ["Never sleep wearing device"]},
            {"step": 7, "tips": ["Add 0.5cm bars gradually", "Log your settings"], "cautions": ["Too fast progression = injury"]},
            {"step": 8, "tips": ["Monthly measurements", "Photos help track"], "cautions": ["Plateaus normal - don't force progress"]}
        ]
    },
    "Manual Girth Squeezes": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Liberal lubrication essential", "Reapply frequently"], "cautions": ["Dry squeezing causes skin damage"]},
            {"step": 2, "tips": ["60-80% erection ideal", "Maintain level throughout"], "cautions": ["100% erection = vascular damage risk"]},
            {"step": 3, "tips": ["OK grip at base", "Firm but not crushing"], "cautions": ["Death grip causes nerve damage"]},
            {"step": 4, "tips": ["Hold steady pressure", "Should see expansion above grip"], "cautions": ["Release if pain or numbness"]},
            {"step": 5, "tips": ["30-60 seconds per squeeze", "Watch the clock"], "cautions": ["Longer holds don't mean better gains"]},
            {"step": 6, "tips": ["Full release between squeezes", "Restores blood flow"], "cautions": ["Continuous pressure causes damage"]},
            {"step": 7, "tips": ["5-10 squeezes for beginners", "Build up slowly"], "cautions": ["Overwork causes turtling"]},
            {"step": 8, "tips": ["Warm down important", "Light massage helps"], "cautions": ["Red spots indicate too intense"]}
        ]
    },
    "Kegel Exercises": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Practice stopping urine to find muscle", "Same as preventing gas release"], "cautions": ["Don't regularly stop urine - bladder issues"]},
            {"step": 2, "tips": ["Can do anywhere unnoticed", "Start lying down if difficult"], "cautions": ["Empty bladder first"]},
            {"step": 3, "tips": ["Squeeze and lift feeling", "Visualize lifting testicles"], "cautions": ["Don't clench glutes or abs"]},
            {"step": 4, "tips": ["Start with 3 seconds", "Build to 10 seconds"], "cautions": ["Overwork causes premature ejaculation"]},
            {"step": 5, "tips": ["Complete relaxation crucial", "Prevents pelvic floor dysfunction"], "cautions": ["Chronic tension causes problems"]},
            {"step": 6, "tips": ["10-15 reps, 3x daily", "Quality over quantity"], "cautions": ["Balance with reverse kegels"]},
            {"step": 7, "tips": ["Do during commute or TV", "Make it habit"], "cautions": ["Stop if pelvic pain develops"]},
            {"step": 8, "tips": ["Results in 4-6 weeks", "Improves erection angle"], "cautions": ["Too much causes hard flaccid"]}
        ]
    },
    "Reverse Kegels": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Like pushing out urine", "Or bearing down gently"], "cautions": ["Don't strain like bowel movement"]},
            {"step": 2, "tips": ["Start lying down", "Hand on perineum helps feel"], "cautions": ["Not if hemorrhoids present"]},
            {"step": 3, "tips": ["Gentle push, not force", "Should feel relaxation"], "cautions": ["Straining causes problems"]},
            {"step": 4, "tips": ["3-5 seconds holds", "Less than regular kegels"], "cautions": ["Don't hold breath"]},
            {"step": 5, "tips": ["Return to neutral", "Not clenched"], "cautions": ["Maintain relaxation"]},
            {"step": 6, "tips": ["5-10 reps enough", "2-3x daily"], "cautions": ["Less is more with reverse"]},
            {"step": 7, "tips": ["Before sex helps last longer", "Relaxes pelvic floor"], "cautions": ["Not during urination"]},
            {"step": 8, "tips": ["Balances regular kegels", "Prevents tension"], "cautions": ["Stop if causes incontinence"]}
        ]
    },
    "Edging Practice": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Privacy and time essential", "No distractions"], "cautions": ["Don't rush - defeats purpose"]},
            {"step": 2, "tips": ["Vary stimulation", "Learn your triggers"], "cautions": ["Death grip reduces sensitivity"]},
            {"step": 3, "tips": ["Rate arousal 1-10", "Stop at 8-9"], "cautions": ["Going over is normal - keep practicing"]},
            {"step": 4, "tips": ["Complete stop or slow down", "Deep breathing helps"], "cautions": ["Frustration is normal initially"]},
            {"step": 5, "tips": ["3-5 edges for beginners", "Build up over time"], "cautions": ["Too many causes desensitization"]},
            {"step": 6, "tips": ["Combine with kegels", "Improves control"], "cautions": ["Don't overwork PC muscle"]},
            {"step": 7, "tips": ["20-30 minutes typical", "Quality over duration"], "cautions": ["Addiction risk if overdone"]},
            {"step": 8, "tips": ["Can finish or retain", "Cold water if retaining"], "cautions": ["Blue balls temporary and harmless"]}
        ]
    },
    "Basic Manual Stretch": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["5-10 minutes heat minimum", "Rice sock works great"], "cautions": ["Cold stretching causes micro-tears"]},
            {"step": 2, "tips": ["OK grip 1 inch behind glans", "Baby powder for grip"], "cautions": ["Never grip glans directly"]},
            {"step": 3, "tips": ["Pull to mild discomfort not pain", "Should feel internal stretch"], "cautions": ["Sharp pain means too hard"]},
            {"step": 4, "tips": ["30 seconds each direction", "Breathe normally"], "cautions": ["Don't bounce or jerk"]},
            {"step": 5, "tips": ["All directions: up, down, left, right, straight", "Rotate through systematically"], "cautions": ["Equal time prevents curve development"]},
            {"step": 6, "tips": ["Can do seated or standing", "Morning wood stretch bonus"], "cautions": ["Never stretch erect"]},
            {"step": 7, "tips": ["5-10 minutes total", "2x daily okay"], "cautions": ["Overwork causes turtling"]}
        ]
    },
    "Wet Jelq": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["More lube than you think", "Reapply every 20-30 strokes"], "cautions": ["Friction burns from insufficient lube"]},
            {"step": 2, "tips": ["40-60% ideal for length", "60-80% for girth"], "cautions": ["90%+ causes injury"]},
            {"step": 3, "tips": ["OK grip, not death grip", "Consistent pressure"], "cautions": ["Varying pressure causes uneven growth"]},
            {"step": 4, "tips": ["3 second strokes standard", "Count for consistency"], "cautions": ["Fast strokes ineffective and dangerous"]},
            {"step": 5, "tips": ["Switch hands prevents curve", "Equal strokes each"], "cautions": ["Favoring one hand causes asymmetry"]},
            {"step": 6, "tips": ["100-200 for beginners", "Add 50 weekly"], "cautions": ["Jump to 500+ causes injury"]},
            {"step": 7, "tips": ["Should feel fatigue not pain", "Like worked muscle"], "cautions": ["Pain or spots = stop immediately"]},
            {"step": 8, "tips": ["Fuller hang normal", "Veins more visible"], "cautions": ["Thrombosed veins need rest"]}
        ]
    },
    "Bundled Stretches": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Heat crucial for this technique", "10 minutes minimum"], "cautions": ["Cold bundling causes torsion injury"]},
            {"step": 2, "tips": ["Behind glans grip", "Firm but not crushing"], "cautions": ["Glans grip causes nerve damage"]},
            {"step": 3, "tips": ["Start with 180° twist", "Work up to 360° over months"], "cautions": ["720° only for very advanced"]},
            {"step": 4, "tips": ["Twist then stretch", "Should feel deep internal stretch"], "cautions": ["Sharp pain = untwist immediately"]},
            {"step": 5, "tips": ["Hold 30-60 seconds", "Less time than regular stretches"], "cautions": ["Longer holds with twist = injury"]},
            {"step": 6, "tips": ["Reverse direction each set", "Prevents permanent twist"], "cautions": ["Same direction only causes corkscrew"]},
            {"step": 7, "tips": ["Advanced technique", "Master basics first"], "cautions": ["Not for first 6 months of PE"]},
            {"step": 8, "tips": ["Untwist slowly", "Massage after"], "cautions": ["Watch for lasting twist in flaccid"]}
        ]
    },
    "Firegoat Rolls": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["30-50% erection ideal", "Too soft won't work"], "cautions": ["Too hard makes rolling painful"]},
            {"step": 2, "tips": ["Table/counter height", "Towel for hygiene"], "cautions": ["Rough surfaces cause abrasion"]},
            {"step": 3, "tips": ["Use palm or forearm", "Start gentle"], "cautions": ["Full body weight too intense initially"]},
            {"step": 4, "tips": ["Roll from base to below glans", "Smooth motion"], "cautions": ["Never roll over glans"]},
            {"step": 5, "tips": ["Moderate downward pressure", "Should feel internal compression"], "cautions": ["Numbness means too much pressure"]},
            {"step": 6, "tips": ["Start with 50 rolls", "Build to 100-200"], "cautions": ["More than 200 causes excessive trauma"]},
            {"step": 7, "tips": ["Temporary numbness normal", "Subsides in minutes"], "cautions": ["Lasting numbness = nerve damage"]},
            {"step": 8, "tips": ["Follow with light stretches", "Heat helps recovery"], "cautions": ["Skip if very sore next day"]}
        ]
    },
    "Length Pumping Protocol": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Cylinder 0.25-0.5\" wider than erect girth", "Length matters more than width"], "cautions": ["Too wide cylinder won't create length stress"]},
            {"step": 2, "tips": ["2-4 Hg for length", "Less pressure than girth pumping"], "cautions": ["High pressure causes donut effect not length"]},
            {"step": 3, "tips": ["Feel stretch at base", "Packed feeling"], "cautions": ["Pain means too much vacuum"]},
            {"step": 4, "tips": ["15-20 minute sets", "Can do while working"], "cautions": ["Fluid buildup if too long"]},
            {"step": 5, "tips": ["5 minute breaks crucial", "Prevents edema"], "cautions": ["Continuous pumping causes blisters"]},
            {"step": 6, "tips": ["2-3 sets standard", "Daily okay if conditioned"], "cautions": ["Overuse causes toughening"]},
            {"step": 7, "tips": ["Increase time before pressure", "Conditioning important"], "cautions": ["Rapid increases cause injury"]},
            {"step": 8, "tips": ["Jelq between sets", "Helps prevent donut"], "cautions": ["Heavy exercise after pumping risky"]}
        ]
    },
    "Horse Squeeze": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Oil better than water lube", "Warm it first"], "cautions": ["Insufficient lube causes burn"]},
            {"step": 2, "tips": ["70-80% erection", "Maintain throughout"], "cautions": ["90%+ erection dangerous"]},
            {"step": 3, "tips": ["OK grip at base", "Tight seal"], "cautions": ["Too tight cuts circulation"]},
            {"step": 4, "tips": ["Slow 3-5 second stroke", "Watch expansion"], "cautions": ["Fast strokes cause trauma"]},
            {"step": 5, "tips": ["Squeeze harder at mid-shaft", "Creates ballooning"], "cautions": ["Don't squeeze at glans"]},
            {"step": 6, "tips": ["Full stroke back to base", "Reset each rep"], "cautions": ["Partial strokes less effective"]},
            {"step": 7, "tips": ["20-30 for beginners", "Very intense exercise"], "cautions": ["50+ causes overwork"]},
            {"step": 8, "tips": ["Expect vein prominence", "Temporary expansion"], "cautions": ["Spots or bruising = too intense"]}
        ]
    },
    "Uli Exercise": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Minimal lube needed", "Just enough for grip"], "cautions": ["Too much lube = no grip"]},
            {"step": 2, "tips": ["90-95% erection required", "Maximum engorgement"], "cautions": ["100% = injury risk"]},
            {"step": 3, "tips": ["Very tight OK grip", "Trap maximum blood"], "cautions": ["Should maintain some feeling"]},
            {"step": 4, "tips": ["Second hand squeezes shaft", "Extreme expansion"], "cautions": ["Don't squeeze glans"]},
            {"step": 5, "tips": ["30-45 seconds max", "Use timer"], "cautions": ["Over 60 seconds dangerous"]},
            {"step": 6, "tips": ["Complete release essential", "Blood flow restoration"], "cautions": ["Multiple back-to-back dangerous"]},
            {"step": 7, "tips": ["3-5 reps plenty", "Very intense"], "cautions": ["10+ reps excessive"]},
            {"step": 8, "tips": ["Purple color normal", "Subsides quickly"], "cautions": ["Lasting discoloration concerning"]}
        ]
    },
    "Ballooning Technique": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Learn your arousal scale", "Practice awareness"], "cautions": ["Takes weeks to master"]},
            {"step": 2, "tips": ["Edge to 90% arousal", "Right before point of no return"], "cautions": ["Going over normal while learning"]},
            {"step": 3, "tips": ["Complete stimulation stop", "Let arousal drop to 70%"], "cautions": ["Partial stop less effective"]},
            {"step": 4, "tips": ["Deep breathing helps", "Relax PC muscle"], "cautions": ["Clenching prevents ballooning"]},
            {"step": 5, "tips": ["Repeat 3-5 times minimum", "More cycles = more expansion"], "cautions": ["Diminishing returns after 10"]},
            {"step": 6, "tips": ["Maximum engorgement achieved", "Rock hard without ejaculation"], "cautions": ["Blue balls if overdone"]},
            {"step": 7, "tips": ["30-45 minutes typical session", "Take your time"], "cautions": ["Rushing defeats purpose"]},
            {"step": 8, "tips": ["Can finish or retain", "Benefits either way"], "cautions": ["Retention discomfort temporary"]}
        ]
    },
    "Cock Ring Training": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Silicone best for beginners", "Measure for proper size"], "cautions": ["Metal rings risky - can't remove if stuck"]},
            {"step": 2, "tips": ["Apply when completely soft", "Use lube for comfort"], "cautions": ["Never force over erect penis"]},
            {"step": 3, "tips": ["Behind balls most restrictive", "Just shaft for lighter restriction"], "cautions": ["Too tight causes damage"]},
            {"step": 4, "tips": ["Achieve full erection", "Ring maintains hardness"], "cautions": ["Remove if can't get erect"]},
            {"step": 5, "tips": ["15-20 minutes max initially", "Build tolerance"], "cautions": ["30 minutes absolute maximum"]},
            {"step": 6, "tips": ["Enhanced size temporary", "Good for confidence"], "cautions": ["Numbness or cold = remove now"]},
            {"step": 7, "tips": ["May need lube to remove", "Pull skin through first"], "cautions": ["Don't panic if stuck - stay calm"]},
            {"step": 8, "tips": ["Wash with toy cleaner", "Check for damage"], "cautions": ["Replace if stretched or torn"]}
        ]
    },
    "Fulcrum Stretches": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Drumstick or marker ideal", "Smooth rounded object"], "cautions": ["Nothing with edges or points"]},
            {"step": 2, "tips": ["Standard stretch grip", "Behind glans"], "cautions": ["Don't grip glans"]},
            {"step": 3, "tips": ["Object at mid-shaft", "Creates leverage point"], "cautions": ["Not at base - less effective"]},
            {"step": 4, "tips": ["Pull over fulcrum", "Focused stress point"], "cautions": ["Sharp pain = wrong angle"]},
            {"step": 5, "tips": ["30 seconds per angle", "Less than regular stretches"], "cautions": ["Longer with fulcrum = injury"]},
            {"step": 6, "tips": ["Try different fulcrum positions", "Targets different areas"], "cautions": ["Same spot repeatedly causes weak point"]},
            {"step": 7, "tips": ["All directions important", "Systematic approach"], "cautions": ["Favoring one direction causes curve"]},
            {"step": 8, "tips": ["Remove fulcrum slowly", "Massage area"], "cautions": ["Watch for indentation marks"]}
        ]
    },
    "Modified Extreme Measures (MEM)": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Extended warmup crucial", "15+ minutes"], "cautions": ["This is extreme - not for beginners"]},
            {"step": 2, "tips": ["Mental preparation important", "Will be uncomfortable"], "cautions": ["Only after 6+ months regular PE"]},
            {"step": 3, "tips": ["Maximum safe stretch", "To discomfort not pain"], "cautions": ["Injury risk high if too aggressive"]},
            {"step": 4, "tips": ["Brief release only", "30 seconds max"], "cautions": ["Keep tissues stressed"]},
            {"step": 5, "tips": ["5 rounds minimum", "Endurance test"], "cautions": ["Stop if sharp pain"]},
            {"step": 6, "tips": ["Cover every angle", "No direction missed"], "cautions": ["Systematic to prevent imbalance"]},
            {"step": 7, "tips": ["Ice reduces inflammation", "10-15 minutes"], "cautions": ["Not directly on skin"]},
            {"step": 8, "tips": ["2-3 days recovery minimum", "Monitor for injury"], "cautions": ["Weekly maximum frequency"]}
        ]
    }
}

# Additional general safety tips from community
GENERAL_SAFETY = """
CRITICAL COMMUNITY SAFETY GUIDELINES:
- Never exceed 20 minutes for restriction exercises (clamping/rings)
- Stop immediately if numbness, coldness, or sharp pain
- Red spots (petechiae) indicate too much pressure
- Start with 50% intensity and time recommendations
- Heat before and after every session (10+ minutes)
- Consistency beats intensity - slow gains are permanent gains
- Take decon breaks every 3-4 months
- Monitor for thrombosed veins, hard lumps, or lasting discoloration
- Document everything - measurements, routines, issues
- If it hurts, STOP - "no pain no gain" doesn't apply to PE
"""

def fetch_method_details(token: str, method_id: str) -> Dict:
    """Fetch detailed method data"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{method_id}"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers)
    return response.json() if response.status_code == 200 else None

def update_method(token: str, method_id: str, doc: Dict) -> bool:
    """Update method in Firestore"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{method_id}"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    response = requests.patch(url, headers=headers, json=doc)
    return response.status_code in [200, 204]

def main():
    print("🔧 Adding Community-Sourced Tips and Cautions")
    print("=" * 50)
    print("\nSource: r/TheScienceOfPE and PE community wisdom\n")

    # Get auth token
    print("🔐 Authenticating...")
    token = get_firebase_token()
    print("✅ Authenticated\n")

    success = 0
    failed = 0

    for method_name, enhancements in METHOD_ENHANCEMENTS.items():
        # Convert to ID format
        method_id = method_name.lower().replace(" ", "_").replace("(", "").replace(")", "")

        # Handle special cases
        id_mappings = {
            "pump_assisted_clamping_pac": "pac",
            "modified_extreme_measures_mem": "mem_stretch",
            "all_day_stretcher_ads": "ads"
        }
        method_id = id_mappings.get(method_id, method_id)

        print(f"📝 {method_name}...")

        # Fetch current document
        doc = fetch_method_details(token, method_id)
        if not doc:
            print(f"   ⏭️  Not found")
            failed += 1
            continue

        # Update steps with tips/cautions
        steps_field = doc.get("fields", {}).get("steps", {}).get("arrayValue", {}).get("values", [])

        for i, step in enumerate(steps_field):
            step_num = i + 1
            step_map = step.get("mapValue", {}).get("fields", {})

            # Find matching enhancement
            for enh in enhancements["steps_tips_cautions"]:
                if enh["step"] == step_num:
                    if "tips" in enh:
                        step_map["tips"] = {
                            "arrayValue": {
                                "values": [{"stringValue": tip} for tip in enh["tips"]]
                            }
                        }
                    if "cautions" in enh:
                        step_map["cautions"] = {
                            "arrayValue": {
                                "values": [{"stringValue": caution} for caution in enh["cautions"]]
                            }
                        }
                    break

        # Update document
        doc["fields"]["steps"] = {"arrayValue": {"values": steps_field}}

        if update_method(token, method_id, doc):
            print(f"   ✅ Updated")
            success += 1
        else:
            print(f"   ❌ Failed")
            failed += 1

    print("\n" + "=" * 50)
    print(f"✅ Success: {success}")
    print(f"❌ Failed: {failed}")
    print("\n" + GENERAL_SAFETY)

if __name__ == "__main__":
    main()