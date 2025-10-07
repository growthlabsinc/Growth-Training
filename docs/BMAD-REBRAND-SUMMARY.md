# BMAD Documentation Update Summary - Growth Training Rebrand
<!-- Powered by BMAD™ Core -->

## Overview
Updated BMAD documentation to reflect the Growth Training rebrand from Angion Method, targeting r/ScienceofPE and r/GettingBigger communities.

## Key Changes Made

### 1. Core Configuration Updates
**File**: `.bmad-core/core-config.yaml`
- Updated project type to `brownfield-rebrand`
- Added rebrand context in header comments
- Updated PRD reference to `growth-training-rebrand-prd.md`
- Added epic references for all 6 rebrand epics
- Updated project context with:
  - Previous name (Angion Method) and new name (Growth Training)
  - Target communities (r/ScienceofPE, r/GettingBigger)
  - Bundle ID changes
  - Rebrand scope details

### 2. Documentation Index Updates
**File**: `docs/BMAD-INDEX.md`
- Updated title to reflect rebrand status
- Added rebrand context to project overview
- Updated PRD links to point to rebrand documentation
- Listed all 6 epics with descriptions
- Updated project status to show rebrand progress
- Added remaining rebrand tasks

### 3. PRD Structure
**Main PRD**: `docs/prd/growth-training-rebrand-prd.md`
- Complete rebranding requirements
- Business objectives focused on PE communities
- User personas for ScienceofPE and GettingBigger
- Risk assessment and mitigation strategies

**Epic Documentation**:
1. `epic-1-infrastructure.md` - Firebase & Google Cloud setup
2. `epic-2-content-migration.md` - PE content replacement
3. `epic-3-ai-coach.md` - Safe PE guidance transformation
4. `epic-4-ui-branding.md` - Visual and UX updates
5. `epic-5-code-refactoring.md` - Terminology updates
6. `epic-6-testing-validation.md` - QA and launch preparation

## Key Rebrand Requirements

### Technical Changes
- **Bundle ID**: `com.growthlabs.growthmethod` → `com.growthlabs.growthtraining`
- **Firebase Project**: `growth-training-app` → `growth-training`
- **App Name**: Angion Method → Growth Training

### Content Changes
- Complete replacement of Angion Method exercises with PE protocols
- AI knowledge base focused on safe PE practices
- Updated onboarding and educational content
- Safety-first approach with medical disclaimers

### Minimal UI Changes
- Subtle color adjustments only
- Maintain all existing functionality
- Preserve Live Activities and timer systems
- Keep architecture intact

## Current Status

### Completed
- Epic 3, Story 3.5: Knowledge deployment scripts ✅
- Epic 4, Story 4.1: Color palette updates ✅
- Core app functionality (100% working)

### In Progress
- Epic 3, Story 3.6: Response filtering
- Epic 3, Story 3.7: Conversation templates
- Firebase Functions deployment

### Remaining
- Complete Firebase project migration
- Update all bundle identifiers
- Deploy PE-focused knowledge base
- Replace remaining Angion references
- Final testing and App Store submission

## BMAD Agent Usage

The updated configuration enables BMAD agents to:
1. Understand the rebrand context when generating stories
2. Reference correct PRD and epic documents
3. Maintain awareness of the transition from Angion to Growth Training
4. Focus on safety-first PE guidance in AI Coach updates
5. Preserve existing functionality while updating content

## Important Notes

1. **This is a brownfield rebrand** - The app is 100% functional, only content/branding changes needed
2. **Target communities** have different focus (ED → PE)
3. **Safety is paramount** - All PE guidance must emphasize safety
4. **Minimal UI changes** - Preserve existing user experience
5. **Firebase migration** required for new project setup

---

**Updated**: 2025-10-03
**Updated By**: BMAD Orchestrator
**Owner**: jon@growthlabs.coach