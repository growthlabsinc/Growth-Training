/**
 * Deploy PE Knowledge Base to Firebase
 * Story 3.2: Deploy PE Knowledge Base
 *
 * This script deploys comprehensive PE training knowledge to the AI Coach
 * knowledge base, covering all aspects of PE training with a safety-first approach.
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
 * Knowledge document factory function
 */
function createKnowledgeDocument(id, category, title, content, keywords, priority = 5) {
  return {
    id: id,
    category: category,
    title: title,
    content: content,
    keywords: keywords,
    priority: priority,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };
}

/**
 * PE Knowledge Base Content
 */
const peKnowledgeBase = {
  // Length Training Knowledge
  length: [
    createKnowledgeDocument(
      'pe-length-001',
      'length',
      'Manual Stretching Techniques',
      `## Manual Stretching for Length Training

Manual stretching is one of the foundational PE exercises for length gains. It involves applying controlled traction to elongate tissues over time.

### Basic Technique
1. **Warm up**: Apply heat or do light massage for 5-10 minutes
2. **Grip**: Form OK grip behind the glans (never grip the glans directly)
3. **Stretch**: Pull gently in various directions (up, down, left, right, straight out)
4. **Hold**: Maintain stretch for 30-60 seconds per direction
5. **Rest**: Release and massage for blood flow between sets

### Safety Guidelines
- Never stretch to the point of pain
- Stop if numbness occurs
- Start with 5-10 minute sessions
- Progress gradually over weeks
- Minimum 1-2 rest days per week

### Progression Timeline
- Beginner: 5-10 minutes, light tension
- Intermediate: 10-20 minutes, moderate tension
- Advanced: 20-30 minutes, higher tension

### Expected Results
- Initial gains: 0.25-0.5" in 3-6 months
- Continued gains: 0.5-1.0" total over 12-18 months
- Individual results vary significantly

**Medical Disclaimer**: Consult a healthcare provider before beginning any PE training program.`,
      ['stretching', 'manual', 'length', 'technique', 'beginner', 'traction', 'elongation'],
      8
    ),

    createKnowledgeDocument(
      'pe-length-002',
      'length',
      'Hanging for Length',
      `## Hanging Weight Training

Hanging involves attaching weights to apply consistent traction for length gains. This is an intermediate to advanced technique.

### Equipment Needed
- Quality hanger device (vacuum or compression)
- Weights (start with 2.5-5 lbs)
- Wrap material for protection
- Timer for tracking sessions

### Basic Protocol
1. **Preparation**: Warm up thoroughly
2. **Attachment**: Secure hanger behind glans with proper wrap
3. **Weight**: Start with minimal weight (2.5-5 lbs)
4. **Duration**: Begin with 10-15 minute sets
5. **Sets**: 1-3 sets with rest between

### Safety Critical
- NEVER exceed 20 minutes without break
- Blood flow must be maintained
- Stop immediately if cold or numb
- Maximum 20 lbs even for advanced users
- Inspect equipment before each use

### Progression
- Month 1: 2.5-5 lbs, 10-15 minutes
- Month 2-3: 5-10 lbs, 15-20 minutes
- Month 4+: 10-15 lbs, 20 minutes max

### Common Mistakes to Avoid
- Too much weight too soon
- Ignoring discomfort signals
- Inadequate warm-up
- Poor hanger attachment
- Insufficient rest days

**Warning**: Improper hanging can cause permanent injury. Start conservatively and prioritize safety over aggressive gains.`,
      ['hanging', 'weights', 'length', 'advanced', 'hanger', 'traction', 'intermediate'],
      7
    ),

    createKnowledgeDocument(
      'pe-length-003',
      'length',
      'Extender Devices',
      `## Penis Extenders for Length

Extenders provide consistent, low-force traction over extended periods. Medical studies support their effectiveness for length gains.

### How Extenders Work
- Apply constant gentle stretch
- Promote cellular division (mitosis)
- Typically worn 4-8 hours daily
- Results accumulate over months

### Usage Guidelines
1. **Start Gradually**: 2-4 hours daily initially
2. **Increase Slowly**: Add 1 hour weekly
3. **Tension Settings**: Begin with lowest setting
4. **Break Schedule**: 15-minute break every hour
5. **Rest Days**: 1-2 days off weekly

### Realistic Expectations
- 3 months: 0.25-0.5" possible
- 6 months: 0.5-1.0" possible
- 12 months: 1.0-1.5" possible
- Results vary by individual

### Safety Considerations
- Quality device essential
- Proper fitting crucial
- Never sleep wearing device
- Monitor circulation constantly
- Stop if pain or numbness occurs

**Medical Note**: Some extenders have medical approval for Peyronie's disease treatment.`,
      ['extender', 'traction', 'length', 'device', 'stretching', 'medical', 'consistent'],
      7
    )
  ],

  // Girth Training Knowledge
  girth: [
    createKnowledgeDocument(
      'pe-girth-001',
      'girth',
      'Pumping for Girth',
      `## Vacuum Pumping for Girth Enhancement

Pumping uses vacuum pressure to expand tissues, promoting girth gains through controlled expansion training.

### Equipment Essentials
- Quality vacuum pump with gauge
- Properly sized cylinder
- Water-based lubricant
- Timer for session tracking

### Basic Pumping Protocol
1. **Warm Up**: 5-10 minutes heat/massage
2. **Lubricate**: Apply lube to base and cylinder
3. **Initial Pump**: 3-5 HG pressure
4. **Duration**: 5-10 minutes first session
5. **Release**: Slowly release vacuum
6. **Massage**: 5 minutes between sets

### Pressure Guidelines
- Beginner: 3-5 HG
- Intermediate: 5-7 HG
- Advanced: 7-10 HG max
- NEVER exceed 10 HG

### Safety Protocol
- Start with short sessions
- Monitor for discoloration
- Stop if pain occurs
- Check for fluid buildup
- Avoid daily pumping initially

### Expected Results
- Temporary expansion immediate
- Permanent gains: 0.25-0.5" girth over 6-12 months
- Best combined with manual exercises

**Critical Warning**: Excessive pressure or duration can cause blisters, bruising, or permanent damage.`,
      ['pumping', 'vacuum', 'girth', 'pressure', 'expansion', 'cylinder', 'HG'],
      8
    ),

    createKnowledgeDocument(
      'pe-girth-002',
      'girth',
      'Manual Girth Exercises',
      `## Manual Exercises for Girth

Manual girth exercises like jelqing promote blood flow and controlled expansion for girth development.

### Jelqing Technique
1. **Erection Level**: 40-70% (never fully erect)
2. **Lubrication**: Essential to prevent injury
3. **Grip**: OK grip at base
4. **Stroke**: Slide grip toward glans (2-3 seconds)
5. **Pressure**: Firm but not painful
6. **Repetitions**: Start with 50-100

### Safety Guidelines
- Never jelq fully erect
- Stop if pain occurs
- Use adequate lubrication
- Warm up mandatory
- Cool down with light massage

### Progression Schedule
- Week 1-2: 50 jelqs, light pressure
- Week 3-4: 100 jelqs, moderate pressure
- Month 2: 150-200 jelqs
- Month 3+: 200-300 jelqs max

### Variations
- Standard jelq: Basic technique
- V-jelq: Focus on sides
- Uli exercise: Static squeeze (advanced)

### Results Timeline
- Month 1: Improved EQ
- Month 3: Minor girth increase
- Month 6+: 0.25-0.5" girth possible

**Medical Disclaimer**: These exercises carry risk of injury. Start conservatively and prioritize safety.`,
      ['jelqing', 'jelq', 'manual', 'girth', 'exercise', 'blood flow', 'expansion'],
      8
    ),

    createKnowledgeDocument(
      'pe-girth-003',
      'girth',
      'Clamping (Advanced)',
      `## Clamping for Advanced Girth Training

Clamping is an advanced technique using restriction to create expansion pressure. HIGH RISK - experienced users only.

### Prerequisites
- Minimum 6 months PE experience
- Excellent EQ (9-10/10)
- Understanding of injury signs
- Quality equipment

### Equipment Required
- Cable clamp or toe shield
- Wrap material
- Timer (critical)
- Emergency release plan

### Strict Protocol
1. **Full Erection**: 100% required
2. **Apply Clamp**: At base with wrap
3. **Duration**: 5 minutes maximum initially
4. **Sets**: 1-2 sets max with long breaks
5. **Frequency**: 2-3x weekly maximum

### Critical Safety Rules
- NEVER exceed 10 minutes
- Color monitoring essential
- Immediate release if cold/numb
- No alcohol/drugs before
- Partner awareness recommended

### Danger Signs (STOP IMMEDIATELY)
- Purple/dark discoloration
- Numbness or tingling
- Pain or discomfort
- Cold temperature
- Any unusual symptoms

**EXTREME WARNING**: Clamping can cause permanent erectile dysfunction, nerve damage, or tissue death if done incorrectly. This is the highest risk PE exercise.`,
      ['clamping', 'advanced', 'girth', 'restriction', 'high risk', 'experienced'],
      9
    )
  ],

  // EQ Training Knowledge
  eq: [
    createKnowledgeDocument(
      'pe-eq-001',
      'eq',
      'Kegel Exercises for EQ',
      `## Kegel Exercises for Erection Quality

Kegels strengthen the pelvic floor muscles, improving erection quality, control, and stamina.

### Locating PC Muscle
- Muscle used to stop urine mid-stream
- Can make erection "jump" when flexed
- Located between anus and testicles

### Basic Kegel Routine
1. **Contract**: Squeeze PC muscle
2. **Hold**: 5 seconds initially
3. **Release**: Relax completely
4. **Rest**: 5 seconds between reps
5. **Repeat**: 10-20 repetitions

### Progressive Training
- Week 1-2: 20 reps x 5 seconds
- Week 3-4: 30 reps x 10 seconds
- Month 2: 50 reps x 10 seconds
- Advanced: Add resistance with erection

### Reverse Kegels
- Push out gently (like urinating faster)
- Balances muscle development
- Helps prevent premature ejaculation
- 1:1 ratio with regular kegels

### Benefits
- Harder erections
- Better ejaculatory control
- Improved blood flow
- Enhanced stamina
- Potential size improvements

**Note**: Overtraining can cause temporary ED. Balance and rest are essential.`,
      ['kegel', 'PC muscle', 'pelvic floor', 'EQ', 'eq', 'erection', 'erection quality', 'stamina', 'control'],
      9
    ),

    createKnowledgeDocument(
      'pe-eq-002',
      'eq',
      'Cardiovascular Training for EQ',
      `## Cardiovascular Fitness and Erection Quality

Cardiovascular health directly impacts erection quality through improved blood flow and overall health.

### Recommended Cardio Activities
- Brisk walking: 30 minutes daily
- Jogging: 20-30 minutes 3x weekly
- Swimming: Excellent full-body option
- Cycling: Use proper seat
- HIIT: 15-20 minutes 2x weekly

### Target Heart Rate Zones
- Moderate: 50-70% max HR
- Vigorous: 70-85% max HR
- Max HR = 220 - age
- Aim for 150 minutes weekly

### Specific Benefits for EQ
- Improved blood vessel health
- Better nitric oxide production
- Reduced blood pressure
- Enhanced stamina
- Hormone optimization

### Complementary Exercises
- Squats: Boost testosterone
- Deadlifts: Full body strength
- Planks: Core stability
- Yoga: Flexibility and blood flow

### Timeline for Improvements
- Week 2: Better energy
- Month 1: Improved stamina
- Month 2: Noticeable EQ improvement
- Month 3+: Sustained benefits

**Health Note**: Consult physician before starting new exercise program, especially with cardiac conditions.`,
      ['cardio', 'cardiovascular', 'fitness', 'blood flow', 'EQ', 'exercise', 'health'],
      8
    ),

    createKnowledgeDocument(
      'pe-eq-003',
      'eq',
      'Lifestyle Factors for EQ',
      `## Lifestyle Optimization for Erection Quality

Multiple lifestyle factors significantly impact erection quality and PE training results.

### Nutrition Guidelines
- Increase nitric oxide foods (beets, leafy greens)
- Omega-3 fatty acids (fish, nuts)
- Reduce processed foods
- Limit alcohol consumption
- Stay hydrated (8-10 glasses daily)

### Sleep Optimization
- 7-9 hours nightly
- Consistent sleep schedule
- Cool, dark room
- Avoid screens before bed
- Morning erections indicate good hormonal health

### Stress Management
- Chronic stress reduces testosterone
- Practice meditation/mindfulness
- Regular exercise helps
- Work-life balance important
- Consider counseling if needed

### Supplements (Consult Doctor First)
- L-Arginine: Nitric oxide precursor
- L-Citrulline: Converts to L-Arginine
- Vitamin D3: Hormonal support
- Zinc: Testosterone production
- Magnesium: Muscle function

### Habits to Avoid
- Smoking (damages blood vessels)
- Excessive alcohol
- Drug use
- Porn addiction
- Sedentary lifestyle

**Medical Advisory**: Lifestyle changes should complement, not replace, medical treatment when needed.`,
      ['lifestyle', 'nutrition', 'sleep', 'stress', 'supplements', 'EQ', 'health'],
      8
    )
  ],

  // Safety Knowledge
  safety: [
    createKnowledgeDocument(
      'pe-safety-001',
      'safety',
      'Injury Prevention Guidelines',
      `## Comprehensive Injury Prevention for PE Training

Safety must be the absolute priority in all PE training. Prevention is always better than treatment.

### Universal Safety Rules
1. **Start Conservative**: Always begin with minimal intensity
2. **Progress Gradually**: 10% increase weekly maximum
3. **Listen to Your Body**: Discomfort okay, pain is not
4. **Rest is Mandatory**: Minimum 1-2 days off weekly
5. **Heat/Warmup**: Never skip preparation

### Warning Signs to Stop Immediately
- Sharp or severe pain
- Numbness or tingling
- Cold sensation
- Discoloration (purple/dark)
- Blisters or spots
- Difficulty urinating
- Erectile dysfunction

### Pre-Training Checklist
□ Well-rested and hydrated
□ No alcohol/drugs in system
□ Equipment inspected
□ Private, comfortable space
□ Emergency plan ready
□ Timer/clock visible

### Common Injuries and Prevention
- **Bruising**: Too much pressure - reduce intensity
- **Numbness**: Nerve compression - stop immediately
- **Thrombosed veins**: Overtraining - rest required
- **Skin irritation**: Poor technique - check form
- **ED symptoms**: Overwork - extended rest needed

### Recovery Protocol
1. Stop all PE activities
2. Apply ice if swelling
3. Rest minimum 1 week
4. Gentle massage when healed
5. Resume at 50% previous intensity

**CRITICAL**: If symptoms persist beyond 48 hours or worsen, seek immediate medical attention.`,
      ['safety', 'injury', 'prevention', 'warning signs', 'recovery', 'medical', 'critical'],
      10
    ),

    createKnowledgeDocument(
      'pe-safety-002',
      'safety',
      'Recovery and Rest Protocols',
      `## Recovery Optimization for PE Training

Recovery is when actual growth occurs. Proper rest protocols are essential for gains and injury prevention.

### Mandatory Rest Guidelines
- Minimum 1 day off weekly
- 2 days off recommended for beginners
- Full week off every 8-12 weeks
- Extended break if plateau occurs

### Active Recovery Techniques
- Light massage: Promotes blood flow
- Gentle stretching: Maintains flexibility
- Heat therapy: Improves circulation
- Kegels only: Maintains muscle tone
- Walking: General circulation boost

### Post-Session Recovery
1. **Cool Down**: 5-10 minutes light massage
2. **Hydrate**: Drink water immediately
3. **Assess**: Check for any issues
4. **Document**: Log session details
5. **Plan**: Schedule next session

### Nutrition for Recovery
- Protein: Tissue repair
- Vitamin C: Collagen synthesis
- Zinc: Wound healing
- Water: Hydration essential
- Anti-inflammatories: Natural sources preferred

### Sleep and Recovery
- 8+ hours optimal
- Growth hormone release during deep sleep
- Consistent schedule important
- Quality matters more than quantity

### Deload Weeks
- Every 4-6 weeks
- 50% normal intensity
- Focus on technique
- Assess progress
- Prevent burnout

**Remember**: More is not better. Strategic rest accelerates progress and prevents setbacks.`,
      ['recovery', 'rest', 'deload', 'active recovery', 'nutrition', 'sleep', 'safety'],
      9
    ),

    createKnowledgeDocument(
      'pe-safety-003',
      'safety',
      'Medical Considerations',
      `## Medical Considerations and Disclaimers

PE training carries inherent risks. Understanding medical considerations is crucial for safe practice.

### Contraindications (DO NOT START PE)
- Blood clotting disorders
- Peyronie's disease (without doctor approval)
- Active STIs or infections
- Recent urological surgery
- Priapism history
- Severe cardiovascular disease

### Consult Doctor If You Have
- Diabetes
- High blood pressure
- Heart conditions
- Circulation problems
- Previous penile injury
- Any urological conditions

### Medication Interactions
- Blood thinners: Increased bruising risk
- ED medications: Don't combine with PE same day
- Blood pressure meds: Monitor closely
- Testosterone therapy: May affect recovery

### Age Considerations
- Under 18: Not recommended, still developing
- 18-25: Use conservative approach
- 25-40: Prime age for PE
- 40+: Medical clearance advised
- 50+: Extra caution required

### When to Seek Medical Help
- Persistent pain (>24 hours)
- Difficulty urinating
- Severe discoloration
- Deformity or bending
- Loss of sensation
- Erectile dysfunction lasting >1 week

### Legal Disclaimer
This information is for educational purposes only and does not constitute medical advice. Always consult qualified healthcare providers before beginning any PE training program. The authors assume no liability for injuries or damages resulting from this information.

**CRITICAL**: Your health is more important than any potential gains. When in doubt, stop and seek professional medical guidance.`,
      ['medical', 'disclaimer', 'contraindications', 'doctor', 'health', 'safety', 'consultation'],
      10
    )
  ],

  // Equipment Knowledge
  equipment: [
    createKnowledgeDocument(
      'pe-equipment-001',
      'equipment',
      'Choosing Quality PE Equipment',
      `## PE Equipment Selection Guide

Quality equipment is essential for safe and effective PE training. Poor equipment increases injury risk significantly.

### Pump Selection Criteria
- Pressure gauge mandatory
- Quality valve system
- Appropriate cylinder sizing
- Medical-grade materials
- Reputable manufacturer
- Reviews from verified users

### Hanger Device Options
- Vacuum hangers: Gentler, beginner-friendly
- Compression hangers: More secure, advanced
- Size adjustability important
- Comfort padding essential
- Quick release mechanism

### Extender Features
- Medical approval preferred
- Spring or tension system quality
- Comfort strap/noose options
- Adjustment increments
- Spare parts availability
- Warranty consideration

### Red Flags to Avoid
- No gauge on pumps
- Cheap materials
- No safety features
- Unrealistic claims
- No customer support
- Counterfeit products

### Budget Considerations
- Entry-level: $50-100 (basic pump or extender)
- Mid-range: $100-250 (quality devices)
- Premium: $250+ (medical grade)
- Don't sacrifice safety for price

### Maintenance Requirements
- Regular cleaning mandatory
- Inspection before each use
- Replace worn parts promptly
- Proper storage important
- Follow manufacturer guidelines

**Investment Wisdom**: Quality equipment is an investment in safety. Better to start with one good device than multiple poor ones.`,
      ['equipment', 'device', 'pump', 'hanger', 'extender', 'quality', 'selection', 'safety'],
      7
    )
  ],

  // Progression Knowledge
  progression: [
    createKnowledgeDocument(
      'pe-progression-001',
      'progression',
      'PE Training Progression Timeline',
      `## Realistic PE Progression Expectations

Understanding realistic timelines prevents frustration and overtraining. Individual results vary significantly.

### Typical Progression Timeline

#### Month 1-3 (Foundation)
- Focus: Technique mastery
- Gains: Minimal (0-0.25")
- Primary benefit: Improved EQ
- Training: Light intensity only

#### Month 4-6 (Development)
- Focus: Gradual intensity increase
- Gains: 0.25-0.5" possible
- Benefit: First visible changes
- Training: Moderate intensity

#### Month 7-12 (Advancement)
- Focus: Optimizing routine
- Gains: 0.5-1.0" total possible
- Benefit: Consolidated gains
- Training: Higher intensity viable

#### Year 2+ (Refinement)
- Focus: Maintaining and slow gains
- Gains: 0.25-0.5" per year
- Benefit: Long-term results
- Training: Cycling intensity

### Plateau Management
- Normal at 3, 6, 12 months
- Deload for 1-2 weeks
- Change routine variables
- Focus on EQ during plateaus
- Consider extended break

### Factors Affecting Progress
- Age (younger generally responds better)
- Genetics (individual variation high)
- Consistency (most important factor)
- Recovery quality
- Overall health
- Technique precision

**Reality Check**: Most gain 0.5-1.5" length and 0.25-0.75" girth over 12-18 months with consistent, safe training.`,
      ['progression', 'timeline', 'expectations', 'plateau', 'results', 'gains', 'realistic'],
      8
    )
  ]
};

/**
 * Deploy knowledge to Firestore
 */
async function deployKnowledge() {
  console.log('🚀 Starting PE Knowledge Deployment to Firebase\n');

  const collection = db.collection('ai_coach_knowledge');
  let successCount = 0;
  let errorCount = 0;
  const errors = [];

  // Process each category
  for (const [category, documents] of Object.entries(peKnowledgeBase)) {
    console.log(`\n📁 Deploying ${category} knowledge (${documents.length} documents)...`);

    for (const doc of documents) {
      try {
        await collection.doc(doc.id).set(doc);
        console.log(`  ✅ ${doc.title}`);
        successCount++;
      } catch (error) {
        console.error(`  ❌ Failed to deploy ${doc.title}: ${error.message}`);
        errors.push(`${doc.id}: ${error.message}`);
        errorCount++;
      }
    }
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 DEPLOYMENT SUMMARY');
  console.log('='.repeat(50));
  console.log(`✅ Successfully deployed: ${successCount} documents`);
  console.log(`❌ Failed deployments: ${errorCount} documents`);

  if (errors.length > 0) {
    console.log('\n⚠️ Errors encountered:');
    errors.forEach(err => console.log(`  - ${err}`));
  }

  console.log('\n✨ PE Knowledge deployment complete!');

  // Return summary for testing
  return {
    success: successCount,
    failed: errorCount,
    total: successCount + errorCount,
    errors: errors
  };
}

// Execute deployment if run directly
if (require.main === module) {
  deployKnowledge()
    .then(summary => {
      console.log('\n📈 Final Status:', summary);
      process.exit(summary.failed > 0 ? 1 : 0);
    })
    .catch(error => {
      console.error('\n💥 Fatal error during deployment:', error);
      process.exit(1);
    });
}

module.exports = { deployKnowledge, createKnowledgeDocument, peKnowledgeBase };