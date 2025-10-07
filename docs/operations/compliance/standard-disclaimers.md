# Standard Medical and Legal Disclaimers

## Overview

This document defines the standard disclaimers that must be included with all educational content in the Growth Training app. These disclaimers are designed to:
- Protect against medical liability
- Comply with FDA/FTC regulations
- Set appropriate user expectations
- Minimize legal exposure

## Individual Disclaimers

### 1. Medical Consultation Advisory

**Disclaimer Text**:
> This information is for educational purposes only and does not constitute medical advice. Consult with a healthcare provider before beginning any exercise program.

**Purpose**: Establishes that content is educational, not medical advice. Directs users to seek professional medical consultation.

**Legal Basis**: Standard medical disclaimer language recommended for health and fitness applications.

---

### 2. No Guarantee of Results

**Disclaimer Text**:
> Individual results may vary. This app does not guarantee specific outcomes or results from following the information provided.

**Purpose**: Manages user expectations and protects against claims of false advertising or guaranteed outcomes.

**Legal Basis**: FTC compliance for health and fitness claims. Prevents misleading advertising allegations.

---

### 3. Individual Variation Acknowledgment

**Disclaimer Text**:
> Every individual's physiology is different. What works for one person may not work for another.

**Purpose**: Acknowledges biological variability and reduces liability for individual outcomes.

**Legal Basis**: Reinforces "no guarantee" disclaimer with scientific acknowledgment of individual differences.

---

### 4. Risk Disclosure

**Disclaimer Text**:
> There are inherent risks associated with physical exercise programs. Stop immediately if you experience pain, discomfort, or unusual symptoms, and seek medical attention.

**Purpose**: Warns users of potential exercise risks and provides clear stop-exercise guidance.

**Legal Basis**: Product liability protection through adequate warning of foreseeable risks.

---

### 5. Age Restrictions (18+)

**Disclaimer Text**:
> This app and its content are intended for adults 18 years of age and older only.

**Purpose**: Restricts use to adults and protects against minors using the app without parental supervision.

**Legal Basis**: Age-appropriate content designation. Limits liability for use by minors.

---

## Combined Full Standard Disclaimer

### Full Disclaimer (All 5 Combined)

This is the complete standard disclaimer combining all 5 individual disclaimers. This text should be used on all educational articles.

```
⚠️ **MEDICAL DISCLAIMER**

This information is for educational purposes only and does not constitute medical advice. Consult with a healthcare provider before beginning any exercise program.

Individual results may vary. This app does not guarantee specific outcomes or results from following the information provided.

Every individual's physiology is different. What works for one person may not work for another.

There are inherent risks associated with physical exercise programs. Stop immediately if you experience pain, discomfort, or unusual symptoms, and seek medical attention.

This app and its content are intended for adults 18 years of age and older only.
```

---

## Usage Guidelines

### Where to Display Disclaimers

1. **Article Markdown Files**:
   - Include full disclaimer at beginning or end of article
   - Use prominent formatting (heading, emoji, bold)
   - Example: See "Full Disclaimer" section above

2. **Firestore Documents**:
   - Store full disclaimer text in `medical_disclaimer` field
   - Field type: String
   - Field name: `medical_disclaimer` (snake_case)

3. **App UI (EducationalResourceDetailView)**:
   - Display disclaimer prominently (top or bottom of article)
   - Use warning icon: `exclamationmark.triangle.fill` (SF Symbol)
   - Use distinct visual styling: warning color, bordered box
   - Ensure always visible (not hidden in scroll)

### Formatting Standards

**Markdown Format** (for article files):
```markdown
## Medical Disclaimer

⚠️ **IMPORTANT HEALTH INFORMATION**

This information is for educational purposes only and does not constitute medical advice. Consult with a healthcare provider before beginning any exercise program.

Individual results may vary. This app does not guarantee specific outcomes or results from following the information provided.

Every individual's physiology is different. What works for one person may not work for another.

There are inherent risks associated with physical exercise programs. Stop immediately if you experience pain, discomfort, or unusual symptoms, and seek medical attention.

This app and its content are intended for adults 18 years of age and older only.
```

**Plain Text Format** (for Firestore):
```
This information is for educational purposes only and does not constitute medical advice. Consult with a healthcare provider before beginning any exercise program. Individual results may vary. This app does not guarantee specific outcomes or results from following the information provided. Every individual's physiology is different. What works for one person may not work for another. There are inherent risks associated with physical exercise programs. Stop immediately if you experience pain, discomfort, or unusual symptoms, and seek medical attention. This app and its content are intended for adults 18 years of age and older only.
```

### Disclaimer Placement

**Recommended Placement**:
- **Option 1 (Preferred)**: At the **end** of the article, before references/citations
- **Option 2**: At the **beginning** of the article, after title and introduction

**Rationale**: End placement ensures users read content first, then see disclaimers. Beginning placement ensures disclaimers are seen immediately.

**Current Standard**: Use end placement (Option 1) for consistency across all articles.

## Version Control

### Disclaimer Version History

| Version | Date       | Changes | Author |
|---------|------------|---------|--------|
| 1.0     | 2025-10-06 | Initial standard disclaimers | James (Developer) |

### Updating Disclaimers

If disclaimer text needs to be updated:
1. Update this document with new text
2. Increment version number
3. Document changes in version history
4. Update all article files with new disclaimer
5. Update Firestore documents via script
6. Legal counsel must approve all disclaimer changes

## Legal Review

**Status**: Pending initial legal counsel review

**Reviewer**: To be assigned

**Review Date**: Pending

**Approval**: Pending

## Contact Information

For questions about disclaimer usage or legal compliance:
- Legal Counsel: [To be assigned]
- Compliance Officer: [To be assigned]
- Product Owner: [To be assigned]

## Change Log

| Date       | Version | Change Description | Author |
|------------|---------|-------------------|---------|
| 2025-10-06 | 1.0     | Initial standard disclaimers documentation | James (Developer) |
