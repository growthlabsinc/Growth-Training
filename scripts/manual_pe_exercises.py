"""
Manual PE Exercises Database
Core exercises from the PE community with proper categorization
"""

MANUAL_PE_EXERCISES = [
    {
        "id": "basic_stretch",
        "name": "Basic Manual Stretch",
        "category": "Length",
        "difficulty": "Beginner",
        "description": "The fundamental length exercise using manual traction to promote tissue elongation.",
        "instructions": """1. Ensure completely flaccid state
2. Grip firmly behind the glans (head) with OK grip
3. Pull straight out with moderate tension (should feel stretch, not pain)
4. Hold for 30 seconds
5. Release and massage for 30 seconds
6. Repeat in different directions (up, down, left, right)
7. Total session: 5-10 minutes""",
        "duration": "5-10 minutes",
        "equipment": [],
        "warnings": [
            "Never grip the glans directly",
            "Stop if numbness or tingling occurs",
            "Avoid excessive force"
        ],
        "prerequisites": [],
        "source_type": "manual",
        "community_rating": 95
    },
    {
        "id": "wet_jelq",
        "name": "Wet Jelq",
        "category": "Girth",
        "difficulty": "Beginner",
        "description": "Classic girth exercise using lubrication for controlled blood flow manipulation.",
        "instructions": """1. Apply water-based lubricant generously
2. Achieve 40-60% erection level
3. Form OK grip at base of shaft
4. Slowly slide grip toward glans (3-4 seconds)
5. Stop before reaching glans
6. Release and repeat with alternating hands
7. Maintain consistent pressure throughout stroke
8. Session: 50-100 strokes initially, build up gradually""",
        "duration": "10-15 minutes",
        "equipment": ["Lubricant"],
        "warnings": [
            "Never jelq at 100% erection",
            "Stop if bruising or spots appear",
            "Avoid death grip pressure"
        ],
        "prerequisites": ["2 week conditioning period"],
        "source_type": "manual",
        "community_rating": 92
    },
    {
        "id": "bathmate_pump",
        "name": "Bathmate Water Pump",
        "category": "Girth",
        "difficulty": "Intermediate",
        "description": "Water-based vacuum pumping for temporary and permanent girth gains.",
        "instructions": """1. Fill pump with warm water in shower/bath
2. Insert flaccid or semi-erect penis
3. Create seal against pubic bone
4. Pump to create vacuum (3-5 pumps initially)
5. Hold for 3-5 minutes
6. Release pressure and remove
7. Massage for 2 minutes
8. Repeat 2-3 times per session
9. Monitor pressure - should feel stretch, not pain""",
        "duration": "15-20 minutes",
        "equipment": ["Bathmate pump", "Warm water"],
        "warnings": [
            "Start with minimal pressure",
            "Never exceed 20 minutes total",
            "Watch for fluid buildup (edema)"
        ],
        "prerequisites": ["4 weeks manual conditioning"],
        "source_type": "manual",
        "community_rating": 88
    },
    {
        "id": "bfr_clamping",
        "name": "BFR Clamping",
        "category": "Girth",
        "difficulty": "Advanced",
        "description": "Blood flow restriction for advanced girth development.",
        "instructions": """1. Achieve 90-95% erection
2. Apply cable clamp at base with padding
3. Tighten to restrict outflow (not inflow)
4. Maintain for 5-10 minutes maximum
5. Perform light jelqs or squeezes during session
6. Release immediately if numbness occurs
7. Massage thoroughly after removal
8. Limit to 2-3 sets per session""",
        "duration": "10-15 minutes total",
        "equipment": ["Cable clamp", "Padding material"],
        "warnings": [
            "ADVANCED ONLY - high injury risk",
            "Never exceed 10 minutes per set",
            "Monitor for coldness or discoloration"
        ],
        "prerequisites": ["6 months PE experience", "Conditioned tissues"],
        "source_type": "manual",
        "community_rating": 85
    },
    {
        "id": "kegels",
        "name": "Kegel Exercises",
        "category": "EQ",
        "difficulty": "Beginner",
        "description": "Pelvic floor strengthening for improved erection quality and control.",
        "instructions": """1. Locate PC muscle (stop urine mid-stream)
2. Contract PC muscle firmly
3. Hold for 5 seconds
4. Release for 5 seconds
5. Repeat 10-20 times
6. Perform 3-4 sets daily
7. Can be done anywhere, anytime
8. Progress to longer holds over time""",
        "duration": "5-10 minutes",
        "equipment": [],
        "warnings": [
            "Don't overdo - can cause tension",
            "Ensure full relaxation between reps"
        ],
        "prerequisites": [],
        "source_type": "manual",
        "community_rating": 98
    },
    {
        "id": "reverse_kegels",
        "name": "Reverse Kegels",
        "category": "EQ",
        "difficulty": "Beginner",
        "description": "Pelvic floor relaxation to balance muscle tone and improve blood flow.",
        "instructions": """1. Assume comfortable position
2. Instead of contracting, push out gently
3. Feel slight bulge in perineum area
4. Hold for 3-5 seconds
5. Return to neutral
6. Repeat 10-15 times
7. Focus on relaxation, not force
8. Practice alongside regular kegels""",
        "duration": "5 minutes",
        "equipment": [],
        "warnings": [
            "Use gentle pressure only",
            "Stop if straining occurs"
        ],
        "prerequisites": ["Master regular kegels first"],
        "source_type": "manual",
        "community_rating": 90
    },
    {
        "id": "edging",
        "name": "Edging Practice",
        "category": "Stamina",
        "difficulty": "Beginner",
        "description": "Arousal control training for improved stamina and EQ.",
        "instructions": """1. Begin stimulation to 70-80% arousal
2. Stop before point of no return
3. Allow arousal to decrease to 40-50%
4. Resume stimulation
5. Repeat cycle 4-5 times
6. Finish or stop completely
7. Focus on awareness of arousal levels
8. Practice 3-4 times per week""",
        "duration": "15-30 minutes",
        "equipment": ["Lubricant (optional)"],
        "warnings": [
            "Avoid excessive sessions",
            "Don't edge to exhaustion"
        ],
        "prerequisites": [],
        "source_type": "manual",
        "community_rating": 87
    },
    {
        "id": "extender_length",
        "name": "Penis Extender Protocol",
        "category": "Length",
        "difficulty": "Intermediate",
        "description": "Traction device usage for consistent length gains.",
        "instructions": """1. Secure base ring behind glans
2. Attach to extender cradle or noose
3. Adjust bars to comfortable stretch
4. Start with 1-2 hours daily
5. Build up to 4-6 hours over weeks
6. Take breaks every hour
7. Increase tension gradually (weekly)
8. Track measurements monthly""",
        "duration": "4-6 hours daily",
        "equipment": ["Penis extender device"],
        "warnings": [
            "Start with minimal tension",
            "Never sleep with device on",
            "Monitor for circulation issues"
        ],
        "prerequisites": ["2 weeks manual stretching"],
        "source_type": "manual",
        "community_rating": 91
    },
    {
        "id": "hanging_weight",
        "name": "Weight Hanging",
        "category": "Length",
        "difficulty": "Advanced",
        "description": "Gravitational traction using weights for length development.",
        "instructions": """1. Attach hanger behind glans (vacuum or compression)
2. Start with 2.5-5 lbs maximum
3. Hang for 20 minutes per set
4. Rest 10 minutes between sets
5. Perform 2-3 sets per session
6. Increase weight by 1-2 lbs monthly
7. Always warm up first
8. Use rice sock heating between sets""",
        "duration": "60-90 minutes",
        "equipment": ["Hanger device", "Weights", "Rice sock"],
        "warnings": [
            "ADVANCED - high injury potential",
            "Never exceed comfortable weight",
            "Stop if numbness occurs"
        ],
        "prerequisites": ["6+ months PE experience", "Conditioned ligaments"],
        "source_type": "manual",
        "community_rating": 86
    },
    {
        "id": "manuals_girth",
        "name": "Manual Girth Squeezes",
        "category": "Girth",
        "difficulty": "Intermediate",
        "description": "Targeted expansion exercises for girth development.",
        "instructions": """1. Achieve 80-90% erection
2. Grip base firmly with one hand
3. Grip below glans with other hand
4. Gently compress shaft between hands
5. Hold for 5-10 seconds
6. Release and massage
7. Repeat 10-15 times
8. Focus on expansion, not crushing""",
        "duration": "10-15 minutes",
        "equipment": [],
        "warnings": [
            "Avoid excessive pressure",
            "Stop if pain occurs",
            "Monitor for bruising"
        ],
        "prerequisites": ["4 weeks jelqing experience"],
        "source_type": "manual",
        "community_rating": 84
    },
    {
        "id": "bundled_stretches",
        "name": "Bundled Stretches",
        "category": "Length",
        "difficulty": "Intermediate",
        "description": "Rotational stretching for tunica development.",
        "instructions": """1. While flaccid, grip behind glans
2. Rotate penis 180-360 degrees
3. While rotated, pull outward
4. Hold stretch for 30 seconds
5. Slowly unwind rotation
6. Repeat in opposite direction
7. Perform 5-10 repetitions each way
8. Can combine with multiple rotation angles""",
        "duration": "10-15 minutes",
        "equipment": [],
        "warnings": [
            "Don't over-rotate",
            "Stop if sharp pain occurs",
            "Ensure good grip to prevent slipping"
        ],
        "prerequisites": ["2 weeks basic stretching"],
        "source_type": "manual",
        "community_rating": 83
    },
    {
        "id": "fulcrum_stretch",
        "name": "Fulcrum Stretches",
        "category": "Length",
        "difficulty": "Intermediate",
        "description": "Leveraged stretching using a fulcrum point for targeted expansion.",
        "instructions": """1. Use cylindrical object (rice sock, foam roller)
2. Place fulcrum at mid-shaft
3. Grip behind glans
4. Pull over fulcrum creating bend
5. Hold for 30-60 seconds
6. Move fulcrum to different positions
7. Work entire shaft length
8. Always maintain control of stretch""",
        "duration": "10-15 minutes",
        "equipment": ["Fulcrum object (rice sock, roller)"],
        "warnings": [
            "Avoid sharp bending angles",
            "Use soft fulcrum only",
            "Monitor for pain"
        ],
        "prerequisites": ["4 weeks manual stretching"],
        "source_type": "manual",
        "community_rating": 82
    },
    {
        "id": "uli_exercise",
        "name": "Uli Exercise",
        "category": "Girth",
        "difficulty": "Advanced",
        "description": "Extreme expansion exercise for advanced girth gains.",
        "instructions": """1. Achieve 95-100% erection
2. Grip very firmly at base
3. Squeeze and hold for 30 seconds
4. Focus on shaft expansion
5. Release and massage thoroughly
6. Rest 1-2 minutes
7. Repeat 3-5 times maximum
8. Limit to 2-3 times per week""",
        "duration": "10-15 minutes",
        "equipment": [],
        "warnings": [
            "VERY ADVANCED - high risk",
            "Never exceed 30 seconds",
            "Stop if discoloration occurs"
        ],
        "prerequisites": ["6+ months girth work", "Conditioned tissues"],
        "source_type": "manual",
        "community_rating": 79
    },
    {
        "id": "horse_squeeze",
        "name": "Horse Squeeze",
        "category": "Girth",
        "difficulty": "Advanced",
        "description": "Intense girth exercise combining compression and expansion.",
        "instructions": """1. Achieve 80-90% erection
2. Form OK grip at base
3. Form second OK grip at mid-shaft
4. Slowly compress hands together
5. Hold compression for 10 seconds
6. Release and massage
7. Repeat with different hand positions
8. Maximum 10 repetitions per session""",
        "duration": "10-15 minutes",
        "equipment": [],
        "warnings": [
            "ADVANCED technique only",
            "Risk of burst blood vessels",
            "Requires excellent tissue conditioning"
        ],
        "prerequisites": ["6+ months PE experience"],
        "source_type": "manual",
        "community_rating": 77
    },
    {
        "id": "ads_device",
        "name": "All Day Stretcher (ADS)",
        "category": "Length",
        "difficulty": "Intermediate",
        "description": "Low-tension traction worn throughout the day for consistent gains.",
        "instructions": """1. Attach ADS device per manufacturer
2. Set to light tension (1-2 lbs)
3. Wear for 2-4 hours initially
4. Build up to 6-8 hours daily
5. Take hourly bathroom breaks
6. Check circulation regularly
7. Remove if numbness occurs
8. Can wear under loose clothing""",
        "duration": "4-8 hours daily",
        "equipment": ["ADS device"],
        "warnings": [
            "Never sleep with ADS",
            "Monitor for circulation issues",
            "Start with minimal time"
        ],
        "prerequisites": ["2 weeks manual work"],
        "source_type": "manual",
        "community_rating": 89
    },
    {
        "id": "pumping_length",
        "name": "Length Pumping Protocol",
        "category": "Length",
        "difficulty": "Intermediate",
        "description": "Vacuum pumping specifically for length gains using narrow cylinder.",
        "instructions": """1. Use cylinder 0.25" wider than erect girth
2. Enter pump 50-70% erect
3. Pump to 3-5 HG pressure
4. Hold for 5 minutes
5. Release and massage 2 minutes
6. Repeat 3-4 times
7. Focus on length not girth
8. Track measurements after session""",
        "duration": "20-30 minutes",
        "equipment": ["Vacuum pump", "Length cylinder", "Gauge"],
        "warnings": [
            "Don't exceed 5 HG initially",
            "Watch for fluid buildup",
            "Stop if blisters form"
        ],
        "prerequisites": ["Understanding of vacuum levels"],
        "source_type": "manual",
        "community_rating": 85
    },
    {
        "id": "ballooning",
        "name": "Ballooning Technique",
        "category": "EQ",
        "difficulty": "Intermediate",
        "description": "Arousal-based exercise for improved erection quality and size.",
        "instructions": """1. Stimulate to 90% arousal
2. Stop direct stimulation
3. Massage areas around penis
4. Focus on perineum and base
5. Maintain high arousal without direct touch
6. Allow engorgement to maximize
7. Hold state for 10-15 minutes
8. Promotes blood flow capacity""",
        "duration": "15-20 minutes",
        "equipment": ["Lubricant (optional)"],
        "warnings": [
            "Don't edge to exhaustion",
            "Avoid blue balls"
        ],
        "prerequisites": ["Good arousal control"],
        "source_type": "manual",
        "community_rating": 81
    },
    {
        "id": "cock_ring_training",
        "name": "Cock Ring Training",
        "category": "Girth",
        "difficulty": "Beginner",
        "description": "Passive girth work using constriction rings for engorgement.",
        "instructions": """1. Achieve 70-80% erection
2. Apply silicone ring at base
3. Maintain light engorgement
4. Wear for 10-15 minutes maximum
5. Perform light jelqs with ring on
6. Remove if numbness occurs
7. Massage after removal
8. Use during sex for added girth""",
        "duration": "10-15 minutes",
        "equipment": ["Silicone cock ring"],
        "warnings": [
            "Never exceed 20 minutes",
            "Don't fall asleep with ring on",
            "Use proper sized ring"
        ],
        "prerequisites": [],
        "source_type": "manual",
        "community_rating": 76
    },
    {
        "id": "firegoat_rolls",
        "name": "Firegoat Rolls",
        "category": "Length",
        "difficulty": "Advanced",
        "description": "Aggressive rolling technique for length development.",
        "instructions": """1. Semi-erect state (30-50%)
2. Place penis on hard surface
3. Roll with palm applying pressure
4. Roll from base to glans
5. Use moderate downward force
6. Perform 50-100 rolls
7. Should feel internal stretch
8. Follow with light stretching""",
        "duration": "10-15 minutes",
        "equipment": ["Hard flat surface"],
        "warnings": [
            "Can cause temporary numbness",
            "Start with light pressure",
            "Not for beginners"
        ],
        "prerequisites": ["3+ months PE experience"],
        "source_type": "manual",
        "community_rating": 74
    },
    {
        "id": "mem_stretch",
        "name": "Modified Extreme Measures (MEM)",
        "category": "Length",
        "difficulty": "Advanced",
        "description": "High-intensity stretching protocol for breaking plateaus.",
        "instructions": """1. Warm up thoroughly (10 min)
2. Maximum intensity stretch for 1 minute
3. Hold at absolute limit
4. Release and shake out
5. Rest 30 seconds
6. Repeat 5 times per angle
7. Work all angles (up, down, left, right, straight)
8. Ice pack after session""",
        "duration": "20-30 minutes",
        "equipment": ["Rice sock heater", "Ice pack"],
        "warnings": [
            "EXTREME technique",
            "High injury risk",
            "Only for plateau breaking"
        ],
        "prerequisites": ["1+ year PE experience", "Hit plateau"],
        "source_type": "manual",
        "community_rating": 71
    }
]

def get_manual_exercises():
    """Return the manual PE exercises database"""
    return MANUAL_PE_EXERCISES

def get_exercises_by_category(category):
    """Get all exercises for a specific category"""
    return [ex for ex in MANUAL_PE_EXERCISES if ex['category'] == category]

def get_exercises_by_difficulty(difficulty):
    """Get all exercises for a specific difficulty level"""
    return [ex for ex in MANUAL_PE_EXERCISES if ex['difficulty'] == difficulty]