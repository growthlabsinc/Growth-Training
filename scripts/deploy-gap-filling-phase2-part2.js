#!/usr/bin/env node

/**
 * Deploy Phase 2 Gap-Filling Knowledge (Part 2: Articles 3-5)
 *
 * Part 2 includes:
 * 3. Routine Planning & Customization
 * 4. Plateau Breaking Strategies
 * 5. Advanced Techniques (PAC, Clamping, Anti-LOX)
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/deploy-gap-filling-phase2-part2.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

// Standard medical disclaimer
const MEDICAL_DISCLAIMER = `**IMPORTANT MEDICAL DISCLAIMER:**

1. Penis enlargement exercises carry inherent risks including injury, pain, tissue damage, and erectile dysfunction
2. These techniques are NOT medically supervised or FDA-approved
3. Results vary significantly and are not guaranteed
4. STOP immediately if you experience pain, numbness, discoloration, or loss of sensation
5. Consult a healthcare provider before starting any PE program, especially if you have cardiovascular conditions, diabetes, or take blood thinners

This information is for educational purposes only and does not constitute medical advice.`;

// Phase 2 Articles (Part 2: Articles 3-5)
const PHASE_2_PART2_ARTICLES = [
  {
    id: 'routine_planning_customization',
    title: 'Routine Planning & Customization',
    category: 'routine',
    subcategories: ['beginner', 'intermediate', 'advanced', 'planning'],
    priority: 9,
    keywords: [
      'routine', 'schedule', 'plan', 'progression', 'customize', 'program',
      'beginner routine', 'intermediate routine', 'advanced routine',
      'length routine', 'girth routine', 'balanced', 'periodization',
      'training split', 'rest day', 'decon', 'cycle', 'mesocycle'
    ],
    content: `# Routine Planning & Customization

## Overview

Building an effective PE routine is both art and science. This guide teaches you how to design custom routines that match your goals, experience level, and schedule while maximizing gains and minimizing injury risk.

## Routine Building Principles

### 1. Progressive Overload
**Concept:** Gradually increase training stimulus over time

**Application in PE:**
- **Weeks 1-4:** Establish baseline (learn technique, build tissue conditioning)
- **Weeks 5-8:** Increase duration by 25-50%
- **Weeks 9-12:** Increase intensity (pressure, tension, speed)
- **Weeks 13-16:** Add volume (more sets, more exercises)
- **Repeat cycle at higher baseline**

**Example Progression (Jelqing):**
- Week 1-2: 5 minutes, 50 reps, light pressure
- Week 3-4: 7 minutes, 70 reps, light pressure
- Week 5-6: 10 minutes, 100 reps, medium pressure
- Week 7-8: 12 minutes, 120 reps, medium pressure
- Week 9-10: 15 minutes, 150 reps, medium-firm pressure

### 2. Specificity
**Concept:** Train specifically for your goals

**Length Goals:**
- Primary: Manual stretching, extending, hanging
- Secondary: Light jelqing for EQ, pumping for length
- Avoid: Heavy girth work (can impede length gains)

**Girth Goals:**
- Primary: Jelqing, pumping, clamping (advanced)
- Secondary: Light stretching for warm-up
- Avoid: Excessive length work (may reduce girth focus)

**Balanced Goals (Both Length & Girth):**
- Split focus: Alternate days or use AM/PM split
- Example: Stretching AM, jelqing PM
- Example: Length focus Mon/Wed/Fri, girth Tue/Thu/Sat

### 3. Recovery & Adaptation
**Concept:** Gains happen during recovery, not during training

**Rest Day Guidelines:**
- **Beginners:** 1-2 rest days per week minimum
- **Intermediate:** 1 rest day per week minimum
- **Advanced:** 1 rest day every 5-7 days, or active recovery

**Decon Breaks (Complete Rest):**
- **Frequency:** Every 12-16 weeks
- **Duration:** 5-10 days
- **Purpose:** Allow full tissue recovery, reset CNS, prevent chronic fatigue
- **Benefits:** Many report growth surge after decon (tissues "catch up")

### 4. Individual Response
**Concept:** Everyone responds differently

**High-Responders:**
- See gains within 2-3 months
- Can handle higher volume
- May need less intensity for results

**Low-Responders:**
- May take 6-12 months for first gains
- Need higher intensity or volume
- Benefit from technique optimization

**Finding Your Type:**
- Start with standard beginner routine
- Track response over 12 weeks
- Adjust based on results (more/less volume, intensity)

---

## Beginner Routines (0-3 Months Experience)

### Beginner Routine 1: Balanced (Length + Girth)

**Goals:** Build tissue conditioning, learn techniques, modest balanced gains

**Schedule:** 5-6 days per week, 20-25 minutes per session

**Routine:**
1. **Warm-up:** 5-10 minutes
   - Hot wrap (rice sock or warm towel)
   - Light massage

2. **Manual Stretching:** 5-7 minutes
   - Straight out: 30 seconds × 3 sets
   - Straight down: 30 seconds × 3 sets
   - Straight up: 30 seconds × 3 sets
   - Left/right: 30 seconds each × 2 sets

3. **Jelqing:** 5-10 minutes
   - 40-60% erection level
   - 50-100 reps (3-second strokes)
   - Light-medium pressure

4. **Warm-down:** 3-5 minutes
   - Warm wrap
   - Gentle massage

**Progression:**
- Week 1-2: 5 min jelqing (50 reps)
- Week 3-4: 7 min jelqing (70 reps)
- Week 5-8: 10 min jelqing (100 reps)
- Week 9-12: Progress to intermediate routine

### Beginner Routine 2: Girth Focus

**Goals:** Girth gains, EQ improvement

**Schedule:** 5 days per week, 20 minutes per session

**Routine:**
1. **Warm-up:** 5-10 minutes

2. **Light Stretching (warm-up only):** 3 minutes
   - Straight out: 20 seconds × 3 sets

3. **Jelqing:** 10-15 minutes
   - 40-70% erection level
   - 100-150 reps
   - Focus on girth (wider grip, slower strokes)

4. **Warm-down:** 5 minutes

**Progression:**
- Week 1-4: 10 min jelqing, 100 reps
- Week 5-8: 12 min jelqing, 120 reps, add wet jelqs
- Week 9-12: 15 min jelqing, 150 reps, increase pressure

### Beginner Routine 3: Length Focus

**Goals:** Length gains, ligament conditioning

**Schedule:** 6 days per week, 25 minutes per session

**Routine:**
1. **Warm-up:** 5-10 minutes

2. **Manual Stretching:** 12-15 minutes
   - Basic stretches: 5 minutes (as in Routine 1)
   - V-stretches: 2 minutes (10 reps)
   - A-stretches: 2 minutes (10 reps)
   - Rotary stretches: 3 minutes (30 sec each direction × 3)

3. **Light Jelqing (EQ maintenance):** 5 minutes
   - 60% erection, 50 reps, light pressure

4. **Warm-down:** 5 minutes

**Progression:**
- Week 1-4: 12 min stretching
- Week 5-8: 15 min stretching, add bundled stretches
- Week 9-12: Progress to intermediate or add extender

---

## Intermediate Routines (3-12 Months Experience)

### Intermediate Routine 1: Balanced with Equipment

**Goals:** Continued balanced gains, equipment integration

**Schedule:** 5-6 days per week, 40-50 minutes per session

**Routine:**
1. **Warm-up:** 5-10 minutes

2. **Manual Stretching:** 10 minutes
   - Include bundled stretches, JAI stretches

3. **Extending (if available):** 60-120 minutes
   - Throughout day (work, home)
   - Light-medium tension
   - 1-2 hour blocks with 15-min breaks

4. **Jelqing:** 15-20 minutes
   - 200-300 reps
   - Mix of techniques (standard, V-jelqs, horse squeezes)

5. **Pumping (optional, 2-3x per week):** 15 minutes
   - 3 sets × 5 minutes at 5-7 Hg
   - 2-minute breaks between sets

6. **Warm-down:** 5 minutes

**Progression:**
- Month 4-6: Establish routine, optimize technique
- Month 7-9: Increase extender time (2-4 hours daily)
- Month 10-12: Increase pump pressure (7-9 Hg) or add clamping prep

### Intermediate Routine 2: Girth Specialist

**Goals:** Maximum girth gains

**Schedule:** 5 days per week, 35-45 minutes per session

**Routine:**
1. **Warm-up:** 10 minutes (thorough warm-up critical for girth work)

2. **Pumping:** 20 minutes
   - 4 sets × 5 minutes at 5-9 Hg
   - 2-3 minute breaks between sets
   - Slow expansion focus

3. **Jelqing:** 15-20 minutes
   - 250-350 reps
   - Mix of wet/dry jelqs
   - Slower strokes (4-5 seconds each)
   - Focus on mid-shaft expansion

4. **Horse Squeezes (advanced intermediate):** 5 minutes
   - 10-15 reps, 15-30 second holds
   - Medium pressure

5. **Warm-down:** 5 minutes

**Progression:**
- Month 4-6: Master pumping technique, optimize pressure
- Month 7-9: Add horse squeezes, increase jelq volume
- Month 10-12: Prepare for clamping (if desired)

---

## Advanced Routines (12+ Months Experience)

### Advanced Routine 1: Clamping Protocol

**⚠️ REQUIRES 12+ MONTHS EXPERIENCE, EXCELLENT EQ, ZERO INJURY HISTORY**

**Goals:** Maximum girth expansion

**Schedule:** 4-5 days per week (requires more recovery), 45 minutes

**Routine:**
1. **Warm-up:** 10-15 minutes (critical for clamping safety)

2. **Pumping (pre-clamp expansion):** 10 minutes
   - 2 sets × 5 minutes at 7-9 Hg

3. **Clamping:** 15-20 minutes
   - Set 1: 5 minutes, light clamp
   - Rest: 10 minutes
   - Set 2: 7 minutes, medium clamp
   - Rest: 10 minutes
   - Set 3: 8-10 minutes, medium-firm clamp

4. **Post-Clamp Jelqing:** 5 minutes
   - Light jelqs to restore circulation

5. **Warm-down:** 10 minutes

**Safety Rules:**
- NEVER exceed 10 minutes per clamp set
- NEVER fall asleep clamped
- Remove immediately if numbness, coldness, dark purple
- Minimum 10-minute breaks between sets
- Take 2 rest days per week minimum

**Progression:**
- Month 1-2: 5 min sets only, light-medium clamp
- Month 3-4: Add 7-min second set
- Month 5+: Add 10-min third set (optional, not required)

### Advanced Routine 2: Length Intensive

**Goals:** Maximum length gains

**Schedule:** 6 days per week, equipment-dependent

**Routine:**
1. **Warm-up:** 10 minutes

2. **Extending:** 4-8 hours daily
   - Multiple 2-hour sessions throughout day
   - Medium-high tension
   - 15-minute breaks every 1-2 hours

3. **Manual Stretching (PM session):** 15 minutes
   - Bundled stretches
   - A-stretches
   - Rotary stretches
   - JAI stretches

4. **Hanging (optional, very advanced):** 20-30 minutes
   - 3-5 sets × 5-10 minutes
   - 5-10 lbs starting weight
   - 5-minute breaks between sets

5. **Warm-down:** 5-10 minutes

**Progression:**
- Increase extender time: 4hr → 6hr → 8hr over months
- Increase hanging weight: +1 lb every 4-8 weeks
- Focus on time under tension (TUT)

---

## Custom Routine Template

### Step 1: Define Your Goals

**Primary Goal:** (Check one)
- [ ] Length
- [ ] Girth
- [ ] Balanced (Both)
- [ ] EQ/Health

**Secondary Goals:** (Optional)
- [ ] Flaccid hang
- [ ] Curve correction
- [ ] Stamina/control

### Step 2: Assess Your Resources

**Time Available:**
- [ ] 15-20 min per day (minimalist routine)
- [ ] 30-45 min per day (standard routine)
- [ ] 60+ min per day (intensive routine)
- [ ] Can wear extender during day (adds 2-6 hours)

**Equipment Available:**
- [ ] None (manual only)
- [ ] Pump
- [ ] Extender
- [ ] Clamps (advanced only)
- [ ] Hanging setup (very advanced)

**Experience Level:**
- [ ] Beginner (0-3 months)
- [ ] Intermediate (3-12 months)
- [ ] Advanced (12+ months)

### Step 3: Build Your Routine

**Template:**

1. **Warm-up:** ___ minutes
   - Hot wrap, massage, or shower

2. **Primary Exercise (matches your goal):** ___ minutes
   - Length: Stretching or extending
   - Girth: Jelqing or pumping
   - Balanced: Mix

3. **Secondary Exercise:** ___ minutes
   - Complementary to primary goal

4. **Conditioning/EQ Work (optional):** ___ minutes
   - Light jelqing, edging, kegels

5. **Warm-down:** ___ minutes
   - Warm wrap, massage

**Total Time:** ___ minutes

### Step 4: Plan Progression

**Month 1-3:**
- Focus: Technique mastery, tissue conditioning
- Intensity: Light (50-60% max)
- Volume: Low-moderate

**Month 4-6:**
- Focus: Gradual intensity increase
- Intensity: Medium (60-75% max)
- Volume: Moderate

**Month 7-12:**
- Focus: Progressive overload
- Intensity: Medium-high (75-85% max)
- Volume: Moderate-high

**Month 13+:**
- Focus: Optimization, plateau breaking
- Intensity: Variable (periodization)
- Volume: Variable (periodization)

### Step 5: Schedule Rest & Recovery

**Rest Days:**
- Beginner: 2 days per week
- Intermediate: 1 day per week
- Advanced: 1 day per 5-7 days

**Decon Breaks:**
- Every 12-16 weeks
- Duration: 5-10 days
- Mark on calendar NOW

---

## Periodization for Advanced Trainers

### Linear Periodization

**Structure:** Gradually increase intensity over 12-16 weeks, then decon

**Example 16-Week Cycle:**
- Weeks 1-4: High volume, low intensity (conditioning)
- Weeks 5-8: Moderate volume, medium intensity (growth)
- Weeks 9-12: Low volume, high intensity (peak)
- Weeks 13-14: Very low volume, maintain (taper)
- Weeks 15-16: Decon break (rest)

### Undulating Periodization

**Structure:** Vary intensity throughout the week

**Example Weekly Split:**
- Monday: High intensity, low volume
- Tuesday: Rest or active recovery
- Wednesday: Medium intensity, medium volume
- Thursday: Rest
- Friday: High volume, low intensity
- Saturday: Medium intensity, medium volume
- Sunday: Rest

### Block Periodization

**Structure:** Focus blocks of 4-6 weeks, each with different emphasis

**Example 24-Week Plan:**
- Block 1 (Weeks 1-6): Volume accumulation (lots of time under tension)
- Block 2 (Weeks 7-12): Intensity (higher pressure, tension, weight)
- Block 3 (Weeks 13-18): Realization (optimize technique, peak performance)
- Block 4 (Weeks 19-20): Taper (reduce volume, maintain intensity)
- Block 5 (Weeks 21-22): Decon
- Block 6 (Weeks 23-24): Reintroduction (ease back into training)

---

## Common Routine Mistakes

### Mistake 1: Too Much Too Soon
**Problem:** Starting with 60-minute intensive routines
**Solution:** Start with 15-20 minutes, progress gradually

### Mistake 2: No Progression Plan
**Problem:** Same routine month after month
**Solution:** Increase duration, intensity, or volume every 2-4 weeks

### Mistake 3: Ignoring Recovery
**Problem:** Training 7 days per week with no rest
**Solution:** Minimum 1 rest day per week, decon every 3-4 months

### Mistake 4: Routine Hopping
**Problem:** Changing routine every 2 weeks
**Solution:** Stick with a routine for minimum 8-12 weeks before evaluating

### Mistake 5: Mismatched Goals & Exercises
**Problem:** Doing only jelqing for length gains
**Solution:** Match primary exercises to primary goals

### Mistake 6: Ignoring EQ
**Problem:** Pushing through declining EQ
**Solution:** EQ below 7/10 = reduce intensity or take rest days

---

## Sample Training Logs

### Beginner Log Template

**Week:** ___
**Goal:** ___

| Day | Warm-up | Stretching | Jelqing | Other | Warm-down | EQ Rating | Notes |
|-----|---------|------------|---------|-------|-----------|-----------|-------|
| Mon |         |            |         |       |           |    /10    |       |
| Tue |         |            |         |       |           |    /10    |       |
| Wed |         |            |         |       |           |    /10    |       |
| Thu |         |            |         |       |           |    /10    |       |
| Fri |         |            |         |       |           |    /10    |       |
| Sat |         |            |         |       |           |    /10    |       |
| Sun | REST    |            |         |       |           |    /10    |       |

**Weekly Average EQ:** ___ /10
**Consistency:** ___ / 7 days completed
**Next Week Adjustment:** ___

${MEDICAL_DISCLAIMER}

## Conclusion

Effective routine planning requires:
1. **Clear goals** (length, girth, or balanced)
2. **Appropriate exercises** (matched to goals)
3. **Progressive overload** (gradual intensity increase)
4. **Adequate recovery** (rest days, decon breaks)
5. **Consistent tracking** (logs, measurements, EQ monitoring)

Start simple, progress gradually, and adjust based on YOUR individual response. The best routine is the one you'll actually do consistently for months and years.`,
    medical_disclaimer: MEDICAL_DISCLAIMER,
    type: 'article',
    version: '1.0',
    language: 'en',
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp()
  },

  {
    id: 'plateau_breaking_strategies',
    title: 'Plateau Breaking Strategies',
    category: 'advanced',
    subcategories: ['plateau', 'stuck', 'gains', 'breakthrough'],
    priority: 8,
    keywords: [
      'plateau', 'stuck', 'gains stopped', 'break through', 'not growing',
      'stall', 'no progress', 'hit wall', 'overcome', 'shock',
      'decon', 'change routine', 'intensity', 'variation', 'cement gains'
    ],
    content: `# Plateau Breaking Strategies

## Understanding Plateaus

**Plateau:** Period of 8-12+ weeks with no measurable gains despite consistent training

**Why Plateaus Happen:**
1. **Adaptation:** Tissues adapt to stimulus, become resistant to current routine
2. **Insufficient Intensity:** What worked at beginner level may not work now
3. **Overtraining:** Chronic tissue fatigue preventing growth
4. **Technique Stagnation:** Not progressing or refining methods
5. **Physiological Limits:** Approaching genetic potential (rare before 2+ years)

**First: Confirm It's Actually a Plateau**

Before making changes, verify:
- [ ] Measuring consistently (same time, same method)
- [ ] Measuring at appropriate intervals (monthly, not weekly)
- [ ] Tracking EQ (maintained or improved = tissue is healthy)
- [ ] Training consistently (90%+ adherence)
- [ ] 8+ weeks since last measurable gain

**If EQ is declining:** NOT a plateau, it's overtraining - see "Troubleshooting" guide

---

## Strategy 1: Deconditioning Break (Most Effective)

### The Concept

**Decon Break:** Complete rest from ALL PE for 5-14 days

**Why It Works:**
- Allows full tissue recovery
- Resets nervous system adaptation
- Permits "catch-up" growth (tissues consolidate previous work)
- Many report growth surge during or immediately after decon

**When to Use:**
- After 12-16 weeks of consistent training
- When EQ is good but gains have stalled
- As planned periodic reset (every 3-4 months)

**How to Execute:**

**Days 1-3:**
- Complete rest, no PE, no edging, no stimulation beyond normal sex
- Focus on cardiovascular health (light cardio)
- Adequate sleep (8+ hours)
- Good nutrition (protein, vitamins, minerals)

**Days 4-7:**
- Continue rest
- May notice EQ improvement
- Possible temporary size reduction (blood flow normalization)
- Don't panic - this is normal

**Days 8-10 (Optional Extended Decon):**
- For stubborn plateaus or chronic fatigue
- Continue complete rest
- Many report feeling "recharged"

**Days 11-14 (Reintroduction):**
- Light sessions (50% intensity)
- Focus on EQ restoration
- Monitor tissue response

**Expected Results:**
- 60-70% report growth surge within 4 weeks of resuming
- Improved EQ (most common benefit)
- Renewed tissue responsiveness
- Psychological refresh (renewed motivation)

**Decon Schedule:**
- Minimum: Every 16 weeks (4 months)
- Optimal: Every 12 weeks (3 months)
- Aggressive trainers: Every 8-10 weeks

---

## Strategy 2: Intensity Variation (Shock Protocol)

### High-Intensity Shock Days

**Concept:** Periodically exceed normal intensity to shock tissues into responding

**Protocol:**

**Normal Training (4-5 days per week):**
- Standard intensity (60-75% max)
- Moderate volume

**Shock Day (1 day per week):**
- High intensity (80-90% max)
- Higher pressure, tension, or duration
- Maximum tissue stretch/expansion
- REQUIRES excellent EQ and tissue health

**Example Shock Day (Girth Focus):**
1. Extended warm-up: 15 minutes
2. Pumping: 4 sets × 7 minutes at 8-10 Hg (vs. normal 5-7 Hg)
3. Intense jelqing: 20 minutes, 300+ reps, firm pressure
4. Horse squeezes: 15 reps, 30-second holds
5. Extended warm-down: 10 minutes

**Safety Rules:**
- Only if EQ is consistently 8+/10
- Only if no injuries or pain
- Maximum 1 shock day per week
- Follow with rest day
- Monitor EQ closely (drop below 7/10 = dial back)

**Expected Results:**
- Tissues respond to novel stimulus
- May see temporary expansion
- Can "wake up" stalled growth
- Effective for 4-8 weeks before needing new variation

---

## Strategy 3: Exercise Variation

### Change Your Stimulus

**Principle:** Different exercises target different tissues/mechanisms

**If Plateaued with Jelqing:**
- Add pumping (different expansion mechanism)
- Try dry jelqs if doing wet (or vice versa)
- Vary jelq styles: V-jelqs, horse squeezes, slow squash jelqs
- Change erection level (40% vs. 70%)

**If Plateaued with Manual Stretching:**
- Add extending (continuous tension vs. intermittent)
- Try bundled stretches (rotational stress)
- Incorporate A-stretches, V-stretches (targeted ligs)
- Change angles (behind thighs, over shoulder)

**If Plateaued with Pumping:**
- Switch to clamping (different pressure dynamics)
- Try water pumping vs. air (or vice versa)
- Vary pressure protocols (intervals vs. static)
- Change cylinder size

**Exercise Rotation Protocol:**

**8-Week Block 1:** Focus Exercise A + Support Exercise B
**8-Week Block 2:** Focus Exercise C + Support Exercise D
**8-Week Block 3:** Return to Exercise A (with increased intensity)

**Example (Girth Plateau):**
- Block 1: Jelqing + Pumping
- Block 2: Clamping + Horse Squeezes
- Block 3: Return to Jelqing + Pumping (higher intensity/volume)

---

## Strategy 4: Volume Manipulation

### High Volume Phase

**Concept:** Dramatically increase training volume for 4-6 weeks

**Standard Routine:** 30 minutes, 5 days per week
**High Volume Phase:** 60 minutes, 6 days per week

**Example Implementation (Girth):**

**Week 1-2:**
- Jelqing: 30 minutes (400+ reps)
- Pumping: 30 minutes (6 sets × 5 min)
- Total: 60 minutes daily, 6 days per week

**Week 3-4:**
- Continue high volume
- Monitor EQ closely (drop = reduce immediately)

**Week 5-6:**
- Begin reducing volume (taper)
- Return to standard routine

**Week 7-8:**
- Normal routine or decon break
- Assess gains

**Expected Results:**
- Tissues forced to adapt to higher workload
- Growth stimulus increased
- Requires excellent recovery (sleep, nutrition)
- Not sustainable long-term (fatigue risk)

### Low Volume Phase

**Concept:** Reduce volume, maintain or increase intensity

**Standard Routine:** 30 minutes, 5 days per week
**Low Volume Phase:** 15 minutes, 3-4 days per week, HIGH intensity

**Why It Works:**
- Reduces chronic fatigue
- Allows full recovery between sessions
- High intensity provides growth stimulus
- Prevents adaptation to high volume

**Example (Length):**
- 3 days per week: 15 minutes maximum intensity stretching
- Rest days: Complete rest or light EQ work only
- Duration: 6-8 weeks

---

## Strategy 5: Targeted Weak Point Training

### Identify Your Limitation

**Base Girth vs. Mid-Shaft vs. Below Glans:**
- If base is limiting factor, focus clamping/pumping at base
- If mid-shaft lags, target mid-shaft jelqs
- If below glans is narrow, focus upper-shaft squeezes

**Length: Ligaments vs. Tunica:**
- If ligament-limited (tight when pulling), focus lig stretches (straight down, behind thighs)
- If tunica-limited (tough, resistant tissue), focus shaft stretches (straight out, rotational)

**Protocol:**
- 80% of training targets weak point
- 20% maintains other areas
- 6-8 weeks focused training
- Re-assess, adjust

**Example (Base Girth Weak Point):**
1. Warm-up: 10 min
2. Base-focused clamping: 15 min (clamp positioned low)
3. Base jelqs: 10 min (grip stays at base, push blood to base)
4. Regular jelqing: 5 min (maintenance)
5. Warm-down: 5 min

---

## Strategy 6: Supplement Stack (Supporting Strategy)

**Concept:** Optimize physiological conditions for growth

**Core Supplements for PE:**

1. **L-Citrulline (6-8g daily):**
   - Boosts nitric oxide production
   - Improves blood flow
   - Enhances EQ and pumps

2. **L-Arginine (3-5g daily):**
   - NO precursor
   - Synergistic with citrulline

3. **Vitamin D (2000-5000 IU daily):**
   - Testosterone support
   - Tissue health

4. **Zinc (30-50mg daily):**
   - Testosterone support
   - Collagen synthesis

5. **Vitamin C (1000mg daily):**
   - Collagen production
   - Tissue repair

6. **Magnesium (400mg daily):**
   - Muscle relaxation
   - Blood flow

**Optional Advanced:**
- Pycnogenol (100-200mg): Vascular health
- Fish oil (2-3g omega-3): Inflammation reduction
- CoQ10 (100-200mg): Cellular energy

**Timing:**
- Take L-Citrulline 30-60 min before training
- Take zinc/mag in evening (sleep support)
- Vitamin D with fat-containing meal

**Expected Results:**
- Improved EQ (primary benefit)
- Better tissue pliability
- Enhanced recovery
- NOT a magic bullet - supplements support, don't replace training

---

## Strategy 7: Technique Refinement

### Audit Your Form

**Jelqing Technique Checklist:**
- [ ] Correct erection level (40-70%)?
- [ ] Adequate lubrication?
- [ ] Proper grip (OK sign, firm but not death grip)?
- [ ] Full stroke (base to just below glans)?
- [ ] Appropriate duration (3-5 seconds per stroke)?
- [ ] Alternating hands smoothly?
- [ ] Maintaining consistent pressure throughout stroke?

**Common Jelqing Mistakes (Plateau Causers):**
- EQ too high (>80%): Less effective for growth
- EQ too low (<40%): Insufficient blood for expansion
- Rushing strokes (<2 seconds): Inadequate tissue stress
- Partial strokes: Missing tissue stimulation
- Inconsistent pressure: Some strokes effective, others wasted

**Stretching Technique Checklist:**
- [ ] Adequate warm-up before stretching?
- [ ] Full stretch (feeling pull in ligaments or shaft)?
- [ ] Holding 30+ seconds per stretch?
- [ ] Varying angles (not just one direction)?
- [ ] Progressive tension (increasing over weeks)?

**Solution:**
- Film yourself (for personal review)
- Post form check in PE communities
- Review technique guides every 3 months
- Try new variations to find what works for YOUR anatomy

---

## Strategy 8: Environmental & Lifestyle Optimization

### Factors Affecting Gains

**Sleep:**
- <7 hours: Impaired recovery, reduced testosterone
- 8-9 hours: Optimal for tissue repair and growth
- Fix: Strict sleep schedule, dark room, no screens 1hr before bed

**Stress:**
- Chronic stress: Elevated cortisol, reduced testosterone
- Impacts EQ and tissue recovery
- Fix: Meditation, exercise, stress management techniques

**Diet:**
- Insufficient protein: Impaired tissue repair
- Insufficient calories: No surplus for growth
- Fix: 0.8-1g protein per lb bodyweight, slight caloric surplus

**Cardiovascular Health:**
- Poor cardio: Reduced blood flow, weaker EQ
- Fix: 30 min moderate cardio 3-4x per week (walking, jogging, cycling)

**Body Fat:**
- High body fat: Reduced visible gains, hormonal impacts
- Fix: Fat loss reveals gains, improves EQ

**Alcohol:**
- Frequent consumption: Impairs recovery, reduces testosterone
- Fix: Limit to 1-2 drinks 1-2x per week maximum

---

## Plateau Decision Tree

**Start Here: Confirmed Plateau (8+ weeks, no gains, consistent training)**

**Step 1: Check EQ**
- EQ 8-10/10 → Proceed to Step 2
- EQ 7/10 or below → Not a plateau, it's overtraining. Take decon break, reduce intensity

**Step 2: How Long Have You Trained?**
- 3-6 months → Try Strategy 3 (Exercise Variation) or Strategy 7 (Technique Refinement)
- 6-12 months → Try Strategy 1 (Decon Break) + Strategy 2 (Intensity Variation)
- 12+ months → Try Strategy 1 (Decon Break) + Strategy 4 (Volume Manipulation)

**Step 3: Implement Strategy**
- Choose ONE strategy at a time
- Commit for 6-8 weeks minimum
- Track results

**Step 4: Evaluate Results**
- Gains resumed? → Continue with successful strategy
- No change? → Try different strategy
- EQ declined? → Reduce intensity, take rest

---

## Cementing Gains

**Concept:** Making temporary gains permanent

**Why Gains Can Be Lost:**
- Temporary tissue expansion (lymph, blood)
- Collagen remodeling incomplete
- Insufficient conditioning time

**Cementing Protocol:**

**After Gaining 0.25-0.5":**
1. **Reduce intensity to 70% for 4 weeks**
2. **Maintain volume (time/frequency)**
3. **Focus on EQ exercises** (light jelqing, edging)
4. **Continue warm-up/warm-down** (tissue health)
5. **Goal:** Give tissues time to stabilize at new size

**After Cementing Period:**
- Decon break (1 week)
- Remeasure
- If gains held: Resume progressive training
- If gains lost partially: Extend cementing to 6-8 weeks

---

## Long-Term Expectations

**Reality Check:**

**Months 0-6:** Tissue conditioning, technique learning, first gains (0.25-0.5")
**Months 6-12:** Consistent gains (0.25-0.5" per 6 months)
**Year 2:** Slower gains (0.25-0.5" per year), more effort required
**Year 3+:** Very slow gains, diminishing returns

**Most users see:**
- 0.5-1" length gain in first 2 years
- 0.5-1" girth gain in first 2 years
- Diminishing returns after

**Plateau Frequency:**
- Beginner year: 1-2 plateaus
- Year 2: 2-3 plateaus
- Year 3+: More frequent, longer duration

${MEDICAL_DISCLAIMER}

## Conclusion

Plateaus are normal and expected. Breaking through requires:
1. **Accurate diagnosis** (confirm it's actually a plateau, not overtraining)
2. **Strategic intervention** (choose appropriate strategy for your situation)
3. **Patience** (changes take 6-8 weeks to show results)
4. **Consistency** (don't routine-hop)

The most effective strategy for most people: Decon break + Resume with modified routine (new exercises or intensity variation). Try this first before complex protocols.`,
    medical_disclaimer: MEDICAL_DISCLAIMER,
    type: 'article',
    version: '1.0',
    language: 'en',
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp()
  }
];

// Due to length constraints, Article 5 (Advanced Techniques) will be in a separate minimal script
// This keeps each file manageable

/**
 * Deploy articles to Firestore
 */
async function deployArticles() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Deploy Phase 2 Gap-Filling (Part 2: Articles 3-4)        ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}\n`);

  const collection = db.collection('ai_coach_knowledge');
  let successCount = 0;
  let errorCount = 0;

  for (const article of PHASE_2_PART2_ARTICLES) {
    try {
      console.log(`📝 Deploying: ${article.title}`);
      console.log(`   ID: ${article.id}`);
      console.log(`   Category: ${article.category}`);
      console.log(`   Priority: ${article.priority}/10`);
      console.log(`   Keywords: ${article.keywords.length}`);
      console.log(`   Content Length: ${article.content.length.toLocaleString()} characters`);

      // Create searchable content
      const searchableContent = [
        article.title,
        article.category,
        ...article.subcategories,
        ...article.keywords,
        article.content
      ].join(' ').toLowerCase();

      const documentData = {
        ...article,
        searchableContent,
        content_text: article.content,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      };

      await collection.doc(article.id).set(documentData);

      console.log(`   ✅ Successfully deployed\n`);
      successCount++;

    } catch (error) {
      console.error(`   ❌ Error deploying ${article.title}:`, error.message);
      errorCount++;
    }
  }

  return { successCount, errorCount, totalArticles: PHASE_2_PART2_ARTICLES.length };
}

async function main() {
  try {
    console.log('⚙️  Initializing Firebase Admin SDK...\n');

    const results = await deployArticles();

    console.log('╔════════════════════════════════════════════════════════════╗');
    console.log('║  Deployment Summary (Part 2)                               ║');
    console.log('╚════════════════════════════════════════════════════════════╝\n');
    console.log(`✅ Successfully deployed: ${results.successCount} / ${results.totalArticles}`);
    console.log(`❌ Failed to deploy: ${results.errorCount} / ${results.totalArticles}\n`);

    if (results.successCount === results.totalArticles) {
      console.log('🎉 Phase 2 Part 2 articles deployed successfully!');
      console.log('📝 Note: Advanced Techniques article (Part 3) can be deployed separately if needed\n');
      process.exit(0);
    } else {
      console.log('⚠️  Some articles failed to deploy.\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Deployment failed:', error);
    process.exit(1);
  }
}

main();
