/**
 * Deploy pelvic floor and progression knowledge to AI Coach knowledge base
 */

const admin = require('firebase-admin');

// Initialize if needed
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function deployPelvicFloorKnowledge() {
  const knowledgeRef = db.collection('ai_coach_knowledge');

  const documents = [
    {
      id: 'pelvic_floor_guidance',
      title: 'Pelvic Floor Considerations for Angion Methods',
      category: 'technique',
      type: 'safety',
      keywords: ['pelvic', 'floor', 'tight', 'kegel', 'relaxation', 'am1', 'am2', 'beginner', 'tension'],
      searchableContent: 'pelvic floor tight tension relaxation kegel muscle overuse am1 am2 beginner starting slow gentle',
      content: `For users with tight pelvic floor muscles:

**Starting Recommendations:**
- Begin with AM1 (Angion Method 1.0) as it's the gentlest method
- Start with just 5-10 minutes per session
- Focus on keeping the pelvic floor RELAXED throughout
- Avoid kegeling or clenching during exercises

**Important AM2 Warning:**
AM2 documentation specifically states: "This technique is best performed without the use of kegeling due to the risk of pelvic floor overtraining. If a male relies too heavily on his pelvic floor to push blood into his glans, he will quickly overstimulate the muscles in the area and notice a sharp drop in EQ and increased difficulty obtaining an erection."

**Safe Progression:**
- Week 1-2: 5 minutes per session
- Week 3-4: 10 minutes per session
- Add 5 minutes weekly thereafter
- Maximum 30 minutes once conditioned
- Use 1-on-1-off schedule (exercise one day, rest the next)

**Key Points:**
- Relaxation is more important than intensity
- Let blood flow naturally without forcing
- Stop if you experience discomfort or tension
- Progress slowly to avoid overtraining`,
      metadata: {
        source: 'Angion Method documentation',
        lastUpdated: new Date().toISOString()
      }
    },
    {
      id: 'warmup_and_progression',
      title: 'Warmup and Progressive Training Guidelines',
      category: 'technique',
      type: 'progression',
      keywords: ['warmup', 'warm', 'up', 'progression', 'weekly', 'routine', 'schedule', 'beginner', 'start'],
      searchableContent: 'warmup warm up progression weekly schedule routine beginner starting gradually increase minutes',
      content: `**Warmup Recommendations:**
- 1-2 minutes of gentle preparation is reasonable
- Light manual stimulation to achieve initial engorgement
- Apply lubricant during warmup phase
- Focus on relaxation rather than intensity

**Progressive Training Schedule:**
- Beginners: Start with 5 minutes of actual technique practice
- Add 5 minutes per week as tolerance builds
- Target: Work up to 30 minutes over 5-6 weeks
- Never rush progression - consistency over intensity

**Session Structure Example:**
1. 1-2 minute gentle warmup
2. 5 minutes technique practice (initial weeks)
3. Gradual weekly increases of 5 minutes
4. Cool down with gentle massage

**Frequency Guidelines:**
- Optimal: 1-on-1-off schedule (every other day)
- Allows recovery between sessions
- More frequent training can lead to overtraining
- Less frequent may slow progression`,
      metadata: {
        source: 'Angion Method best practices',
        lastUpdated: new Date().toISOString()
      }
    },
    {
      id: 'am1_for_beginners',
      title: 'AM1 - Ideal Starting Point for Beginners',
      category: 'method',
      type: 'beginner',
      keywords: ['am1', 'angion', 'method', '1', 'beginner', 'start', 'gentle', 'venous'],
      searchableContent: 'am1 angion method 1 beginner starting gentle venous pelvic floor safe',
      content: `AM1 (Angion Method 1.0) is the recommended starting point, especially for those with pelvic floor tension.

**Why AM1 for Tight Pelvic Floor:**
- Gentlest of all Angion Methods
- Focuses on venous stimulation (less intense)
- Doesn't require strong erections
- Allows practice with relaxed pelvic floor

**Technique Overview:**
- Apply lubricant along the dorsal (top) side
- Use alternating thumb strokes
- Create a "traveling wave" effect
- Maintain 60-80% erection level
- Keep pelvic floor relaxed throughout

**Progression Timeline:**
- Weeks 1-2: 5-10 minutes
- Weeks 3-4: 10-15 minutes
- Weeks 5-6: 15-20 minutes
- Target: 30 minutes when fully conditioned

**Graduation Criteria:**
Move to AM2 when you can:
- Maintain erection for 30 minutes
- Feel clear arterial pulse
- Complete sessions without fatigue`,
      metadata: {
        source: 'AM1 documentation',
        lastUpdated: new Date().toISOString()
      }
    }
  ];

  // Deploy each document
  for (const doc of documents) {
    try {
      await knowledgeRef.doc(doc.id).set(doc);
      console.log(`✅ Deployed: ${doc.title}`);
    } catch (error) {
      console.error(`❌ Failed to deploy ${doc.id}:`, error);
    }
  }

  console.log('\n✅ Pelvic floor knowledge deployment complete');
}

// Run if called directly
if (require.main === module) {
  deployPelvicFloorKnowledge()
    .then(() => process.exit(0))
    .catch(error => {
      console.error('Deployment failed:', error);
      process.exit(1);
    });
}

module.exports = { deployPelvicFloorKnowledge };