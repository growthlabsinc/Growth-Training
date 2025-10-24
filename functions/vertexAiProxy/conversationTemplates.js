/**
 * Conversation Templates - Minimal Stub for Deployment
 * Full templates disabled to avoid deployment timeout
 */

// Minimal template structure for safety override only
const TEMPLATES = {
  safety_stop_signal: {
    id: 'safety_stop_signal',
    priority: 10,
    tags: ['safety', 'emergency'],
    content: `🚨 STOP TRAINING IMMEDIATELY

You've described symptoms that require immediate medical attention.

**URGENT ACTIONS:**
1. STOP all PE training immediately
2. Apply cold compress if swelling
3. Seek medical attention if symptoms persist > 15 minutes
4. Do NOT resume training until cleared by healthcare provider

**WARNING SIGNS:**
- Severe or sharp pain
- Numbness lasting > 15 minutes
- Discoloration (blue/purple)
- Bleeding or bruising

Your health and safety are paramount.

**MEDICAL DISCLAIMER:**
This is NOT medical advice. Consult a healthcare provider immediately for proper medical evaluation and treatment.`
  }
};

function getTemplateById(id) {
  return TEMPLATES[id] || null;
}

function getTemplatesByTag(tag) {
  return Object.values(TEMPLATES).filter(t => t.tags?.includes(tag));
}

function getTemplatesByCategory(category) {
  return [];
}

const TEMPLATE_PRIORITY = {
  CRITICAL: 10,
  HIGH: 8,
  MEDIUM: 5,
  LOW: 3
};

module.exports = {
  getTemplateById,
  getTemplatesByTag,
  getTemplatesByCategory,
  TEMPLATE_PRIORITY
};
