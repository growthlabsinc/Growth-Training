#!/usr/bin/env python3
"""
Script to add tips and cautions to all PE methods that don't have them
This enriches the step-by-step instructions with helpful guidance
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
        print("❌ Error: Failed to get auth token. Make sure you're logged in with:")
        print("   gcloud auth login")
        sys.exit(1)

# Define tips and cautions for each method
METHOD_ENHANCEMENTS = {
    "Weight Hanging": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Use baby powder or chalk for better grip", "Ensure complete privacy and comfortable room temperature"], "cautions": ["Never attach directly to glans - can cause permanent nerve damage", "Compression hanging has no data supporting effectiveness per medical experts"]},
            {"step": 2, "tips": ["Start with 2.5 lbs maximum for first 2-4 weeks", "Use a digital luggage scale to verify exact weight"], "cautions": ["Starting too heavy is the #1 cause of injury", "Tissue damage and nerve damage are permanent risks"]},
            {"step": 3, "tips": ["Set multiple timers as backup", "Stay seated and relaxed during sets"], "cautions": ["Stop immediately if you feel numbness, tingling, or coldness", "These are signs of nerve compression"]},
            {"step": 4, "tips": ["Gentle massage restores blood flow", "Walk around during rest periods"], "cautions": ["Never skip rest periods - tissue fatigue leads to injury", "Rest is when adaptation occurs"]},
            {"step": 5, "tips": ["Consistency over intensity for gains", "Keep detailed log with weight, time, and sensations"], "cautions": ["Maximum 3 sets for first month", "More sets doesn't mean faster gains"]},
            {"step": 6, "tips": ["Only add weight when current feels too easy", "1 lb increments maximum"], "cautions": ["Never increase more than 20% at once", "Plateau means you need deload week, not more weight"]},
            {"step": 7, "tips": ["Rice sock or heating pad for 5-10 minutes", "Gentle stretches during cooldown"], "cautions": ["Skipping warmup/cooldown significantly increases injury risk", "Cold tissue is injury-prone tissue"]},
            {"step": 8, "tips": ["Photo documentation monthly, not daily", "Measure at same time of day"], "cautions": ["Take 1-2 rest days per week minimum", "Chronic fatigue leads to injury and kills gains"]}
        ]
    },
    "Basic Manual Stretch": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Hot shower or rice sock heating pad works well", "Ensure complete privacy"], "cautions": ["Not too hot - avoid burns"]},
            {"step": 2, "tips": ["OK grip behind glans is most effective", "Use baby powder for grip"], "cautions": ["Never grip the glans directly"]},
            {"step": 3, "tips": ["Breathe normally during stretch", "Count seconds to maintain consistency"], "cautions": ["Stop if sharp pain occurs"]},
            {"step": 4, "tips": ["Use this time to regain grip", "Light shaking helps circulation"], "cautions": ["Don't rush - full rest is important"]},
            {"step": 5, "tips": ["Mirror helps check form", "Maintain consistent grip pressure"], "cautions": ["Reduce intensity if skin irritation occurs"]},
            {"step": 6, "tips": ["Can be done seated or standing", "Combine with rotations for variety"], "cautions": ["Avoid extreme angles initially"]},
            {"step": 7, "tips": ["Light massage promotes recovery", "Moisturize if skin feels dry"], "cautions": ["Monitor for any bruising or spots"]}
        ]
    },
    "Basic Jelq": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Water-based lube needs reapplication but safer", "Coconut oil or olive oil are natural alternatives"], "cautions": ["Insufficient lubrication causes friction burns", "Reddit users warn jelqing is considered outdated and dangerous"]},
            {"step": 2, "tips": ["40-70% erection level is safer than higher", "Use minimal stimulation to maintain level"], "cautions": ["Never jelq above 80% - high risk of vein thrombosis", "Medical experts warn of erectile dysfunction risk"]},
            {"step": 3, "tips": ["2-3 second strokes are standard", "OK grip with moderate pressure only"], "cautions": ["Death grip causes tissue damage", "Can lead to Peyronie's disease (curved, painful erections)"]},
            {"step": 4, "tips": ["Start with 50-100 strokes maximum", "Quality over quantity always"], "cautions": ["Sharp pain means stop immediately", "Unusual bending indicates tissue damage"]},
            {"step": 5, "tips": ["5-10 minute warm wrap aids recovery", "Check for symmetry and spots"], "cautions": ["Red spots indicate burst capillaries", "Dark bruising means too much pressure - take days off"]}
        ]
    },
    "Bathmate Water Pump": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Trim pubic hair 1-2mm for optimal seal", "Warm shower beforehand helps prepare tissue"], "cautions": ["Never pump with any cuts, sores, or irritation", "Check for STDs or infections first"]},
            {"step": 2, "tips": ["Water temp around 100-105°F is ideal", "Refill with hot water halfway through"], "cautions": ["Too hot causes burns and blisters", "Test on wrist first like baby bottle"]},
            {"step": 3, "tips": ["Press firmly against pubic bone", "Slight rotation helps seal"], "cautions": ["Forcing seal can damage comfort ring", "Poor seal means less effective session"]},
            {"step": 4, "tips": ["3-4 pumps initially is enough", "Wait 5-10 seconds between pumps"], "cautions": ["Keep pressure below 5 in/hg (13.5 kPa)", "Higher pressure doesn't mean better results"]},
            {"step": 5, "tips": ["Maximum 15 minutes per session", "Can do gentle rotations for variety"], "cautions": ["Never exceed 15 minutes - edema risk", "Discoloration means pressure too high"]},
            {"step": 6, "tips": ["Press valve slowly and steadily", "Support pump during release"], "cautions": ["Rapid release can cause blood vessel damage", "May feel lightheaded - sit down"]},
            {"step": 7, "tips": ["Stay in green zone on gauge", "Less pressure for longer is better than high pressure"], "cautions": ["Red zone can cause permanent damage", "Pain is never normal - stop immediately"]},
            {"step": 8, "tips": ["Rinse with clean water, mild soap weekly", "Store in dry, cool place"], "cautions": ["Bacteria buildup causes infections", "Replace if rubber shows cracks or wear"]},
            {"step": 9, "tips": ["Weekly measurements are sufficient", "Same time of day for consistency"], "cautions": ["Daily measuring causes anxiety and is inaccurate", "Temporary expansion isn't permanent gain"]}
        ]
    },
    "BFR Clamping": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Cable clamp with toe shield or mousepad padding", "Measure girth to get right clamp size"], "cautions": ["Metal clamps can cut off circulation completely", "Reddit warns clamping is high-risk for newbies"]},
            {"step": 2, "tips": ["Must achieve 100% natural erection", "Forced erection with drugs is dangerous"], "cautions": ["Clamping below 100% can cause venous leak", "Viagra/Cialis with clamping is extremely dangerous"]},
            {"step": 3, "tips": ["Place 1 inch behind glans", "Should feel tight but not painful"], "cautions": ["Too tight causes permanent nerve damage", "Should still have some sensation in glans"]},
            {"step": 4, "tips": ["Gentle kegels only", "Stay relaxed and breathe normally"], "cautions": ["Numbness or coldness means remove immediately", "These indicate dangerous blood flow restriction"]},
            {"step": 5, "tips": ["5-7 minutes for beginners maximum", "Use countdown timer with alarm"], "cautions": ["10 minutes absolute maximum even for advanced", "Tissue death can occur after 20 minutes"]},
            {"step": 6, "tips": ["Open clamp gradually over 5-10 seconds", "Massage gently after removal"], "cautions": ["Rapid release can cause blood pressure spike", "Temporary numbness is common but concerning"]},
            {"step": 7, "tips": ["5-10 minutes light massage", "Warm compress helps recovery"], "cautions": ["No sex or masturbation for 2-4 hours after", "Tissue is vulnerable post-clamping"]},
            {"step": 8, "tips": ["Purple color fades within minutes", "Document any unusual marks"], "cautions": ["Dark purple or black means too long/tight", "Persistent discoloration needs medical attention"]}
        ]
    },
    "Bundled Stretches": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Hot wrap or shower ideal", "Do some light stretches first"], "cautions": ["Ensure fully flaccid state"]},
            {"step": 2, "tips": ["OK grip most effective", "Baby powder helps grip"], "cautions": ["Don't grip too tightly"]},
            {"step": 3, "tips": ["Start with 180° if new", "Can work up to 720° over time"], "cautions": ["Stop if skin twists painfully"]},
            {"step": 4, "tips": ["Pull steadily, not jerky", "Breathe normally throughout"], "cautions": ["Reduce force if sharp pain"]},
            {"step": 5, "tips": ["Count to maintain consistency", "Can do seated or standing"], "cautions": ["Don't exceed moderate tension"]},
            {"step": 6, "tips": ["Important for balanced development", "Prevents uneven stress"], "cautions": ["Equal rotations each direction"]},
            {"step": 7, "tips": ["Combines two effective techniques", "Feel for the stretch internally"], "cautions": ["Advanced move - master basics first"]},
            {"step": 8, "tips": ["Helps prevent torsion", "Massage lightly if needed"], "cautions": ["Monitor for any lasting twist"]}
        ]
    },
    "Cock Ring Training": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Silicone rings are beginner-friendly", "Measure for proper size"], "cautions": ["Avoid metal rings initially"]},
            {"step": 2, "tips": ["Trim hair to prevent pulling", "Use water-based lube"], "cautions": ["Must be 100% flaccid to start"]},
            {"step": 3, "tips": ["Ring behind balls gives most restriction", "Can use multiple rings"], "cautions": ["Should not cause pain"]},
            {"step": 4, "tips": ["Visual/physical stimulation both work", "Take your time"], "cautions": ["Remove if difficulty achieving erection"]},
            {"step": 5, "tips": ["Enhances size and hardness", "Great for partner play"], "cautions": ["Maximum 30 minutes continuous wear"]},
            {"step": 6, "tips": ["Color change is normal", "Veins more prominent is expected"], "cautions": ["Remove immediately if numbness or cold"]},
            {"step": 7, "tips": ["May need lube to remove", "Go slowly"], "cautions": ["Don't force - add more lube if stuck"]},
            {"step": 8, "tips": ["Clean with toy cleaner", "Store in clean, dry place"], "cautions": ["Replace if any tears or damage"]}
        ]
    },
    "Edging Practice": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Privacy essential for focus", "Comfortable temperature helps"], "cautions": ["Avoid if stressed or rushed"]},
            {"step": 2, "tips": ["Vary speed and pressure", "Focus on sensation"], "cautions": ["Don't death grip"]},
            {"step": 3, "tips": ["Learn your arousal levels", "Breathe deeply near edge"], "cautions": ["Going over occasionally is normal"]},
            {"step": 4, "tips": ["Complete stop or just slow down", "Squeeze technique can help"], "cautions": ["Don't be frustrated by accidents"]},
            {"step": 5, "tips": ["Count edges for progress tracking", "Quality over quantity"], "cautions": ["Stop if becoming desensitized"]},
            {"step": 6, "tips": ["Kegels during edges build control", "Reverse kegels help relax"], "cautions": ["Don't overdo PC muscle work"]},
            {"step": 7, "tips": ["Gets easier with practice", "Can increase session length gradually"], "cautions": ["Take rest days to prevent addiction"]},
            {"step": 8, "tips": ["Can finish or not - your choice", "Cold water helps if not finishing"], "cautions": ["Blue balls discomfort is temporary"]}
        ]
    },
    "Penis Extender Protocol": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Quality device worth investment", "Comfort strap better than noose"], "cautions": ["Avoid cheap knock-offs"]},
            {"step": 2, "tips": ["Follow manufacturer instructions", "Practice before first real session"], "cautions": ["Ensure all parts secure"]},
            {"step": 3, "tips": ["Baby powder helps with grip", "Ensure glans protected"], "cautions": ["Never attach to glans directly"]},
            {"step": 4, "tips": ["Start with least tension", "Gradually increase over weeks"], "cautions": ["Pain means too much tension"]},
            {"step": 5, "tips": ["Can wear under loose clothing", "Standing desk compatible"], "cautions": ["Take breaks every hour initially"]},
            {"step": 6, "tips": ["Build up time gradually", "4-6 hours optimal for gains"], "cautions": ["Don't sleep with device on"]},
            {"step": 7, "tips": ["Increase by small increments", "Log your settings"], "cautions": ["Plateau means need break, not more force"]},
            {"step": 8, "tips": ["Weekly measurements sufficient", "Photos help track progress"], "cautions": ["Don't measure daily - causes anxiety"]}
        ]
    },
    "Firegoat Rolls": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["30-50% ideal for this exercise", "Natural arousal better than porn"], "cautions": ["Too hard makes rolling difficult"]},
            {"step": 2, "tips": ["Table or counter height ideal", "Put towel down for hygiene"], "cautions": ["Ensure surface is smooth"]},
            {"step": 3, "tips": ["Use forearm or palm", "Start from base"], "cautions": ["Don't use excessive force initially"]},
            {"step": 4, "tips": ["Smooth continuous motion", "Count rolls for consistency"], "cautions": ["Stop if sharp pain"]},
            {"step": 5, "tips": ["Firm but not crushing pressure", "Should feel internal stretch"], "cautions": ["Reduce pressure if numbness"]},
            {"step": 6, "tips": ["50 rolls is good start", "Can work up to 200"], "cautions": ["Quality over quantity"]},
            {"step": 7, "tips": ["Normal to feel worked", "Similar to muscle fatigue"], "cautions": ["Numbness should resolve quickly"]},
            {"step": 8, "tips": ["Light stretches help recovery", "Warm wrap feels good"], "cautions": ["Skip next day if very sore"]}
        ]
    },
    "Fulcrum Stretches": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Marker, drumstick, or tube work", "Smooth surface important"], "cautions": ["Nothing sharp or rough"]},
            {"step": 2, "tips": ["OK grip most effective", "Use baby powder if needed"], "cautions": ["Don't grip glans directly"]},
            {"step": 3, "tips": ["Mid-shaft placement typical", "Can vary placement"], "cautions": ["Not too close to base"]},
            {"step": 4, "tips": ["Creates focused stress point", "Should feel deep stretch"], "cautions": ["Stop if sharp pain"]},
            {"step": 5, "tips": ["Breathe normally", "Count for consistency"], "cautions": ["Don't bounce or jerk"]},
            {"step": 6, "tips": ["Try different positions", "Find what works for you"], "cautions": ["Some angles may be too intense"]},
            {"step": 7, "tips": ["Important for balance", "Prevents uneven development"], "cautions": ["Equal time all directions"]},
            {"step": 8, "tips": ["Helps restore circulation", "Light massage beneficial"], "cautions": ["Check for any bruising"]}
        ]
    },
    "Horse Squeeze": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Oil or thick lube best", "Warm it up first"], "cautions": ["Too little risks skin damage"]},
            {"step": 2, "tips": ["Visual stimulation helps", "80% is perfect level"], "cautions": ["Never do at 100% erection"]},
            {"step": 3, "tips": ["Standard OK grip", "Firm but not death grip"], "cautions": ["Stop if pain"]},
            {"step": 4, "tips": ["Slow, deliberate movement", "Should see expansion"], "cautions": ["Don't rush the movement"]},
            {"step": 5, "tips": ["Creates intense expansion", "Should feel pump"], "cautions": ["Don't hold if painful"]},
            {"step": 6, "tips": ["Back to base resets", "Maintains blood flow"], "cautions": ["Full release important"]},
            {"step": 7, "tips": ["Start with 20-30", "Work up gradually"], "cautions": ["Quality over quantity"]},
            {"step": 8, "tips": ["Normal to see veins", "Temporary expansion expected"], "cautions": ["Stop if spots appear"]}
        ]
    },
    "Kegel Exercises": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Same muscle stops urine", "Practice finding it first"], "cautions": ["Don't practice during urination regularly"]},
            {"step": 2, "tips": ["Start lying down", "Progress to sitting/standing"], "cautions": ["Empty bladder first"]},
            {"step": 3, "tips": ["Like lifting elevator up", "Breathe normally"], "cautions": ["Don't tense other muscles"]},
            {"step": 4, "tips": ["Build up gradually", "Quality over duration"], "cautions": ["Don't overdo initially"]},
            {"step": 5, "tips": ["Complete relaxation important", "Prevents tension"], "cautions": ["Incomplete release causes problems"]},
            {"step": 6, "tips": ["Start with 10", "Build to 50+"], "cautions": ["Rest between sets"]},
            {"step": 7, "tips": ["Can do anywhere", "Traffic lights, meetings"], "cautions": ["Don't do if prostate issues"]},
            {"step": 8, "tips": ["Keep log of progress", "Combine with reverse kegels"], "cautions": ["Balance with reverse kegels"]}
        ]
    },
    "Manual Girth Squeezes": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Any quality lube works", "Warm it first"], "cautions": ["Don't use soap"]},
            {"step": 2, "tips": ["60-80% ideal range", "Maintain throughout"], "cautions": ["Never fully erect"]},
            {"step": 3, "tips": ["Fingers and thumb circle", "Like holding baseball bat"], "cautions": ["Not too tight"]},
            {"step": 4, "tips": ["Firm, steady pressure", "Should see expansion above grip"], "cautions": ["Stop if pain"]},
            {"step": 5, "tips": ["Watch clock or count", "Consistent timing important"], "cautions": ["Don't exceed time"]},
            {"step": 6, "tips": ["Blood flow restoration", "Prevents numbness"], "cautions": ["Full release necessary"]},
            {"step": 7, "tips": ["Feel the burn", "Similar to muscle workout"], "cautions": ["Stop if sharp pain"]},
            {"step": 8, "tips": ["Light massage helps", "Warm wrap beneficial"], "cautions": ["Check for spots or bruising"]}
        ]
    },
    "Modified Extreme Measures (MEM)": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Rice sock works great", "10 minutes minimum"], "cautions": ["Not too hot"]},
            {"step": 2, "tips": ["This is extreme - prepare mentally", "Have towel ready"], "cautions": ["Not for beginners"]},
            {"step": 3, "tips": ["Really push your limits", "Should be uncomfortable"], "cautions": ["Stop if sharp pain"]},
            {"step": 4, "tips": ["Complete release important", "Shake out tension"], "cautions": ["Don't skip rest"]},
            {"step": 5, "tips": ["Mental toughness required", "Breathe through it"], "cautions": ["Stop if feeling faint"]},
            {"step": 6, "tips": ["Cover all angles", "Systematic approach"], "cautions": ["Equal stress all directions"]},
            {"step": 7, "tips": ["Ice reduces inflammation", "10-15 minutes"], "cautions": ["Not directly on skin"]},
            {"step": 8, "tips": ["Recovery crucial", "May need 2-3 days off"], "cautions": ["Don't do daily"]}
        ]
    },
    "Length Pumping Protocol": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Length cylinders are longer/narrower", "Measure for proper fit"], "cautions": ["Too wide won't work for length"]},
            {"step": 2, "tips": ["Slow pump creation", "Watch gauge carefully"], "cautions": ["Stop if pain"]},
            {"step": 3, "tips": ["Lower pressure than girth pumping", "Should feel stretch not pain"], "cautions": ["Blisters from too much pressure"]},
            {"step": 4, "tips": ["Can read or watch TV", "Stay relaxed"], "cautions": ["Monitor for discoloration"]},
            {"step": 5, "tips": ["Helps prevent fluid buildup", "Restores circulation"], "cautions": ["Don't skip breaks"]},
            {"step": 6, "tips": ["Start with 3 sets", "Work up to 5"], "cautions": ["More isn't always better"]},
            {"step": 7, "tips": ["Slow, gradual increase", "Log your pressures"], "cautions": ["Plateau means rest needed"]},
            {"step": 8, "tips": ["Helps restore circulation", "Prevents fluid retention"], "cautions": ["Don't do intense exercise after"]}
        ]
    },
    "Reverse Kegels": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Opposite of regular kegel", "Like trying to pee faster"], "cautions": ["Don't actually urinate"]},
            {"step": 2, "tips": ["Lying down easiest", "Progress to other positions"], "cautions": ["Empty bladder first"]},
            {"step": 3, "tips": ["Gentle push out", "Like bearing down slightly"], "cautions": ["Don't strain hard"]},
            {"step": 4, "tips": ["Start with 2-3 seconds", "Build gradually"], "cautions": ["Don't hold breath"]},
            {"step": 5, "tips": ["Return to neutral", "Not contracted"], "cautions": ["Full relaxation important"]},
            {"step": 6, "tips": ["Less reps than regular kegels", "Quality focus"], "cautions": ["Don't overdo"]},
            {"step": 7, "tips": ["Throughout the day", "Balance with regular kegels"], "cautions": ["Avoid if hemorrhoids"]},
            {"step": 8, "tips": ["Helps prevent premature ejaculation", "Improves erection angle"], "cautions": ["Takes time to see benefits"]}
        ]
    },
    "Uli Exercise": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Small amount sufficient", "Oil-based lasts longer"], "cautions": ["Too much makes grip difficult"]},
            {"step": 2, "tips": ["90-95% ideal", "Maximum expansion"], "cautions": ["Never 100% erect"]},
            {"step": 3, "tips": ["Tight OK grip", "Traps blood effectively"], "cautions": ["Not cutting circulation completely"]},
            {"step": 4, "tips": ["Additional hand increases pressure", "Should see significant expansion"], "cautions": ["Stop if pain"]},
            {"step": 5, "tips": ["Watch clock", "Consistent timing"], "cautions": ["Never exceed 45 seconds beginner"]},
            {"step": 6, "tips": ["Blood flow restoration", "Prevents issues"], "cautions": ["Complete release required"]},
            {"step": 7, "tips": ["Start with 5", "Work to 10-15"], "cautions": ["Quality over quantity"]},
            {"step": 8, "tips": ["Veins prominent normal", "Temporary expansion expected"], "cautions": ["Stop if spots or bruising"]}
        ]
    },
    "Wet Jelq": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Generous amount needed", "Reapply as needed"], "cautions": ["Insufficient causes friction burn"]},
            {"step": 2, "tips": ["40-70% ideal range", "Adjust as needed"], "cautions": ["Never fully erect"]},
            {"step": 3, "tips": ["Behind glans best", "Firm but comfortable"], "cautions": ["Don't squeeze too hard"]},
            {"step": 4, "tips": ["2-3 second strokes", "Smooth motion"], "cautions": ["Don't rush"]},
            {"step": 5, "tips": ["Maintains circulation", "Prevents one-sided stress"], "cautions": ["Equal reps each hand"]},
            {"step": 6, "tips": ["Start with 100", "Build to 300-500"], "cautions": ["Stop if skin irritation"]},
            {"step": 7, "tips": ["Should feel worked", "Like muscle pump"], "cautions": ["Pain means stop"]},
            {"step": 8, "tips": ["Normal to hang fuller", "Veins may be prominent"], "cautions": ["Spots mean too intense"]}
        ]
    },
    "Ballooning Technique": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Learn your arousal levels", "Practice recognition"], "cautions": ["Takes time to master"]},
            {"step": 2, "tips": ["Near climax but not over", "Deep breathing helps"], "cautions": ["Going over is normal initially"]},
            {"step": 3, "tips": ["Complete stop best initially", "Can just slow later"], "cautions": ["Don't get frustrated"]},
            {"step": 4, "tips": ["Full relaxation", "Mental and physical"], "cautions": ["Incomplete relaxation reduces effectiveness"]},
            {"step": 5, "tips": ["Creates maximum engorgement", "Should feel very full"], "cautions": ["Don't force if not working"]},
            {"step": 6, "tips": ["Gets easier with practice", "Quality over quantity"], "cautions": ["Takes weeks to master"]},
            {"step": 7, "tips": ["Document what works", "Everyone different"], "cautions": ["Don't compare to others"]},
            {"step": 8, "tips": ["Can finish or not", "Blue balls temporary"], "cautions": ["Discomfort normal if not finishing"]}
        ]
    },
    "All Day Stretcher (ADS)": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Many devices available", "Comfort is key for all day wear", "Stealth important for public"], "cautions": ["Cheap devices can cause injury", "Check reviews thoroughly"]}
        ]
    },
    "ADS (All Day Stretcher)": {
        "steps_tips_cautions": [
            {"step": 1, "tips": ["Many devices available", "Comfort is key for all day wear", "Stealth important for public"], "cautions": ["Cheap devices can cause injury", "Check reviews thoroughly"]}
        ]
    }
}

def fetch_method_details(token: str, method_id: str) -> Dict:
    """Fetch detailed method data from Firestore"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{method_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response.json()
    return None

def update_method_with_tips(token: str, method_id: str, method_data: Dict, enhancements: Dict) -> bool:
    """Update a method with tips and cautions"""

    # Get the current document
    current_doc = fetch_method_details(token, method_id)
    if not current_doc:
        print(f"  ❌ Could not fetch {method_id}")
        return False

    # Extract current steps
    steps_field = current_doc.get("fields", {}).get("steps", {}).get("arrayValue", {}).get("values", [])

    # Update each step with tips and cautions
    updated_steps = []
    for i, step in enumerate(steps_field):
        step_map = step.get("mapValue", {}).get("fields", {})
        step_number = i + 1

        # Find matching enhancement
        enhancement = None
        for enh in enhancements.get("steps_tips_cautions", []):
            if enh["step"] == step_number:
                enhancement = enh
                break

        if enhancement:
            # Add tips if present
            if "tips" in enhancement and enhancement["tips"]:
                tips_array = {
                    "arrayValue": {
                        "values": [{"stringValue": tip} for tip in enhancement["tips"]]
                    }
                }
                step_map["tips"] = tips_array

            # Add cautions if present
            if "cautions" in enhancement and enhancement["cautions"]:
                cautions_array = {
                    "arrayValue": {
                        "values": [{"stringValue": caution} for caution in enhancement["cautions"]]
                    }
                }
                step_map["cautions"] = cautions_array

        updated_steps.append({"mapValue": {"fields": step_map}})

    # Prepare update request
    current_doc["fields"]["steps"] = {"arrayValue": {"values": updated_steps}}

    # Send update
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{method_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    response = requests.patch(url, headers=headers, json=current_doc)
    return response.status_code in [200, 204]

def main():
    print("🔧 Adding Tips and Cautions to PE Methods")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Process each method
    success_count = 0
    skip_count = 0
    fail_count = 0

    # Map method names to actual Firebase document IDs
    METHOD_ID_MAP = {
        "Weight Hanging": "hanging_weight",
        "Basic Manual Stretch": "basic_stretch",
        "Basic Jelq": "basic_jelq",
        "Bathmate Water Pump": "bathmate_pump",
        "BFR Clamping": "bfr_clamping",
        "Bundled Stretches": "bundled_stretches",
        "Cock Ring Training": "cock_ring_training",
        "Edging Practice": "edging",
        "Penis Extender Protocol": "extender_length",
        "Firegoat Rolls": "firegoat_rolls",
        "Fulcrum Stretches": "fulcrum_stretch",
        "Horse Squeeze": "horse_squeeze",
        "Kegel Exercises": "kegels",
        "Manual Girth Squeezes": "manuals_girth",
        "Modified Extreme Measures (MEM)": "mem_stretch",
        "Length Pumping Protocol": "pumping_length",
        "Reverse Kegels": "reverse_kegels",
        "Uli Exercise": "uli_exercise",
        "Wet Jelq": "wet_jelq",
        "Ballooning Technique": "ballooning",
        "All Day Stretcher (ADS)": "ads_all_day_stretcher",
        "ADS (All Day Stretcher)": "ads_device"
    }

    for method_name, enhancements in METHOD_ENHANCEMENTS.items():
        # Get the actual Firebase document ID
        method_id = METHOD_ID_MAP.get(method_name)
        if not method_id:
            print(f"\n📝 Processing: {method_name}")
            print(f"   ⚠️  No ID mapping found, skipping")
            skip_count += 1
            continue

        print(f"\n📝 Processing: {method_name}")
        print(f"   ID: {method_id}")

        # Check if method exists
        method_doc = fetch_method_details(token, method_id)
        if not method_doc:
            print(f"   ⏭️  Method not found, skipping")
            skip_count += 1
            continue

        # Update with tips and cautions
        if update_method_with_tips(token, method_id, method_doc, enhancements):
            print(f"   ✅ Successfully updated with tips and cautions")
            success_count += 1
        else:
            print(f"   ❌ Failed to update")
            fail_count += 1

    print("\n" + "=" * 50)
    print(f"📊 Summary:")
    print(f"   ✅ Successfully updated: {success_count}")
    print(f"   ⏭️  Skipped (not found): {skip_count}")
    print(f"   ❌ Failed: {fail_count}")
    print()
    print("✨ Tips and cautions have been added to enhance user safety and effectiveness!")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--dry-run":
        print("Dry run mode - showing what would be updated:")
        for method_name, enhancements in METHOD_ENHANCEMENTS.items():
            print(f"\n{method_name}:")
            for step_enh in enhancements.get("steps_tips_cautions", []):
                print(f"  Step {step_enh['step']}:")
                if "tips" in step_enh:
                    print(f"    Tips: {', '.join(step_enh['tips'][:1])}...")
                if "cautions" in step_enh:
                    print(f"    Cautions: {', '.join(step_enh['cautions'][:1])}...")
    else:
        main()