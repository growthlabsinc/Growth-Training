/**
 * Deploy Expanded PE Knowledge Base to Firebase
 * Story 3.3: Develop Training Protocol Knowledge
 *
 * This script deploys 50+ comprehensive PE training documents to the AI Coach
 * knowledge base, expanding from the initial 14 to provide detailed coverage
 * of all PE training aspects with safety-first approach.
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin using default credentials (gcloud auth)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'growth-training-app'
  });
}

const db = admin.firestore();

/**
 * Standard medical disclaimer for all PE content
 */
const MEDICAL_DISCLAIMER = '\n\n**Medical Disclaimer**: This information is for educational purposes only. Consult with a healthcare provider before beginning any PE training program. Stop immediately if you experience pain, numbness, or discoloration.';

/**
 * Knowledge document factory function
 */
function createKnowledgeDocument(id, category, title, content, keywords, priority = 5) {
  return {
    id: id,
    category: category,
    title: title,
    content: content + MEDICAL_DISCLAIMER,
    keywords: keywords,
    priority: priority,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };
}

/**
 * Deploy documents in batches to respect Firestore limits
 */
async function deployBatch(documents, batchName) {
  console.log(`\n📦 Deploying ${batchName}...`);
  const batch = db.batch();
  let batchCount = 0;
  let totalDeployed = 0;

  for (const doc of documents) {
    const docRef = db.collection('ai_coach_knowledge').doc(doc.id);
    batch.set(docRef, doc);
    batchCount++;

    // Firestore batch limit is 500 operations
    if (batchCount >= 500) {
      await batch.commit();
      totalDeployed += batchCount;
      console.log(`  ✅ Deployed batch of ${batchCount} documents`);
      batchCount = 0;
    }
  }

  // Commit remaining documents
  if (batchCount > 0) {
    await batch.commit();
    totalDeployed += batchCount;
    console.log(`  ✅ Deployed final batch of ${batchCount} documents`);
  }

  console.log(`  ✅ Total ${batchName} deployed: ${totalDeployed}`);
  return totalDeployed;
}

/**
 * Main deployment function
 */
async function deployExpandedKnowledge() {
  console.log('🚀 Starting Expanded PE Knowledge Base Deployment');
  console.log('📊 Target: 50+ comprehensive training documents\n');

  try {
    let totalDocuments = 0;

    // Deploy Length Training Documents (15+)
    const lengthDocs = createLengthDocuments();
    totalDocuments += await deployBatch(lengthDocs, 'Length Training Documents');

    // Deploy Girth Training Documents (12+)
    const girthDocs = createGirthDocuments();
    totalDocuments += await deployBatch(girthDocs, 'Girth Training Documents');

    // Deploy EQ Enhancement Documents (8+)
    const eqDocs = createEQDocuments();
    totalDocuments += await deployBatch(eqDocs, 'EQ Enhancement Documents');

    // Deploy Equipment Guides (10+)
    const equipmentDocs = createEquipmentDocuments();
    totalDocuments += await deployBatch(equipmentDocs, 'Equipment Guides');

    // Deploy Progression Paths (5+)
    const progressionDocs = createProgressionDocuments();
    totalDocuments += await deployBatch(progressionDocs, 'Progression Paths');

    // Deploy Enhanced Safety Documents (existing 3 + enhancements)
    const safetyDocs = createEnhancedSafetyDocuments();
    totalDocuments += await deployBatch(safetyDocs, 'Safety Documents');

    console.log('\n' + '='.repeat(50));
    console.log(`✅ DEPLOYMENT COMPLETE!`);
    console.log(`📊 Total documents deployed: ${totalDocuments}`);
    console.log(`🎯 Target achieved: ${totalDocuments >= 50 ? 'YES ✅' : 'NO ❌'}`);
    console.log('='.repeat(50));

  } catch (error) {
    console.error('❌ Deployment failed:', error);
    process.exit(1);
  }
}

/**
 * Create 15+ Length Training Documents
 */
function createLengthDocuments() {
  return [
    // Beginner Length Documents (5)
    createKnowledgeDocument(
      'pe-length-beginner-001',
      'length',
      'Manual Stretching Fundamentals',
      `## Manual Stretching for Beginners

**Safety First**: Start with minimal force and progress gradually over weeks.

### Basic Technique
1. **Warm up** (5-10 minutes): Apply heat or light massage
2. **Grip**: OK grip 1 inch behind glans, never grip glans directly
3. **Stretch**: Apply gentle traction in one direction
4. **Hold**: 30-60 seconds per stretch
5. **Release**: Slowly release and massage

### Directional Routine
- Straight out: 3 sets of 30 seconds
- Up toward belly: 3 sets of 30 seconds
- Down toward feet: 3 sets of 30 seconds
- Left: 2 sets of 30 seconds
- Right: 2 sets of 30 seconds

### Progression
- Week 1-2: 5 minutes total, light tension
- Week 3-4: 7-10 minutes, slightly increased tension
- Month 2+: 10-15 minutes, moderate tension`,
      ['manual', 'stretching', 'beginner', 'length', 'basic', 'fundamentals'],
      9
    ),

    createKnowledgeDocument(
      'pe-length-beginner-002',
      'length',
      'JAI Stretches for Beginners',
      `## JAI (Just Another Inch) Stretches

A beginner-friendly stretching variation focusing on short, intense holds.

### Technique
1. **Warm up thoroughly** (10 minutes minimum)
2. **Maximum stretch**: Pull to comfortable maximum
3. **Short hold**: Hold for just 2 seconds
4. **Quick release**: Immediately release
5. **Repeat**: 30-50 quick repetitions

### Benefits
- Reduces injury risk from prolonged stretching
- Allows higher intensity safely
- Good for building stretch tolerance
- Can be done daily with proper warm-up

### Session Structure
- 10 minute warm-up
- 50 JAI stretches straight out
- 30 JAI stretches up
- 30 JAI stretches down
- 5 minute cool-down massage`,
      ['JAI', 'stretches', 'beginner', 'length', 'quick', 'repetitions'],
      8
    ),

    createKnowledgeDocument(
      'pe-length-beginner-003',
      'length',
      'Basic Length Theory and Tissue Adaptation',
      `## Understanding Length Gains

### Tissue Adaptation Process
Length gains occur through gradual tissue remodeling under consistent tension.

### Key Principles
1. **Time Under Tension**: Cumulative stretch time matters
2. **Progressive Overload**: Gradually increase intensity
3. **Rest and Recovery**: Tissues grow during rest periods
4. **Consistency**: Regular practice yields better results than sporadic intense sessions

### Realistic Expectations
- First 3 months: 0.25-0.5 inches possible
- 6-12 months: 0.5-1.0 inches total
- Beyond 1 year: Gains slow significantly
- Individual variation is substantial

### Factors Affecting Gains
- Starting size (smaller may gain more %)
- Age and tissue elasticity
- Consistency of practice
- Proper technique and safety`,
      ['theory', 'length', 'gains', 'tissue', 'adaptation', 'expectations'],
      7
    ),

    createKnowledgeDocument(
      'pe-length-beginner-004',
      'length',
      'Warm-Up Protocols for Length Training',
      `## Essential Warm-Up for Length Work

Proper warm-up is critical for injury prevention and effectiveness.

### Heat Application Methods
1. **Hot wrap**: Wet washcloth in hot water, wrap for 5-10 minutes
2. **Rice sock**: Microwave rice-filled sock, apply for 5-10 minutes
3. **Hot shower**: Direct warm water for 5-10 minutes
4. **Infrared lamp**: 10-15 minutes at safe distance

### Massage Warm-Up
1. **Base to tip strokes**: 30-50 light strokes
2. **Twisting motions**: Gentle twists along shaft
3. **Light stretches**: Very gentle pre-stretches
4. **Kegel exercises**: 20-30 to promote blood flow

### Warm-Up Indicators
- Tissue feels warm and pliable
- Slight temporary size increase
- Improved stretchability
- No cold or stiff feeling`,
      ['warm-up', 'heat', 'preparation', 'length', 'safety', 'beginner'],
      10
    ),

    createKnowledgeDocument(
      'pe-length-beginner-005',
      'length',
      'Beginner Length Routine Template',
      `## Complete Beginner Length Routine

A structured 3-month program for length training newcomers.

### Month 1: Foundation
**3-4 days per week**
- 10 min warm-up
- 5 min basic manual stretches
- 5 min cool-down massage
- Total: 20 minutes

### Month 2: Development
**4-5 days per week**
- 10 min warm-up
- 10 min manual stretches (varied directions)
- 5 min JAI stretches
- 5 min cool-down
- Total: 30 minutes

### Month 3: Establishment
**5 days per week**
- 10 min warm-up
- 15 min manual stretches
- 10 min JAI or advanced variations
- 5 min cool-down
- Total: 40 minutes

### Progress Tracking
- Measure monthly (not weekly)
- Track consistency, not just size
- Note tissue conditioning improvements`,
      ['routine', 'beginner', 'length', 'program', 'schedule', 'template'],
      8
    ),

    // Intermediate Length Documents (5)
    createKnowledgeDocument(
      'pe-length-intermediate-001',
      'length',
      'Introduction to Hanging',
      `## Hanging Weight Training - Intermediate

Hanging uses weights for consistent traction over extended periods.

### Prerequisites
- 3+ months manual stretching experience
- Good understanding of personal limits
- Quality equipment investment

### Equipment Essentials
1. **Hanger types**: Vacuum or compression
2. **Weights**: Start with 2.5-5 lbs
3. **Wrap**: Theraband or cloth for protection
4. **Timer**: Track all sessions precisely

### Starting Protocol
- Week 1-2: 2.5 lbs, 10 minutes x 1 set
- Week 3-4: 2.5 lbs, 10 minutes x 2 sets
- Month 2: 5 lbs, 10 minutes x 2 sets
- Month 3+: Gradual progression

### Critical Safety
- Never exceed 20 lbs (most gain below 15 lbs)
- Check circulation every 5 minutes
- Immediate stop if numbness occurs`,
      ['hanging', 'weights', 'intermediate', 'length', 'traction', 'advanced'],
      9
    ),

    createKnowledgeDocument(
      'pe-length-intermediate-002',
      'length',
      'Fulcrum Stretching Techniques',
      `## Fulcrum Stretching for Enhanced Length

Using a fulcrum point to increase stretch intensity at specific locations.

### Basic Fulcrum Method
1. **Create fulcrum**: Use padded rod or bundled socks
2. **Position**: Place fulcrum at desired stress point
3. **Stretch over**: Pull penis over fulcrum
4. **Angle adjustment**: Change angle for different effects
5. **Hold**: 30-60 seconds per position

### Fulcrum Variations
- **A-stretch**: Wrist as fulcrum, very intense
- **Bundled stretch**: Twist then stretch over fulcrum
- **Progressive fulcrum**: Move fulcrum point during stretch

### Safety Considerations
- Extreme care with pressure points
- Start with soft fulcrums only
- Never use sharp or hard objects
- Monitor for bruising or pain`,
      ['fulcrum', 'stretching', 'intermediate', 'A-stretch', 'bundled', 'advanced'],
      8
    ),

    createKnowledgeDocument(
      'pe-length-intermediate-003',
      'length',
      'All Day Stretcher (ADS) Systems',
      `## All Day Stretcher Principles

ADS devices provide light, constant traction for extended periods.

### ADS Concept
- Low tension (1-2 lbs) for 4-8 hours
- Prevents tissue retraction
- Supplements primary exercises
- Promotes healing in extended state

### Common ADS Types
1. **Leg strap**: Attaches to leg, provides downward traction
2. **Belt system**: Around waist, adjustable direction
3. **Sleeve extender**: Maintains mild stretch
4. **Traction wrap**: Simple, low-tech option

### Usage Guidelines
- Start with 2-hour sessions
- Build to 4-6 hours gradually
- Never sleep with ADS
- Regular circulation checks mandatory

### Integration with Routine
- Use on non-hanging days
- After manual stretching sessions
- During work or sedentary activities`,
      ['ADS', 'all-day', 'stretcher', 'traction', 'intermediate', 'passive'],
      7
    ),

    createKnowledgeDocument(
      'pe-length-intermediate-004',
      'length',
      'Intermediate Hanging Progressions',
      `## Progressive Hanging Protocols

Structured advancement for intermediate hangers.

### Time Progression (at constant weight)
- Month 1: 10 min sets
- Month 2: 15 min sets
- Month 3: 20 min sets
- Maintain: 20 min maximum per set

### Weight Progression (at constant time)
- Weeks 1-4: 2.5 lbs
- Weeks 5-8: 5 lbs
- Weeks 9-12: 7.5 lbs
- Advanced: 10+ lbs (with extreme caution)

### Angle Variations
- **SO** (Straight Out): Default position
- **SD** (Straight Down): Standing or seated
- **BTC** (Between The Cheeks): Advanced, targets ligs
- **OTS** (Over The Shoulder): Very advanced

### Fatigue Management
- Fatigue is the goal, not weight
- Reduce weight if form compromised
- Take deload weeks every 4-6 weeks`,
      ['hanging', 'progression', 'intermediate', 'weight', 'fatigue', 'angles'],
      8
    ),

    createKnowledgeDocument(
      'pe-length-intermediate-005',
      'length',
      'Length Plateau Breaking Strategies',
      `## Overcoming Length Plateaus

Strategies when gains stall after 6+ months.

### Plateau Indicators
- No measurable gains for 2+ months
- Reduced tissue fatigue from same routine
- Loss of motivation or compliance

### Breaking Through
1. **Deconditioning break**: 2-4 weeks complete rest
2. **Shock routines**: Dramatic change in approach
3. **Intensity cycling**: Alternate heavy/light weeks
4. **Technique refinement**: Perfect form over weight
5. **Angle exploration**: Find untapped angles

### Advanced Techniques
- Heat during stretching (not just before)
- Chemical assistance (Vitamin E, L-Arginine)
- Ultrasound therapy (experimental)
- Professional PT consultation

### Mindset Adjustment
- Focus on tissue quality over length
- Appreciate maintenance of gains
- Consider goals achieved`,
      ['plateau', 'intermediate', 'stalled', 'gains', 'breakthrough', 'advanced'],
      7
    ),

    // Advanced Length Documents (5)
    createKnowledgeDocument(
      'pe-length-advanced-001',
      'length',
      'Advanced Hanging: BTC Position',
      `## Between The Cheeks (BTC) Hanging

The most intense hanging position for targeting ligaments.

### Prerequisites
- 6+ months regular hanging experience
- Mastery of SO and SD positions
- Excellent body awareness
- Superior equipment

### BTC Setup
1. **Position**: Seated on edge of chair/bed
2. **Attachment**: Hanger attached normally
3. **Routing**: Penis pulled back between legs
4. **Weight placement**: Hanging behind buttocks
5. **Posture**: Lean forward slightly

### Unique Benefits
- Maximum ligament stretch
- Targets suspensory ligament
- Can break through plateaus
- Most efficient for some individuals

### Critical Warnings
- Extreme stress on attachment point
- Higher injury risk
- Start with 50% normal weight
- Maximum 10-minute sets initially`,
      ['BTC', 'advanced', 'hanging', 'ligaments', 'intense', 'position'],
      9
    ),

    createKnowledgeDocument(
      'pe-length-advanced-002',
      'length',
      'Bundled Stretching Techniques',
      `## Bundled Stretching - Advanced Method

Combines rotation with stretching for intense multi-angle work.

### Basic Bundle Technique
1. **Rotation**: Twist penis 180-360 degrees
2. **Maintain twist**: Hold rotation firmly
3. **Add stretch**: Pull while maintaining rotation
4. **Hold**: 30-60 seconds
5. **Unwind slowly**: Gradual release

### Advanced Variations
- **Double bundle**: 720-degree rotation
- **Fulcrum bundle**: Add fulcrum to bundled stretch
- **Hanging bundle**: Light weights with rotation
- **Dynamic bundle**: Slow rotation during stretch

### Target Areas
- Addresses tunica from multiple angles
- Can help with curvature correction
- Breaks up adhesions
- Promotes even growth

### Safety Critical
- Never force rotation
- Stop if sharp pain occurs
- Limit to 2-3 times weekly`,
      ['bundled', 'rotation', 'advanced', 'stretching', 'twist', 'intense'],
      8
    ),

    createKnowledgeDocument(
      'pe-length-advanced-003',
      'length',
      'Heavy Weight Hanging Protocols',
      `## Heavy Hanging (15+ lbs) Guidelines

For experienced hangers pushing limits safely.

### Prerequisites
- 1+ year hanging experience
- Perfect form at lower weights
- Gradual progression to this level
- Premium equipment only

### Heavy Hanging Principles
- **Fatigue over weight**: Not about max weight
- **Reduced time**: 10-minute sets maximum
- **Perfect attachment**: Critical at high weights
- **Active monitoring**: Constant awareness

### Session Structure
1. Extended warm-up (15 minutes)
2. Progressive weight build-up
3. Heavy sets (2-3 maximum)
4. Immediate cool-down work
5. Extended recovery period

### Recovery Requirements
- Minimum 48 hours between sessions
- Active recovery with ADS
- Increased nutrition focus
- Monitor for overtraining signs`,
      ['heavy', 'hanging', 'advanced', 'weight', 'intense', 'experienced'],
      8
    ),

    createKnowledgeDocument(
      'pe-length-advanced-004',
      'length',
      'Extreme Length: Surgical Prep Protocols',
      `## Pre/Post Surgical Lengthening Protocols

PE as preparation or supplement to surgical options.

### Surgical Options Overview
- **Ligament release**: Cutting suspensory ligament
- **Fat injection**: Girth enhancement primarily
- **Dermal grafts**: More complex procedures

### PE as Surgical Prep
1. **Maximize natural gains first**: 12-18 months PE
2. **Condition tissues**: Improve elasticity
3. **Establish baseline**: Know natural potential
4. **Post-op maintenance**: Prevent retraction

### Post-Surgical PE
- Follow surgeon protocol exactly
- Gentle stretching prevents adhesions
- ADS critical for healing position
- Very gradual return to weights

### Considerations
- Surgery risks are significant
- Results often disappointing
- PE alone often exceeds surgical gains
- Combination approach for extremes only`,
      ['surgical', 'advanced', 'extreme', 'ligament', 'medical', 'procedure'],
      6
    ),

    createKnowledgeDocument(
      'pe-length-advanced-005',
      'length',
      'Length Maximization: 2+ Year Programs',
      `## Long-Term Length Development

Strategies for committed multi-year practitioners.

### Year 1: Foundation
- Months 1-3: Manual stretching mastery
- Months 4-6: Introduction to devices
- Months 7-9: Hanging fundamentals
- Months 10-12: Routine optimization

### Year 2: Specialization
- Focus on most effective technique
- Advanced variations exploration
- Plateau management strategies
- Consider chemical aids

### Year 3+: Refinement
- Maintenance vs. gaining phases
- Extreme techniques (if appropriate)
- Injury prevention paramount
- Realistic goal adjustment

### Lifetime Management
- Periodic deconditioning breaks
- Seasonal variation in intensity
- Health monitoring essential
- Community support valuable

### Final Expectations
- 1-2 inches possible for dedicated
- Diminishing returns after year 2
- Maintenance becomes primary goal`,
      ['long-term', 'advanced', 'years', 'maximization', 'lifetime', 'dedication'],
      7
    )
  ];
}

/**
 * Create 12+ Girth Training Documents
 */
function createGirthDocuments() {
  return [
    // Beginner Girth Documents (4)
    createKnowledgeDocument(
      'pe-girth-beginner-001',
      'girth',
      'Introduction to Jelqing',
      `## Jelqing - The Foundation of Girth Training

Jelqing is a milking motion that forces blood through the penis to expand tissues.

### Basic Jelq Technique
1. **Warm up**: Essential 10-minute heat application
2. **Erection level**: 40-70% (never fully erect)
3. **OK grip**: Form ring with thumb and index finger
4. **Stroke**: 3-second stroke from base to below glans
5. **Switch hands**: Alternate for continuous motion

### Beginner Protocol
- Week 1-2: 50 jelqs, light pressure
- Week 3-4: 100 jelqs, moderate pressure
- Month 2: 150-200 jelqs
- Month 3+: 200-300 jelqs maximum

### Critical Safety
- Never jelq fully erect (injury risk)
- Stop if pain or excessive swelling
- Dark spots indicate too much pressure
- Rest days are mandatory`,
      ['jelqing', 'girth', 'beginner', 'milking', 'basic', 'foundation'],
      9
    ),

    createKnowledgeDocument(
      'pe-girth-beginner-002',
      'girth',
      'Wet vs Dry Jelqing Techniques',
      `## Jelqing Variations: Wet and Dry Methods

Different jelqing styles suit different preferences and goals.

### Wet Jelqing
- **Lubrication**: Water-based or coconut oil
- **Benefits**: Smoother motion, less friction
- **Technique**: Continuous gliding strokes
- **Best for**: Beginners, sensitive skin

### Dry Jelqing
- **No lubrication**: Uses natural skin movement
- **Benefits**: More intense, better grip
- **Technique**: Skin moves with hand
- **Best for**: Uncircumcised, experienced users

### Choosing Your Method
- Start with wet for safety
- Dry requires more skill
- Can alternate methods
- Listen to your body's response

### Session Comparison
- Wet: 10-15 minute sessions
- Dry: 5-10 minute sessions (more intense)`,
      ['jelqing', 'wet', 'dry', 'techniques', 'beginner', 'girth'],
      8
    ),

    createKnowledgeDocument(
      'pe-girth-beginner-003',
      'girth',
      'Basic Pumping Introduction',
      `## Penis Pumping for Beginners

Vacuum pumping creates negative pressure to expand tissues.

### Equipment Needed
- Quality cylinder (proper fit crucial)
- Hand or electric pump
- Pressure gauge (essential)
- Water-based lubricant

### Sizing Guidelines
- Cylinder 0.25-0.5" wider than erect girth
- Length 2" longer than erect length
- Too large = ineffective
- Too small = dangerous

### Beginner Protocol
1. **Warm up**: 10 minutes heat
2. **Enter cylinder**: Semi-erect
3. **Pump slowly**: Gradual pressure increase
4. **Hold**: 5-10 minutes at 3-5 HG
5. **Release**: Slowly reduce pressure
6. **Massage**: 5 minutes between sets

### Safety Rules
- Never exceed 10 HG pressure
- Start with 3-5 HG only
- Watch for fluid buildup
- Stop if pain occurs`,
      ['pumping', 'vacuum', 'beginner', 'girth', 'cylinder', 'pressure'],
      9
    ),

    createKnowledgeDocument(
      'pe-girth-beginner-004',
      'girth',
      'Girth-Focused Kegel Exercises',
      `## Kegels for Girth Enhancement

Strengthening pelvic floor muscles improves erection quality and apparent girth.

### Basic Kegel Technique
1. **Identify muscles**: Stop urination mid-stream
2. **Isolate contraction**: Don't flex other muscles
3. **Hold contraction**: 5-10 seconds
4. **Release slowly**: Controlled relaxation
5. **Rest**: Equal time between contractions

### Girth Benefits
- Harder erections = larger appearance
- Better blood retention
- Improved staying power
- Enhanced pump effectiveness

### Training Program
- Week 1: 20 reps, 5-second holds
- Week 2-3: 30 reps, 10-second holds
- Month 2+: 50 reps, varied holds

### Advanced Variations
- Reverse kegels (pushing out)
- Erect kegels (with erection)
- Towel raises (resistance training)`,
      ['kegels', 'pelvic', 'floor', 'girth', 'erection', 'beginner'],
      8
    ),

    // Intermediate Girth Documents (4)
    createKnowledgeDocument(
      'pe-girth-intermediate-001',
      'girth',
      'Advanced Jelqing Techniques',
      `## Intermediate Jelqing Variations

Progressive jelqing methods for experienced practitioners.

### V-Jelq (Intense Focus)
1. Form V with two fingers
2. Focus pressure on sides
3. Targets corpus cavernosum
4. Higher intensity than standard

### Horse Squeeze
1. Full OK grip at base
2. Squeeze and hold 10-20 seconds
3. Kegel during hold
4. Release and massage

### Uli Exercise
1. 90%+ erection required
2. Tight grip at base
3. Second hand squeezes glans
4. Hold 30 seconds maximum

### Slow Squash Jelq (SSJ)
1. Dual hand technique
2. One blocks at glans
3. Other jelqs into block
4. Extreme expansion focus

### Safety Critical
- These are intense techniques
- Master basics first
- Limit to 2-3 weekly
- Monitor for injuries closely`,
      ['jelqing', 'advanced', 'intermediate', 'girth', 'horse', 'uli'],
      8
    ),

    createKnowledgeDocument(
      'pe-girth-intermediate-002',
      'girth',
      'Progressive Pumping Protocols',
      `## Intermediate Vacuum Pumping

Advanced pumping strategies for girth development.

### Pyramid Sets
- Set 1: 5 min at 3 HG
- Set 2: 7 min at 5 HG
- Set 3: 10 min at 7 HG
- Set 4: 7 min at 5 HG
- Set 5: 5 min at 3 HG

### Interval Pumping
- 2 min high pressure (7-8 HG)
- 1 min low pressure (3 HG)
- Repeat 5-10 cycles
- Promotes expansion/recovery

### Water Pumping
- Fill cylinder with warm water
- More uniform expansion
- Less fluid buildup
- Better for longer sessions

### Packing the Tube
- Goal: Penis fills cylinder
- Indicates maximum expansion
- Requires proper cylinder size
- Sign to end session

### Recovery Protocol
- 24-48 hours between sessions
- Use cock ring post-pump (10 min max)
- Massage and heat therapy`,
      ['pumping', 'intermediate', 'pyramid', 'interval', 'water', 'girth'],
      8
    ),

    createKnowledgeDocument(
      'pe-girth-intermediate-003',
      'girth',
      'Clamping Fundamentals',
      `## Clamping for Girth (Advanced Technique)

Clamping restricts blood outflow for extreme engorgement.

### Prerequisites
- 6+ months PE experience
- Excellent EQ (erection quality)
- Understanding of risks
- Quality equipment

### Equipment
- Cable clamp or toe shield
- Wrap material for padding
- Timer (critical)
- Emergency release plan

### Basic Protocol
1. Achieve 100% erection
2. Apply wrap at base
3. Attach clamp over wrap
4. Tighten to restrict outflow
5. Maximum 10 minutes
6. Release immediately if numbness

### Progressive Approach
- Week 1: 5 minutes x 1 set
- Week 2-3: 5 minutes x 2 sets
- Month 2: 7-10 minutes x 2 sets
- Never exceed 10 minutes per set

### Extreme Warnings
- High injury risk
- Never sleep with clamp
- Blue/cold = immediate release
- Not for beginners`,
      ['clamping', 'advanced', 'girth', 'restriction', 'engorgement', 'cable'],
      9
    ),

    createKnowledgeDocument(
      'pe-girth-intermediate-004',
      'girth',
      'Girth Routine Combinations',
      `## Combining Girth Techniques

Strategic combination of methods for optimal results.

### The Girth Blaster Routine
1. Warm-up: 10 minutes
2. Jelqing: 100-150 reps
3. Pumping: 10 minutes at 5-7 HG
4. Jelqing: 50 reps
5. Cool-down massage

### Pump and Clamp Protocol
1. Pump: 10 minutes moderate pressure
2. Release and massage
3. Clamp: 5-7 minutes
4. Massage thoroughly
5. Light pump: 5 minutes

### Jelq and Squeeze Combo
1. Wet jelq: 100 reps
2. Horse squeezes: 10 x 10 seconds
3. Wet jelq: 100 reps
4. Uli exercise: 5 x 30 seconds
5. Cool-down jelq: 50 reps

### Recovery Between Combos
- Minimum 48 hours rest
- Assess tissue condition
- Reduce if overworked
- Quality over quantity`,
      ['combination', 'routine', 'intermediate', 'girth', 'protocol', 'blaster'],
      8
    ),

    // Advanced Girth Documents (4)
    createKnowledgeDocument(
      'pe-girth-advanced-001',
      'girth',
      'Extreme Pumping Protocols',
      `## Advanced Pumping for Maximum Girth

High-pressure and extended pumping strategies.

### High-Pressure Protocol
- Requires 1+ year experience
- 10-12 HG for short periods
- Maximum 5 minutes at high pressure
- Extensive conditioning required

### Marathon Sessions
- Low pressure (3-5 HG)
- Extended time (30-60 minutes)
- With breaks every 10 minutes
- Focus on tissue expansion

### Dual Cylinder Method
- Start with larger cylinder
- Pump to moderate expansion
- Switch to fitted cylinder
- Pack the tube completely

### Chemical Enhancement
- L-Arginine pre-pump
- Viagra/Cialis (with doctor approval)
- Topical vasodilators
- Enhanced blood flow

### Permanent Gains Focus
- Consistency over intensity
- 5-6 days per week
- Moderate pressure
- Long-term commitment required`,
      ['pumping', 'extreme', 'advanced', 'girth', 'marathon', 'pressure'],
      8
    ),

    createKnowledgeDocument(
      'pe-girth-advanced-002',
      'girth',
      'Modified Jelqing for Extreme Girth',
      `## Extreme Jelqing Modifications

Advanced variations for experienced practitioners only.

### Erect Jelqing (Dangerous)
- 80-90% erection level
- Extremely light pressure
- 5-second strokes
- Maximum 20-30 reps
- High injury risk

### Dry Clamped Jelqing
- Light clamp at base
- Jelq with restriction
- Extreme engorgement
- 5 minutes maximum
- Expert technique only

### Double-Handed Jelq
- Both hands work simultaneously
- One pushes, one pulls
- Creates compression zone
- Very intense technique

### Bend Jelqing
- Slight curve during stroke
- Targets specific areas
- Corrects asymmetry
- Requires perfect control

### Recovery Essential
- These cause micro-tears
- 72 hours minimum rest
- Monitor for injury signs
- Reduce if pain occurs`,
      ['jelqing', 'extreme', 'advanced', 'erect', 'modified', 'girth'],
      8
    ),

    createKnowledgeDocument(
      'pe-girth-advanced-003',
      'girth',
      'Permanent Girth Cementing',
      `## Cementing Girth Gains

Strategies to make girth gains permanent.

### The Cementing Process
- Gains need consistent reinforcement
- 6-12 months to become "permanent"
- Maintenance required indefinitely
- Individual variation significant

### Cementing Routine
1. Reduce intensity by 30%
2. Maintain frequency
3. Focus on EQ improvement
4. Light pumping 3x weekly
5. Continue for 6+ months

### Signs of Cemented Gains
- Size maintains without PE
- Less temporary swelling
- Better flaccid hang
- Improved vascularity

### Long-Term Maintenance
- Weekly light sessions
- Monthly measurement checks
- Adjust based on changes
- Accept natural variance

### Realistic Expectations
- 0.5-1" girth possible
- Takes 1-2 years minimum
- Some loss normal without maintenance`,
      ['cementing', 'permanent', 'gains', 'girth', 'maintenance', 'advanced'],
      7
    ),

    createKnowledgeDocument(
      'pe-girth-advanced-004',
      'girth',
      'Girth Enhancement Surgery Considerations',
      `## Surgical Girth Options vs PE

Comparing surgical and natural girth enhancement.

### Surgical Options
1. **Fat injection**: Temporary, uneven results
2. **Dermal grafts**: More permanent, scarring
3. **Silicone implants**: Unnatural feel
4. **PMMA injections**: Permanent but risky

### PE Advantages
- Natural tissue expansion
- No surgical risks
- Cost-effective
- Reversible if stopped
- Maintains sensation

### Surgical Risks
- Infection possibility
- Nerve damage risk
- Aesthetic issues common
- Sexual function impact
- Expensive revisions

### Hybrid Approach
- PE first for natural gains
- Surgery only if PE fails
- PE post-surgery for optimization
- Realistic expectations crucial

### Final Recommendation
- Try PE for 18-24 months first
- Most achieve goals naturally
- Surgery last resort only`,
      ['surgery', 'girth', 'injection', 'dermal', 'silicone', 'comparison'],
      6
    )
  ];
}

/**
 * Create 8+ EQ Enhancement Documents
 */
function createEQDocuments() {
  return [
    createKnowledgeDocument(
      'pe-eq-exercises-001',
      'eq',
      'Kegel Exercises for EQ',
      `## Kegel Exercises for Erection Quality

Strengthening the PC muscle for better erections.

### Finding Your PC Muscle
- Stop urination mid-stream
- The muscle used is your PC muscle
- Also called pelvic floor muscle
- Critical for erection control

### Basic Kegel Routine
1. Contract PC muscle firmly
2. Hold for 5-10 seconds
3. Release slowly
4. Rest 5-10 seconds
5. Repeat 20-50 times

### Progressive Training
- Week 1: 20 reps, 5-second holds
- Week 2-4: 30 reps, 10-second holds
- Month 2: 50 reps, varied holds
- Advanced: 100+ reps daily

### EQ Benefits
- Harder erections
- Better staying power
- Improved ejaculation control
- Enhanced blood flow`,
      ['kegels', 'PC', 'muscle', 'erection', 'quality', 'pelvic'],
      9
    ),

    createKnowledgeDocument(
      'pe-eq-exercises-002',
      'eq',
      'Reverse Kegels for Balance',
      `## Reverse Kegels - The Missing Piece

Balancing PC muscle with reverse kegels prevents over-tightness.

### Reverse Kegel Technique
1. Instead of clenching, push out gently
2. Like trying to urinate faster
3. Or passing gas deliberately
4. Hold for 5-10 seconds
5. Relax completely

### Why Reverse Kegels Matter
- Prevents PC muscle imbalance
- Reduces premature ejaculation
- Improves blood flow
- Enhances relaxation

### Balanced Routine
- 1 regular kegel
- 1 reverse kegel
- Maintain 1:1 ratio
- 20-30 of each daily

### Advanced Applications
- During sex for control
- Before jelqing sessions
- Post-workout recovery
- Tension release`,
      ['reverse', 'kegels', 'balance', 'relaxation', 'PC', 'muscle'],
      8
    ),

    createKnowledgeDocument(
      'pe-eq-exercises-003',
      'eq',
      'Cardio Training for EQ',
      `## Cardiovascular Fitness and EQ

Heart health directly impacts erection quality.

### Cardio Benefits for EQ
- Improved blood flow
- Better arterial health
- Reduced blood pressure
- Enhanced stamina
- Stress reduction

### Recommended Cardio
1. **HIIT Training**: 20 minutes 3x weekly
2. **Running**: 30-45 minutes moderate pace
3. **Swimming**: Full body, low impact
4. **Cycling**: Great for pelvic blood flow
5. **Jump Rope**: Efficient and effective

### Minimum Requirements
- 150 minutes moderate cardio weekly
- Or 75 minutes vigorous cardio
- Spread across 3-5 sessions
- Consistency is key

### EQ Improvements Timeline
- 2 weeks: Noticeable energy increase
- 4 weeks: Better morning erections
- 8 weeks: Significant EQ improvement
- 12 weeks: Sustained enhancement`,
      ['cardio', 'fitness', 'blood', 'flow', 'heart', 'health'],
      8
    ),

    createKnowledgeDocument(
      'pe-eq-exercises-004',
      'eq',
      'Edging for Stamina and Control',
      `## Edging Practice for EQ and Control

Building stamina and erection control through edging.

### Basic Edging Technique
1. Achieve full erection
2. Stimulate to 80-90% of climax
3. Stop all stimulation
4. Allow arousal to drop to 50%
5. Repeat 3-5 cycles

### Benefits for EQ
- Improved erection control
- Increased stamina
- Better awareness
- Enhanced hardness
- Mental discipline

### Progressive Training
- Week 1: 10-minute sessions
- Week 2-4: 20-minute sessions
- Month 2: 30+ minute sessions
- Advanced: 45-60 minutes

### Integration with PE
- Edge before jelqing
- Helps maintain proper erection level
- Improves session quality
- Enhances gains`,
      ['edging', 'stamina', 'control', 'erection', 'practice', 'arousal'],
      7
    ),

    createKnowledgeDocument(
      'pe-eq-lifestyle-001',
      'eq',
      'Diet and Nutrition for EQ',
      `## Nutritional Support for Erection Quality

Diet directly impacts vascular health and erections.

### Key Nutrients for EQ
1. **L-Arginine**: Nitric oxide precursor
2. **L-Citrulline**: Converts to arginine
3. **Zinc**: Testosterone production
4. **Vitamin D**: Hormone regulation
5. **Omega-3**: Vascular health

### Foods That Improve EQ
- Dark leafy greens (nitrates)
- Beets (nitric oxide)
- Dark chocolate (flavonoids)
- Pistachios (arginine)
- Watermelon (citrulline)
- Oysters (zinc)

### Foods to Avoid
- Processed foods
- Excessive alcohol
- High sodium
- Trans fats
- Excessive sugar

### Hydration Importance
- 3-4 liters water daily
- Critical for blood volume
- Affects all PE exercises`,
      ['diet', 'nutrition', 'supplements', 'food', 'vitamins', 'health'],
      8
    ),

    createKnowledgeDocument(
      'pe-eq-lifestyle-002',
      'eq',
      'Sleep Optimization for EQ',
      `## Sleep Quality and Erection Health

Sleep is when testosterone peaks and recovery occurs.

### Sleep Requirements
- 7-9 hours nightly
- Consistent schedule
- Dark, cool room
- No screens before bed

### Sleep and Hormones
- Testosterone produced during sleep
- Growth hormone release
- Cortisol regulation
- Recovery processes

### EQ Impact of Poor Sleep
- Reduced morning erections
- Lower testosterone
- Decreased libido
- Poor recovery from PE

### Sleep Optimization Tips
1. Fixed bedtime routine
2. No caffeine after 2 PM
3. Exercise regularly (not late)
4. Manage stress levels
5. Consider melatonin if needed`,
      ['sleep', 'recovery', 'testosterone', 'hormones', 'rest', 'health'],
      7
    ),

    createKnowledgeDocument(
      'pe-eq-lifestyle-003',
      'eq',
      'Stress Management for EQ',
      `## Stress Reduction and Erection Quality

Chronic stress is the enemy of good erections.

### How Stress Affects EQ
- Increases cortisol
- Reduces testosterone
- Constricts blood vessels
- Impacts libido
- Disrupts sleep

### Stress Management Techniques
1. **Meditation**: 10-20 minutes daily
2. **Deep Breathing**: 4-7-8 technique
3. **Exercise**: Natural stress relief
4. **Yoga**: Combines movement and mindfulness
5. **Journaling**: Process emotions

### Quick Stress Relief
- 5-minute breathing exercise
- Cold shower
- Brief walk
- Progressive muscle relaxation
- Visualization

### Long-term Strategies
- Regular exercise routine
- Healthy work-life balance
- Social connections
- Professional help if needed`,
      ['stress', 'cortisol', 'relaxation', 'mental', 'health', 'management'],
      7
    ),

    createKnowledgeDocument(
      'pe-eq-lifestyle-004',
      'eq',
      'Supplements for EQ Enhancement',
      `## Evidence-Based Supplements for EQ

Supplements that may support erection quality.

### Tier 1 (Strong Evidence)
1. **L-Citrulline**: 6-8g daily
2. **L-Arginine**: 3-6g daily
3. **Pycnogenol**: 120mg daily
4. **Vitamin D3**: 2000-5000 IU

### Tier 2 (Moderate Evidence)
- **Zinc**: 15-30mg daily
- **Magnesium**: 400mg daily
- **Ashwagandha**: 600mg daily
- **Maca Root**: 1.5-3g daily

### Tier 3 (Limited Evidence)
- **Horny Goat Weed**
- **Tribulus Terrestris**
- **Fenugreek**
- **D-Aspartic Acid**

### Safety Notes
- Consult doctor before starting
- Start with single supplements
- Monitor for side effects
- Quality brands only`,
      ['supplements', 'vitamins', 'citrulline', 'arginine', 'zinc', 'health'],
      7
    )
  ];
}

/**
 * Create 10+ Equipment Guide Documents
 */
function createEquipmentDocuments() {
  return [
    createKnowledgeDocument(
      'pe-equipment-pumps-001',
      'equipment',
      'Penis Pump Selection Guide',
      `## Choosing the Right Penis Pump

Comprehensive guide to selecting pumping equipment.

### Cylinder Sizing (Critical)
- **Diameter**: Your girth + 0.25-0.5 inches
- **Length**: Your length + 2 inches minimum
- Too large = ineffective
- Too small = dangerous

### Pump Types
1. **Manual pumps**: Budget-friendly, good control
2. **Electric pumps**: Consistent pressure, hands-free
3. **Water pumps**: Even expansion, comfortable
4. **Hand-squeeze**: Portable, simple

### Essential Features
- Pressure gauge (mandatory)
- Quick release valve
- Comfortable base seal
- Clear cylinder for monitoring

### Quality Brands
- LA Pump (premium)
- Bathmate (water pumps)
- LeLuv (budget option)
- Custom sizes available

### Budget Expectations
- Entry level: $50-100
- Mid-range: $100-250
- Premium: $250+`,
      ['pump', 'cylinder', 'sizing', 'equipment', 'selection', 'vacuum'],
      9
    ),

    createKnowledgeDocument(
      'pe-equipment-pumps-002',
      'equipment',
      'Water Pumping Systems',
      `## Bathmate and Water-Based Pumping

Water pumps offer unique advantages for girth work.

### Water Pump Benefits
- Even pressure distribution
- Less fluid buildup
- More comfortable sessions
- Can use in shower/bath
- Better for longer sessions

### Popular Models
1. **Bathmate Hydromax**: Most popular
2. **Bathmate HydroXtreme**: Premium features
3. **Penomet**: Alternative brand
4. **DIY conversions**: Regular pump + water

### Usage Protocol
1. Fill with warm water
2. Insert semi-erect
3. Pump to create seal
4. Hold 5-15 minutes
5. Release and repeat

### Maintenance
- Clean after every use
- Replace valves annually
- Check seals regularly
- Store dry`,
      ['water', 'pump', 'bathmate', 'hydro', 'shower', 'equipment'],
      8
    ),

    createKnowledgeDocument(
      'pe-equipment-pumps-003',
      'equipment',
      'Advanced Pumping Accessories',
      `## Pump Accessories and Modifications

Enhancing your pumping setup for better results.

### Useful Accessories
1. **Silicone sleeves**: Comfort and seal
2. **Donut inserts**: Prevent edema
3. **Cock rings**: Post-pump retention
4. **Heating pads**: Better expansion
5. **Digital gauge**: Precise pressure

### Cylinder Modifications
- Custom flanges for comfort
- Multiple cylinder sizes
- Length limiters
- Vibration attachments

### Safety Equipment
- Emergency shears (for rings)
- First aid supplies
- Arnica gel for bruising
- Timer with alerts

### Maintenance Supplies
- Silicone lubricant
- Replacement seals
- Cleaning supplies
- Storage case`,
      ['accessories', 'pump', 'modifications', 'safety', 'equipment', 'gauge'],
      7
    ),

    createKnowledgeDocument(
      'pe-equipment-hangers-001',
      'equipment',
      'Penis Hanger Types and Selection',
      `## Comprehensive Hanger Equipment Guide

Different hanger types for weight hanging.

### Vacuum Hangers
- **Pros**: Even distribution, comfortable
- **Cons**: Limited weight, blisters possible
- **Best for**: Beginners, all-day wear
- **Brands**: Total Man, Auto Extender

### Compression Hangers
- **Pros**: Heavy weights possible
- **Cons**: Learning curve, circulation issues
- **Best for**: Experienced users
- **Brands**: Bib Hanger, Mal Hanger

### Noose/Strap Style
- **Pros**: Simple, cheap
- **Cons**: Uncomfortable, risky
- **Best for**: Not recommended
- **Avoid**: High injury risk

### Selection Criteria
- Experience level
- Weight goals
- Circumcision status
- Budget available
- Time commitment`,
      ['hanger', 'vacuum', 'compression', 'weight', 'equipment', 'selection'],
      8
    ),

    createKnowledgeDocument(
      'pe-equipment-hangers-002',
      'equipment',
      'Weight Selection and Progression',
      `## Weights for Hanging - Complete Guide

Building your weight collection for hanging.

### Starting Weights
- 1.25 lbs plates
- 2.5 lbs plates
- 5 lbs plates
- 10 lbs plates (advanced)

### Weight Types
1. **Olympic plates**: Standard, widely available
2. **Magnetic weights**: Easy adjustments
3. **Lead shot bags**: Custom weights
4. **Water bottles**: Emergency option

### Progressive Loading
- Start: 2.5 lbs
- Week 2-4: 5 lbs
- Month 2: 7.5 lbs
- Month 3: 10 lbs
- Advanced: 15+ lbs

### Storage and Organization
- Weight tree or rack
- Labeled clearly
- Easy access during sessions
- Safe storage location`,
      ['weights', 'hanging', 'progression', 'plates', 'loading', 'equipment'],
      7
    ),

    createKnowledgeDocument(
      'pe-equipment-hangers-003',
      'equipment',
      'Hanging Attachment and Wrap Methods',
      `## Proper Attachment for Safe Hanging

Critical techniques for hanger attachment.

### Wrapping Materials
1. **Theraband**: Gold standard
2. **Cloth strips**: Budget option
3. **Silicone sleeves**: Reusable
4. **Medical tape**: Emergency use

### Wrapping Technique
1. Start behind glans
2. Spiral wrap downward
3. Overlap by 50%
4. 2-3 layers typical
5. Smooth, no wrinkles

### Attachment Process
1. Achieve 30-50% erection
2. Apply wrap properly
3. Position hanger correctly
4. Tighten gradually
5. Test before adding weight

### Troubleshooting
- Slippage: Better wrap needed
- Pain: Reduce weight/time
- Numbness: Too tight
- Cold: Circulation issue`,
      ['wrapping', 'attachment', 'hanger', 'theraband', 'safety', 'technique'],
      9
    ),

    createKnowledgeDocument(
      'pe-equipment-extenders-001',
      'equipment',
      'Penis Extender Selection',
      `## Traction Devices and Extenders

All-day stretching devices for length.

### Extender Types
1. **Rod-based**: Traditional, adjustable
2. **Belt systems**: More comfortable
3. **Vacuum extenders**: Best retention
4. **Leg straps**: Simple traction

### Quality Features
- Medical grade materials
- Multiple rod lengths
- Comfort accessories
- Tension indicators
- Replacement parts available

### Popular Brands
- Size Genetics (premium)
- Quick Extender Pro
- Penimaster Pro
- JES Extender
- Male Edge

### Cost Considerations
- Entry: $100-200
- Quality: $200-400
- Premium: $400+
- Replacement parts add up`,
      ['extender', 'traction', 'device', 'all-day', 'stretcher', 'equipment'],
      8
    ),

    createKnowledgeDocument(
      'pe-equipment-extenders-002',
      'equipment',
      'Extender Fitting and Comfort',
      `## Making Extenders Comfortable

Tips for all-day extender wear.

### Proper Fitting
1. Adjust base ring size
2. Set appropriate length
3. Calibrate tension (start low)
4. Use comfort accessories
5. Test for 30 minutes first

### Comfort Modifications
- Silicone straps/sleeves
- Padding additions
- Vacuum cup upgrades
- Anti-slip materials
- Custom modifications

### Wearing Schedule
- Week 1: 2 hours daily
- Week 2-3: 4 hours daily
- Month 2: 6 hours daily
- Goal: 8+ hours daily
- Take hourly breaks

### Common Issues
- Slippage: Use vacuum attachment
- Soreness: Reduce time/tension
- Circulation: Check every hour
- Discretion: Loose clothing`,
      ['extender', 'comfort', 'fitting', 'wearing', 'schedule', 'modifications'],
      7
    ),

    createKnowledgeDocument(
      'pe-equipment-extenders-003',
      'equipment',
      'ADS Systems and DIY Options',
      `## All Day Stretcher Alternatives

Simple ADS options beyond commercial extenders.

### Commercial ADS
- Leg straps
- Belt systems
- Sleeve stretchers
- Vacuum ADS
- Silicone stretchers

### DIY Options (Use Caution)
1. **Sock method**: Weight in sock
2. **Tape method**: Medical tape stretch
3. **Wrap method**: ACE bandage
4. **Ring method**: Silicone rings

### Safety Considerations
- Never restrict circulation
- Check hourly minimum
- Start with minimal tension
- Quality materials only
- Have emergency removal plan

### ADS vs Extenders
- ADS: Lower tension, longer time
- Extenders: Higher tension, measured
- Both: Complement active PE
- Choose: Based on lifestyle`,
      ['ADS', 'all-day', 'stretcher', 'DIY', 'alternatives', 'equipment'],
      7
    ),

    createKnowledgeDocument(
      'pe-equipment-extenders-004',
      'equipment',
      'Equipment Maintenance and Care',
      `## Maintaining Your PE Equipment

Proper care extends equipment life and safety.

### Cleaning Protocols
1. **After each use**: Basic cleaning
2. **Weekly**: Deep clean
3. **Monthly**: Full inspection
4. **Products**: Mild soap, isopropyl alcohol

### Pump Maintenance
- Replace seals every 6 months
- Check gauge accuracy
- Lubricate moving parts
- Store in case

### Hanger Care
- Inspect for wear
- Replace padding regularly
- Check attachment points
- Clean thoroughly

### Extender Upkeep
- Tighten screws monthly
- Replace springs/elastics
- Clean all contact points
- Organize spare parts

### When to Replace
- Visible wear/damage
- Lost effectiveness
- Safety concerns
- Missing parts`,
      ['maintenance', 'care', 'cleaning', 'equipment', 'replacement', 'safety'],
      8
    )
  ];
}

/**
 * Create 5+ Progression Path Documents
 */
function createProgressionDocuments() {
  return [
    createKnowledgeDocument(
      'pe-progression-beginner-path',
      'progression',
      'Complete Beginner Progression Path',
      `## The First Year: Beginner's Journey

Structured progression for PE newcomers.

### Month 1-3: Foundation Phase
**Goal**: Conditioning and technique
- Manual stretching only
- Basic jelqing introduction
- Kegel exercises daily
- Focus on form over intensity
- 20-30 minute sessions

### Month 4-6: Development Phase
**Goal**: Introduce tools and variation
- Continue manual work
- Add basic pumping (optional)
- Introduce JAI stretches
- Increase session to 30-40 minutes
- Track measurements monthly

### Month 7-9: Specialization Phase
**Goal**: Find what works best
- Try different techniques
- Consider hanging or extenders
- Optimize routine based on response
- 40-50 minute sessions
- Address weak points

### Month 10-12: Advancement Phase
**Goal**: Prepare for intermediate
- Master current techniques
- Gradual intensity increase
- Cement initial gains
- Plan year 2 strategy

### Expected Results
- Length: 0.5-1.0 inches
- Girth: 0.25-0.5 inches
- EQ: Significant improvement`,
      ['beginner', 'progression', 'path', 'first', 'year', 'journey'],
      9
    ),

    createKnowledgeDocument(
      'pe-progression-intermediate-path',
      'progression',
      'Intermediate Progression Strategy',
      `## Year 2-3: Intermediate Development

Building on foundation with advanced techniques.

### Prerequisites
- 1 year consistent PE
- Mastered basic techniques
- Good injury prevention habits
- Realistic expectations set

### Intermediate Goals
- Refine technique selection
- Increase intensity safely
- Target specific dimensions
- Maintain consistency

### Technique Progression
1. **Length focus**: Hanging 10-15 lbs, BTC position
2. **Girth focus**: Clamping introduction, advanced pumping
3. **Balanced**: Alternate focus monthly

### Sample Routine Structure
**Monday/Wednesday/Friday**: Primary work
- 15 min warm-up
- 30-45 min main exercises
- 10 min cool-down

**Tuesday/Thursday**: Light/Recovery
- ADS or extender wear
- Kegel exercises
- Light pumping

### Plateau Management
- Deconditioning breaks
- Technique rotation
- Intensity cycling
- Form refinement`,
      ['intermediate', 'progression', 'year', 'development', 'advanced', 'plateau'],
      8
    ),

    createKnowledgeDocument(
      'pe-progression-advanced-path',
      'progression',
      'Advanced Practitioner Path',
      `## Year 3+: Advanced PE Practice

Long-term strategies for experienced practitioners.

### Advanced Characteristics
- 2+ years consistent practice
- Near genetic potential
- Excellent body awareness
- Injury prevention mastery

### Advanced Goals
- Final size refinement
- Maintenance protocols
- Injury prevention
- Lifestyle integration

### Advanced Techniques
- Heavy hanging (15+ lbs)
- Extended clamping sessions
- Combination routines
- Experimental methods

### Periodization Model
**Gaining Phases** (3-4 months)
- High intensity
- Progressive overload
- 5-6 days/week
- New techniques

**Maintenance Phases** (2-3 months)
- Reduced intensity
- 3 days/week
- Focus on EQ
- Cement gains

### Reality Check
- Gains much slower
- Injury risk higher
- Maintenance becomes primary
- Consider goals met`,
      ['advanced', 'practitioner', 'long-term', 'maintenance', 'periodization'],
      7
    ),

    createKnowledgeDocument(
      'pe-progression-plateau-management',
      'progression',
      'Breaking Through Plateaus',
      `## Plateau Breaking Strategies

When progress stalls, strategic changes needed.

### Identifying True Plateaus
- No gains for 2-3 months
- Same routine becoming easy
- Lost motivation
- Measurements static

### Deconditioning Protocol
**Purpose**: Reset tissue adaptation
1. Complete break 2-4 weeks
2. No PE exercises at all
3. Maintain good EQ habits
4. Return with modified routine

### Shock Techniques
1. **Intensity shock**: Brief high-intensity period
2. **Volume shock**: Doubled volume for 1 week
3. **Technique shock**: Completely new exercises
4. **Angle shock**: New stretching angles

### Routine Cycling
- 4 weeks focus length
- 4 weeks focus girth
- 2 weeks maintenance
- Repeat with variations

### Supplementary Strategies
- Improve general health
- Address testosterone levels
- Enhance recovery
- Consider coaching/guidance

### Mental Approach
- Appreciate current gains
- Reset expectations
- Focus on quality over quantity`,
      ['plateau', 'breaking', 'stalled', 'gains', 'deconditioning', 'shock'],
      8
    ),

    createKnowledgeDocument(
      'pe-progression-deconditioning',
      'progression',
      'Strategic Deconditioning',
      `## Deconditioning for Renewed Gains

Strategic breaks to resensitize tissues.

### Why Deconditioning Works
- Tissues become adapted
- Reduces effectiveness
- Break resets sensitivity
- Returns "newbie gains"

### When to Decondition
- After 6-12 months continuous PE
- Hit stubborn plateau
- Feeling overtrained
- Before major routine change

### Deconditioning Protocol
**Week 1-2**: Complete cessation
- No PE exercises
- No devices
- Maintain regular sex/masturbation
- Focus on general health

**Week 3-4**: Extended break
- Continue no PE
- Light kegels okay
- Prepare new routine
- Gather motivation

### Return Strategy
1. Start at 50% previous intensity
2. Focus on perfect form
3. Gradually build back up
4. Try new techniques
5. Track carefully

### Expected Results
- Initial size loss (temporary)
- Rapid regains upon return
- Breakthrough previous plateau
- Renewed sensitivity to exercises`,
      ['deconditioning', 'break', 'reset', 'plateau', 'sensitivity', 'gains'],
      8
    )
  ];
}

/**
 * Create Enhanced Safety Documents
 */
function createEnhancedSafetyDocuments() {
  return [
    createKnowledgeDocument(
      'pe-safety-fundamentals',
      'safety',
      'Fundamental PE Safety Guidelines',
      `## Core Safety Principles for All PE

Essential safety rules that apply to all PE practices.

### Universal Safety Rules
1. **Pain = Stop**: Never work through pain
2. **Start Conservative**: Low intensity, short duration
3. **Progress Gradually**: 10% increases maximum
4. **Rest Days Mandatory**: Minimum 2 per week
5. **Listen to Your Body**: When in doubt, rest

### Warning Signs (Stop Immediately)
- Sharp pain anywhere
- Numbness or tingling
- Color changes (purple, blue, white)
- Cold temperature
- Excessive swelling
- Blood spots/blisters
- Difficulty urinating

### Injury Prevention
- Always warm up 10+ minutes
- Never skip cool-down
- Maintain hygiene
- Quality equipment only
- Regular health checkups

### Emergency Protocols
1. If injury suspected: Stop all PE
2. Apply ice if swelling
3. Rest minimum 1 week
4. Seek medical help if serious
5. Return gradually when healed`,
      ['safety', 'fundamental', 'injury', 'prevention', 'warning', 'emergency'],
      10
    ),

    createKnowledgeDocument(
      'pe-safety-injury-management',
      'safety',
      'Injury Recognition and Treatment',
      `## Common PE Injuries and Treatment

Identifying and managing PE-related injuries.

### Common Injuries
1. **Burst blood vessels**: Red spots, rest 3-7 days
2. **Edema**: Fluid buildup, reduce intensity
3. **Thrombosed veins**: Hard lumps, medical attention
4. **Nerve damage**: Numbness, stop immediately
5. **Skin tears**: Broken skin, heal completely

### First Aid Protocols
**R.I.C.E Method**
- Rest: Stop all PE
- Ice: 20 minutes on/off
- Compression: Light wrap
- Elevation: Above heart level

### Recovery Timelines
- Minor spots: 3-7 days
- Bruising: 1-2 weeks
- Edema: 3-5 days
- Major injury: 4+ weeks
- When in doubt: Add extra rest

### Return to PE
1. Complete healing first
2. Start at 25% previous intensity
3. Gradually build back
4. Monitor carefully
5. Stop if issues return

### Medical Attention Needed
- Severe pain
- Lasting numbness
- Significant swelling
- Difficulty with urination
- Any infection signs`,
      ['injury', 'treatment', 'recovery', 'first-aid', 'safety', 'medical'],
      10
    ),

    createKnowledgeDocument(
      'pe-safety-medical-disclaimer',
      'safety',
      'Medical Considerations and Disclaimers',
      `## Important Medical Information

Critical health considerations for PE practitioners.

### Medical Contraindications
Do NOT attempt PE with:
- Blood clotting disorders
- Peyronie's disease (without doctor approval)
- Active infections
- Recent surgery
- Cardiovascular issues (uncontrolled)
- Diabetes (uncontrolled)

### Medications That Affect PE
- Blood thinners: Higher injury risk
- ED medications: Use cautiously
- Blood pressure meds: Monitor closely
- Steroids: May affect healing
- Antidepressants: May affect EQ

### Regular Health Monitoring
- Blood pressure checks
- Cardiovascular health
- Hormone levels (testosterone)
- General physical exams
- Mental health awareness

### Legal Disclaimer
**This information is educational only. Not medical advice. Consult healthcare providers before beginning any PE program. PE carries inherent risks including permanent injury. Proceed at your own risk.**

### Doctor Consultation Recommended
- Before starting PE
- If pre-existing conditions
- When injuries occur
- For hormone optimization
- Before using supplements`,
      ['medical', 'disclaimer', 'contraindications', 'health', 'consultation', 'safety'],
      10
    )
  ];
}

// Add execution function at the end
if (require.main === module) {
  deployExpandedKnowledge().catch(console.error);
}

module.exports = {
  deployExpandedKnowledge,
  createLengthDocuments,
  createGirthDocuments,
  createEQDocuments,
  createEquipmentDocuments,
  createProgressionDocuments,
  createEnhancedSafetyDocuments
};