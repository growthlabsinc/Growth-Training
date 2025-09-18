/**
 * Fallback knowledge base for AI Coach
 * This provides responses when the Firestore knowledge base is unavailable
 */

const fallbackKnowledge = {
  // AM1/Angion Method 1.0 specific content
  'am1': {
    keywords: ['am1', 'am 1', 'angion method 1', 'angion method 1.0', 'beginner method'],
    response: `AM1 (Angion Method 1.0) is designed for those who can obtain an erection without devices or substances, but cannot yet take their pulse on their dorsal arteries (or the pulse is weak/difficult to detect).

**Key Points about AM1:**

• **Target**: Manipulates the venous side of circulation through thumb-based techniques
• **Duration**: Work up to 30-minute sessions gradually  
• **Position**: Always perform lying down (never seated)
• **Progression**: Master before moving to AM2 - look for palpable arterial pulse

**Technique Summary:**
1. Apply lubricant along the dorsal (top) side of the shaft
2. Use alternating thumb strokes to create a "traveling wave" effect
3. Maintain 60-80% erection level
4. Focus on rhythm and consistency

**Common Issues:**
- Losing erection during practice is normal with arterial insufficiency
- This will improve as vascular development progresses
- Patience and consistency are key

Start with shorter sessions (5-10 minutes) and gradually build up. You're ready for AM2 when you can maintain an erection for 30 minutes and feel a clear pulse in your dorsal arteries.`
  },

  // AM2/Angion Method 2.0 content
  'am2': {
    keywords: ['am2', 'am 2', 'angion method 2', 'angion method 2.0', 'arterial method'],
    response: `AM2 (Angion Method 2.0) represents a significant progression, focusing on arterial manipulation rather than venous stimulation.

**Key Differences from AM1:**
• Requires palpable arterial pulse to begin
• Works with semi-erect state (not fully hard)
• Avoid overusing pelvic floor muscles

**Proper Erection Level:**
The creator emphasizes using a **semi-erect state** for better blood flow. Many struggle because they try to maintain full erection, which restricts flow.

**Common Challenge - Pelvic Floor:**
The #1 issue when transitioning from AM1 to AM2 is overusing kegel muscles, which:
- Makes maintaining erection difficult
- Causes loss of fullness
- Restricts the blood flow you're trying to enhance

**Best Practice:**
- Lie back on your bed
- Keep pelvic floor relaxed
- Start with semi-erect/heavily engorged state
- Focus on the arterial "wave" effect

The jump from AM1 to AM2 is large - expect challenges initially. Flattened CS and shriveled glans are normal at first and will improve with practice.`
  },

  // Abbreviations and terminology
  'abbreviations': {
    keywords: ['abbreviation', 'what is', 'what does', 'mean', 'terminology', 'cc', 'cs', 'bfr', 'eq', 'sabre'],
    response: `**Common Abbreviations in Growth Methods:**

**Method Terms:**
• **AM** - Angion Method: Primary vascular training methodology
• **SABRE** - Strike Activated Bayliss Response Exercise: Advanced percussion technique
• **BFR** - Blood Flow Restrictive: Controlled restriction technique

**Anatomical Terms:**
• **CC** - Corpus Cavernosum: Two side chambers that fill with blood
• **CS** - Corpus Spongiosum: Bottom chamber containing urethra
• **BC** - Bulbospongiosus Muscle: Pelvic floor muscle
• **IC** - Ischiocavernosus Muscle: Helps maintain erections

**Measurement Terms:**
• **BPEL** - Bone Pressed Erect Length
• **NBPEL** - Non Bone Pressed Erect Length
• **EG** - Erect Girth

**Function Terms:**
• **EQ** - Erection Quality (rated 1-10)
• **ED** - Erectile Dysfunction
• **NO** - Nitric Oxide: Crucial for vessel dilation

Remember: Focus on understanding concepts, not just memorizing terms. The Angion Method prioritizes functional improvements and vascular health over cosmetic changes.`
  },

  // Vascion/AM3 content
  'vascion': {
    keywords: ['vascion', 'am3', 'am 3', 'angion method 3', 'corpus spongiosum'],
    response: `Vascion (Angion Method 3.0) is the advanced technique focusing specifically on the Corpus Spongiosum (CS) through rapid finger stimulation.

**Prerequisites:**
- Strong arterial development from AM2
- Excellent erection quality
- CS is prominent and responsive

**Technique:**
• Use alternating middle finger strikes on the CS
• Create a "drumming" effect from base to glans
• Maintain rapid rhythm (2-3 strikes per second)
• Work along the CS groove

**Key Points:**
- Most intense of the hand-based methods
- Requires excellent coordination
- Start slowly to develop proper rhythm
- Can practice on forearm first

Only attempt Vascion after mastering AM2. The intense stimulation can cause vessel spasm or inflammation if attempted too early. This technique represents peak manual vascular stimulation.`
  },

  // SABRE techniques
  'sabre': {
    keywords: ['sabre', 'strike', 'percussion', 'bayliss', 'advanced technique'],
    response: `SABRE (Strike Activated Bayliss Response Exercise) is an advanced technique that uses controlled percussion to stimulate vascular development.

**CRITICAL WARNING**: SABRE is a double-edged sword - extremely effective but potentially dangerous. Improper use can cause blood vessel damage. Proceed with extreme caution.

**Key Concepts:**
• Uses controlled strikes to create fluid displacement
• Combines shear stress AND cyclic stretch
• Bypasses normal tissue limitations
• Requires mastery of AM1 and AM2 first

**Execution Basics:**
- Always at 100% erection
- Lying down position only
- Target base where penis meets pubic bone
- Light taps (like knocking on door)
- Start VERY gentle, progress slowly
- Sessions: 20-30 minutes

**Important Notes:**
- You don't need to maintain erection throughout
- Focus on tissue fullness, not erection
- 1-on-2-off schedule (more rest than Angion Methods)
- Any pain means stop immediately

SABRE represents cutting-edge vascular enhancement but demands respect, patience, and intelligent application.`
  },

  // Progression timeline
  'progression': {
    keywords: ['timeline', 'progression', 'results', 'how long', 'when will'],
    response: `**Vascularity Progression Timeline:**

**Early Stage (Weeks 1-4):**
• Return/improvement of morning erections
• Better frequency and strength
• Initial vein visibility

**Middle Stage (Weeks 4-8):**
• Morning erections persist longer
• Develop "morning soreness" (positive sign)
• Noticeably fuller erections
• Improved flaccid hang

**Advanced Stage (Week 8+):**
• Visible throbbing with pulse
• Consistent fullness throughout day
• Partners notice improvements

**Functional Improvements:**
• Faster arousal response
• Quicker recovery between sessions
• Enhanced sensitivity
• Better control and awareness

**Important Notes:**
1. Functionality improves before size
2. Timeline varies by individual
3. Consistency is key
4. Patience required - major changes take months

Focus on functional gains - they indicate healthy progression and lead to sustainable improvements.`
  },

  // General help
  'help': {
    keywords: ['help', 'what can', 'how to use', 'getting started'],
    response: `I'm your Growth Coach, here to help you understand and practice Growth Methods safely and effectively.

**I can help you with:**

**Growth Methods:**
• AM1, AM2, Vascion techniques
• SABRE advanced methods
• Proper progression paths
• Technique troubleshooting

**Understanding Terms:**
• Method abbreviations (AM, CS, CC, etc.)
• Anatomical terminology
• Measurement standards

**Progress & Safety:**
• Expected timelines
• Safety guidelines
• When to advance stages
• Common mistakes to avoid

**Best Practices:**
• Always perform exercises lying down
• Start with appropriate stage for your level
• Be patient - progression takes time
• Stop if you experience pain

What specific aspect would you like to explore?`
  }
};

/**
 * Get fallback response based on query
 * @param {string} query User's query
 * @returns {string|null} Fallback response or null if no match
 */
function getFallbackResponse(query) {
  const lowerQuery = query.toLowerCase();
  
  // Check each knowledge category
  for (const [category, data] of Object.entries(fallbackKnowledge)) {
    // Check if any keywords match
    const matches = data.keywords.some(keyword => lowerQuery.includes(keyword));
    if (matches) {
      return data.response;
    }
  }
  
  // Default response if no specific match
  return null;
}

module.exports = {
  getFallbackResponse,
  fallbackKnowledge
};