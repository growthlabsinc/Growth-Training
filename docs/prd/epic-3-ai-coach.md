# Epic 3: AI Coach Transformation

## Epic Overview
Transform the AI Coach from Angion Method expertise to safe, evidence-based PE guidance

**Priority**: P0 - Critical
**Estimated Effort**: 4 days
**Dependencies**: Epic 1 (Infrastructure), Epic 2 (Content)
**Owner**: AI/ML Team & Content Team

## Epic Goals
- Replace Angion-focused AI knowledge base
- Implement PE safety-first response system
- Create comprehensive PE knowledge repository
- Ensure medically responsible AI guidance

## Acceptance Criteria
- [ ] All Angion knowledge removed from AI system
- [ ] New PE knowledge base deployed
- [ ] Safety checks integrated in responses
- [ ] AI provides evidence-based guidance
- [ ] Response quality validated
- [ ] Legal/medical disclaimers enforced

## User Stories

### Story 3.1: Remove Angion Knowledge Base
**As a** system administrator
**I want to** purge all Angion-specific knowledge
**So that** AI doesn't reference old methodology

**Tasks:**
- Delete Angion knowledge from Firestore
- Remove fallbackKnowledge.js content
- Clean up deployment scripts
- Archive old knowledge for reference
- Verify complete removal

**Acceptance Criteria:**
- No Angion references in AI responses
- Knowledge collection cleaned
- Deployment scripts updated
- Verification tests pass

---

### Story 3.2: Create PE Safety Knowledge Base
**As a** content creator
**I want to** build safety-focused knowledge
**So that** users receive safe guidance

**Tasks:**
- Write injury prevention guidelines
- Document warning signs and red flags
- Create "when to stop" protocols
- Develop recovery recommendations
- Include medical consultation advice

**Knowledge Documents:**
```javascript
{
  id: "pe-safety-001",
  category: "safety",
  title: "Fundamental PE Safety",
  content: "Complete safety guidelines...",
  keywords: ["safety", "injury prevention", "warning signs"],
  priority: "critical"
}
```

**Acceptance Criteria:**
- 20+ safety documents created
- Medical disclaimer prominent
- Conservative approach emphasized
- Recovery integrated

---

### Story 3.3: Develop Training Protocol Knowledge
**As a** content expert
**I want to** create exercise knowledge base
**So that** AI can guide training effectively

**Tasks:**
- Document length training techniques
- Create girth training knowledge
- Develop EQ improvement content
- Write progression guidelines
- Include equipment usage

**Categories:**
- Length techniques (15+ documents)
- Girth techniques (12+ documents)
- EQ techniques (8+ documents)
- Equipment guides (10+ documents)
- Progression paths (5+ documents)

**Acceptance Criteria:**
- 50+ training documents
- Evidence-based content
- Clear instructions
- Safety integrated

---

### Story 3.4: Implement AI System Prompts
**As a** AI engineer
**I want to** update system prompts
**So that** AI behavior aligns with PE focus

**Tasks:**
- Rewrite base system prompt
- Update safety guardrails
- Implement medical disclaimers
- Configure response style
- Add community context

**System Prompt Structure:**
```javascript
const systemPrompt = `
You are a knowledgeable PE training coach focused on safety and evidence-based practices.

Core Principles:
1. Safety is paramount - always err on conservative side
2. Provide evidence-based guidance only
3. Encourage medical consultation for concerns
4. Never provide medical advice
5. Focus on injury prevention

Context: You serve the r/ScienceofPE and r/GettingBigger communities...
`;
```

**Acceptance Criteria:**
- System prompt updated
- Safety focus clear
- Disclaimers automated
- Response quality consistent

---

### Story 3.5: Create Knowledge Deployment Scripts
**As a** developer
**I want to** build deployment automation
**So that** knowledge updates are efficient

**Tasks:**
- Create deployGrowthTrainingKnowledge.js
- Build deployPESafetyGuidelines.js
- Develop deployEquipmentGuides.js
- Implement validation scripts
- Add rollback capability

**Script Requirements:**
- Batch upload capability
- Version control
- Validation checks
- Error handling
- Progress tracking

**Acceptance Criteria:**
- Scripts functional
- Deployment automated
- Validation passing
- Rollback tested

---

### Story 3.6: Implement Response Filtering
**As a** safety engineer
**I want to** filter AI responses
**So that** unsafe advice is prevented

**Tasks:**
- Create unsafe keyword filters
- Implement medical claim detection
- Add injury risk assessment
- Build conservative override
- Log filtered responses

**Filter Categories:**
- Medical claims
- Dangerous techniques
- Excessive parameters
- Unproven methods
- Legal risks

**Acceptance Criteria:**
- Filters active
- No unsafe content passes
- Logging functional
- Override system works

---

### Story 3.7: Develop Conversation Templates
**As a** UX designer
**I want to** create response templates
**So that** AI provides consistent guidance

**Tasks:**
- Create beginner guidance templates
- Develop routine building templates
- Build troubleshooting templates
- Design progress assessment templates
- Implement safety check templates

**Template Types:**
```javascript
const templates = {
  beginnerWelcome: "Welcome to PE training. Safety first...",
  routineBuilder: "Based on your experience level...",
  safetyCheck: "Before continuing, please confirm...",
  progressReview: "Your progress indicates...",
  injuryResponse: "Stop immediately and..."
};
```

**Acceptance Criteria:**
- Templates comprehensive
- Consistency maintained
- Safety integrated
- User-friendly language

---

### Story 3.8: Validate AI Response Quality
**As a** QA engineer
**I want to** test AI responses
**So that** guidance quality is assured

**Tasks:**
- Create test scenario bank
- Run response validation
- Check safety compliance
- Verify accuracy
- Document edge cases

**Test Scenarios:**
- Beginner questions (20+)
- Safety concerns (15+)
- Routine requests (20+)
- Progress questions (15+)
- Equipment queries (10+)

**Acceptance Criteria:**
- 80+ scenarios tested
- 100% safety compliance
- Accuracy validated
- Edge cases handled

---

## Knowledge Base Architecture

### Collection Structure
```
Firestore: growth_training_knowledge/
├── safety/
│   ├── injury_prevention
│   ├── warning_signs
│   └── recovery
├── techniques/
│   ├── length/
│   ├── girth/
│   └── eq/
├── equipment/
│   ├── pumps/
│   ├── hangers/
│   └── extenders/
├── progressions/
│   ├── beginner/
│   ├── intermediate/
│   └── advanced/
└── medical/
    ├── disclaimers/
    └── consultation/
```

### Knowledge Priority System
1. **Critical**: Safety, medical disclaimers
2. **High**: Basic techniques, beginner guidance
3. **Medium**: Advanced techniques, equipment
4. **Low**: Community wisdom, anecdotes

## AI Safety Framework

### Response Validation
- No medical advice
- No dangerous techniques
- No unrealistic promises
- No specific measurements
- Always include disclaimers

### Guardrails
```javascript
const safetyGuardrails = {
  maxDuration: 60, // minutes
  maxFrequency: "daily",
  requiredRest: 1, // days per week
  beginnerLimit: 15, // minutes
  warningKeywords: ["pain", "injury", "numb", "cold"],
  stopKeywords: ["severe", "bleeding", "emergency"]
};
```

## Risks & Mitigations
- **Risk**: Unsafe AI advice
  - **Mitigation**: Multiple safety layers, conservative defaults
- **Risk**: Medical liability
  - **Mitigation**: Clear disclaimers, no medical claims
- **Risk**: Knowledge gaps
  - **Mitigation**: Comprehensive knowledge base, fallback responses

## Definition of Done
- [ ] Angion knowledge completely removed
- [ ] 100+ PE knowledge documents deployed
- [ ] System prompts updated and tested
- [ ] Safety filters operational
- [ ] Response quality validated
- [ ] Deployment scripts functional
- [ ] Team trained on new system