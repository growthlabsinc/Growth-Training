# Angion Content Removal Archive

**Date**: 2025-01-21
**Story**: 3.1 - Remove Angion Knowledge Base
**Purpose**: Archive of all Angion-related content removed from the AI Coach system

## Archive Contents

### Backed Up Files

1. **fallbackKnowledge.js.backup**
   - Original fallback knowledge with Angion Method content
   - Contained AM1, AM2, AM3/Vascion, SABRE techniques
   - Replaced with generic PE safety content

2. **deploy-angion-methods.js**
   - Deployment script for Angion methods
   - Removed from functions directory

3. **deployAngionMethods.js**
   - Alternative deployment script for Angion content
   - Removed from functions directory

4. **deploy-methods.js**
   - General deployment script that included Angion methods
   - Removed from functions directory

## Removal Summary

### Firestore Collection
- Collection: `ai_coach_knowledge`
- Status: Already empty (0 documents found)
- No deletion required

### Fallback Knowledge Updates
- Removed all Angion-specific content including:
  - AM1 (Angion Method 1.0)
  - AM2 (Angion Method 2.0)
  - AM3/Vascion
  - SABRE techniques
  - Angion terminology and abbreviations
- Replaced with:
  - Generic PE safety guidelines
  - Evidence-based training methodology
  - Equipment safety information
  - Medical disclaimers

### Deployment Scripts
- Removed 3 deployment scripts that contained Angion content
- No package.json references found

### System Prompt Updates
- Updated `functions/vertexAiProxy/index.js`
- Removed references to "Angion Methods" and "vascular training"
- Replaced with "safe and evidence-based PE training"
- Added emphasis on safety and medical disclaimers

## Verification

To verify complete removal:
1. AI Coach should not respond with Angion-specific content
2. Fallback knowledge should provide generic PE safety information
3. No deployment scripts for Angion content remain
4. System prompts focus on PE safety, not Angion methods

## Restoration

If needed, these archived files can be restored:
1. Copy `.backup` files back to original names
2. Re-add deployment scripts to functions directory
3. Revert system prompt changes in vertexAiProxy/index.js

**Note**: This archive is for historical reference only. The app has transitioned to generic PE safety content.