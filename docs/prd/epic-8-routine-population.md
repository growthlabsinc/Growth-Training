# Epic 8: Routine Population & Exercise Library - Brownfield Enhancement

## Epic Goal

Populate the Growth Training app with comprehensive PE routines and exercises sourced from Reddit communities (r/GettingBigger, r/AJelqForYou, r/TheScienceOfPE), removing unsuitable Level 0 guides and creating structured beginner/intermediate/advanced routine templates that align with community best practices.

## Epic Description

**Existing System Context:**

- Current relevant functionality: TrainingProtocol model (renamed from GrowthMethod), RoutineService, MethodsGuideView
- Technology stack: Swift/SwiftUI, Firebase Firestore for data storage
- Integration points: FirestoreService, TrainingProtocolService, routine UI components

**Enhancement Details:**

- What's being added/changed:
  1. Remove Level 0 guides (more suitable for Learning Center)
  2. Add comprehensive PE exercise library based on Reddit community data
  3. Create 6 structured routines (2 beginner, 2 intermediate, 2 advanced)
  4. Ensure proper categorization and safety information

- How it integrates: Uses existing TrainingProtocol model structure and Firestore collections
- Success criteria:
  - All common PE exercises from Reddit communities available in app
  - 6 complete routines with proper progression
  - Safety notes and equipment requirements clearly documented
  - Exercises properly categorized (length/girth/conditioning)

## Stories

1. **Story 8.1: Remove Level 0 Guides & Restructure Content**
   - Move Level 0 guides to Learning Center content area
   - Update RoutineService to exclude these from main routine views
   - Verify no breaking changes in existing UI

2. **Story 8.2: Populate PE Exercise Library**
   - Create comprehensive exercise entries using TrainingProtocol model
   - Include exercises: Manual Stretches, Jelqing variants, Pumping, Clamping, Hanging, Extending
   - Add proper safety notes, equipment lists, and categorization

3. **Story 8.3: Create Structured Routine Templates**
   - Implement 2 beginner routines (Length-focused, Balanced)
   - Implement 2 intermediate routines (Shock Loading, Pumping)
   - Implement 2 advanced routines (RIP Protocol, PAC Protocol)
   - Ensure proper progression criteria and recovery schedules

## Compatibility Requirements

- [x] Existing APIs remain unchanged
- [x] Database schema changes are backward compatible (using existing TrainingProtocol model)
- [x] UI changes follow existing patterns in MethodsGuideView
- [x] Performance impact is minimal (data loading optimized)

## Risk Mitigation

- **Primary Risk:** Content safety - PE exercises carry physical risks if done incorrectly
- **Mitigation:** Include comprehensive safety warnings, contraindications, and stop signals in all exercise descriptions. Add disclaimer screens.
- **Rollback Plan:** Firestore data can be reverted to previous state; UI components remain unchanged structurally

## Definition of Done

- [x] All stories completed with acceptance criteria met
- [x] Existing functionality verified through testing
- [x] Integration points working correctly
- [x] Documentation updated appropriately
- [x] No regression in existing features
- [x] Safety disclaimers and warnings properly implemented
- [x] 6 complete routines available in app
- [x] All common PE exercises from Reddit data included

## Exercise Categories to Implement

Based on comprehensive Reddit analysis:

### Manual Methods (No Equipment)
- Basic Manual Stretch
- Modified Jelq
- Timed Pressure Hold (TPH)
- Timed Squash
- Milking (for EQ)

### Device-Based Methods
- Static Pumping
- Rapid Interval Pumping (RIP)
- Vanilla Interval Pumping
- Soft Clamping (Advanced)
- Shopping Bag Hanger
- Vacuum Extending
- All-Day Stretcher (ADS)

### Advanced Techniques
- Shock Loading (pre-length work)
- Pump-Assisted Clamping (PAC)
- Bundles with Pumping

### Conditioning & EQ
- Angion Method
- Milking
- Heat Application (adjuvant)

## Routine Templates to Create

### Beginner Routines (2)
1. **Length-Focused Beginner**
   - Daily manual stretches or device wear
   - 30-60 minutes
   - Safety-first approach

2. **Balanced Beginner**
   - Alternating length/girth days
   - Modified jelq + manual stretches
   - Recovery-focused schedule

### Intermediate Routines (2)
1. **Intermediate Shock Loading**
   - 5 min girth work before length
   - Accelerated length gains
   - Daily schedule

2. **Intermediate Pumping**
   - Static or interval pumping
   - Girth-focused
   - 1 on/1 off schedule

### Advanced Routines (2)
1. **Advanced RIP Protocol**
   - Rapid interval pumping
   - Maximum girth expansion
   - Experienced users only

2. **Advanced PAC Protocol**
   - Pump-assisted clamping
   - Combination technique
   - Strict safety protocols

## Data Migration Notes

- Use existing TrainingProtocol structure
- Categories field: ["length", "girth", "conditioning", "eq"]
- Classification field: "Beginner", "Intermediate", "Advanced"
- SafetyNotes field: CRITICAL for all exercises
- TimerConfig: Set appropriate durations for timed exercises
- ProgressionCriteria: Define clear advancement requirements

## Handoff to Story Manager

**Story Manager Handoff:**

"Please develop detailed user stories for this brownfield epic. Key considerations:

- This is an enhancement to an existing system running Swift/SwiftUI with Firebase Firestore
- Integration points: TrainingProtocolService, RoutineService, FirestoreService
- Existing patterns to follow: TrainingProtocol model structure, MethodsGuideView UI patterns
- Critical compatibility requirements: Must use existing data models, no schema changes
- Each story must include verification that existing functionality remains intact

The epic should maintain system integrity while delivering comprehensive PE routine and exercise content sourced from Reddit community best practices. Safety disclaimers and proper categorization are critical requirements."

---

## Important Safety Considerations

All content must include:
1. Medical disclaimer screens
2. Clear warning signs to stop immediately
3. Equipment safety guidelines
4. Recovery and rest day requirements
5. Links to educational content about risks
6. Emergency response information

## Success Metrics

- User can access 15+ distinct PE exercises
- 6 complete routines available with clear progression paths
- Safety information prominently displayed
- Exercises properly categorized for user navigation
- No regression in existing app functionality