#!/usr/bin/env node

/**
 * Deploy Phase 2 Gap-Filling Knowledge to AI Coach Knowledge Base
 *
 * Phase 2 includes:
 * 1. Equipment Selection & Safety Guide
 * 2. Troubleshooting Common Problems
 * 3. Routine Planning & Customization
 * 4. Plateau Breaking Strategies
 * 5. Advanced Techniques (PAC, Clamping, Anti-LOX)
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/deploy-gap-filling-phase2.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

// Standard medical disclaimer for all PE content
const MEDICAL_DISCLAIMER = `**IMPORTANT MEDICAL DISCLAIMER:**

1. Penis enlargement exercises carry inherent risks including injury, pain, tissue damage, and erectile dysfunction
2. These techniques are NOT medically supervised or FDA-approved
3. Results vary significantly and are not guaranteed
4. STOP immediately if you experience pain, numbness, discoloration, or loss of sensation
5. Consult a healthcare provider before starting any PE program, especially if you have cardiovascular conditions, diabetes, or take blood thinners

This information is for educational purposes only and does not constitute medical advice.`;

// Phase 2 Gap-Filling Articles
const PHASE_2_ARTICLES = [
  {
    id: 'equipment_selection_safety_guide',
    title: 'Equipment Selection & Safety Guide',
    category: 'equipment',
    subcategories: ['beginner', 'safety', 'buying guide'],
    priority: 9,
    keywords: [
      'pump', 'extender', 'clamp', 'equipment', 'device', 'quality',
      'safety', 'beginner', 'buying', 'recommend', 'budget', 'cheap',
      'bathmate', 'vacutech', 'size genetics', 'phallosan', 'penis pump',
      'vacuum', 'gauge', 'cylinder', 'sleeve', 'comfort pad'
    ],
    content: `# Equipment Selection & Safety Guide

## Overview

Choosing quality equipment is crucial for safe and effective PE training. Poor equipment can lead to injury, wasted money, and discouragement. This guide covers beginner-friendly options, safety features, and quality vs. budget considerations.

## Equipment Categories

### 1. Penis Pumps (Vacuum Devices)

**What They Do:**
- Create negative pressure to draw blood into the penis
- Primarily used for girth training and EQ improvement
- Can be used for length when combined with extending techniques

**Essential Safety Features:**
- **Pressure Gauge:** MANDATORY - prevents over-pumping injury
- **Quick-Release Valve:** Allows rapid pressure release in emergencies
- **Quality Cylinder:** Medical-grade plastic, no seams or sharp edges
- **Comfort Pad:** Creates seal without pinching skin

**Recommended Beginner Pumps:**
- **Bathmate Hydromax** ($100-150): Water-based, beginner-friendly, good safety features
- **LA Pump** ($150-200): Medical-grade, excellent gauge, durable
- **Vacutech** ($200-300): Premium quality, medical-grade components

**Budget Options ($50-80):**
- Basic pumps with gauges from reputable sellers
- **MUST HAVE:** Pressure gauge (non-negotiable)
- Avoid: No-name Amazon pumps without gauges

**Cylinder Sizing:**
- Start with 1.5-2" wider than your erect girth
- Too wide = difficulty maintaining seal, less effective
- Too narrow = uncomfortable, limits expansion

### 2. Penis Extenders (Traction Devices)

**What They Do:**
- Apply continuous stretch for length gains
- Based on tissue expansion principles (proven in medical studies)
- Require 4-6 hours daily wear for results

**Essential Safety Features:**
- **Adjustable Tension:** Gradual progression capability
- **Comfort Straps/Cradle:** Prevents cutting circulation
- **Quality Rods:** Stainless steel, smooth threads
- **Proper Sizing:** Fits your current length without excessive compression

**Recommended Beginner Extenders:**
- **Phallosan Forte** ($300-400): Most comfortable, vacuum-based, can wear overnight
- **SizeGenetics** ($200-300): Classic design, proven results, good comfort
- **Quick Extender Pro** ($150-250): Budget-friendly, decent comfort

**Budget Options ($100-150):**
- Generic extenders with good reviews
- **MUST HAVE:** Comfort padding, adjustable tension
- Avoid: Metal-only designs that pinch

**Wearing Schedule (Beginner):**
- Week 1-2: 1-2 hours daily, minimal tension
- Week 3-4: 2-4 hours daily, light tension
- Month 2+: 4-6 hours daily, progressive tension
- ALWAYS take breaks every 1-2 hours to restore circulation

### 3. Clamps (Advanced Equipment)

**What They Do:**
- Restrict outflow while maintaining inflow for extreme girth expansion
- **HIGH RISK** - only for advanced users with 6+ months experience
- Can cause injury if used improperly

**Essential Safety Features:**
- **Quick-Release:** Must be able to remove in <5 seconds
- **Padding:** Prevents pinching and bruising
- **Proper Sizing:** Fits comfortably without excessive tightness

**Types:**
- **Cable Clamps:** Most common, adjustable, cheap ($5-10)
- **Silicone Rings:** Gentler, progressive restriction
- **Commercial Devices:** Purpose-built, expensive ($50-100)

**SAFETY RULES (NON-NEGOTIABLE):**
- Maximum 10 minutes clamped (beginners: 5 minutes)
- NEVER fall asleep with a clamp on
- Remove immediately if numbness, coldness, or discoloration occurs
- Minimum 10 minutes rest between sets
- NOT for beginners - requires established conditioning

### 4. Sleeves & Accessories

**Comfort Sleeves:**
- Silicone sleeves for extenders/pumps ($10-30)
- Reduce chafing and improve comfort
- Highly recommended for multi-hour sessions

**Heating Pads:**
- Rice sock (DIY, $0): Microwave 1-2 minutes
- Electric heating pad ($20-40): Consistent temperature
- IR lamp ($30-60): Penetrating heat for deep tissue

**Lubricants:**
- Water-based lube ($10-20): For jelqing, pumping, safe with silicone
- Coconut oil ($5-10): Natural, pleasant, NOT safe with latex

## Quality vs. Budget: What Matters

### Worth Spending On:
1. **Pressure Gauge** (pumps): Prevents injury - NOT optional
2. **Comfort Features** (extenders): 4-6 hours daily means comfort = consistency
3. **Medical-Grade Materials**: Reduce skin irritation and allergic reactions
4. **Warranty/Support**: Reputable companies stand behind products

### Safe to Go Budget:
1. **Cable Clamps**: $5 hardware store clamps work fine (with padding)
2. **Heating Pads**: DIY rice sock as effective as $50 IR lamp
3. **Lubricant**: Generic water-based lube works as well as premium
4. **Measuring Tape**: Dollar store tape measures accurately

### NEVER Cheap Out On:
1. **Pump Gauges**: Inaccurate gauges = injury risk
2. **Extender Comfort**: Cheap painful extender = won't wear it = no results
3. **Materials**: Toxic plastics, rough edges, poor seals = injuries

## Red Flags: Avoid These Products

❌ **Pumps without gauges** - Impossible to track safe pressure
❌ **"Miracle" devices** - Claims of 3" gains in 30 days
❌ **Extremely cheap clones** - Toxic materials, poor quality control
❌ **Devices without reviews** - No community feedback = risky
❌ **"As seen on TV"** - Usually overpriced, under-delivering
❌ **Electric/automatic pumps** - Hard to control, higher injury risk for beginners

## Beginner Equipment Recommendations by Budget

### Minimal Budget ($50-100):
- Basic pump with gauge ($50-80)
- DIY rice sock heating pad ($0-5)
- Water-based lubricant ($10)
- Soft measuring tape ($5)
- **Total:** ~$65-100

### Moderate Budget ($200-300):
- Quality pump (Bathmate or LA Pump) ($150-200)
- Basic extender or comfort sleeves ($50-100)
- Heating pad and lubricant ($30)
- **Total:** ~$230-330

### Optimal Beginner Setup ($400-500):
- Premium pump (Bathmate Hydromax) ($150)
- Comfortable extender (Phallosan or SizeGenetics) ($250-300)
- Accessories (heating, lube, sleeves) ($50)
- **Total:** ~$450-500

## Safety Checklists

### Before First Use (Any Equipment):
- [ ] Read ALL manufacturer instructions
- [ ] Inspect for defects, sharp edges, cracks
- [ ] Test quick-release mechanisms
- [ ] Have lubricant and warm-up supplies ready
- [ ] Set timer (prevent over-use)

### During Use (Pumps):
- [ ] Warm up 5-10 minutes before pumping
- [ ] Start at low pressure (3-5 Hg for beginners)
- [ ] Monitor pressure gauge constantly
- [ ] Stay under 7 Hg for first month
- [ ] Pump for 5-10 minutes maximum per set
- [ ] Take 5-minute breaks between sets
- [ ] Stop if pain, numbness, or discoloration

### During Use (Extenders):
- [ ] Warm up before applying
- [ ] Start with minimal tension
- [ ] Take 10-minute breaks every 1-2 hours
- [ ] Check circulation (should remain pink/normal color)
- [ ] Adjust if numbness, coldness, or discoloration
- [ ] Remove before sleep (unless using Phallosan specifically designed for overnight)

### During Use (Clamps - Advanced Only):
- [ ] 6+ months PE experience required
- [ ] Warm up thoroughly (10+ minutes)
- [ ] Achieve full erection before clamping
- [ ] Set timer for 5-10 minutes MAX
- [ ] Monitor color (should stay reddish, NOT purple/blue)
- [ ] Remove immediately if numbness or cold sensation
- [ ] NEVER exceed 10 minutes
- [ ] Minimum 10-minute rest between sets

## Maintenance & Longevity

### Cleaning (After EVERY Use):
- Pumps: Wash cylinder with warm soapy water, rinse thoroughly, air dry
- Extenders: Wipe down with antibacterial wipe, let air dry
- Clamps: Wash padding, dry completely before storage
- Sleeves: Wash with toy cleaner or mild soap, air dry

### Storage:
- Keep in cool, dry place (avoid humid bathrooms long-term)
- Store pumps upright to prevent seal degradation
- Keep extenders assembled to avoid losing parts
- Replace padding/sleeves every 6-12 months (hygiene)

### Replacement Schedule:
- Pump seals: Every 12-18 months (or when leaking)
- Extender straps: Every 6-12 months (or when worn)
- Clamp padding: Every 3-6 months (compression degrades)
- Lubricant: Replace when expired or contaminated

## Common Equipment Mistakes

### Mistake 1: Buying Too Much Too Soon
**Problem:** Overwhelming, expensive, unused equipment
**Solution:** Start with ONE device (pump OR extender), add more after 2-3 months of consistency

### Mistake 2: Cheapest Option Available
**Problem:** Poor quality = injury risk, wasted money when replacing
**Solution:** Mid-range proven products beat cheap clones

### Mistake 3: No Pressure Gauge
**Problem:** MOST COMMON cause of pump injuries
**Solution:** NEVER use a pump without a working gauge - non-negotiable

### Mistake 4: Wrong Size Cylinder/Extender
**Problem:** Ineffective at best, painful/injurious at worst
**Solution:** Measure accurately, size up when between sizes

### Mistake 5: Skipping Warm-Up
**Problem:** Increased injury risk, reduced effectiveness
**Solution:** ALWAYS warm up 5-10 minutes before equipment use

## When to Upgrade Equipment

### Signs You've Outgrown Your Pump:
- Cylinder fills completely (girth expansion maxed)
- Consistently hitting max pressure safely
- Using 15+ minutes per session regularly
- 3+ months consistent use with good EQ

### Signs You've Outgrown Your Extender:
- Rods fully extended (no more room to increase tension)
- Comfortable at max tension for 4+ hours
- 6+ months consistent use
- Documented length gains plateauing

### When to Add New Equipment:
- After 3+ months consistency with first device
- When you have clear goals (e.g., add extender to pump routine for balanced gains)
- When current equipment limitations are hindering progress
- When you can afford quality (not budget) version

## Community-Vetted Brands

### Pumps:
- ✅ Bathmate (most popular, good quality-to-price)
- ✅ LA Pump (medical-grade, excellent gauges)
- ✅ Vacutech (premium, clinical quality)
- ⚠️ Penomet (mixed reviews, some users love it)

### Extenders:
- ✅ Phallosan Forte (most comfortable, expensive)
- ✅ SizeGenetics (proven track record, good support)
- ✅ Quick Extender Pro (budget-friendly option)
- ⚠️ Penimaster Pro (good but very expensive)

### Clamps:
- ✅ Standard cable clamps (hardware store, add padding)
- ✅ UltimateClamping.com clamps (purpose-built)
- ⚠️ Commercial "ED rings" (often too weak for PE clamping)

${MEDICAL_DISCLAIMER}

## Conclusion

Quality equipment is an investment in safety and results. Prioritize:
1. **Safety features** (gauges, quick-release, comfort)
2. **Proven brands** with community feedback
3. **Appropriate sizing** for your current measurements
4. **One device at a time** until you establish consistency

Start conservatively, progress gradually, and upgrade when you've proven you'll use it consistently. The best equipment is the equipment you'll actually use safely every day.`,
    medical_disclaimer: MEDICAL_DISCLAIMER,
    type: 'article',
    version: '1.0',
    language: 'en',
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp()
  },

  {
    id: 'troubleshooting_common_problems',
    title: 'Troubleshooting Common Problems',
    category: 'troubleshooting',
    subcategories: ['beginner', 'intermediate', 'safety', 'injury prevention'],
    priority: 9,
    keywords: [
      'problem', 'help', 'troubleshoot', 'fix', 'issue', 'solution',
      'not working', 'no gains', 'pain', 'injury', 'eq drop', 'hard flaccid',
      'discoloration', 'numbness', 'turtle', 'retraction', 'red spots',
      'bruising', 'swelling', 'edema', 'lymph', 'thrombosed vein'
    ],
    content: `# Troubleshooting Common PE Problems

## Overview

This guide addresses the most common problems PE practitioners encounter, from minor setbacks to serious warning signs. Learn to identify issues early, implement solutions, and know when to stop training.

## Problem Category Index

1. **No Results/Slow Progress** (most common)
2. **Pain & Discomfort** (technique issues)
3. **Injury Warning Signs** (STOP training)
4. **EQ Problems** (erectile quality decline)
5. **Skin Issues** (discoloration, spots, bruising)
6. **Equipment Problems**
7. **Psychological/Motivation Issues**

---

## 1. No Results / Slow Progress

### Problem: "I've been training for 2-3 months with no gains"

**Diagnosis Checklist:**
- [ ] Are you measuring consistently (same time, same method)?
- [ ] Are you taking progress photos?
- [ ] Are you tracking sessions (consistency)?
- [ ] Are you progressively increasing intensity?
- [ ] Is your EQ maintained or improved?

**Common Causes:**

**A. Inconsistent Training**
- **Issue:** Missing 3+ sessions per week
- **Solution:** Treat PE like gym - 5-6 days/week minimum
- **Goal:** 90% adherence over 8-12 weeks before expecting visible results

**B. Insufficient Intensity**
- **Issue:** Staying at beginner intensity for months
- **Solution:** Progressive overload - increase time, pressure, or sets every 2-4 weeks
- **Example:** Jelqing 5 min → 10 min → 15 min over 8 weeks

**C. Poor Technique**
- **Issue:** Incorrect erection level, grip, or form
- **Solution:** Review technique guides, post form check in r/GettingBigger
- **Common mistakes:** Too high EQ for jelqing (should be 40-70%), rushing strokes

**D. Unrealistic Timeline Expectations**
- **Issue:** Expecting results in weeks instead of months
- **Reality:** First measurable gains typically 3-6 months, visible gains 6-12 months
- **Solution:** Focus on EQ improvement (comes first), then size

**E. Wrong Routine for Goals**
- **Issue:** Doing length work when wanting girth (or vice versa)
- **Solution:** Match routine to goals:
  - **Length:** Stretching, extending, hanging
  - **Girth:** Jelqing, pumping, clamping
  - **Both:** Balanced routine with both modalities

**F. Poor Recovery**
- **Issue:** Overtraining, insufficient rest days
- **Solution:** Take 1-2 rest days per week, decon break every 3-4 months
- **Signs of overtraining:** Declining EQ, persistent fatigue, harder to achieve erection

**Solutions:**

1. **Audit Your Routine:**
   - Track every session for 2 weeks
   - Calculate actual adherence percentage
   - Identify patterns (skipping certain days, rushing sessions)

2. **Measure Properly:**
   - BPEL (bone-pressed erect length): Ruler pressed to pubic bone, measure along top
   - EG (erect girth): Tape measure at mid-shaft, fully erect
   - Same time of day (morning = most consistent)
   - Same method every time
   - Photos from same angle/distance
   - Measure every 4 weeks (not weekly - obsessing backfires)

3. **Progressive Overload Plan:**
   - Week 1-4: Establish baseline (consistent technique, low intensity)
   - Week 5-8: Increase time by 25-50%
   - Week 9-12: Increase intensity (pressure, stretch tension)
   - Repeat cycle

4. **Patience Mindset:**
   - Set 6-month minimum expectation
   - Focus on process goals (consistency) not outcome goals (size)
   - Celebrate EQ improvements (they come before size)

---

## 2. Pain & Discomfort

### Problem: "I feel pain during or after sessions"

**⚠️ PAIN IS A WARNING SIGNAL - NEVER TRAIN THROUGH PAIN**

**Types of Pain:**

**A. Sharp/Acute Pain (STOP IMMEDIATELY)**
- **Characteristics:** Sudden, intense, localized
- **Causes:** Tissue tear, nerve compression, ligament strain
- **Action:**
  1. STOP training immediately
  2. Apply cold compress (20 min)
  3. Rest minimum 1 week
  4. If pain persists >3 days, see doctor
  5. When resuming, reduce intensity by 50%

**B. Dull Ache (Warning - Reduce Intensity)**
- **Characteristics:** General soreness, similar to muscle fatigue
- **Causes:** Overtraining, insufficient warm-up, too much intensity
- **Action:**
  1. Take 2-3 rest days
  2. Reduce intensity by 25-30%
  3. Increase warm-up time to 10-15 minutes
  4. Focus on EQ recovery (no PE, only gentle EQ work)

**C. Skin Discomfort (Technique Issue)**
- **Characteristics:** Chafing, burning, surface irritation
- **Causes:** Insufficient lubricant, too much friction, grip too tight
- **Action:**
  1. Use more lubricant (generous amount)
  2. Reduce grip pressure (should slide smoothly, not drag)
  3. Check technique (grip too tight or wrong hand position)
  4. Consider break (24-48 hours) to let skin recover

**Common Pain Scenarios:**

**Scenario 1: Base Pain During Stretching**
- **Cause:** Lig stress (normal if mild, concerning if sharp)
- **Fix:** Warm up longer (10 min), stretch at lower intensity, progress slower
- **When to worry:** Sharp pain, persists after session, gets worse over time

**Scenario 2: Head/Glans Pain**
- **Cause:** Excessive pressure, poor circulation, grip too close to glans
- **Fix:** Grip 1" below glans, reduce pressure/intensity, shorter sets
- **When to worry:** Numbness, discoloration, lasts >1 hour post-session

**Scenario 3: Shaft Pain During Jelqing**
- **Cause:** EQ too high (>70%), grip too tight, wrong stroke angle
- **Fix:** Reduce EQ to 40-60%, lighter grip, straight stroke (not angled)
- **When to worry:** Pain during every stroke, dark bruising, lumps

---

## 3. Injury Warning Signs (STOP ALL TRAINING)

### 🚨 RED FLAGS - Stop Training & See Doctor If:

1. **Thrombosed Vein (Hard Lump on Shaft)**
   - Feels like a cord or bead under skin
   - May be painful or painless
   - **Action:** STOP all PE, see urologist within 1 week
   - **Recovery:** 4-8 weeks complete rest usually required

2. **Severe Discoloration (Dark Purple/Black)**
   - Normal: Light purple/red (temporary blood pooling)
   - Concerning: Dark purple, doesn't fade in 24 hours
   - **Action:** STOP, ice 20 min, see doctor if persists >2 days

3. **Numbness or Loss of Sensation**
   - Mild tingling after pumping: Common, should fade in 30 min
   - Persistent numbness >1 hour: Nerve compression
   - **Action:** STOP immediately, do not resume until full sensation returns (may take days to weeks)

4. **Hard Flaccid Syndrome**
   - Penis feels hard/rigid even when flaccid
   - Difficulty achieving erection or maintaining
   - Pelvic floor tension/pain
   - **Action:** STOP all PE immediately, see pelvic floor physical therapist

5. **Inability to Achieve Erection**
   - Temporary ED for a few hours: Take rest day
   - ED lasting >24 hours: Overtraining or injury
   - **Action:** Rest 1 week minimum, see doctor if persists

6. **Peyronie's Disease Signs (Curvature/Hard Plaque)**
   - New curvature during erection
   - Hard spot/plaque in shaft
   - Pain during erection
   - **Action:** STOP PE, see urologist - early treatment critical

---

## 4. EQ (Erectile Quality) Problems

### Problem: "My erections are weaker since starting PE"

**EQ Decline is THE MOST IMPORTANT indicator of overtraining**

**EQ Rating Scale (Track Weekly):**
- **EQ 10/10:** Rock hard, maintain easily, morning wood strong
- **EQ 7-9/10:** Firm, maintain with stimulation, normal
- **EQ 5-6/10:** Adequate for sex but not maximally hard
- **EQ 3-4/10:** Difficulty maintaining, requires constant stimulation
- **EQ 0-2/10:** Barely achievable, cannot maintain, no morning wood

**If EQ Drops Below 7/10:**

**Immediate Actions:**
1. **Take 3-5 rest days** (no PE at all)
2. **Light cardio** (20-30 min walking/jogging daily)
3. **Kegel exercises** (3 sets of 10, 5-sec holds, daily)
4. **Reduce stress** (sleep 8+ hours, limit alcohol)
5. **Check diet** (adequate zinc, vitamin D, healthy fats)

**When Resuming:**
1. Start at 50% intensity
2. Shorter sessions (5-10 min instead of 15-20)
3. Focus on EQ-boosting exercises (light jelqing at 60-70% EQ)
4. Add extra rest day per week
5. Monitor EQ for 2 weeks before increasing intensity

**EQ Recovery Routine (Use Instead of Regular PE):**
- **Warm-up:** 10 minutes
- **Light edging:** 5-10 minutes at 70-80% EQ (no ejaculation)
- **Light jelqing:** 50-100 reps at 60% EQ, very light pressure
- **Warm-down:** 5 minutes
- **Goal:** Pump blood through tissue without stressing it

**Long-Term EQ Protection:**
- Always include 1-2 rest days per week
- Decon break (1-2 weeks off) every 12-16 weeks
- Prioritize EQ over size gains (EQ drops = reduce intensity)
- Cardio 3-4x per week (strong cardiovascular health = strong EQ)
- Pelvic floor exercises (kegels + reverse kegels for balance)

---

## 5. Skin Issues

### Problem: Red Spots, Bruising, Discoloration

**A. Red Dots/Petechiae (Small Red Spots)**
- **Cause:** Burst capillaries from pressure/suction
- **Severity:** Minor if few and fade in 2-4 days
- **Fix:** Reduce pressure/intensity by 25%, more gradual warm-up
- **When to worry:** Covering large area, not fading, getting worse

**B. Bruising (Purple/Dark Patches)**
- **Cause:** Blood pooling from excessive pressure or trauma
- **Severity:** Moderate - indicates overtraining
- **Fix:**
  - STOP training until bruise fades (1-2 weeks)
  - Ice first 24 hours (20 min on/off)
  - Arnica cream or vitamin K cream
  - When resuming, reduce intensity 50%

**C. Temporary Discoloration (Purple Tint After Pumping)**
- **Cause:** Blood trapped in surface tissues
- **Severity:** Normal if fades within 24 hours
- **Fix:** Stay under 7 Hg pressure, limit session to 10-15 min, more frequent breaks
- **Prevention:** Gradually build up pumping duration and pressure over weeks

**D. Permanent Discoloration (Dark Skin Tone Change)**
- **Cause:** Chronic pressure, repeated bruising, melanin response
- **Severity:** Cosmetic issue, permanent or semi-permanent
- **Prevention:**
  - Never exceed safe pressure (7-10 Hg max)
  - Limit clamping sets to 10 min max
  - Adequate rest between sets
  - Vitamin C + sunscreen (may help prevent)
- **Treatment:** Often fades over 6-12 months if you stop aggressive techniques
- **Note:** More common in darker skin tones

**E. Lymph Buildup/Edema (Donut Effect)**
- **Cause:** Pumping too long or too high pressure
- **Appearance:** Soft, squishy ring around corona or under skin
- **Severity:** Harmless but unsightly, reduces over time
- **Fix:**
  - Reduce pump time to 5-10 min sets
  - Lower pressure (stay under 5 Hg for a while)
  - Massage gently to promote lymph drainage
  - Kegel exercises
  - Usually resolves in 24-48 hours
- **Prevention:** Stay under 10 min per pump set, adequate pressure breaks

---

## 6. Equipment Problems

### Problem: Equipment Not Working as Expected

**A. Pump Not Building Pressure**
- **Cause:** Seal leak, valve failure, crack in cylinder
- **Fix:**
  - Check seal (replace if worn)
  - Test valve (should hold pressure)
  - Inspect cylinder for cracks
  - Replace faulty component or pump

**B. Extender Slipping/Won't Stay On**
- **Cause:** Wrong size, insufficient comfort strap, too much tension too soon
- **Fix:**
  - Size down cylinder or adjust straps
  - Add comfort sleeve
  - Reduce tension (you should be able to wear 1-2 hours minimum)
  - Shave base area (hair interferes with grip)

**C. Clamp Won't Release / Gets Stuck**
- **Cause:** Over-tightening, mechanism failure
- **Fix:**
  - Practice quick-release when NOT clamped
  - Never tighten more than you can release one-handed
  - Keep backup scissors nearby for emergencies
  - Replace clamps with worn mechanisms

---

## 7. Psychological & Motivation Issues

### Problem: "I'm losing motivation / Can't stay consistent"

**Common Psychological Barriers:**

**A. Body Dysmorphia**
- **Issue:** Obsessing over millimeters, measuring daily, never satisfied
- **Fix:**
  - Limit measuring to once per month
  - Hide ruler between measurements
  - Focus on functional improvements (EQ, stamina)
  - Consider therapy if obsessive thoughts interfere with daily life

**B. Comparison to Others**
- **Issue:** Seeing others' gains on Reddit, feeling inadequate
- **Fix:**
  - Remember: Survivorship bias (people with gains post more)
  - Genetics vary - some gain faster, some slower
  - Focus on YOUR progress, not others'
  - Celebrate small wins (EQ improvement, consistency streaks)

**C. Burnout from Overtraining**
- **Issue:** PE becomes a chore, dreading sessions
- **Fix:**
  - Take a decon break (1-2 weeks complete rest)
  - Reduce frequency (5 days → 3-4 days per week)
  - Simplify routine (complex 45-min routine → simple 15-min routine)
  - Reconnect with your "why" (goals, motivations)

**D. Partner/Privacy Concerns**
- **Issue:** Difficulty finding time/privacy for sessions
- **Fix:**
  - Morning routine before others wake
  - Bathroom sessions (15 min possible)
  - Portable equipment (extender under clothes, discrete pumps)
  - Communication with partner (if appropriate)

---

## Decision Flowchart: Should I Stop Training?

**Start Here:**

1. **Are you experiencing ANY of these?**
   - Sharp pain
   - Numbness lasting >1 hour
   - Dark discoloration not fading
   - Hard lump on shaft
   - Inability to achieve erection
   - **YES → STOP TRAINING IMMEDIATELY, SEE DOCTOR**
   - NO → Continue to #2

2. **Is your EQ declining (below 7/10)?**
   - **YES → Take 3-5 rest days, follow EQ recovery routine**
   - NO → Continue to #3

3. **Are you seeing red spots, bruising, or lymph buildup?**
   - **YES → Reduce intensity 25-50%, improve technique**
   - NO → Continue to #4

4. **Have you been training 3+ months with zero progress?**
   - **YES → Audit routine, increase intensity, check consistency**
   - NO → Continue to #5

5. **Is your motivation/consistency suffering?**
   - **YES → Simplify routine, take decon break, reconnect with goals**
   - NO → Continue training safely!

---

## When to Seek Professional Help

**See a Doctor/Urologist If:**
- Pain persists >1 week
- New curvature or hard lumps appear
- ED lasting >3 days
- Discoloration not fading after 1 week
- Numbness/loss of sensation
- Any concern that feels serious

**See a Pelvic Floor Physical Therapist If:**
- Hard flaccid symptoms
- Pelvic pain during or after training
- Difficulty with urination or ejaculation
- Chronic tension in pelvic area

**See a Mental Health Professional If:**
- Body dysmorphia interfering with daily life
- Obsessive measuring/checking
- Anxiety or depression related to PE progress
- PE negatively impacting relationship

${MEDICAL_DISCLAIMER}

## Conclusion

Most problems in PE are solvable with:
1. **Early recognition** (monitor EQ, listen to your body)
2. **Immediate action** (rest when needed, reduce intensity)
3. **Technique correction** (review guides, ask for help)
4. **Patience** (recovery takes time, results take time)

**Remember:** The goal is long-term, sustainable gains. Pushing through problems leads to injuries that can end your PE journey permanently. Train smart, not hard.`,
    medical_disclaimer: MEDICAL_DISCLAIMER,
    type: 'article',
    version: '1.0',
    language: 'en',
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp()
  }
];

// Continue with articles 3, 4, and 5 in the next file due to length...
// This file will deploy the first 2 articles, and I'll create a continuation

/**
 * Deploy articles to Firestore
 */
async function deployArticles() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Deploy Phase 2 Gap-Filling Knowledge (Part 1: Articles 1-2) ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}\n`);

  const collection = db.collection('ai_coach_knowledge');
  let successCount = 0;
  let errorCount = 0;

  for (const article of PHASE_2_ARTICLES) {
    try {
      console.log(`📝 Deploying: ${article.title}`);
      console.log(`   ID: ${article.id}`);
      console.log(`   Category: ${article.category}`);
      console.log(`   Priority: ${article.priority}/10`);
      console.log(`   Keywords: ${article.keywords.length}`);
      console.log(`   Content Length: ${article.content.length.toLocaleString()} characters`);

      // Create searchable content (lowercase for case-insensitive search)
      const searchableContent = [
        article.title,
        article.category,
        ...article.subcategories,
        ...article.keywords,
        article.content
      ].join(' ').toLowerCase();

      // Create document with all fields
      const documentData = {
        ...article,
        searchableContent,
        content_text: article.content, // Duplicate for compatibility
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      };

      // Write to Firestore
      await collection.doc(article.id).set(documentData);

      console.log(`   ✅ Successfully deployed\n`);
      successCount++;

    } catch (error) {
      console.error(`   ❌ Error deploying ${article.title}:`, error.message);
      errorCount++;
    }
  }

  return { successCount, errorCount, totalArticles: PHASE_2_ARTICLES.length };
}

/**
 * Main execution
 */
async function main() {
  try {
    console.log('⚙️  Initializing Firebase Admin SDK...\n');

    const results = await deployArticles();

    console.log('╔════════════════════════════════════════════════════════════╗');
    console.log('║  Deployment Summary (Part 1)                               ║');
    console.log('╚════════════════════════════════════════════════════════════╝\n');
    console.log(`✅ Successfully deployed: ${results.successCount} / ${results.totalArticles}`);
    console.log(`❌ Failed to deploy: ${results.errorCount} / ${results.totalArticles}`);
    console.log(`📊 Success rate: ${((results.successCount / results.totalArticles) * 100).toFixed(1)}%\n`);

    if (results.successCount === results.totalArticles) {
      console.log('🎉 All Phase 2 Part 1 articles deployed successfully!');
      console.log('📝 Next: Run deploy-gap-filling-phase2-part2.js for remaining articles\n');
      process.exit(0);
    } else {
      console.log('⚠️  Some articles failed to deploy. Check errors above.\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Deployment failed:', error);
    process.exit(1);
  }
}

// Run the script
main();
