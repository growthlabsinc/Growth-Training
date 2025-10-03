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

  // Check if medical disclaimers are needed for borderline educational content
  const needsMedicalDisclaimer = medicalClaimResult.needsDisclaimer ||
                                  medicalClaimResult.bypassedForEducation;

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
  } else if (needsMedicalDisclaimer && !medicalClaimResult.detected) {
    // Add medical disclaimer for educational content
    filterResults.filteredResponse = addMedicalDisclaimer(response);
    filterResults.filtersApplied.push('medical_disclaimer');
    filterResults.requiresLogging = false; // Don't log educational content
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
    matches: [],
    needsDisclaimer: false,
    bypassedForEducation: false
  };

  // Legitimate educational phrases that should bypass filtering
  const educationalBypassPhrases = [
    'may help',
    'could improve',
    'might support',
    'potentially beneficial',
    'some users report',
    'research suggests',
    'studies indicate',
    'general wellness',
    'pelvic health',
    'muscle strength'
  ];

  // Check if content is educational and should bypass strict filtering
  const isEducational = educationalBypassPhrases.some(phrase =>
    text.toLowerCase().includes(phrase)
  );

  // More sophisticated medical claim patterns
  const enhancedMedicalPatterns = [
    /will\s+(cure|fix|heal|eliminate|reverse)\s+(?:your\s+)?(?:ED|erectile|dysfunction)/gi,
    /guaranteed\s+to\s+(?:cure|fix|heal|work)/gi,
    /(?:proven|clinically)\s+to\s+(?:cure|treat|heal)/gi,
    /(?:100%|completely)\s+(?:cure|effective|guaranteed)/gi,
    /replace\s+(?:medication|drugs|prescription)/gi,
    /better\s+than\s+(?:viagra|cialis|medication)/gi,
    /medical\s+(?:treatment|cure|therapy)/gi,
    /diagnose\s+(?:your|the)\s+(?:condition|problem)/gi
  ];

  // Check medical claim keywords
  FILTER_CATEGORIES.medicalClaims.keywords.forEach(keyword => {
    if (text.toLowerCase().includes(keyword.toLowerCase())) {
      // If educational context, add disclaimer instead of filtering
      if (isEducational && !['cure', 'guarantee', 'diagnose'].includes(keyword.toLowerCase())) {
        result.needsDisclaimer = true;
        result.bypassedForEducation = true;
      } else {
        result.detected = true;
        result.severity = 'high';
        result.filters.push('medical_claim');
        result.reasons.push(`Contains medical claim: ${keyword}`);
        result.matches.push(keyword);
      }
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

  // Check enhanced medical patterns
  enhancedMedicalPatterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) {
      result.detected = true;
      result.severity = 'critical';
      result.filters.push('enhanced_medical_pattern');
      result.reasons.push(`Strong medical claim detected: ${matches[0]}`);
      result.matches.push(...matches);
    }
  });

  // Check for unproven method claims
  FILTER_CATEGORIES.unprovenMethods.keywords.forEach(keyword => {
    if (text.toLowerCase().includes(keyword.toLowerCase())) {
      if (isEducational) {
        result.needsDisclaimer = true;
      } else {
        result.detected = true;
        result.severity = result.severity === 'high' ? 'high' : 'medium';
        result.filters.push('unproven_method');
        result.reasons.push(`Contains unproven method: ${keyword}`);
        result.matches.push(keyword);
      }
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
    riskFactors: [],
    riskScore: 0
  };

  const isBeginnerUser = userContext.userExperienceLevel === 'beginner';
  const isIntermediateUser = userContext.userExperienceLevel === 'intermediate';

  // Enhanced risk parameters with thresholds
  const riskParameters = {
    duration: {
      beginner: { warning: 15, danger: 30 },
      intermediate: { warning: 30, danger: 60 },
      advanced: { warning: 60, danger: 90 }
    },
    intensity: {
      beginner: { warning: 'moderate', danger: 'high' },
      intermediate: { warning: 'high', danger: 'extreme' },
      advanced: { warning: 'very high', danger: 'extreme' }
    },
    frequency: {
      beginner: { warning: 1, danger: 2 },
      intermediate: { warning: 2, danger: 3 },
      advanced: { warning: 3, danger: 4 }
    }
  };

  const userLevel = userContext.userExperienceLevel || 'beginner';
  const thresholds = {
    duration: riskParameters.duration[userLevel] || riskParameters.duration.beginner,
    intensity: riskParameters.intensity[userLevel] || riskParameters.intensity.beginner,
    frequency: riskParameters.frequency[userLevel] || riskParameters.frequency.beginner
  };

  // Check duration parameters
  const durationPatterns = [
    /(\d+)\s*hours?/gi,
    /(\d+)\s*minutes?/gi,
    /(\d+)\s*mins?/gi
  ];

  durationPatterns.forEach(pattern => {
    const matches = [...text.matchAll(pattern)];
    matches.forEach(match => {
      let minutes = parseInt(match[1]);
      if (match[0].includes('hour')) {
        minutes *= 60;
      }

      if (minutes > thresholds.duration.danger) {
        result.detected = true;
        result.severity = 'critical';
        result.filters.push('excessive_duration');
        result.reasons.push(`Duration exceeds limit: ${match[0]}`);
        result.riskFactors.push({
          type: 'duration',
          value: minutes,
          limit: thresholds.duration.danger,
          severity: 'critical'
        });
        result.riskScore += 30;
      } else if (minutes > thresholds.duration.warning) {
        result.detected = true;
        result.severity = result.severity === 'critical' ? 'critical' : 'high';
        result.filters.push('high_duration');
        result.reasons.push(`Duration is high: ${match[0]}`);
        result.riskFactors.push({
          type: 'duration',
          value: minutes,
          limit: thresholds.duration.warning,
          severity: 'warning'
        });
        result.riskScore += 15;
      }
    });
  });

  // Check frequency parameters
  const frequencyPatterns = [
    /(\d+)\s*times?\s*(?:per|a|\/)\s*day/gi,
    /(\d+)x?\s*(?:daily|per\s*day)/gi,
    /(?:twice|three\s*times|four\s*times)\s*(?:daily|per\s*day)/gi
  ];

  frequencyPatterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) {
      let frequency = 1;
      if (matches[0].includes('twice')) frequency = 2;
      else if (matches[0].includes('three')) frequency = 3;
      else if (matches[0].includes('four')) frequency = 4;
      else {
        const numberMatch = matches[0].match(/\d+/);
        if (numberMatch) frequency = parseInt(numberMatch[0]);
      }

      if (frequency > thresholds.frequency.danger) {
        result.detected = true;
        result.severity = 'critical';
        result.filters.push('excessive_frequency');
        result.reasons.push(`Frequency exceeds limit: ${frequency} times per day`);
        result.riskFactors.push({
          type: 'frequency',
          value: frequency,
          limit: thresholds.frequency.danger,
          severity: 'critical'
        });
        result.riskScore += 25;
      } else if (frequency > thresholds.frequency.warning) {
        result.detected = true;
        result.severity = result.severity === 'critical' ? 'critical' : 'high';
        result.filters.push('high_frequency');
        result.reasons.push(`Frequency is high: ${frequency} times per day`);
        result.riskFactors.push({
          type: 'frequency',
          value: frequency,
          limit: thresholds.frequency.warning,
          severity: 'warning'
        });
        result.riskScore += 15;
      }
    }
  });

  // Check intensity indicators
  const intensityKeywords = {
    extreme: ['maximum', 'extreme', 'intense', 'aggressive', 'forceful'],
    high: ['strong', 'firm', 'vigorous', 'substantial'],
    moderate: ['moderate', 'gentle', 'comfortable', 'gradual']
  };

  intensityKeywords.extreme.forEach(keyword => {
    if (text.toLowerCase().includes(keyword)) {
      result.detected = true;
      result.severity = 'critical';
      result.filters.push('extreme_intensity');
      result.reasons.push(`Contains extreme intensity indicator: ${keyword}`);
      result.riskScore += 20;
    }
  });

  if (isBeginnerUser) {
    intensityKeywords.high.forEach(keyword => {
      if (text.toLowerCase().includes(keyword)) {
        result.detected = true;
        result.severity = result.severity === 'critical' ? 'critical' : 'high';
        result.filters.push('high_intensity_for_beginner');
        result.reasons.push(`High intensity for beginner: ${keyword}`);
        result.riskScore += 10;
      }
    });
  }

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
  // Enhanced override triggers for ambiguous safety situations

  // 1. Apply override if any critical severity detected
  const hasCritical = results.some(r => r.detected && r.severity === 'critical');

  // 2. Apply override if multiple high severity issues
  const highSeverityCount = results.filter(r => r.detected && r.severity === 'high').length;

  // 3. Apply override if mix of issues across categories
  const categoriesDetected = results.filter(r => r.detected).length;

  // 4. Check for ambiguous content combinations
  const hasAmbiguousCombination = checkAmbiguousCombinations(results);

  // 5. Check cumulative risk factors
  const cumulativeRiskScore = results.reduce((sum, r) => {
    if (r.riskScore) return sum + r.riskScore;
    if (r.detected) return sum + (r.severity === 'high' ? 20 : 10);
    return sum;
  }, 0);

  // Apply conservative override based on multiple criteria
  return hasCritical ||
         highSeverityCount >= 2 ||
         categoriesDetected >= 3 ||
         hasAmbiguousCombination ||
         cumulativeRiskScore >= 60;
}

/**
 * Check for ambiguous content combinations that warrant conservative override
 */
function checkAmbiguousCombinations(results) {
  const detectedTypes = new Set();

  results.forEach(r => {
    if (r.detected && r.filters) {
      r.filters.forEach(filter => {
        if (filter.includes('medical')) detectedTypes.add('medical');
        if (filter.includes('duration') || filter.includes('frequency')) detectedTypes.add('parameters');
        if (filter.includes('intensity') || filter.includes('force')) detectedTypes.add('intensity');
        if (filter.includes('beginner')) detectedTypes.add('experience');
      });
    }
  });

  // Ambiguous if medical claims + high parameters
  if (detectedTypes.has('medical') && detectedTypes.has('parameters')) return true;

  // Ambiguous if intensity issues + experience mismatch
  if (detectedTypes.has('intensity') && detectedTypes.has('experience')) return true;

  // Ambiguous if 3+ different categories present
  return detectedTypes.size >= 3;
}

/**
 * Apply conservative override to the response
 */
function applyConservativeOverride(response, filterResults) {
  let modifiedResponse = response;

  // Add safety header with escalation notice
  const safetyHeader = `⚠️ **Important Safety Notice**: The following response has been modified for your safety.\n\n`;

  // Safety buffer parameters - more conservative than normal limits
  const safetyBuffer = {
    duration: {
      beginner: '10-15 minutes',
      intermediate: '15-25 minutes',
      advanced: '20-30 minutes'
    },
    frequency: {
      beginner: 'once every other day',
      intermediate: 'once daily',
      advanced: 'once or twice daily with rest days'
    },
    intensity: {
      beginner: 'gentle to moderate',
      intermediate: 'moderate',
      advanced: 'moderate to firm'
    },
    pressure: {
      beginner: '3-5 HG',
      intermediate: '5-7 HG',
      advanced: '7-10 HG'
    },
    weight: {
      beginner: '1-2.5 lbs',
      intermediate: '2.5-5 lbs',
      advanced: '5-10 lbs'
    }
  };

  // Determine user level for safety buffer
  const userLevel = filterResults.some(r =>
    r.filters && r.filters.includes('beginner')
  ) ? 'beginner' : 'intermediate';

  // Replace specific problematic content with safety buffer values
  filterResults.forEach(result => {
    if (result.detected) {
      // Duration replacements
      if (result.filters && (result.filters.includes('excessive_duration') ||
                              result.filters.includes('high_duration'))) {
        modifiedResponse = modifiedResponse.replace(
          /\d+\s*(hours?|minutes?|mins?)/gi,
          safetyBuffer.duration[userLevel]
        );
      }

      // Frequency replacements
      if (result.filters && (result.filters.includes('excessive_frequency') ||
                              result.filters.includes('high_frequency'))) {
        modifiedResponse = modifiedResponse.replace(
          /\d+\s*times?\s*(per|a|\/)\s*day/gi,
          safetyBuffer.frequency[userLevel]
        );
        modifiedResponse = modifiedResponse.replace(
          /(twice|three\s*times|four\s*times)\s*(daily|per\s*day)/gi,
          safetyBuffer.frequency[userLevel]
        );
      }

      // Pressure replacements
      if (result.filters && result.filters.includes('excessive_pressure')) {
        modifiedResponse = modifiedResponse.replace(
          /\d+\.?\d*\s*(hg|mercury)/gi,
          safetyBuffer.pressure[userLevel]
        );
      }

      // Weight replacements
      if (result.filters && result.filters.includes('excessive_weight')) {
        modifiedResponse = modifiedResponse.replace(
          /\d+\.?\d*\s*(lbs?|pounds?|kg|kilograms?)/gi,
          safetyBuffer.weight[userLevel]
        );
      }

      // Intensity replacements
      if (result.filters && (result.filters.includes('extreme_intensity') ||
                              result.filters.includes('high_intensity_for_beginner'))) {
        const intensityTerms = ['maximum', 'extreme', 'intense', 'aggressive', 'forceful', 'strong', 'firm'];
        intensityTerms.forEach(term => {
          const regex = new RegExp(`\\b${term}\\b`, 'gi');
          modifiedResponse = modifiedResponse.replace(regex, safetyBuffer.intensity[userLevel]);
        });
      }
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
 * Add medical disclaimer for educational content
 */
function addMedicalDisclaimer(response) {
  const medicalDisclaimer = `\n\n**Medical Disclaimer**: This information is for educational purposes only and should not be considered medical advice. It is not intended to diagnose, treat, cure, or prevent any medical condition. Always consult with a qualified healthcare professional before starting any new exercise program or if you have health concerns.`;

  return response + medicalDisclaimer;
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
/**
 * Log filtered responses for audit and monitoring
 */
async function logFilteredResponse(filterResults, userContext) {
  try {
    const db = admin.firestore();

    // Enhanced metadata capture
    const logData = {
      // Timestamp and identification
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      logId: generateLogId(),
      userId: userContext.userId || 'anonymous',
      conversationId: userContext.conversationId || null,

      // User context
      userContext: {
        experienceLevel: userContext.userExperienceLevel || 'unknown',
        sessionType: userContext.sessionType || 'general',
        platform: userContext.platform || 'ios',
        appVersion: userContext.appVersion || null
      },

      // Query information
      query: {
        original: userContext.query || '',
        timestamp: new Date().toISOString(),
        wordCount: userContext.query ? userContext.query.split(' ').length : 0
      },

      // Response data (truncated for storage)
      responses: {
        original: truncateText(filterResults.originalResponse, 1000),
        filtered: truncateText(filterResults.filteredResponse, 1000),
        wasModified: filterResults.originalResponse !== filterResults.filteredResponse
      },

      // Filter details
      filteringDetails: {
        filtersApplied: filterResults.filtersApplied || [],
        filterReasons: filterResults.filterReasons || [],
        riskScore: filterResults.riskScore || 0,
        severity: calculateSeverityLevel(filterResults.riskScore),
        blocked: filterResults.blocked || false,
        requiresReview: filterResults.riskScore > 80
      },

      // Analytics metadata
      analytics: {
        processingTimeMs: Date.now() - (userContext.startTime || Date.now()),
        filterCategories: categorizeFilters(filterResults.filtersApplied),
        actionTaken: determineActionTaken(filterResults),
        escalationRequired: filterResults.blocked || filterResults.riskScore > 90
      },

      // Monitoring flags
      monitoring: {
        requiresManualReview: shouldRequireManualReview(filterResults),
        falsePositiveCandidate: checkFalsePositiveIndicators(filterResults),
        severity: filterResults.blocked ? 'critical' :
                  filterResults.riskScore > 70 ? 'high' :
                  filterResults.riskScore > 50 ? 'medium' : 'low'
      }
    };

    // Add to Firestore with automatic ID
    const docRef = await db.collection('ai_coach_filter_logs').add(logData);

    // Create index entry for quick lookups
    if (filterResults.blocked || filterResults.riskScore > 80) {
      await createHighRiskIndex(docRef.id, logData);
    }

    // Log summary for monitoring
    console.log(`Filter log created: ${docRef.id}`, {
      userId: logData.userId,
      riskScore: logData.filteringDetails.riskScore,
      blocked: logData.filteringDetails.blocked,
      filtersApplied: logData.filteringDetails.filtersApplied.length
    });

    return docRef.id;
  } catch (error) {
    console.error('Error logging filtered response:', error);
    // Don't throw - logging failure shouldn't break the response flow
    // But track the failure for monitoring
    trackLoggingFailure(error, userContext);
  }
}

/**
 * Helper function to generate unique log ID
 */
function generateLogId() {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 9);
  return `filter_${timestamp}_${random}`;
}

/**
 * Safely truncate text while preserving structure
 */
function truncateText(text, maxLength) {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength - 3) + '...';
}

/**
 * Calculate severity level based on risk score
 */
function calculateSeverityLevel(riskScore) {
  if (riskScore >= 90) return 'critical';
  if (riskScore >= 70) return 'high';
  if (riskScore >= 50) return 'medium';
  if (riskScore >= 30) return 'low';
  return 'minimal';
}

/**
 * Categorize filters for analytics
 */
function categorizeFilters(filters) {
  const categories = {
    medical: 0,
    safety: 0,
    parameters: 0,
    legal: 0,
    other: 0
  };

  filters.forEach(filter => {
    if (filter.includes('medical') || filter.includes('claim')) categories.medical++;
    else if (filter.includes('keyword') || filter.includes('danger')) categories.safety++;
    else if (filter.includes('duration') || filter.includes('frequency')) categories.parameters++;
    else if (filter.includes('legal') || filter.includes('FDA')) categories.legal++;
    else categories.other++;
  });

  return categories;
}

/**
 * Determine the action taken based on filter results
 */
function determineActionTaken(filterResults) {
  if (filterResults.blocked) return 'blocked';
  if (filterResults.filteredResponse !== filterResults.originalResponse) return 'modified';
  if (filterResults.filtersApplied.includes('medical_disclaimer')) return 'disclaimer_added';
  if (filterResults.filtersApplied.includes('safety_disclaimers')) return 'safety_notice_added';
  return 'monitored_only';
}

/**
 * Check if manual review is required
 */
function shouldRequireManualReview(filterResults) {
  // Require review for blocked content
  if (filterResults.blocked) return true;

  // Require review for very high risk scores
  if (filterResults.riskScore >= 85) return true;

  // Require review if multiple critical filters triggered
  const criticalFilterCount = filterResults.filtersApplied.filter(f =>
    f.includes('critical') || f.includes('excessive') || f.includes('extreme')
  ).length;

  return criticalFilterCount >= 2;
}

/**
 * Check for false positive indicators
 */
function checkFalsePositiveIndicators(filterResults) {
  // Check if only minor filters triggered with low risk score
  if (filterResults.riskScore < 30 && filterResults.filtersApplied.length <= 2) {
    return true;
  }

  // Check if educational content was flagged
  return filterResults.filtersApplied.includes('medical_disclaimer') &&
         !filterResults.filtersApplied.includes('blocked');
}

/**
 * Create high-risk index for monitoring dashboard
 */
async function createHighRiskIndex(logId, logData) {
  try {
    const db = admin.firestore();
    await db.collection('ai_coach_high_risk_logs').doc(logId).set({
      logId: logId,
      timestamp: logData.timestamp,
      userId: logData.userId,
      riskScore: logData.filteringDetails.riskScore,
      blocked: logData.filteringDetails.blocked,
      requiresReview: logData.monitoring.requiresManualReview,
      reviewStatus: 'pending'
    });
  } catch (error) {
    console.error('Error creating high-risk index:', error);
  }
}

/**
 * Track logging failures for system monitoring
 */
function trackLoggingFailure(error, userContext) {
  console.error('Logging failure tracked:', {
    error: error.message,
    userId: userContext.userId,
    timestamp: new Date().toISOString()
  });
  // In production, this could send to an external monitoring service
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