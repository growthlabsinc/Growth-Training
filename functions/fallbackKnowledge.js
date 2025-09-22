/**
 * Fallback knowledge base for AI Coach
 * This provides responses when the Firestore knowledge base is unavailable
 * Updated: Focused on PE safety and evidence-based training
 */

const fallbackKnowledge = {
  // General safety guidelines
  'safety': {
    keywords: ['safety', 'safe', 'injury', 'pain', 'hurt', 'damage', 'risk'],
    response: `**Safety First - PE Training Guidelines:**

**Stop Immediately If You Experience:**
• Sharp or severe pain
• Numbness lasting more than 15 minutes
• Cold sensation or discoloration
• Any bleeding or bruising
• Persistent discomfort after sessions

**Core Safety Principles:**
1. **Start Conservative**: Begin with minimal intensity and duration
2. **Progress Gradually**: Increase by no more than 10% weekly
3. **Listen to Your Body**: Discomfort is okay, pain is not
4. **Rest is Essential**: Minimum 1-2 rest days per week
5. **Warmup Always**: Heat application or light massage before training

**Medical Disclaimer:**
This information is for educational purposes only and does not replace professional medical advice. Consult a healthcare provider before beginning any PE training program, especially if you have existing health conditions.

Remember: Patience and consistency are safer than aggressive intensity.`
  },

  // General PE methodology
  'methodology': {
    keywords: ['method', 'technique', 'exercise', 'training', 'routine', 'program'],
    response: `**PE Training Methodology Overview:**

**Evidence-Based Approaches:**
• **Length Training**: Manual stretching, hanging, extending
• **Girth Training**: Pumping, clamping, manual exercises
• **EQ Enhancement**: Kegels, cardiovascular fitness, lifestyle factors

**Training Principles:**
1. **Progressive Overload**: Gradually increase stress on tissues
2. **Recovery Focus**: Growth occurs during rest periods
3. **Consistency**: Regular practice yields better results than intensity
4. **Individual Response**: Results vary based on genetics and dedication

**Typical Progression:**
• Beginner: 3 months foundation building
• Intermediate: 6-12 months focused training
• Advanced: Maintenance and specialized techniques

**Important Notes:**
- Start with manual exercises before equipment
- Master basics before attempting advanced techniques
- Document progress with measurements monthly
- Realistic expectations: 0.5-1.5 inches over 12-18 months

Always prioritize safety over aggressive gains.`
  },

  // Equipment guidance
  'equipment': {
    keywords: ['pump', 'hanger', 'extender', 'device', 'equipment', 'tool'],
    response: `**PE Equipment Guidelines:**

**Common Equipment Types:**
• **Pumps**: Create vacuum for expansion training
• **Hangers**: Apply traction for length work
• **Extenders**: Provide consistent stretch over time
• **Clamps**: Advanced girth technique (use with caution)

**Equipment Safety:**
1. **Quality Matters**: Invest in reputable equipment
2. **Start Light**: Begin with minimal pressure/weight
3. **Time Limits**: Follow manufacturer guidelines
4. **Hygiene**: Keep equipment clean and sanitized
5. **Inspection**: Check for damage before each use

**General Guidelines:**
- Manual exercises first, equipment later
- Never exceed recommended pressures/weights
- Stop if you experience pain or numbness
- Allow tissue recovery between sessions

**Warning**: Improper equipment use can cause permanent injury. When in doubt, err on the side of caution.`
  },

  // Progression and results
  'progression': {
    keywords: ['results', 'gains', 'progress', 'timeline', 'how long', 'when will'],
    response: `**PE Progression & Results Timeline:**

**Realistic Expectations:**

**Early Phase (Months 1-3):**
• Improved erection quality
• Better blood flow
• Minor temporary expansion
• Establishing routine consistency

**Development Phase (Months 4-9):**
• First measurable gains (0.25-0.5")
• Improved stamina
• Better vascular health
• Technique refinement

**Advanced Phase (Months 10+):**
• Continued gradual gains
• Plateau periods are normal
• Focus shifts to maintenance
• Total realistic gains: 0.5-1.5" length, 0.25-0.75" girth

**Key Factors for Success:**
1. Consistency over intensity
2. Proper recovery between sessions
3. Good overall health habits
4. Realistic expectations
5. Patient, gradual progression

Remember: Results vary significantly between individuals. Focus on the process, not just outcomes.`
  },

  // General help
  'help': {
    keywords: ['help', 'what can', 'how to use', 'getting started', 'coach'],
    response: `I'm your PE Training Coach, focused on safe and evidence-based training guidance.

**I can help you with:**

**Training Guidance:**
• Safe exercise techniques
• Progression planning
• Equipment recommendations
• Recovery protocols

**Safety & Health:**
• Injury prevention
• Warning signs to watch for
• When to take breaks
• Medical considerations

**Progress Tracking:**
• Measurement techniques
• Realistic timelines
• Plateau management
• Goal setting

**Best Practices:**
• Always warm up before training
• Start with beginner techniques
• Document your progress
• Prioritize recovery
• Stop if you experience pain

**Medical Disclaimer:**
This guidance is educational only. Consult healthcare providers for medical advice.

What specific aspect of PE training would you like to explore?`
  },

  // Abbreviations and terminology
  'abbreviations': {
    keywords: ['abbreviation', 'what is', 'what does', 'mean', 'terminology', 'bpel', 'eq'],
    response: `**Common PE Terminology:**

**Measurement Terms:**
• **BPEL** - Bone Pressed Erect Length
• **NBPEL** - Non Bone Pressed Erect Length
• **EG** - Erect Girth (circumference)
• **BPFSL** - Bone Pressed Flaccid Stretched Length

**Anatomical Terms:**
• **CC** - Corpus Cavernosum (erectile chambers)
• **CS** - Corpus Spongiosum (contains urethra)
• **Tunica** - Tough tissue surrounding erectile chambers
• **Glans** - Head of the penis

**Training Terms:**
• **EQ** - Erection Quality (1-10 scale)
• **PI** - Physiological Indicators (signs of overtraining)
• **Newbie Gains** - Initial gains in first months
• **Plateau** - Period of no measurable gains

**Safety Terms:**
• **Discoloration** - Darkening from broken capillaries
• **Edema** - Fluid buildup (temporary swelling)
• **Thrombosed** - Blocked vein (requires rest)

Understanding proper terminology helps track progress and communicate effectively about training.`
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

  // Default safety response if no specific match
  return `I understand you're looking for PE training guidance. While I search for specific information, please remember:

**Core Safety Principles:**
• Start conservatively and progress gradually
• Stop immediately if you experience pain
• Allow adequate recovery between sessions
• Consult a healthcare provider for medical concerns

For specific guidance, please rephrase your question or ask about:
• Safety guidelines
• Training methodology
• Equipment usage
• Progress expectations

Your safety is the top priority in any training program.`;
}

module.exports = {
  getFallbackResponse,
  fallbackKnowledge
};