/**
 * Response Filter Module for AI Coach
 * Implements comprehensive safety filtering for AI-generated responses
 */

const admin = require('firebase-admin');

// Safety guardrails from Epic 3 requirements
const SAFETY_GUARDRAILS = {
  maxDuration: 60, // minutes
  maxFrequency: 'daily',
  requiredRest: 1, // days per week
  beginnerLimit: 15, // minutes
  warningKeywords: ['pain', 'injury', 'numb', 'cold', 'discomfort', 'tingling', 'burning'],
  stopKeywords: ['severe', 'bleeding', 'emergency', 'fracture', 'tear', 'rupture', 'blackout']
};

// Filter categories with severity levels
const FILTER_CATEGORIES = {
  // Medical claims that must be filtered
  medicalClaims: {
    severity: 'high',
    keywords: [
      'cure', 'guarantee', 'medical treatment', 'diagnose', 'heal',
      'prescription', 'medication', 'surgery', 'doctor approved',
      'clinically proven', 'FDA', 'medical device', 'therapeutic'
    ],
    patterns: [
      /will\s+(cure|heal|fix|treat)/gi,
      /guaranteed\s+(results|growth|gains)/gi,
      /medical\s+(treatment|therapy|intervention)/gi,
      /diagnos(e|is|ing)/gi,
      /prescri(be|ption)/gi
    ]
  },

  // Dangerous techniques that pose injury risk
  dangerousTechniques: {
    severity: 'critical',
    keywords: [
      'extreme', 'maximum force', 'ignore pain', 'push through pain',
      'no rest', 'constant pressure', 'all day', 'overnight',
      'dangerous', 'risky', 'aggressive', 'hardcore'
    ],
    patterns: [
      /ignore\s+(pain|discomfort|warning)/gi,
      /push\s+through\s+(pain|injury)/gi,
      /no\s+rest\s+(days|needed)/gi,
      /24\s*hours/gi,
      /all\s+day\s+long/gi
    ]
  },

  // Excessive parameters beyond safe limits
  excessiveParameters: {
    severity: 'high',
    checks: [
      { type: 'duration', max: 60, unit: 'minutes' },
      { type: 'frequency', max: 2, unit: 'daily' },
      { type: 'pressure', max: 10, unit: 'hg' },
      { type: 'weight', max: 20, unit: 'lbs' }
    ],
    patterns: [
      /(\d+)\s*hours?\s+(of|straight|continuous)/gi,
      /(\d+)\s*times?\s+(per|a)\s*day/gi,
      /more\s+than\s+(\d+)\s*minutes/gi
    ]
  },

  // Unproven or experimental methods
  unprovenMethods: {
    severity: 'medium',
    keywords: [
      'experimental', 'untested', 'theoretical', 'unverified',
      'secret technique', 'hidden method', 'breakthrough discovery',
      'revolutionary', 'miracle', 'instant results'
    ],
    patterns: [
      /secret\s+(technique|method|formula)/gi,
      /instant\s+(results|gains|growth)/gi,
      /miracle\s+(cure|solution|technique)/gi,
      /breakthrough\s+discovery/gi
    ]
  },

  // Legal risk content
  legalRisks: {
    severity: 'high',
    keywords: [
      'lawsuit', 'legal action', 'medical advice', 'professional diagnosis',
      'replace doctor', 'instead of medical', 'don\'t see doctor'
    ],
    patterns: [
      /replace\s+(your\s+)?doctor/gi,
      /don't\s+need\s+(a\s+)?doctor/gi,
      /medical\s+advice/gi,
      /professional\s+diagnosis/gi
    ]
  }
};

// Severity levels and their actions
const SEVERITY_ACTIONS = {
  critical: 'block', // Completely block the response
  high: 'modify', // Heavily modify the response
  medium: 'warn', // Add warnings to the response
  low: 'log' // Just log the issue
};

/**
 * Main response filter function
 * @param {string} response - The AI-generated response text
 * @param {Object} userContext - Context about the user (experience level, etc.)
 * @returns {Object} - Filtered response and metadata
 */
async function filterResponse(response, userContext = {}) {
  const filterResults = {
    originalResponse: response,
    filteredResponse: response,
    filtersApplied: [],
    filterReasons: [],
    riskScore: 0,
    requiresLogging: false,
    blocked: false
  };

  // Run through all filter categories
  const keywordFilterResult = detectUnsafeKeywords(response);
  const medicalClaimResult = detectMedicalClaims(response);
  const riskAssessmentResult = assessInjuryRisk(response, userContext);
  const parameterCheckResult = checkExcessiveParameters(response);

  // Aggregate results
  const allResults = [
    keywordFilterResult,
    medicalClaimResult,
    riskAssessmentResult,
    parameterCheckResult
  ];

  // Calculate overall risk score (0-100)
  filterResults.riskScore = calculateRiskScore(allResults);

  // Apply conservative override if risk score is high
  if (filterResults.riskScore > 70 || shouldApplyConservativeOverride(allResults)) {
    filterResults.filteredResponse = applyConservativeOverride(response, allResults);
    filterResults.filtersApplied.push('conservative_override');
    filterResults.requiresLogging = true;
  } else if (filterResults.riskScore > 50) {
    // Modify response to add safety disclaimers
    filterResults.filteredResponse = addSafetyDisclaimers(response, allResults);
    filterResults.filtersApplied.push('safety_disclaimers');
    filterResults.requiresLogging = true;
  }

  // Check if response should be completely blocked
  if (filterResults.riskScore > 90 || containsCriticalContent(allResults)) {
    filterResults.blocked = true;
    filterResults.filteredResponse = generateSafetyBlockMessage(allResults);
    filterResults.filtersApplied.push('blocked');
    filterResults.requiresLogging = true;
  }

  // Collect all filter reasons
  allResults.forEach(result => {
    if (result.detected) {
      filterResults.filtersApplied.push(...result.filters);
      filterResults.filterReasons.push(...result.reasons);
    }
  });

  // Log if necessary
  if (filterResults.requiresLogging) {
    await logFilteredResponse(filterResults, userContext);
  }

  // Determine if content was actually filtered/modified
  const wasFiltered = filterResults.blocked ||
                      filterResults.filteredResponse !== filterResults.originalResponse ||
                      filterResults.riskScore >= 50 ||
                      filterResults.filtersApplied.length > 0;

  // Return proper format for the filter response
  return {
    text: filterResults.filteredResponse,
    wasFiltered: wasFiltered,
    filterReasons: filterResults.filterReasons,
    riskScore: filterResults.riskScore,
    blocked: filterResults.blocked
  };
}

/**
 * Detect unsafe keywords and phrases
 */
function detectUnsafeKeywords(text) {
  const result = {
    detected: false,
    filters: [],
    reasons: [],
    severity: 'low',
    matches: []
  };

  // Check stop keywords (critical)
  SAFETY_GUARDRAILS.stopKeywords.forEach(keyword => {
    if (text.toLowerCase().includes(keyword.toLowerCase())) {
      result.detected = true;
      result.severity = 'critical';
      result.filters.push('stop_keyword');
      result.reasons.push(`Contains stop keyword: ${keyword}`);
      result.matches.push(keyword);
    }
  });

  // Check warning keywords (high)
  if (!result.detected || result.severity !== 'critical') {
    SAFETY_GUARDRAILS.warningKeywords.forEach(keyword => {
      if (text.toLowerCase().includes(keyword.toLowerCase())) {
        result.detected = true;
        result.severity = result.severity === 'critical' ? 'critical' : 'high';
        result.filters.push('warning_keyword');
        result.reasons.push(`Contains warning keyword: ${keyword}`);
        result.matches.push(keyword);
      }
    });
  }

  // Check dangerous technique keywords
  FILTER_CATEGORIES.dangerousTechniques.keywords.forEach(keyword => {
    if (text.toLowerCase().includes(keyword.toLowerCase())) {
      result.detected = true;
      result.severity = 'critical';
      result.filters.push('dangerous_technique');
      result.reasons.push(`Contains dangerous technique: ${keyword}`);
      result.matches.push(keyword);
    }
  });

  // Check dangerous patterns
  FILTER_CATEGORIES.dangerousTechniques.patterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) {
      result.detected = true;
      result.severity = 'critical';
      result.filters.push('dangerous_pattern');
      result.reasons.push(`Matches dangerous pattern: ${matches[0]}`);
      result.matches.push(...matches);
    }
  });

  return result;
}

/**
 * Detect medical claims and promises
 */
function detectMedicalClaims(text) {
  const result = {
    detected: false,
    filters: [],
    reasons: [],
    severity: 'low',
    matches: []
  };

  // Check medical claim keywords
  FILTER_CATEGORIES.medicalClaims.keywords.forEach(keyword => {
    if (text.toLowerCase().includes(keyword.toLowerCase())) {
      result.detected = true;
      result.severity = 'high';
      result.filters.push('medical_claim');
      result.reasons.push(`Contains medical claim: ${keyword}`);
      result.matches.push(keyword);
    }
  });

  // Check medical patterns
  FILTER_CATEGORIES.medicalClaims.patterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) {
      result.detected = true;
      result.severity = 'high';
      result.filters.push('medical_pattern');
      result.reasons.push(`Matches medical pattern: ${matches[0]}`);
      result.matches.push(...matches);
    }
  });

  // Check for unproven method claims
  FILTER_CATEGORIES.unprovenMethods.keywords.forEach(keyword => {
    if (text.toLowerCase().includes(keyword.toLowerCase())) {
      result.detected = true;
      result.severity = result.severity === 'high' ? 'high' : 'medium';
      result.filters.push('unproven_method');
      result.reasons.push(`Contains unproven method: ${keyword}`);
      result.matches.push(keyword);
    }
  });

  return result;
}

/**
 * Assess injury risk based on recommended parameters
 */
function assessInjuryRisk(text, userContext) {
  const result = {
    detected: false,
    filters: [],
    reasons: [],
    severity: 'low',
    riskFactors: []
  };

  const isBeginnerUser = userContext.experienceLevel === 'beginner';

  // Check for excessive parameters
  FILTER_CATEGORIES.excessiveParameters.patterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) {
      const value = parseInt(matches[1]);

      // Check duration
      if (pattern.toString().includes('hours') && value > 1) {
        result.detected = true;
        result.severity = 'high';
        result.filters.push('excessive_duration');
        result.reasons.push(`Excessive duration: ${value} hours`);
        result.riskFactors.push({ type: 'duration', value, limit: 1 });
      }

      // Check frequency
      if (pattern.toString().includes('times') && value > 2) {
        result.detected = true;
        result.severity = 'high';
        result.filters.push('excessive_frequency');
        result.reasons.push(`Excessive frequency: ${value} times per day`);
        result.riskFactors.push({ type: 'frequency', value, limit: 2 });
      }

      // Check against beginner limits
      if (isBeginnerUser && pattern.toString().includes('minutes') && value > SAFETY_GUARDRAILS.beginnerLimit) {
        result.detected = true;
        result.severity = 'high';
        result.filters.push('exceeds_beginner_limit');
        result.reasons.push(`Exceeds beginner limit: ${value} minutes`);
        result.riskFactors.push({ type: 'beginner_duration', value, limit: SAFETY_GUARDRAILS.beginnerLimit });
      }
    }
  });

  // Check for missing rest day recommendations
  if (!text.toLowerCase().includes('rest') && !text.toLowerCase().includes('recovery')) {
    result.detected = true;
    result.severity = result.severity === 'high' ? 'high' : 'medium';
    result.filters.push('missing_rest_advice');
    result.reasons.push('No rest or recovery mentioned');
    result.riskFactors.push({ type: 'no_rest', value: true });
  }

  return result;
}

/**
 * Check for excessive parameters in recommendations
 */
function checkExcessiveParameters(text) {
  const result = {
    detected: false,
    filters: [],
    reasons: [],
    severity: 'low',
    violations: []
  };

  // Extract numeric values with units
  const durationPattern = /(\d+)\s*(minutes?|mins?|hours?|hrs?)/gi;
  const frequencyPattern = /(\d+)\s*(times?|x)\s*(per|a|\/)\s*(day|daily)/gi;
  const pressurePattern = /(\d+\.?\d*)\s*(hg|mercury|pressure)/gi;
  const weightPattern = /(\d+\.?\d*)\s*(lbs?|pounds?|kgs?|kilograms?)/gi;

  // Check durations
  let matches = text.matchAll(durationPattern);
  for (const match of matches) {
    const value = parseInt(match[1]);
    const unit = match[2].toLowerCase();

    let minutes = value;
    if (unit.includes('hour')) {
      minutes = value * 60;
    }

    if (minutes > SAFETY_GUARDRAILS.maxDuration) {
      result.detected = true;
      result.severity = 'high';
      result.filters.push('excessive_duration');
      result.reasons.push(`Duration exceeds limit: ${minutes} minutes`);
      result.violations.push({ type: 'duration', value: minutes, limit: SAFETY_GUARDRAILS.maxDuration });
    }
  }

  // Check frequency
  matches = text.matchAll(frequencyPattern);
  for (const match of matches) {
    const value = parseInt(match[1]);

    if (value > 2) {
      result.detected = true;
      result.severity = 'high';
      result.filters.push('excessive_frequency');
      result.reasons.push(`Frequency exceeds limit: ${value} times per day`);
      result.violations.push({ type: 'frequency', value, limit: 2 });
    }
  }

  // Check pressure (for pumping)
  matches = text.matchAll(pressurePattern);
  for (const match of matches) {
    const value = parseFloat(match[1]);

    if (value > 10) {
      result.detected = true;
      result.severity = 'high';
      result.filters.push('excessive_pressure');
      result.reasons.push(`Pressure exceeds limit: ${value} HG`);
      result.violations.push({ type: 'pressure', value, limit: 10 });
    }
  }

  // Check weight (for hanging)
  matches = text.matchAll(weightPattern);
  for (const match of matches) {
    const value = parseFloat(match[1]);
    const unit = match[2].toLowerCase();

    let pounds = value;
    if (unit.includes('kg')) {
      pounds = value * 2.20462;
    }

    if (pounds > 20) {
      result.detected = true;
      result.severity = 'high';
      result.filters.push('excessive_weight');
      result.reasons.push(`Weight exceeds limit: ${pounds.toFixed(1)} lbs`);
      result.violations.push({ type: 'weight', value: pounds, limit: 20 });
    }
  }

  return result;
}

/**
 * Calculate overall risk score from all filter results
 */
function calculateRiskScore(results) {
  let score = 0;
  let hasCritical = false;

  results.forEach(result => {
    if (!result.detected) return;

    switch (result.severity) {
      case 'critical':
        score += 40;
        hasCritical = true;
        break;
      case 'high':
        score += 30;
        break;
      case 'medium':
        score += 20;
        break;
      case 'low':
        score += 10;
        break;
    }

    // Add points for multiple violations
    if (result.filters) {
      score += result.filters.length * 5;
    }
  });

  // If any critical issue found, ensure minimum score of 75
  if (hasCritical) {
    score = Math.max(score, 75);
  }

  return Math.min(score, 100); // Cap at 100
}

/**
 * Determine if conservative override should be applied
 */
function shouldApplyConservativeOverride(results) {
  // Apply override if any critical severity detected
  const hasCritical = results.some(r => r.detected && r.severity === 'critical');

  // Apply override if multiple high severity issues
  const highSeverityCount = results.filter(r => r.detected && r.severity === 'high').length;

  // Apply override if mix of issues across categories
  const categoriesDetected = results.filter(r => r.detected).length;

  return hasCritical || highSeverityCount >= 2 || categoriesDetected >= 3;
}

/**
 * Apply conservative override to the response
 */
function applyConservativeOverride(response, filterResults) {
  let modifiedResponse = response;

  // Add safety header
  const safetyHeader = `⚠️ **Important Safety Notice**: The following response has been modified for your safety.\n\n`;

  // Replace specific problematic content
  filterResults.forEach(result => {
    if (result.detected && result.matches) {
      result.matches.forEach(match => {
        // Replace dangerous content with safer alternatives
        if (result.filters.includes('excessive_duration')) {
          modifiedResponse = modifiedResponse.replace(/\d+\s*hours?/gi, '15-30 minutes');
        }
        if (result.filters.includes('excessive_frequency')) {
          modifiedResponse = modifiedResponse.replace(/\d+\s*times?\s*(per|a|\/)\s*day/gi, 'once daily');
        }
        if (result.filters.includes('excessive_pressure')) {
          modifiedResponse = modifiedResponse.replace(/\d+\.?\d*\s*(hg|mercury)/gi, '5-7 HG');
        }
        if (result.filters.includes('excessive_weight')) {
          modifiedResponse = modifiedResponse.replace(/\d+\.?\d*\s*(lbs?|pounds?)/gi, '2.5-5 lbs');
        }
      });
    }
  });

  // Add safety footer
  const safetyFooter = `\n\n**Safety Reminders**:
- Never exceed recommended limits
- Stop immediately if you experience pain or discomfort
- Take at least ${SAFETY_GUARDRAILS.requiredRest} rest day(s) per week
- Consult a medical professional if you have any concerns
- Start conservatively and progress gradually`;

  return safetyHeader + modifiedResponse + safetyFooter;
}

/**
 * Check if response contains critical content that should be blocked
 */
function containsCriticalContent(results) {
  const criticalCount = results.filter(r => r.detected && r.severity === 'critical').length;

  // Block if multiple critical issues
  if (criticalCount >= 2) return true;

  // Block if specific dangerous combinations detected
  const hasDangerousTechnique = results.some(r =>
    r.filters && r.filters.includes('dangerous_technique')
  );
  const hasExcessiveParams = results.some(r =>
    r.filters && (r.filters.includes('excessive_duration') || r.filters.includes('excessive_weight'))
  );

  return hasDangerousTechnique && hasExcessiveParams;
}

/**
 * Generate a safety block message when content is too dangerous
 */
function generateSafetyBlockMessage(filterResults) {
  const issues = [];

  filterResults.forEach(result => {
    if (result.detected) {
      issues.push(...result.reasons);
    }
  });

  return `🚫 **Response Blocked for Safety**

I cannot provide the requested information as it may pose a risk to your safety and well-being.

**Detected Issues**:
${issues.map(issue => `• ${issue}`).join('\n')}

**Safe Alternatives**:
• Start with beginner-friendly routines (10-15 minutes max)
• Focus on proper form and technique over intensity
• Maintain regular rest days for recovery
• Progress gradually over weeks and months
• Always listen to your body's signals

**Important**: If you're experiencing any pain, discomfort, or concerning symptoms, please stop all activities and consult a medical professional immediately.

For safe, evidence-based PE guidance, please ask about:
• Beginner routines
• Safety guidelines
• Proper warm-up techniques
• Recovery practices
• Gradual progression strategies`;
}

/**
 * Add safety disclaimers to response
 */
function addSafetyDisclaimers(response, filterResults) {
  const disclaimers = [];

  // Add specific disclaimers based on detected issues
  filterResults.forEach(result => {
    if (result.detected) {
      if (result.filters.includes('medical_claim') || result.filters.includes('medical_pattern')) {
        disclaimers.push('This is educational information only, not medical advice. Consult a healthcare professional for medical concerns.');
      }
      if (result.filters.includes('excessive_duration') || result.filters.includes('excessive_frequency')) {
        disclaimers.push('Recommended durations and frequencies are general guidelines. Start conservatively and adjust based on your individual response.');
      }
      if (result.filters.includes('warning_keyword')) {
        disclaimers.push('Stop immediately if you experience any pain, numbness, or unusual symptoms.');
      }
    }
  });

  // Add unique disclaimers only
  const uniqueDisclaimers = [...new Set(disclaimers)];

  if (uniqueDisclaimers.length > 0) {
    const disclaimerSection = `\n\n⚠️ **Important Disclaimers**:\n${uniqueDisclaimers.map(d => `• ${d}`).join('\n')}`;
    return response + disclaimerSection;
  }

  return response;
}

/**
 * Log filtered response to Firestore for audit
 */
async function logFilteredResponse(filterResults, userContext) {
  try {
    const db = admin.firestore();
    const logData = {
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userId: userContext.userId || 'anonymous',
      userExperience: userContext.experienceLevel || 'unknown',
      originalQuery: userContext.query || '',
      originalResponse: filterResults.originalResponse.substring(0, 1000), // Limit size
      filteredResponse: filterResults.filteredResponse.substring(0, 1000), // Limit size
      filtersApplied: filterResults.filtersApplied,
      filterReasons: filterResults.filterReasons,
      riskScore: filterResults.riskScore,
      blocked: filterResults.blocked,
      metadata: {
        sessionId: userContext.sessionId || null,
        platform: userContext.platform || 'web'
      }
    };

    await db.collection('ai_coach_filter_logs').add(logData);
    console.log('Filter log created successfully');
  } catch (error) {
    console.error('Error logging filtered response:', error);
    // Don't throw - logging failure shouldn't break the response flow
  }
}

module.exports = {
  filterResponse,
  detectUnsafeKeywords,
  detectMedicalClaims,
  assessInjuryRisk,
  checkExcessiveParameters,
  calculateRiskScore,
  SAFETY_GUARDRAILS,
  FILTER_CATEGORIES
};