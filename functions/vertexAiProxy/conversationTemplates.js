/**
 * Conversation Templates for AI Coach
 * Story 3.7: Develop Conversation Templates
 * 
 * This module provides consistent, safety-focused response templates
 * for various user interactions with the AI Coach.
 */

const { SAFETY_GUARDRAILS } = require('./responseFilter');

/**
 * Template categories and their priority levels
 */
const TEMPLATE_PRIORITY = {
  SAFETY_CRITICAL: 10,  // Injury, emergency responses
  BEGINNER_GUIDANCE: 8,  // New user onboarding
  ROUTINE_BUILDING: 6,   // Routine creation/modification
  PROGRESS_TRACKING: 5,  // Progress reviews
  GENERAL_ADVICE: 3      // General Q&A
};

/**
 * Beginner guidance templates
 */
const beginnerTemplates = {
  welcome: {
    id: 'beginner_welcome',
    priority: TEMPLATE_PRIORITY.BEGINNER_GUIDANCE,
    template: `{{userGreeting}}! Welcome to PE training! I'm here to guide you safely through your journey.

**Important First Steps:**
1. **Safety First**: Never push through pain or discomfort
2. **Start Slow**: Begin with {{beginnerDuration}} minute sessions
3. **Listen to Your Body**: Rest is crucial for growth
4. **Track Progress**: Improvements come gradually over months

**Recommended Beginner Routine:**
- Warm-up: 5-10 minutes
- Basic manual exercises: {{beginnerDuration}} minutes
- Cool-down: 5 minutes
- Frequency: {{beginnerFrequency}}
- Rest days: At least {{requiredRest}} per week

**Medical Disclaimer**: This is educational information only. Consult a healthcare professional before starting any new exercise program.

What aspect of PE training would you like to learn about first?`,
    variables: {
      beginnerDuration: '10-15',
      beginnerFrequency: 'every other day',
      requiredRest: '2-3 days'
    },
    tags: ['beginner', 'welcome', 'safety']
  },

  firstRoutine: {
    id: 'beginner_first_routine',
    priority: TEMPLATE_PRIORITY.BEGINNER_GUIDANCE,
    template: `Here's your personalized beginner routine:

**Week 1-2: Foundation Phase**

📝 **Session Structure** ({{totalTime}} minutes):
1. **Warm-up** (5-10 min)
   - Hot wrap or warm shower
   - Light massage
   - Gentle stretching

2. **Main Exercises** ({{exerciseTime}} min)
   - Basic stretches: 30 seconds each direction
   - Light jelqing: 50 reps at 40-50% erection
   - Kegels: 10 reps, hold 5 seconds

3. **Cool-down** (5 min)
   - Light massage
   - Apply moisturizer

⏰ **Schedule**:
- Frequency: {{frequency}}
- Rest days: {{restDays}}
- Session time: {{sessionTime}}

⚠️ **Stop Immediately If**:
- Pain or sharp discomfort
- Numbness or tingling
- Discoloration (purple, blue, white)
- Any unusual symptoms

📈 **Progression**:
- Week 3-4: Add 25% more volume
- Month 2: Introduce new techniques
- Always prioritize form over intensity

Remember: Consistency over intensity. Your safety is paramount.`,
    variables: {
      totalTime: '20-25',
      exerciseTime: '10-15',
      frequency: '3 days per week',
      restDays: 'Monday, Wednesday, Friday, Sunday',
      sessionTime: 'Morning or evening'
    },
    tags: ['beginner', 'routine', 'structured']
  },

  expectations: {
    id: 'beginner_expectations',
    priority: TEMPLATE_PRIORITY.BEGINNER_GUIDANCE,
    template: `Let's set realistic expectations for your PE journey:

**Timeline Reality Check:**

📅 **First Month:**
- Focus: Learning proper technique
- Physical changes: Minimal to none
- Main goal: Establish consistent routine
- EQ improvements: Possible minor improvements

📅 **Months 2-3:**
- Technique refinement
- Improved EQ likely
- Minor size changes possible
- Better understanding of your body

📅 **Months 3-6:**
- Visible improvements more likely
- Length: 0.25-0.5" possible
- Girth: 0.125-0.25" possible
- Consistency is key

📅 **6-12 Months:**
- More substantial gains possible
- Highly individual results
- Plateaus are normal

**Important Reminders:**
- Genetics play a major role
- Age affects recovery and gains
- Consistency > Intensity
- Rest is when growth happens
- Document with measurements monthly
- Photos can help track progress

**Success Factors:**
1. Consistent routine ({{consistency}}%+ adherence)
2. Proper technique
3. Adequate rest
4. Patience and persistence
5. Listening to your body

This is a marathon, not a sprint. Most successful practitioners see best results after 6-12 months of consistent, safe training.`,
    variables: {
      consistency: '80'
    },
    tags: ['beginner', 'expectations', 'realistic']
  }
};

/**
 * Routine building templates
 */
const routineTemplates = {
  assessment: {
    id: 'routine_assessment',
    priority: TEMPLATE_PRIORITY.ROUTINE_BUILDING,
    template: `Let me help you optimize your current routine.

**Current Routine Analysis:**

Based on your {{experienceLevel}} experience level and {{currentFrequency}} training:

{{assessmentDetails}}

**Recommended Adjustments:**
1. {{adjustment1}}
2. {{adjustment2}}
3. {{adjustment3}}

**Optimized Schedule:**
- Training days: {{trainingDays}}
- Session duration: {{sessionDuration}} minutes
- Focus areas: {{focusAreas}}
- Recovery protocol: {{recoveryProtocol}}

**Safety Checks:**
✓ Duration within safe limits (max {{maxDuration}} min)
✓ Frequency allows recovery
✓ Intensity appropriate for level
✓ Rest days scheduled

**Next Steps:**
1. Implement changes gradually
2. Monitor body's response
3. Track measurements monthly
4. Adjust as needed

Would you like specific exercise recommendations for your focus areas?`,
    variables: {
      experienceLevel: 'intermediate',
      currentFrequency: '4x per week',
      assessmentDetails: 'Your routine shows good consistency',
      adjustment1: 'Add 5 minutes to session length',
      adjustment2: 'Include more girth-focused work',
      adjustment3: 'Implement deload weeks',
      trainingDays: 'Mon, Tue, Thu, Sat',
      sessionDuration: '30-40',
      focusAreas: 'Length and EQ',
      recoveryProtocol: '48 hours between sessions',
      maxDuration: '60'
    },
    tags: ['routine', 'assessment', 'optimization']
  },

  exerciseSelection: {
    id: 'routine_exercise_selection',
    priority: TEMPLATE_PRIORITY.ROUTINE_BUILDING,
    template: `Based on your goal of {{primaryGoal}}, here are recommended exercises:

**Primary Exercises** (Core focus - {{corePercentage}}% of session):
{{primaryExercises}}

**Secondary Exercises** (Support work - {{secondaryPercentage}}% of session):
{{secondaryExercises}}

**Conditioning** (Foundation - {{conditioningPercentage}}% of session):
{{conditioningExercises}}

**Exercise Rotation Schedule:**
- Week 1-2: Focus on primary
- Week 3: Add secondary
- Week 4: Full routine
- Week 5: Deload (70% volume)

**Form Cues:**
1. Never rush movements
2. Focus on feeling the stretch/expansion
3. Stop if you feel pain
4. Maintain {{erectionLevel}}% erection for manual work
5. Use adequate lubrication

**Progression Protocol:**
- Master form first (2-3 weeks)
- Then increase time (5-10%)
- Then increase intensity (carefully)
- Never progress all variables at once

Remember: Quality > Quantity. Perfect form prevents injury and maximizes results.`,
    variables: {
      primaryGoal: 'balanced length and girth',
      corePercentage: '60',
      secondaryPercentage: '25',
      conditioningPercentage: '15',
      primaryExercises: '• Manual stretching (all angles)\n• Jelqing (wet, 60% erection)\n• V-stretches',
      secondaryExercises: '• Kegels\n• Reverse kegels\n• Edging for EQ',
      conditioningExercises: '• Warm-up routine\n• Cool-down massage\n• Supplements/nutrition',
      erectionLevel: '40-60'
    },
    tags: ['routine', 'exercises', 'selection']
  }
};

/**
 * Troubleshooting templates
 */
const troubleshootingTemplates = {
  injuryConcern: {
    id: 'trouble_injury_concern',
    priority: TEMPLATE_PRIORITY.SAFETY_CRITICAL,
    template: `⚠️ **IMPORTANT SAFETY RESPONSE** ⚠️

{{concernSummary}}

**IMMEDIATE ACTIONS REQUIRED:**

🛑 **STOP ALL PE ACTIVITIES IMMEDIATELY**

**Assessment Checklist:**
□ Is there severe pain? → Seek medical attention
□ Is there numbness/tingling? → Stop and rest minimum 7 days
□ Is there discoloration? → Apply warm compress, monitor closely
□ Is there swelling? → Ice for 10-15 minutes, elevate
□ Is there bleeding? → Seek medical attention immediately

**Recovery Protocol:**
1. **Complete rest**: No PE activities for minimum {{restPeriod}}
2. **Monitor symptoms**: Document any changes
3. **Gentle massage**: Only if no pain (after 48 hours)
4. **Gradual return**: Start at 30% intensity when healed
5. **Medical consultation**: If symptoms persist > 48 hours

**Warning Signs Requiring Medical Attention:**
- Severe or worsening pain
- Persistent numbness
- Color changes lasting > 1 hour
- Any bleeding or discharge
- Difficulty urinating
- Fever or signs of infection

**Prevention for Future:**
- Reduce intensity/duration
- Improve warm-up routine
- Check your technique
- Ensure adequate rest between sessions
- Never train through pain

**Remember**: No gains are worth permanent injury. Your health and safety must always come first. When in doubt, consult a healthcare professional.

**This is not medical advice** - only educational information. For any serious concerns, please see a doctor.`,
    variables: {
      concernSummary: 'Based on your symptoms',
      restPeriod: '7-14 days'
    },
    tags: ['safety', 'injury', 'critical', 'medical']
  },

  plateau: {
    id: 'trouble_plateau',
    priority: TEMPLATE_PRIORITY.GENERAL_ADVICE,
    template: `Plateaus are completely normal in PE. Here's how to break through:

**Understanding Your Plateau:**

You've been at {{currentMeasurements}} for {{plateauDuration}}. This is actually common at the {{experienceStage}} stage.

**Plateau-Breaking Strategies:**

1. **Deload Week** (Recommended first)
   - Reduce to 50% volume
   - Focus on EQ and health
   - Let tissues recover fully

2. **Change Stimulus**
   - Switch exercise angles
   - Alter timing (longer holds)
   - Try different techniques
   - Adjust erection levels

3. **Shock Week** (After deload)
   - 25% increase in volume
   - Add new exercise
   - Higher frequency (carefully)

4. **Focus Shift**
   - Target different dimension
   - Improve EQ first
   - Work on consistency

5. **Lifestyle Factors**
   - Sleep quality (7-9 hours)
   - Nutrition (protein, vitamins)
   - Hydration (2-3L daily)
   - Stress management
   - Cardio for circulation

**Realistic Expectations:**
- Plateaus last 4-12 weeks typically
- Not all periods show gains
- Body adapts in cycles
- Mental breaks help too

**Action Plan:**
1. Week 1: Deload
2. Week 2-3: Modified routine
3. Week 4: Assess and adjust
4. Month 2: Consider extended break

Remember: Plateaus often precede growth spurts. Stay consistent and patient.`,
    variables: {
      currentMeasurements: 'your current size',
      plateauDuration: '6-8 weeks',
      experienceStage: '6-month'
    },
    tags: ['plateau', 'troubleshooting', 'progress']
  }
};

/**
 * Progress assessment templates
 */
const progressTemplates = {
  checkIn: {
    id: 'progress_check_in',
    priority: TEMPLATE_PRIORITY.PROGRESS_TRACKING,
    template: `Time for your {{checkInType}} progress check-in!

**Progress Review:**

📏 **Measurements:**
- Starting: {{startMeasurements}}
- Current: {{currentMeasurements}}
- Change: {{measurementChange}}
- Rate: {{gainRate}}

💪 **Performance Metrics:**
- Routine adherence: {{adherence}}%
- Session quality: {{quality}}/10
- EQ improvement: {{eqChange}}
- Recovery time: {{recovery}}

**Analysis:**
{{progressAnalysis}}

**What's Working:**
{{positives}}

**Areas for Improvement:**
{{improvements}}

**Next Period Goals:**
1. {{goal1}}
2. {{goal2}}
3. {{goal3}}

**Routine Adjustments:**
{{adjustments}}

**Motivational Note:**
{{motivation}}

Keep up the great work! Consistency is building your success.`,
    variables: {
      checkInType: 'monthly',
      startMeasurements: 'Your baseline',
      currentMeasurements: 'Current stats',
      measurementChange: '+0.25" length, +0.125" girth',
      gainRate: 'On track',
      adherence: '85',
      quality: '7',
      eqChange: 'Improved',
      recovery: 'Good',
      progressAnalysis: 'Steady progress within expected range',
      positives: 'Consistent training, good form',
      improvements: 'More rest days, better warm-up',
      goal1: 'Maintain consistency',
      goal2: 'Improve EQ further',
      goal3: 'Add 5 minutes to sessions',
      adjustments: 'Consider adding light pumping',
      motivation: 'You\'re in the top 20% for consistency!'
    },
    tags: ['progress', 'check-in', 'review']
  },

  milestone: {
    id: 'progress_milestone',
    priority: TEMPLATE_PRIORITY.PROGRESS_TRACKING,
    template: `🎉 **MILESTONE ACHIEVED!** 🎉

{{achievementMessage}}

**Your Journey:**
- Started: {{startDate}}
- Days trained: {{totalDays}}
- Sessions completed: {{totalSessions}}
- Total gains: {{totalGains}}

**Key Success Factors:**
1. {{successFactor1}}
2. {{successFactor2}}
3. {{successFactor3}}

**Community Comparison:**
Your progress puts you in the top {{percentile}}% of consistent practitioners!

**Next Milestone Target:**
{{nextMilestone}}

**Celebration Suggestions:**
- Take progress photos
- Share success (anonymously) in community
- Reward yourself (non-PE related!)
- Plan next phase goals

**Important Reminder:**
Every person's journey is unique. Your consistent effort and safe practices are what truly matter.

Congratulations on this achievement! 💪`,
    variables: {
      achievementMessage: 'You\'ve reached your first 0.5" gain!',
      startDate: 'Your start date',
      totalDays: '180',
      totalSessions: '72',
      totalGains: '+0.5" length, +0.25" girth',
      successFactor1: 'Consistent 4x/week training',
      successFactor2: 'Never skipped rest days',
      successFactor3: 'Gradual progression',
      percentile: '15',
      nextMilestone: '1 inch total gain'
    },
    tags: ['milestone', 'celebration', 'motivation']
  }
};

/**
 * Safety check templates
 */
const safetyTemplates = {
  preSession: {
    id: 'safety_pre_session',
    priority: TEMPLATE_PRIORITY.SAFETY_CRITICAL,
    template: `**Pre-Session Safety Check** ✓

Before starting today's session, please confirm:

**Health Status:**
□ No pain from previous session
□ No unusual symptoms
□ Well-rested ({{minSleep}}+ hours sleep)
□ Hydrated
□ Not under influence of alcohol/drugs

**Preparation:**
□ Private, comfortable space
□ Warm-up materials ready
□ Lubrication available
□ Timer/tracking app ready
□ 30-45 minutes uninterrupted time

**Mental State:**
□ Not stressed or rushed
□ Focused and present
□ Ready to stop if needed

**Session Reminders:**
- Maximum duration: {{maxDuration}} minutes
- Target intensity: {{intensity}}/10
- Rest if fatigued
- Quality > Quantity

⚠️ **Skip Today If:**
- Any pain or injury
- Fever or illness
- Less than {{minRest}} hours since last session
- Extremely stressed/tired
- Any concerns about safety

Your safety is paramount. Never compromise it for a session.

**Medical Disclaimer**: This is educational information only. Consult your healthcare provider if you have any concerns.

Ready to proceed safely? Let's begin with your warm-up.`,
    variables: {
      minSleep: '6',
      maxDuration: '45',
      intensity: '6-7',
      minRest: '24'
    },
    tags: ['safety', 'pre-session', 'checklist']
  },

  stopSignal: {
    id: 'safety_stop_signal',
    priority: TEMPLATE_PRIORITY.SAFETY_CRITICAL,
    template: `🛑 **STOP IMMEDIATELY** 🛑

**Critical Warning Detected:**
{{warningType}}

**REQUIRED ACTIONS:**

1. **STOP** all PE activities NOW
2. **ASSESS** the severity:
   {{assessmentSteps}}

3. **IMMEDIATE CARE:**
   {{immediateCare}}

4. **MONITORING PERIOD:**
   - Next 1 hour: Check every 15 minutes
   - Next 24 hours: Monitor for changes
   - Document symptoms

5. **MEDICAL ATTENTION IF:**
   - Symptoms worsen
   - No improvement in 1 hour
   - Severe pain continues
   - Any bleeding
   - Difficulty urinating
   - Fever develops

**DO NOT:**
- Continue exercises
- Apply excessive heat/cold
- Take pain medication to "push through"
- Ignore symptoms

**RECOVERY REQUIREMENT:**
Minimum {{recoveryPeriod}} complete rest before any PE activity.

**MEDICAL DISCLAIMER:**
This is educational information only. For any serious medical concerns, seek immediate professional medical attention.

**Emergency Room if:**
- Severe pain
- Complete numbness
- Black/blue discoloration
- Inability to urinate
- Signs of infection

Your safety is non-negotiable. No gains are worth permanent damage.`,
    variables: {
      warningType: 'Pain/numbness detected',
      assessmentSteps: 'Check for color changes, swelling, temperature',
      immediateCare: 'Apply warm compress, gentle massage if no pain',
      recoveryPeriod: '7-14 days'
    },
    tags: ['safety', 'stop', 'emergency', 'critical']
  }
};

/**
 * Combine all template categories
 */
const allTemplates = {
  beginner: beginnerTemplates,
  routine: routineTemplates,
  troubleshooting: troubleshootingTemplates,
  progress: progressTemplates,
  safety: safetyTemplates
};

/**
 * Get a template by ID
 */
function getTemplateById(templateId) {
  for (const category of Object.values(allTemplates)) {
    for (const template of Object.values(category)) {
      if (template.id === templateId) {
        return template;
      }
    }
  }
  return null;
}

/**
 * Get templates by tag
 */
function getTemplatesByTag(tag) {
  const templates = [];
  for (const category of Object.values(allTemplates)) {
    for (const template of Object.values(category)) {
      if (template.tags && template.tags.includes(tag)) {
        templates.push(template);
      }
    }
  }
  return templates.sort((a, b) => b.priority - a.priority);
}

/**
 * Get templates by category
 */
function getTemplatesByCategory(categoryName) {
  const templates = [];
  const categoryTemplates = allTemplates[categoryName];
  if (categoryTemplates) {
    for (const template of Object.values(categoryTemplates)) {
      templates.push({ ...template, category: categoryName });
    }
  }
  return templates;
}

module.exports = {
  allTemplates,
  getTemplateById,
  getTemplatesByTag,
  getTemplatesByCategory,
  TEMPLATE_PRIORITY,
  beginnerTemplates,
  routineTemplates,
  troubleshootingTemplates,
  progressTemplates,
  safetyTemplates
};