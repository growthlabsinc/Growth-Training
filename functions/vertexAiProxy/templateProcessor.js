/**
 * Template Processor for Variable Substitution
 * Story 3.7: Develop Conversation Templates
 * 
 * This module handles variable substitution and template processing
 * to create personalized responses.
 */

const { getTemplateById } = require('./conversationTemplates');

/**
 * Process a template with variable substitution
 */
function processTemplate(templateId, customVariables = {}, userContext = {}) {
  const template = getTemplateById(templateId);
  
  if (!template) {
    console.error(`Template not found: ${templateId}`);
    return null;
  }
  
  // Merge variables: defaults -> context -> custom
  const variables = {
    ...getDefaultVariables(),
    ...getContextVariables(userContext),
    ...template.variables,
    ...customVariables
  };
  
  // Process the template text
  let processedText = template.template;
  
  // Replace variables using {{variableName}} pattern
  Object.entries(variables).forEach(([key, value]) => {
    const pattern = new RegExp(`{{\\s*${key}\\s*}}`, 'g');
    processedText = processedText.replace(pattern, value);
  });
  
  // Process conditional sections
  processedText = processConditionals(processedText, variables);
  
  // Process lists and iterations
  processedText = processLists(processedText, variables);
  
  // Clean up any remaining unmatched variables
  processedText = cleanupUnmatchedVariables(processedText);
  
  return {
    text: processedText,
    templateId: template.id,
    priority: template.priority,
    tags: template.tags,
    variablesUsed: Object.keys(variables)
  };
}

/**
 * Get default variables available to all templates
 */
function getDefaultVariables() {
  const now = new Date();
  const timeOfDay = getTimeOfDay(now.getHours());
  
  return {
    // Time-based
    currentDate: now.toLocaleDateString(),
    currentTime: now.toLocaleTimeString(),
    timeOfDay: timeOfDay,
    dayOfWeek: getDayName(now.getDay()),
    
    // Safety defaults (from Epic 3 requirements)
    maxDuration: '60',
    maxFrequency: 'once daily',
    requiredRest: '1-2 days',
    beginnerLimit: '15',
    
    // General defaults
    appName: 'Growth Training',
    coachName: 'PE Coach',
    communityName: 'Growth Training Community'
  };
}

/**
 * Extract variables from user context
 */
function getContextVariables(userContext) {
  const variables = {};

  // Handle null/undefined context
  if (!userContext) {
    return variables;
  }

  // User experience level
  if (userContext.userExperienceLevel) {
    variables.experienceLevel = userContext.userExperienceLevel;
    
    // Set level-specific variables
    switch (userContext.userExperienceLevel) {
      case 'beginner':
        variables.sessionDuration = '15-20';
        variables.frequency = 'every other day';
        variables.intensity = 'light to moderate';
        variables.restDays = '3-4';
        break;
      case 'intermediate':
        variables.sessionDuration = '30-45';
        variables.frequency = '4-5 times per week';
        variables.intensity = 'moderate';
        variables.restDays = '2-3';
        break;
      case 'advanced':
        variables.sessionDuration = '45-60';
        variables.frequency = '5-6 times per week';
        variables.intensity = 'moderate to high';
        variables.restDays = '1-2';
        break;
      default:
        variables.sessionDuration = '20-30';
        variables.frequency = '3-4 times per week';
        variables.intensity = 'moderate';
        variables.restDays = '2-3';
    }
  }
  
  // User name if available
  if (userContext.userName) {
    variables.userName = userContext.userName;
    variables.userGreeting = `Hello ${userContext.userName}`;
  } else {
    variables.userName = 'there';
    variables.userGreeting = 'Hello';
  }
  
  // Session-specific variables
  if (userContext.sessionType) {
    variables.sessionType = userContext.sessionType;
  }
  
  // Progress data if available
  if (userContext.progressData) {
    variables.currentStreak = userContext.progressData.streak || '0';
    variables.totalSessions = userContext.progressData.totalSessions || '0';
    variables.lastSessionDate = userContext.progressData.lastSession || 'N/A';
  }
  
  // Goals if specified
  if (userContext.primaryGoal) {
    variables.primaryGoal = userContext.primaryGoal;
    
    // Set goal-specific recommendations
    switch (userContext.primaryGoal) {
      case 'length':
        variables.focusExercises = 'stretching, hanging, extending';
        variables.primaryTechnique = 'manual stretching';
        break;
      case 'girth':
        variables.focusExercises = 'jelqing, clamping, pumping';
        variables.primaryTechnique = 'jelqing';
        break;
      case 'eq':
        variables.focusExercises = 'kegels, edging, cardio';
        variables.primaryTechnique = 'kegel exercises';
        break;
      default:
        variables.focusExercises = 'balanced routine';
        variables.primaryTechnique = 'varied techniques';
    }
  }
  
  return variables;
}

/**
 * Process conditional sections in templates
 * Format: {{if variableName}}content{{/if}}
 */
function processConditionals(text, variables) {
  const conditionalPattern = /{{if\s+(\w+)}}([\s\S]*?){{\/if}}/g;
  
  return text.replace(conditionalPattern, (match, varName, content) => {
    // Check if variable exists and is truthy
    if (variables[varName] && variables[varName] !== 'false' && variables[varName] !== '0') {
      return content;
    }
    return '';
  });
}

/**
 * Process list iterations in templates
 * Format: {{each listName}}item content{{/each}}
 */
function processLists(text, variables) {
  const listPattern = /{{each\s+(\w+)}}([\s\S]*?){{\/each}}/g;
  
  return text.replace(listPattern, (match, listName, itemTemplate) => {
    const list = variables[listName];
    
    if (Array.isArray(list)) {
      return list.map((item, index) => {
        let processed = itemTemplate;
        
        // Replace {{item}} with the actual item
        processed = processed.replace(/{{item}}/g, item);
        
        // Replace {{index}} with the index
        processed = processed.replace(/{{index}}/g, index + 1);
        
        // If item is an object, replace its properties
        if (typeof item === 'object' && item !== null) {
          Object.entries(item).forEach(([key, value]) => {
            const pattern = new RegExp(`{{${key}}}`, 'g');
            processed = processed.replace(pattern, value);
          });
        }
        
        return processed;
      }).join('');
    }
    
    return '';
  });
}

/**
 * Clean up any unmatched variables
 */
function cleanupUnmatchedVariables(text) {
  // Remove any remaining {{variable}} patterns
  return text.replace(/{{\s*\w+\s*}}/g, '');
}

/**
 * Get time of day greeting
 */
function getTimeOfDay(hour) {
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  if (hour < 21) return 'evening';
  return 'night';
}

/**
 * Get day name
 */
function getDayName(dayIndex) {
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return days[dayIndex];
}

/**
 * Enhance template with dynamic content
 */
function enhanceTemplateWithDynamicContent(processedTemplate, userContext) {
  let enhanced = processedTemplate.text;
  
  // Add personalized greeting if not already present
  if (userContext.userName && !enhanced.includes(userContext.userName)) {
    const genericGreetings = ['Hello', 'Hi there', 'Welcome'];
    genericGreetings.forEach(greeting => {
      enhanced = enhanced.replace(
        new RegExp(`^${greeting}`, 'i'),
        `${greeting} ${userContext.userName}`
      );
    });
  }
  
  // Add current progress if relevant
  if (userContext.progressData && processedTemplate.tags.includes('progress')) {
    const progressNote = `\n\n*Current Progress: ${userContext.progressData.summary || 'Tracking in progress'}*`;
    if (!enhanced.includes('Current Progress')) {
      enhanced += progressNote;
    }
  }
  
  // Add safety reminder for high-risk contexts
  if (userContext.riskLevel === 'high' || processedTemplate.tags.includes('safety')) {
    const safetyReminder = `\n\n⚠️ **Remember**: Your safety is paramount. Stop immediately if you experience any pain or unusual symptoms.`;
    if (!enhanced.includes('safety is paramount')) {
      enhanced += safetyReminder;
    }
  }
  
  return {
    ...processedTemplate,
    text: enhanced
  };
}

/**
 * Validate required variables for a template
 */
function validateTemplateVariables(templateId, providedVariables = {}) {
  const template = getTemplateById(templateId);
  
  if (!template) {
    return {
      valid: false,
      error: 'Template not found'
    };
  }
  
  const requiredVariables = [];
  const variablePattern = /{{\s*(\w+)\s*}}/g;
  let match;
  
  while ((match = variablePattern.exec(template.template)) !== null) {
    const varName = match[1];
    if (!requiredVariables.includes(varName)) {
      requiredVariables.push(varName);
    }
  }
  
  // Check which required variables are missing
  const allVariables = {
    ...getDefaultVariables(),
    ...getContextVariables({}), // Add default context variables
    ...(template.variables || {}),
    ...providedVariables
  };
  
  const missingVariables = requiredVariables.filter(v => !allVariables[v]);
  
  return {
    valid: missingVariables.length === 0,
    missingVariables,
    requiredVariables,
    providedVariables: Object.keys(providedVariables)
  };
}

/**
 * Batch process multiple templates
 */
function batchProcessTemplates(templateRequests) {
  return templateRequests.map(request => {
    const { templateId, variables, context } = request;
    
    try {
      const processed = processTemplate(templateId, variables, context);
      if (context && context.enhance) {
        return enhanceTemplateWithDynamicContent(processed, context);
      }
      return processed;
    } catch (error) {
      console.error(`Error processing template ${templateId}:`, error);
      return {
        error: true,
        templateId,
        message: error.message
      };
    }
  });
}

module.exports = {
  processTemplate,
  enhanceTemplateWithDynamicContent,
  validateTemplateVariables,
  batchProcessTemplates,
  getDefaultVariables,
  getContextVariables,
  processConditionals,
  processLists
};