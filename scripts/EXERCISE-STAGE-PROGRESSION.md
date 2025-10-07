# PE Exercise Library - Stage Progression Guide

## Stage Assignment Philosophy

Exercises are assigned to stages based on **complexity, equipment requirements, risk level, and experience needed**. This ensures users progress safely from foundational techniques to advanced protocols.

---

## Stage 1: Beginner/Foundation (5 exercises)

**Criteria:** Manual methods, low risk, no devices, minimal time commitment

### Exercises:
1. **Basic Manual Stretch** (Beginner)
   - Pure manual technique
   - No equipment needed
   - Foundational length work
   - 25 minutes

2. **Modified Jelq** (Beginner)
   - Manual girth technique
   - Only requires lubricant
   - Foundational girth work
   - 20 minutes

3. **Timed Squash** (Beginner)
   - Manual conditioning
   - No equipment
   - Low intensity
   - 10 minutes

4. **Milking (EQ Focus)** (Beginner)
   - Gentle conditioning/EQ
   - No equipment
   - Very low risk
   - 8 minutes

5. **All-Day Stretcher (ADS)** (Beginner)
   - Passive length device
   - Minimal tension
   - Can be worn during daily activities
   - 4-8 hours (passive)

6. **Heat Application** (Beginner)
   - Adjuvant therapy
   - No PE technique knowledge required
   - Used as warm-up/cooldown
   - 10 minutes

---

## Stage 2: Intermediate (7 exercises)

**Criteria:** Device-based, moderate risk, requires some PE experience, 30-60 min sessions

### Exercises:
1. **Timed Pressure Hold (TPH)** (Intermediate)
   - Advanced manual stretching
   - Extended hold times (3-5 min)
   - Requires manual stretch experience
   - 20 minutes

2. **Static Pumping** (Intermediate)
   - First pumping protocol
   - Requires device knowledge
   - Pressure management critical
   - 30 minutes

3. **Vanilla Interval Pumping** (Intermediate)
   - Progression from static pumping
   - Interval training approach
   - Moderate complexity
   - 30 minutes

4. **Shopping Bag Hanger** (Intermediate)
   - Weight hanging protocol
   - Requires attachment device
   - Progressive weight addition
   - 30 minutes

5. **Vacuum Extending** (Intermediate)
   - Extended wear device
   - Comfortable for long sessions
   - Requires proper setup
   - 1-2 hours

6. **Shock Loading** (Intermediate)
   - Combination technique
   - Brief girth pre-fatigue before length
   - Requires understanding both girth and length work
   - 30 minutes

---

## Stage 3: Advanced/Expert (4 exercises)

**Criteria:** High intensity, significant risk, requires extensive PE experience, expert-level techniques

### Exercises:
1. **Rapid Interval Pumping (RIP)** (Advanced)
   - Aggressive pumping protocol
   - 30-second rapid intervals
   - Requires pumping experience
   - High vascular stress
   - 30 minutes

2. **Soft Clamping** (Advanced)
   - Blood restriction technique
   - HIGH RISK if done incorrectly
   - Strict 5-minute maximum
   - Requires significant experience
   - 15 minutes

3. **Pump-Assisted Clamping (PAC)** (Advanced)
   - **EXPERT-LEVEL** combination
   - Pumping + clamping together
   - HIGHEST injury risk
   - Requires mastery of both techniques separately
   - 20 minutes maximum

4. **Bundles with Pumping** (Advanced)
   - Rotational stretching + pumping
   - Complex multi-phase technique
   - Requires experience with both components
   - 30 minutes

---

## Stage Progression Requirements

### To Progress from Stage 1 → Stage 2:
- ✅ Minimum 4-6 weeks of consistent Stage 1 practice
- ✅ Comfortable with manual techniques
- ✅ Understanding of PE safety principles
- ✅ No injuries or adverse reactions
- ✅ Ready to commit to device-based training

### To Progress from Stage 2 → Stage 3:
- ✅ Minimum 8-12 weeks of Stage 2 practice
- ✅ Mastery of pumping OR clamping separately
- ✅ Excellent body awareness and safety monitoring
- ✅ Stable vascular health
- ✅ Understanding that Stage 3 carries significant risk
- ⚠️ **Many practitioners never need Stage 3 techniques**

---

## Safety Warnings by Stage

### Stage 1 Risks:
- Minor skin irritation
- Temporary soreness
- Minimal injury risk with proper technique

### Stage 2 Risks:
- Fluid buildup (donut effect) from pumping
- Temporary discoloration
- Skin blistering if overdone
- Moderate injury risk if safety guidelines ignored

### Stage 3 Risks:
- **SEVERE injury potential**
- Burst blood vessels (thrombosis)
- Prolonged discoloration
- Erectile dysfunction if overdone
- Nerve damage potential
- **Medical intervention may be required if injured**

---

## Classification vs. Stage

**Classification** (Beginner/Intermediate/Advanced) and **Stage** (1/2/3) are related but distinct:

- **Classification** = User experience level required
- **Stage** = Progression tier in the app's routine system

Example:
- **Basic Manual Stretch**: Stage 1, Beginner classification
- **Static Pumping**: Stage 2, Intermediate classification
- **RIP**: Stage 3, Advanced classification

This allows Stage 2 exercises to be filtered out from beginner routines while still being accessible to intermediate users.

---

## Deployment Notes

All exercises deployed to Firestore `growth_exercises` collection with:
- ✅ Proper stage assignments (1, 2, or 3)
- ✅ Classification tags (Beginner, Intermediate, Advanced)
- ✅ Complete safety notes with medical disclaimers
- ✅ Equipment requirements clearly specified
- ✅ Timer configurations for timed exercises
- ✅ Related method links for progression paths

**Total: 16 exercises across 3 stages**
- Stage 1: 6 exercises (Foundation)
- Stage 2: 7 exercises (Intermediate progression)
- Stage 3: 4 exercises (Advanced/Expert only)

---

## Implementation Date
**2025-10-07** - Initial deployment with corrected stage assignments
