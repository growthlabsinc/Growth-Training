#!/usr/bin/env node

/**
 * Deploy Gap-Filling Knowledge Base Content
 *
 * Fills the 10 critical knowledge gaps identified in gap analysis:
 * Phase 1 (Critical): Techniques, Equipment, Troubleshooting
 * Phase 2 (High-Value): Routine Planning, Plateau Breaking, Advanced Techniques
 * Phase 3 (Enhanced UX): Science Deep Dives, Progress Documentation, Time Management
 * Phase 4 (Engagement): Motivation & Mindset
 *
 * Usage:
 *   GCLOUD_PROJECT=growth-training-app node scripts/deploy-gap-filling-knowledge.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'growth-training-app'
});

const db = admin.firestore();

// Standard medical disclaimer
const STANDARD_DISCLAIMER = `⚠️ MEDICAL DISCLAIMER

This information is for educational purposes only and does not constitute medical advice. Consult with a healthcare provider before beginning any exercise program.

Individual results may vary. This app does not guarantee specific outcomes or results from following the information provided.

Every individual's physiology is different. What works for one person may not work for another.

There are inherent risks associated with physical exercise programs. Stop immediately if you experience pain, discomfort, or unusual symptoms, and seek medical attention.

This app and its content are intended for adults 18 years of age and older only.`;

/**
 * Gap-Filling Knowledge Base Articles
 * Based on Reddit community analysis of 1,500 posts
 */
const GAP_FILLING_ARTICLES = [
  // ============================================================================
  // PHASE 1: CRITICAL GAPS
  // ============================================================================

  {
    id: 'jelqing_technique_guide',
    title: 'Jelqing Technique: Complete Guide',
    category: 'technique',
    subcategories: ['manual_techniques', 'girth_training', 'beginner_friendly'],
    priority: 10,
    keywords: [
      'jelq', 'jelqing', 'manual', 'girth', 'technique', 'beginner',
      'stroke', 'pressure', 'ok', 'grip', 'erection', 'level', 'intensity'
    ],
    content: `# Jelqing Technique: Complete Guide

**Category:** Manual Techniques
**Priority:** 10/10 (Beginner Essential)
**Difficulty:** Beginner to Intermediate

## What is Jelqing?

Jelqing is a manual exercise that involves applying controlled pressure along the shaft to encourage blood flow and tissue expansion. It's one of the oldest and most fundamental PE techniques.

## Basic Technique (Standard Jelq)

### Setup
- Warm up for 5-10 minutes (warm towel, rice sock, or warm water)
- Achieve 40-70% erection level (NOT fully erect)
- Apply water-based lubricant generously

### Execution
1. Form OK-grip (thumb and index finger) at base of shaft
2. Apply moderate pressure (should feel stretch, not pain)
3. Slowly stroke toward glans (head) taking 2-3 seconds
4. Stop just before glans (don't jelq over head)
5. Alternate hands, maintaining rhythm

### Key Points
- **Erection Level:** 40-70% is ideal. Too soft = ineffective, too hard = injury risk
- **Pressure:** Moderate and consistent. You should feel expansion, not pain
- **Speed:** Slow and controlled (2-3 seconds per stroke)
- **Duration:** Start with 5-10 minutes, progress to 15-20 minutes
- **Frequency:** 3-5 days per week with rest days

## Common Mistakes

❌ **Jelqing at 100% erection** - High injury risk, especially for tunica
❌ **Too much pressure** - Can cause bruising, discoloration, thrombosis
❌ **Too fast** - Defeats purpose of sustained pressure
❌ **No warm-up** - Increases injury risk significantly
❌ **Going over the glans** - Can damage sensitive tissue

## Variations

### Wet Jelq (Recommended for Beginners)
- Uses lubricant for smooth glide
- Lower friction = safer for beginners
- Better for sensitive skin

### Dry Jelq (Intermediate)
- No lubricant, using skin itself
- More intense tissue engagement
- Higher skill requirement
- Greater discoloration risk

### V-Jelq (Intermediate)
- Uses two fingers in V-shape instead of OK-grip
- More focused pressure on dorsal area
- Good for targeting specific areas

### Power Jelq (Advanced)
- Higher erection level (70-80%)
- More pressure
- Greater expansion
- Significantly higher injury risk

## Safety Guidelines

⚠️ **WARNING SIGNS - Stop Immediately:**
- Sharp pain
- Numbness
- Cold sensation
- Dark purple/black discoloration
- Loss of sensation
- Difficulty achieving erection after session

✅ **Normal Sensations:**
- Mild fatigue/heaviness
- Temporary flushed appearance
- Small red dots (petechiae) that disappear in hours
- Slightly larger flaccid hang post-workout

## Progression Schedule

### Week 1-2: Conditioning
- 5 minutes per session
- 50-70% erection
- Light to moderate pressure
- Every other day

### Week 3-4: Building Volume
- 10 minutes per session
- 50-70% erection
- Moderate pressure
- Every other day

### Week 5-8: Standard Routine
- 15-20 minutes per session
- 50-70% erection
- Moderate to firm pressure
- 3-5 days per week

### Month 3+: Customization
- Adjust based on EQ response
- Experiment with variations
- Combine with other techniques

## Integration with Other Exercises

**Good Combinations:**
- Warmup → Stretching → Jelqing → Cooldown
- Jelqing → Light clamping (advanced)
- Pumping → Jelqing (for cementing expansion)

**Avoid:**
- Jelqing + Heavy clamping same session (too much girth work)
- Jelqing immediately before sex (may reduce EQ temporarily)

## Expected Results

**Realistic Timeline:**
- **Weeks 1-4:** Conditioning, better flaccid hang, improved EQ
- **Months 1-3:** First noticeable temporary expansion
- **Months 3-6:** Possible 0.1-0.25" girth gains (highly individual)
- **Months 6-12:** Progressive gains with consistent training

**Individual Variation:** Some gain quickly, others take longer. Consistency matters more than intensity.

## Troubleshooting

**Q: I'm not seeing gains after 2 months**
A: Check erection level (too soft?), pressure (too light?), consistency (skipping days?), recovery (overtraining?). Gains timeline varies widely.

**Q: I have small red dots after jelqing**
A: Normal (petechiae from capillary pressure). Should disappear in hours. If persistent or dark, reduce pressure.

**Q: My EQ dropped**
A: Overtraining signal. Take 2-3 rest days, reduce intensity, ensure adequate recovery.

**Q: Should I jelq every day?**
A: No. Rest days critical for tissue repair and growth. 3-5 days per week optimal for most.

## Scientific Basis

Jelqing works through:
- **Controlled tissue stress** → Microtrauma → Repair with expansion
- **Blood flow enhancement** → Improved vascular capacity
- **Tunica stretching** → Gradual tissue elongation

Similar principles to tissue expansion in medical contexts (skin grafts, limb lengthening).

## References

Based on community protocols from:
- r/AJelqForYou wiki (M9ter's guides)
- r/TheScienceOfPE beginner guides
- r/GettingBigger community experience
- 10+ years of documented community practice

---

${STANDARD_DISCLAIMER}`,
    type: 'knowledge',
    version: '1.0.0',
    language: 'en'
  },

  {
    id: 'manual_stretching_guide',
    title: 'Manual Stretching: Techniques for Length Training',
    category: 'technique',
    subcategories: ['manual_techniques', 'length_training', 'beginner_friendly'],
    priority: 10,
    keywords: [
      'stretch', 'stretching', 'manual', 'length', 'technique', 'beginner',
      'pull', 'grip', 'tension', 'ligament', 'tunica', 'straight', 'angle'
    ],
    content: `# Manual Stretching: Techniques for Length Training

**Category:** Manual Techniques
**Priority:** 10/10 (Beginner Essential)
**Difficulty:** Beginner
**Focus:** Length Gains

## What is Manual Stretching?

Manual stretching involves applying controlled tension to the penis to encourage tissue elongation. It's the most accessible PE technique requiring zero equipment.

## Basic Technique (Straight Stretch)

### Setup
- Warm up 5-10 minutes
- Completely flaccid (NOT erect)
- Optional: light grip wrap for better hold

### Execution
1. **Grip:** OK-grip behind glans (on shaft, not head)
2. **Squeeze glans** to remove blood (prevents blistering)
3. **Pull:** Steady, straight-out tension for 30-60 seconds
4. **Intensity:** Should feel stretch at base, not pain
5. **Rest:** 10-20 seconds between stretches
6. **Repeat:** 5-10 stretches per direction

### Key Points
- **Grip Location:** Behind glans on shaft, NOT on glans itself
- **Tension:** Firm but not painful (7/10 intensity)
- **Duration:** 30-60 second holds, not quick reps
- **Consistency:** Daily or 6 days/week for length focus

## Stretching Directions

### Straight Out (Primary)
- Directly away from body
- Targets ligaments and tunica equally
- Best starting point

### Straight Down
- Targets upper ligaments (suspensory ligament)
- Good for exposing hidden length
- Can be done seated

### Straight Up
- Targets lower ligaments and tunica
- Complements downward stretches
- Stand for better leverage

### Left & Right
- Targets lateral tunica
- Helps with curvature correction
- Ensures balanced development

### Rotary Stretches
- Gentle rotation while under tension
- Hits all angles progressively
- Good for warm-down

## Advanced Techniques

### V-Stretch (Intermediate)
1. Grip behind glans
2. Place other hand (flat) on mid-shaft
3. Pull glans while pushing down with flat hand
4. Creates fulcrum for intense stretch
5. ⚠️ High intensity - use caution

### A-Stretch (Intermediate)
- Similar to V-stretch
- Fulcrum hand in A-shape
- Focuses pressure on specific area

### Behind-the-Cheeks (BTC) Stretch (Advanced)
- Pull back between legs while seated
- Extreme stretch of tunica and ligaments
- ⚠️ Highest intensity - advanced only

### JAI Stretch (Advanced)
- Grip at base with OK-grip
- Stretch with other hand
- Squeeze base to restrict blood flow
- Intense tunica stretch
- ⚠️ Risk of over-stretching

## Common Mistakes

❌ **Gripping the glans directly** - Blistering, nerve damage risk
❌ **Stretching while erect** - Injury risk, ineffective for length
❌ **Too much force** - Nerve damage, ligament tears
❌ **No warm-up** - Significantly increases injury risk
❌ **Too short holds** - Ineffective for tissue adaptation

## Safety Guidelines

⚠️ **STOP IMMEDIATELY IF:**
- Sharp pain at base or shaft
- Numbness or tingling
- Glans turns blue/purple/black
- Skin tearing or blistering
- Pain persists after releasing tension

✅ **Normal Sensations:**
- Feeling of stretch/tension at base
- Mild soreness after session (like muscle workout)
- Temporary fatigue
- Slightly longer flaccid hang post-workout

## Grip Techniques

### Standard OK-Grip
- Thumb and index finger
- Behind glans on shaft
- Most control

### Overhand Grip
- Full hand over shaft
- Better for high-force stretches
- Less wrist fatigue

### Baby Powder Method
- Apply powder to glans
- Improves grip without squeezing too hard
- Reduces slippage

### Grip Wraps
- Cloth/silicone wraps
- Distributes pressure
- Prevents blistering
- Good for extended sessions

## Progression Schedule

### Weeks 1-2: Conditioning
- 5 minutes total
- Straight stretches only
- 30-second holds
- Daily

### Weeks 3-4: Building Duration
- 10 minutes total
- Add Up/Down stretches
- 45-second holds
- Daily

### Weeks 5-8: Full Routine
- 15-20 minutes total
- All directions (Straight, Up, Down, Left, Right)
- 60-second holds
- 5-6 days per week

### Month 3+: Advanced Options
- Add V-stretches or A-stretches
- Experiment with angles
- Consider device progression (extender/ADS)

## Integration with Equipment

**Manual → Extender/ADS:**
- Many start with manuals
- Progress to extender for longer duration
- Combine: manual stretches + all-day extender
- Dramatically increases "time under tension"

**Manual → Hanging:**
- Build grip strength with manuals first
- Then progress to hanging for higher force
- Use manuals as warm-up before hanging

## Expected Results

**Realistic Timeline:**
- **Weeks 1-4:** Conditioning, improved flaccid hang
- **Months 1-3:** Possible 0.1-0.25" length gain (temporary at first)
- **Months 3-6:** 0.25-0.5" potential gains (highly individual)
- **Months 6-12:** Progressive gains with consistency

**Note:** Manual-only gains typically slower than device-assisted, but zero equipment cost.

## Troubleshooting

**Q: My hands get tired before I feel the stretch**
A: Use grip wraps, or switch to extender/ADS for "passive" stretching

**Q: I have blisters on glans**
A: Gripping glans directly (wrong). Squeeze blood out of glans, grip behind it on shaft

**Q: I don't feel anything at the base**
A: Increase tension gradually. May need stronger grip or different angle

**Q: Can I stretch multiple times per day?**
A: Yes, but total daily time same (split 20 min into 2×10 min sessions). Don't overdo total volume.

## Scientific Basis

Manual stretching works through:
- **Ligament lengthening** (suspensory ligament exposes more length)
- **Tunica elongation** (controlled stress → tissue remodeling)
- **Creep phenomenon** (sustained tension causes tissue elongation)

Similar to medical traction devices, orthodontic expansion, limb lengthening.

## References

Based on community protocols from:
- r/AJelqForYou wiki (M9ter's Monster Length 101)
- r/TheScienceOfPE beginner stretching guides
- r/GettingBigger manual technique discussions
- Decades of documented community practice

---

${STANDARD_DISCLAIMER}`,
    type: 'knowledge',
    version: '1.0.0',
    language: 'en'
  },

  {
    id: 'pumping_protocols_guide',
    title: 'Pumping Protocols: Static, Interval & RIP Techniques',
    category: 'technique',
    subcategories: ['equipment_techniques', 'girth_training', 'intermediate'],
    priority: 9,
    keywords: [
      'pump', 'pumping', 'vacuum', 'girth', 'pressure', 'cylinder',
      'static', 'interval', 'rip', 'edema', 'expansion', 'technique'
    ],
    content: `# Pumping Protocols: Static, Interval & RIP Techniques

**Category:** Equipment Techniques
**Priority:** 9/10 (Very Popular)
**Difficulty:** Beginner to Advanced
**Focus:** Girth Gains (Primary), Length (Secondary)

## What is Pumping?

Vacuum pumping creates negative pressure around the penis, drawing blood into erectile tissues and stretching the tunica albuginea. It's one of the most popular PE techniques with extensive community experience.

## Equipment Basics

### Essential Components
- **Cylinder:** Acrylic or polycarbonate tube (size matters!)
- **Pump:** Hand pump or electric pump
- **Gauge:** Pressure measurement (critical for safety)
- **Seal:** Creates vacuum (base pad or sleeve)

### Cylinder Sizing
- **Diameter:** 0.25-0.5" larger than erect girth
- **Length:** 1-2" longer than erect length
- Too large = poor vacuum, fluid build-up
- Too small = limited expansion, discomfort

### Pressure Measurement
- **InHg** (inches of mercury) - most common
- **kPa** (kilopascals)
- **mmHg** (millimeters of mercury)
- Conversion: 5 inHg ≈ 170 mmHg ≈ 22 kPa

## Basic Technique

### Setup
1. Warm up 5-10 minutes
2. Trim/shave base hair (improves seal)
3. Apply lube to base and cylinder edge
4. Achieve 50-80% erection (helps initial expansion)

### Execution
1. Insert penis into cylinder
2. Create seal against body
3. Pump slowly to target pressure
4. Monitor expansion and comfort
5. Release pressure gradually after set time
6. Rest between sets

### Safety Pressures

**Beginners:**
- 3-4 inHg (100-135 mmHg)
- Build tolerance gradually
- Lower risk, slower gains

**Intermediate:**
- 4-6 inHg (135-200 mmHg)
- Most common working range
- Good balance of safety/effectiveness

**Advanced:**
- 6-8 inHg (200-270 mmHg)
- Higher expansion, higher risk
- Requires experience and monitoring

**⚠️ Danger Zone:**
- 8+ inHg (270+ mmHg)
- Significant injury risk
- Not recommended for most

## Pumping Protocols

### 1. Static Pumping (Beginner)

**Method:**
- Continuous pressure for set duration
- No pressure changes during set
- Simplest protocol

**Example Routine:**
- 3 sets × 5-10 minutes each
- 3-5 inHg pressure
- 5-minute rest between sets
- 2-3× per week

**Pros:** Simple, good for beginners, steady expansion
**Cons:** More edema (fluid build-up), slower than interval methods

---

### 2. Interval Pumping (Intermediate)

**Method:**
- Alternate pressure ON and OFF
- Allows blood flow recovery
- Reduces edema significantly

**Example Routine:**
- 3 minutes ON (4-5 inHg) / 1 minute OFF
- Repeat 5-10 cycles
- Total: 15-30 minutes under pressure
- 3-4× per week

**Variations:**
- 5 ON / 1 OFF (longer sets)
- 2 ON / 1 OFF (more cycles, less fatigue)
- 10 ON / 2 OFF (advanced, longer sets)

**Pros:** Less edema, better tissue quality, faster gains
**Cons:** More complex, requires attention

---

### 3. RIP - Rapid Interval Pumping (Advanced)

**Method:**
- Very short ON/OFF cycles
- Rapid pumping and release
- Maximizes blood flow cycling
- Developed by community user Goldmember

**Example Routine:**
- 30 seconds ON (5-7 inHg) / 30 seconds OFF
- Repeat 10-20 cycles
- 1-2 minute rest after 10 cycles
- Total: 20-30 minutes session
- 4-5× per week

**Variations:**
- 45 ON / 45 OFF (less intense)
- 20 ON / 40 OFF (more recovery)
- 60 ON / 30 OFF (more expansion time)

**Pros:** Minimal edema, excellent tissue quality, fastest gains reported
**Cons:** Requires auto-pump or diligent manual pumping, mentally demanding

---

### 4. PAC - Pump Assisted Clamping (Expert)

**⚠️ Advanced Only - High Risk**

**Method:**
- Pump to expansion
- Apply clamp at base while under pressure
- Release vacuum
- Maintain clamp for set duration
- Combines pumping expansion + clamping restriction

**Safety Notes:**
- Requires extensive pumping AND clamping experience
- Very high intensity
- Significant injury risk if done incorrectly
- Monitor closely for hypoxia (lack of oxygen)

---

## Edema Management

### What is Edema?
- Fluid build-up in skin and superficial tissue
- Appears as "donut" around glans or water-logged shaft
- Temporary but reduces quality of expansion

### Minimizing Edema
✅ **Use interval protocols** (not static)
✅ **Lower pressure, longer duration** (better than high/short)
✅ **Massage during rest periods**
✅ **Adequate warm-up**
✅ **Avoid pumping too frequently**

### Treating Edema
- Rest 1-2 days
- Light massage
- Warm compress
- Kegels to promote circulation
- Usually resolves in 24-48 hours

## Safety Guidelines

⚠️ **STOP IMMEDIATELY IF:**
- Pain (sharp or aching)
- Dark purple/black discoloration
- Cold sensation or numbness
- Blisters forming
- Difficulty achieving erection post-session
- Sustained loss of sensation

✅ **Normal During Pumping:**
- Expansion (obviously!)
- Mild pressure sensation
- Temporary red/pink color
- Warmth from increased blood flow

✅ **Normal After Pumping:**
- Larger girth temporarily
- Red dots (petechiae) that fade in hours
- Slightly sore/fatigued feeling
- Fuller flaccid hang

❌ **NOT Normal:**
- Pain persisting after session
- Dark discoloration lasting hours/days
- Numbness or cold sensation
- Erectile dysfunction

## Common Mistakes

❌ **Starting with too much pressure** - Injury, discoloration, poor tissue quality
❌ **Pumping too long** - Edema, fluid build-up
❌ **No warm-up** - Increased injury risk
❌ **Wrong cylinder size** - Poor results, safety issues
❌ **Pumping daily without rest** - Overtraining, EQ drop

## Progression Schedule

### Week 1-2: Conditioning
- Static pumping only
- 3-4 inHg pressure
- 2 sets × 5 minutes
- 2-3× per week

### Week 3-4: Building Tolerance
- Static or light interval
- 4-5 inHg pressure
- 3 sets × 5-7 minutes
- 3× per week

### Week 5-8: Standard Routine
- Interval pumping (3 ON / 1 OFF)
- 4-6 inHg pressure
- 15-20 minutes under pressure
- 3-4× per week

### Month 3+: Advanced Options
- Try RIP protocol
- Experiment with pressure
- Combine with clamping (if experienced)
- Consider auto-pump for consistency

## Equipment Recommendations

### Budget-Friendly ($50-100)
- LA Pump (basic models)
- Bathmate (water pump, no gauge)
- Hand pump with gauge

### Mid-Range ($100-250)
- LeLuv pumps
- Pumped Up cylinders
- Quality hand pump with accurate gauge

### Premium ($250-500+)
- Auto-pumps (hands-free)
- Medical-grade cylinders
- Advanced pressure control
- Worth it for serious long-term users

## Integration with Other Techniques

**Good Combinations:**
- Warmup → Pumping → Manual work (jelqs/stretches)
- Pumping → Light clamping (for cementing expansion)
- Extending/ADS → Evening pump session

**Avoid:**
- Pumping + Heavy clamping (same session) - Too much girth stress
- Pumping immediately before sex - Temporary EQ reduction

## Expected Results

**Realistic Timeline:**
- **Weeks 1-4:** Conditioning, temporary expansion during/after sessions
- **Months 1-3:** Better flaccid, 0.1-0.25" temporary girth increase
- **Months 3-6:** 0.25-0.5" potential girth gains (cementing begins)
- **Months 6-12:** Progressive gains with consistent training

**Girth vs. Length:**
- Pumping primarily for girth
- Some length gains possible (especially with length cylinder)
- Combine with stretching/extending for length focus

## Troubleshooting

**Q: I only get fluid edema, no real expansion**
A: Pressure too high, or pumping too long. Try lower pressure (3-4 inHg) with interval protocol.

**Q: I have dark discoloration after pumping**
A: Pressure too high or session too long. Reduce pressure by 1-2 inHg, take 2-3 days rest.

**Q: My glans gets huge but shaft doesn't expand much**
A: Cylinder too wide, or not enough pressure. Try smaller diameter cylinder.

**Q: Should I pump every day?**
A: Generally no. 3-5× per week optimal for most. Rest days critical for growth.

## Scientific Basis

Pumping works through:
- **Vacuum-induced tissue expansion** → Tunica stretching
- **Blood flow enhancement** → Vascular capacity increase
- **Controlled hypoxia** → Cellular adaptation response (similar to altitude training)
- **Mechanical stress** → Tissue remodeling and growth

Similar principles used in medical vacuum therapy for ED, wound healing, tissue expansion.

## References

Based on community protocols from:
- r/TheScienceOfPE pumping guides (Karl's trilogy)
- r/GettingBigger pumping discussions
- Goldmember's RIP protocol
- r/PEGym pump forums
- 20+ years of documented pumping experience

---

${STANDARD_DISCLAIMER}`,
    type: 'knowledge',
    version: '1.0.0',
    language: 'en'
  }
];

/**
 * Deploy gap-filling knowledge base
 */
async function deployGapFillingKnowledge() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  Deploy Gap-Filling Knowledge Base Content                ║');
  console.log('║  Phase 1: Critical Gaps (Technique Guides)                 ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`📦 Project: ${process.env.GCLOUD_PROJECT || 'growth-training-app'}`);
  console.log(`📊 Articles to Deploy: ${GAP_FILLING_ARTICLES.length}\n`);

  try {
    const batch = db.batch();
    let deployedCount = 0;

    for (const article of GAP_FILLING_ARTICLES) {
      const { id, ...articleData } = article;

      // Create searchable content
      const searchableContent = `${article.title} ${article.content}`.toLowerCase();

      const docRef = db.collection('ai_coach_knowledge').doc(id);

      batch.set(docRef, {
        ...articleData,
        content_text: article.content,
        searchableContent: searchableContent,
        medical_disclaimer: STANDARD_DISCLAIMER,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        source_type: 'community_synthesis',
        gap_filling: true
      });

      console.log(`✅ ${article.title}`);
      console.log(`   📁 Category: ${article.category}`);
      console.log(`   ⭐ Priority: ${article.priority}/10`);
      console.log(`   🔑 Keywords: ${article.keywords.length}`);
      console.log(`   📝 Content: ${article.content.length} characters\n`);

      deployedCount++;
    }

    // Commit batch
    console.log(`🚀 Committing batch write for ${deployedCount} articles...`);
    await batch.commit();
    console.log('✅ Batch write successful!\n');

    // Summary
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 DEPLOYMENT SUMMARY');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Deployed:        ${deployedCount} gap-filling articles`);
    console.log(`🔑 Total Keywords:  ${GAP_FILLING_ARTICLES.reduce((sum, a) => sum + a.keywords.length, 0)}`);
    console.log(`📝 Total Content:   ${GAP_FILLING_ARTICLES.reduce((sum, a) => sum + a.content.length, 0).toLocaleString()} characters`);
    console.log(`⚠️  Disclaimers:    All articles include medical disclaimer`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    return deployedCount;

  } catch (error) {
    console.error('❌ Deployment failed:', error);
    throw error;
  }
}

/**
 * Main execution
 */
async function main() {
  try {
    const deployedCount = await deployGapFillingKnowledge();

    console.log('🎉 Phase 1 Gap-Filling Complete!');
    console.log(`✅ ${deployedCount} technique guides deployed`);
    console.log('\n📚 Coverage Improvements:');
    console.log('   • Jelqing technique (387 keyword mentions)');
    console.log('   • Manual stretching (498 keyword mentions)');
    console.log('   • Pumping protocols (521 keyword mentions)');
    console.log('\nNext: Deploy Phase 2 (Equipment, Troubleshooting, Routine Planning)\n');

    process.exit(0);

  } catch (error) {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  }
}

// Run the script
main();
