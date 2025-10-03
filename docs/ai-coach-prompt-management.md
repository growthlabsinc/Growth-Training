# AI Coach Prompt Management Guide

## Overview
This document provides comprehensive guidance for managing the AI Coach system prompts in the Growth Training app, focusing on PE-specific knowledge integration and safety-first responses.

## System Architecture

### Core Components
- **Prompt Generator**: `functions/vertexAiProxy/index.js` - `generateSystemPrompt()` function
- **Knowledge Search**: `functions/vertexAiProxy/knowledgeBaseSearch.js` - PE-optimized search
- **AI Model**: Gemini 2.0 Flash Lite (`gemini-2.0-flash-lite-001`)
- **Knowledge Base**: Firestore collection `ai_coach_knowledge` (67 documents)

### Prompt Structure
The system prompt consists of three main sections:

1. **Base Prompt**: Core identity and safety-first principles
2. **Knowledge Integration**: Dynamic content from Firestore search results
3. **Response Instructions**: Structured guidance for AI responses

## Base Prompt Framework

### Identity & Core Principles
```javascript
You are the Growth Coach, an AI assistant for the Growth mobile app specializing in safe and evidence-based PE (penis enlargement) training techniques.

CORE PRINCIPLE: You provide educational guidance focused on safety and evidence-based PE training practices with comprehensive knowledge of length, girth, and EQ enhancement methods.
```

### Safety Guidelines
The prompt enforces these safety principles:
1. Safety is paramount - encourage conservative approaches
2. Provide evidence-based information only
3. Encourage healthcare provider consultation
4. Never provide medical advice or diagnose conditions
5. Focus on proper technique and realistic expectations
6. Default to safety recommendations when uncertain
7. Guide progressive training paths by experience level
8. Emphasize consistency over aggressive approaches

### Medical Disclaimer Integration
All responses automatically include disclaimers that:
- PE carries inherent risks
- Training is not medically supervised
- Users should consult healthcare providers for concerns
- Stop immediately if experiencing pain, numbness, or discoloration

## Knowledge Base Integration

### Search Optimization
The knowledge search has been optimized for PE terminology:

**Replaced Angion Terms**:
- ❌ `am1`, `am2`, `am3`, `angion method`

**Added PE Terms**:
- ✅ `jelqing`, `stretching`, `pumping`, `hanging`
- ✅ `kegels`, `eq`, `extender`, `clamping`
- ✅ `safety`, `beginner`, `routine`, `gains`

### Priority System
Knowledge sources are prioritized as follows:
1. **Safety Content** (Priority 9-10): Gets highest priority
2. **High Priority Content** (Priority 7-8): Moderate boost
3. **Category Matching**: Additional relevance for context-appropriate content
4. **Keyword Relevance**: Based on search term matches

### Content Sorting
Results are sorted by:
1. Safety priority (Priority 9-10 first)
2. Relevance score (keyword matches + category boost)
3. Confidence level

## Response Structure Guidelines

### Progressive Difficulty Levels
Responses should be structured by experience level:
- **Beginner**: Basic techniques, extensive safety warnings
- **Intermediate**: More advanced methods with cautions
- **Advanced**: Complex techniques with strong safety emphasis

### Required Elements
Every AI response should include:
1. **Safety emphasis** (injury prevention paramount)
2. **Progressive guidance** (based on experience level)
3. **Medical disclaimers** (for all technique discussions)
4. **Realistic expectations** (progress in months/years, not weeks)
5. **Proper technique focus** (form over intensity)

## Testing Procedures

### Validation Queries
Test the system with these query categories:

**Safety Queries**:
- "Is PE dangerous?"
- "I have pain during PE"
- "What are the risks?"

**Beginner Queries**:
- "How to start PE?"
- "What is PE training?"
- "Beginner routine"

**Technique Queries**:
- "Jelqing technique"
- "Hanging weights"
- "Kegel exercises"

**Expectation Queries**:
- "How fast can I gain?"
- "Best exercises for gains?"
- "Expected results"

### Success Criteria
For each test query, verify:
1. ✅ Safety content is prioritized (Priority 9-10 appears first)
2. ✅ No Angion methodology references
3. ✅ Medical disclaimers included in technique responses
4. ✅ Conservative guidance emphasized
5. ✅ Realistic timelines provided (months/years)
6. ✅ Progressive difficulty levels respected

### Automated Testing
Use the test script at `/functions/testAICoachPrompts.js`:

```bash
cd functions
node testAICoachPrompts.js
```

Expected output: All tests pass with PE optimization score ≥ 70%

## Maintenance Guidelines

### Regular Reviews
1. **Monthly**: Test with new query patterns
2. **Quarterly**: Review safety content prioritization
3. **After knowledge updates**: Re-run full test suite
4. **When issues reported**: Immediate investigation and testing

### Content Updates
When adding new knowledge documents:
1. Ensure Priority 9-10 for safety content
2. Add relevant PE keywords for searchability
3. Include medical disclaimers in content
4. Test search relevance after deployment

### Prompt Modifications
When updating the system prompt:
1. Maintain safety-first principles
2. Test with existing query patterns
3. Verify knowledge integration still works
4. Update this documentation

## Troubleshooting

### Common Issues

**Low Safety Prioritization**:
- Check Priority values in knowledge documents
- Verify safety content boosting in search logic
- Ensure category='safety' for safety documents

**Poor Search Results**:
- Review keyword variations in knowledgeBaseSearch.js
- Check Firestore indexes are built
- Verify search term expansion logic

**Angion References**:
- Search codebase for remaining 'angion' strings
- Check knowledge documents for old content
- Verify search term replacements

### Emergency Procedures
If safety concerns arise:
1. Immediately update safety boosting multipliers
2. Add emergency safety checks to prompt
3. Deploy hotfix and run full test suite
4. Document incident and prevention measures

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-09-22 | Initial PE-focused prompt system | James (Developer) |

## Related Documentation
- Epic 3: AI Coach Transformation
- Story 3.3: Develop Training Protocol Knowledge
- PE Knowledge Expansion Guide
- Firebase Knowledge Base Schema