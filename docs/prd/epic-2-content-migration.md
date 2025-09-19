# Epic 2: Content & Knowledge Migration

## Epic Overview
Replace all Angion Method content with PE-focused training protocols and educational resources

**Priority**: P0 - Critical
**Estimated Effort**: 5 days
**Dependencies**: Epic 1 (Infrastructure)
**Owner**: Content Team & Product Owner

## Epic Goals
- Remove all Angion Method exercise definitions
- Create comprehensive PE training protocol library
- Develop safety-first educational content
- Establish evidence-based training progressions

## Acceptance Criteria
- [ ] All Angion Method exercises removed
- [ ] New PE training protocols implemented
- [ ] Safety guidelines integrated
- [ ] Educational resources updated
- [ ] Content reviewed by domain experts
- [ ] Legal disclaimers in place

## User Stories

### Story 2.1: Remove Angion Method Exercises
**As a** developer
**I want to** remove all Angion-specific exercises
**So that** the app is clear of old methodology

**Tasks:**
- Remove AM1.0, AM2.0, AM2.5, AM3.0 definitions
- Remove SABRE method variations
- Remove Angion-specific terminology
- Clean up related assets and references
- Archive old content for reference

**Acceptance Criteria:**
- No Angion Method references in codebase
- SampleGrowthMethods.swift updated
- Database cleaned of old methods

---

### Story 2.2: Create Length Training Protocols
**As a** PE practitioner
**I want to** access length-focused exercises
**So that** I can train for length gains safely

**Tasks:**
- Define manual stretching protocols
  - Basic stretches (BTC, straight out, V-stretch)
  - Advanced stretches (A-stretch, bundled stretches)
- Create hanging protocols
  - Beginner hanging progression
  - Advanced hanging with weight progression
- Implement extender protocols
  - Time-based progressions
  - Tension adjustment guidelines

**Acceptance Criteria:**
- 10+ length exercises defined
- Clear progression paths
- Safety warnings included
- Time and intensity guidelines

---

### Story 2.3: Create Girth Training Protocols
**As a** PE practitioner
**I want to** access girth-focused exercises
**So that** I can train for girth gains safely

**Tasks:**
- Define pumping protocols
  - Vacuum pumping progressions
  - Pressure and time guidelines
  - Cylinder sizing information
- Create clamping protocols
  - Safety-first approach
  - Time limits and warnings
  - Progressive intensity
- Implement jelqing variations
  - Wet vs dry techniques
  - Intensity levels
  - Proper form guidelines

**Acceptance Criteria:**
- 8+ girth exercises defined
- Equipment requirements clear
- Safety prominently featured
- Recovery protocols included

---

### Story 2.4: Develop EQ Training Protocols
**As a** user
**I want to** improve erection quality
**So that** I have better overall performance

**Tasks:**
- Create kegel exercise programs
  - Basic PC muscle training
  - Advanced hold patterns
  - Reverse kegels
- Define edging protocols
  - Stamina building
  - EQ improvement focus
  - Time-based progressions
- Implement angion-alternative vascular work
  - Safe blood flow exercises
  - No trademark conflicts

**Acceptance Criteria:**
- 6+ EQ exercises defined
- Clear instructions provided
- Benefits explained
- Progression tracking enabled

---

### Story 2.5: Create Recovery & Safety Content
**As a** user
**I want to** understand recovery and safety
**So that** I can train without injury

**Tasks:**
- Develop warm-up protocols
  - Heat application methods
  - Light stretching routines
  - Preparation guidelines
- Create cool-down procedures
  - Recovery techniques
  - Healing optimization
  - Rest day guidelines
- Write injury prevention content
  - Warning signs
  - When to stop
  - Recovery protocols

**Acceptance Criteria:**
- Comprehensive safety section
- Injury prevention prominent
- Recovery integrated into routines
- Medical disclaimer present

---

### Story 2.6: Establish Training Progressions
**As a** user
**I want to** follow structured progressions
**So that** I can advance safely

**Tasks:**
- Create newbie routine (first 3 months)
  - Conservative starting point
  - Gradual progression
  - Focus on conditioning
- Develop intermediate routines
  - Increased intensity
  - Specialization options
  - Plateau breaking
- Design advanced routines
  - High intensity protocols
  - Combination approaches
  - Maintenance programs

**Acceptance Criteria:**
- 3 difficulty levels defined
- Clear progression criteria
- Time commitments specified
- Expected timeline realistic

---

### Story 2.7: Create Equipment Guides
**As a** user
**I want to** understand equipment options
**So that** I can make informed purchases

**Tasks:**
- Write vacuum pump guide
  - Types and features
  - Sizing information
  - Quality indicators
- Create hanger comparison
  - Different hanger types
  - Safety considerations
  - Weight progression
- Develop extender guide
  - Spring vs vacuum
  - Comfort modifications
  - Usage protocols

**Acceptance Criteria:**
- Equipment clearly explained
- No product endorsements
- Safety emphasized
- Budget options included

---

### Story 2.8: Migrate Educational Resources
**As a** user
**I want to** access educational content
**So that** I understand the science

**Tasks:**
- Create anatomy education
  - Relevant structures
  - Growth mechanisms
  - Scientific basis
- Develop theory content
  - How growth occurs
  - Time expectations
  - Realistic goals
- Write FAQ section
  - Common questions
  - Myth debunking
  - Community wisdom

**Acceptance Criteria:**
- Science-based content
- Accessible language
- References included
- Myths addressed

---

## Content Structure

### Exercise Schema
```swift
struct TrainingProtocol {
    let id: String
    let category: TrainingCategory // length, girth, eq, recovery
    let difficulty: Difficulty // beginner, intermediate, advanced
    let title: String
    let description: String
    let detailedInstructions: String
    let safetyWarnings: [String]
    let equipmentNeeded: [String]
    let estimatedDuration: Int // minutes
    let frequency: String // daily, EOD, etc.
    let progressionGuidelines: String
    let contraindicators: [String]
}
```

### Content Categories
1. **Length Training**
   - Manual Stretching
   - Hanging
   - Extending
   - Advanced Techniques

2. **Girth Training**
   - Pumping
   - Clamping
   - Manual Exercises
   - Combination Methods

3. **EQ Training**
   - Kegel Variations
   - Edging
   - Vascular Health
   - Stamina Building

4. **Recovery**
   - Warm-up Protocols
   - Cool-down Routines
   - Rest Days
   - Injury Recovery

## Safety Framework

### Mandatory Disclaimers
- Medical consultation recommendation
- Age verification (18+)
- Risk acknowledgment
- Not medical advice

### Safety Integration
- Pre-exercise checklist
- Warning indicators
- Stop signs
- Recovery requirements

## Risks & Mitigations
- **Risk**: Unsafe content
  - **Mitigation**: Expert review, conservative guidelines
- **Risk**: Legal liability
  - **Mitigation**: Comprehensive disclaimers, no medical claims
- **Risk**: User injury
  - **Mitigation**: Safety-first approach, clear warnings

## Definition of Done
- [ ] All Angion content removed
- [ ] 30+ PE exercises defined
- [ ] Safety guidelines comprehensive
- [ ] Educational content complete
- [ ] Legal review completed
- [ ] Content deployed to Firestore