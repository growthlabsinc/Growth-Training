/**
 * Template Selector for Conversation Templates
 * Story 3.7: Develop Conversation Templates
 * 
 * This module handles intelligent selection of appropriate templates
 * based on user context, query analysis, and conversation history.
 */

const { 
  getTemplateById, 
  getTemplatesByTag, 
  getTemplatesByCategory,
  TEMPLATE_PRIORITY 
} = require('./conversationTemplates');

/**
 * Query intent patterns for template matching
 */
const INTENT_PATTERNS = {
  // Safety-related intents (highest priority)
  injury: {
    patterns: [/pain/i, /hurt/i, /injury/i, /bleeding/i, /numb/i, /tingle/i, /swell/i, /bruise/i],
    templateIds: ['trouble_injury_concern', 'safety_stop_signal'],
    priority: 10
  },
  emergency: {
    patterns: [/emergency/i, /severe/i, /hospital/i, /doctor/i, /medical/i],
    templateIds: ['safety_stop_signal', 'trouble_injury_concern'],
    priority: 10
  },
  
  // Beginner intents
  newUser: {
    patterns: [/^hello/i, /^hi/i, /start/i, /begin/i, /new to/i, /first time/i, /newbie/i, /never done/i],
    templateIds: ['beginner_welcome'],
    priority: 8
  },
  firstRoutine: {
    patterns: [/first routine/i, /beginner routine/i, /where to start/i, /how to begin/i, /starting routine/i],
    templateIds: ['beginner_first_routine'],
    priority: 8
  },
  expectations: {
    patterns: [/how long/i, /when will/i, /results/i, /gains/i, /timeline/i, /realistic/i, /expect/i],
    templateIds: ['beginner_expectations'],
    priority: 7
  },
  
  // Routine building intents
  routineAssessment: {
    patterns: [/check my routine/i, /review routine/i, /optimize/i, /improve routine/i, /routine feedback/i],
    templateIds: ['routine_assessment'],
    priority: 6
  },
  exerciseSelection: {
    patterns: [/which exercise/i, /what exercise/i, /exercise for/i, /recommend exercise/i, /best exercise/i],
    templateIds: ['routine_exercise_selection'],
    priority: 6
  },
  
  // Troubleshooting intents
  plateau: {
    patterns: [/plateau/i, /stuck/i, /no gains/i, /not growing/i, /stopped working/i, /no progress/i],
    templateIds: ['trouble_plateau'],
    priority: 5
  },
  
  // Progress intents
  progressCheck: {
    patterns: [/progress/i, /check-in/i, /how am i doing/i, /review/i, /measurement/i, /tracking/i],
    templateIds: ['progress_check_in'],
    priority: 5
  },
  milestone: {
    patterns: [/milestone/i, /achievement/i, /reached/i, /goal/i, /success/i, /finally/i],
    templateIds: ['progress_milestone'],
    priority: 5
  },
  
  // Safety check intents
  preSession: {
    patterns: [/before.*session/i, /ready to start/i, /about to train/i, /pre.*workout/i, /warmup/i],
    templateIds: ['safety_pre_session'],
    priority: 9
  },
  safetyCheck: {
    patterns: [/is.*safe/i, /safety/i, /dangerous/i, /risk/i, /careful/i, /precaution/i],
    templateIds: ['safety_pre_session'],
    priority: 8
  }
};

/**
 * Context-based template selection rules
 */
const CONTEXT_RULES = {
  firstInteraction: {
    check: (context) => !context.conversationHistory || context.conversationHistory.length === 0,
    templateTags: ['welcome', 'beginner'],
    boost: 3
  },
  
  beginnerUser: {
    check: (context) => context.userExperienceLevel === 'beginner',
    templateTags: ['beginner', 'safety'],
    boost: 2
  },
  
  recentInjury: {
    check: (context) => {
      if (!context.conversationHistory) return false;
      // Check if injury mentioned in last 5 messages
      const recent = context.conversationHistory.slice(-5);
      return recent.some(msg => 
        /pain|hurt|injury|sore|discomfort/i.test(msg.text)
      );
    },
    templateTags: ['safety', 'injury', 'recovery'],
    boost: 5
  },
  
  sessionTime: {
    check: (context) => {
      const hour = new Date().getHours();
      return context.sessionType === 'pre-workout' || 
             (hour >= 6 && hour <= 10) || 
             (hour >= 18 && hour <= 22);
    },
    templateTags: ['pre-session', 'routine'],
    boost: 1
  }
};

/**
 * Main template selection function
 */
function selectTemplate(query, userContext = {}) {
  const candidates = [];
  
  // 1. Check for exact intent matches
  for (const [intentName, intent] of Object.entries(INTENT_PATTERNS)) {
    const matches = intent.patterns.some(pattern => pattern.test(query));
    if (matches) {
      intent.templateIds.forEach(templateId => {
        candidates.push({
          templateId,
          score: intent.priority * 10,
          reason: `Intent match: ${intentName}`,
          source: 'intent'
        });
      });
    }
  }
  
  // 2. Apply context rules
  for (const [ruleName, rule] of Object.entries(CONTEXT_RULES)) {
    if (rule.check(userContext)) {
      const templates = getTemplatesByTag(rule.templateTags[0]);
      templates.forEach(template => {
        const existingCandidate = candidates.find(c => c.templateId === template.id);
        if (existingCandidate) {
          existingCandidate.score += rule.boost * 5;
          existingCandidate.reason += `, Context: ${ruleName}`;
        } else {
          candidates.push({
            templateId: template.id,
            score: template.priority + (rule.boost * 5),
            reason: `Context match: ${ruleName}`,
            source: 'context'
          });
        }
      });
    }
  }
  
  // 3. Check for keyword matches in query
  const queryLower = query.toLowerCase();
  const allTags = ['beginner', 'routine', 'safety', 'progress', 'injury', 'plateau'];
  
  allTags.forEach(tag => {
    if (queryLower.includes(tag)) {
      const templates = getTemplatesByTag(tag);
      templates.forEach(template => {
        const existingCandidate = candidates.find(c => c.templateId === template.id);
        if (existingCandidate) {
          existingCandidate.score += 3;
          existingCandidate.reason += `, Keyword: ${tag}`;
        } else {
          candidates.push({
            templateId: template.id,
            score: template.priority + 3,
            reason: `Keyword match: ${tag}`,
            source: 'keyword'
          });
        }
      });
    }
  });
  
  // 4. Sort candidates by score
  candidates.sort((a, b) => b.score - a.score);
  
  // 5. Return best match or null
  if (candidates.length > 0) {
    const bestMatch = candidates[0];
    return {
      templateId: bestMatch.templateId,
      confidence: calculateConfidence(bestMatch.score, candidates),
      reason: bestMatch.reason,
      alternativeTemplates: candidates.slice(1, 3).map(c => c.templateId)
    };
  }
  
  return null;
}

/**
 * Calculate confidence score for template selection
 */
function calculateConfidence(topScore, allCandidates) {
  if (topScore >= 100) return 'very_high';
  if (topScore >= 70) return 'high';
  if (topScore >= 40) return 'medium';
  if (topScore >= 20) return 'low';
  return 'very_low';
}

/**
 * Select template based on conversation flow
 */
function selectFollowUpTemplate(previousTemplateId, userResponse) {
  const followUpMap = {
    'beginner_welcome': {
      patterns: [
        { match: /routine/i, templateId: 'beginner_first_routine' },
        { match: /expect/i, templateId: 'beginner_expectations' },
        { match: /exercise/i, templateId: 'routine_exercise_selection' },
        { match: /safety/i, templateId: 'safety_pre_session' }
      ]
    },
    'beginner_first_routine': {
      patterns: [
        { match: /start/i, templateId: 'safety_pre_session' },
        { match: /exercise/i, templateId: 'routine_exercise_selection' },
        { match: /when|results/i, templateId: 'beginner_expectations' }
      ]
    },
    'trouble_injury_concern': {
      patterns: [
        { match: /better|healed|ready/i, templateId: 'safety_pre_session' },
        { match: /prevent/i, templateId: 'safety_pre_session' },
        { match: /routine/i, templateId: 'routine_assessment' }
      ]
    }
  };
  
  const followUps = followUpMap[previousTemplateId];
  if (followUps) {
    for (const pattern of followUps.patterns) {
      if (pattern.match.test(userResponse)) {
        return {
          templateId: pattern.templateId,
          confidence: 'high',
          reason: 'Follow-up conversation flow'
        };
      }
    }
  }
  
  return null;
}

/**
 * Check if a template should be used based on safety triggers
 */
function checkSafetyOverride(query, context) {
  const safetyTriggers = [
    /severe pain/i,
    /can't feel/i,
    /completely numb/i,
    /turning blue/i,
    /turning purple/i,
    /bleeding/i,
    /emergency/i
  ];
  
  const hasTrigger = safetyTriggers.some(trigger => trigger.test(query));
  
  if (hasTrigger) {
    return {
      templateId: 'safety_stop_signal',
      confidence: 'very_high',
      reason: 'Safety trigger detected - override',
      override: true
    };
  }
  
  return null;
}

/**
 * Main entry point for template selection with all checks
 */
function selectBestTemplate(query, userContext = {}) {
  // 1. Check for safety override first
  const safetyOverride = checkSafetyOverride(query, userContext);
  if (safetyOverride) {
    return safetyOverride;
  }
  
  // 2. Check for follow-up flow
  if (userContext.previousTemplateId && userContext.conversationHistory) {
    const followUp = selectFollowUpTemplate(
      userContext.previousTemplateId,
      query
    );
    if (followUp) {
      return followUp;
    }
  }
  
  // 3. Regular template selection
  const selected = selectTemplate(query, userContext);
  
  // 4. Default fallback for new users
  if (!selected && (!userContext.conversationHistory || userContext.conversationHistory.length === 0)) {
    return {
      templateId: 'beginner_welcome',
      confidence: 'medium',
      reason: 'Default for new conversation'
    };
  }
  
  return selected;
}

module.exports = {
  selectBestTemplate,
  selectTemplate,
  selectFollowUpTemplate,
  checkSafetyOverride,
  INTENT_PATTERNS,
  CONTEXT_RULES
};