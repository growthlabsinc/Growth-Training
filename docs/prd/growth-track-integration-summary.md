# GrowthTrack Integration - Epic Summary

## Overview

Two complementary epics designed to enable Growth Training data collaboration with Karl's GrowthTrack research platform, delivered in sequential releases.

---

## Epic 10: Pre/Post Session Measurement Tracking Enhancement
**Priority:** High | **Target:** v1.2.0 | **Dependencies:** None

### Goal
Enable comprehensive pre-session and post-session measurement tracking with automatic yield/fatigue calculation to align Growth Training data structure with GrowthTrack research standards.

### User Value
- **Immediate feedback** on temporary gains ("pump") after each session
- **Yield tracking** to understand which routines are most effective
- **Data quality** through input validation (prevent typos/outliers)
- **Research alignment** for future data contribution

### Technical Summary
**What Changes:**
- `SessionLog` model: Add optional `preMeasurements`, `postMeasurements`, `yieldPercentages` fields
- Session UI: Pre-session measurement prompt (optional/skippable)
- Session UI: Enhanced post-session flow with yield display
- Validation: Hard limits (reject) and soft limits (warn) like GrowthTrack
- Analytics: New "Session Yield" charts and statistics

**What Stays the Same:**
- Existing SessionLog functionality (100% backward compatible)
- GainsEntry flow (independent standalone measurements)
- All existing features work exactly as before

### Stories (5)
1. Extend SessionLog Model for Pre/Post Measurements
2. Pre-Session Measurement Capture UI
3. Post-Session Measurement Capture & Yield Calculation
4. Input Validation System (Soft/Hard Limits)
5. Yield Tracking Analytics

### Key Metrics
- BPEL (Bone Pressed Erect Length)
- BPFSL (Bone Pressed Flaccid Stretched Length)
- MSEG (Mid-Shaft Erect Girth)

### Validation Limits (Based on GrowthTrack Standards)
**Hard Limits (Reject):**
- BPEL/BPFSL: 3.0" - 11.0"
- MSEG: 3.0" - 8.0"

**Soft Limits (Warn):**
- BPEL/BPFSL: 4.0" - 10.0"
- MSEG: 3.5" - 6.5"

---

## Epic 11: Anonymous CSV Export to GrowthTrack
**Priority:** Medium | **Target:** v1.3.0 | **Dependencies:** Epic 10

### Goal
Enable users to export anonymized session and measurement data as CSV files compatible with GrowthTrack's bulk import format, facilitating PE research data collaboration while maintaining strict privacy.

### User Value
- **Contribute to science** without privacy risk
- **Support PE research** with anonymized data
- **Access GrowthTrack analytics** (future potential)
- **Backup data** in standardized format

### Privacy Guarantees
- **No PII exported:** No userId, email, name, identifiable notes
- **Anonymous ID:** Random statistical ID (GT-ABC123 format)
- **Opt-in only:** Default OFF, explicit consent required
- **Regenerate ID:** Break longitudinal linkage anytime
- **GDPR compliant:** Right to anonymity, withdraw, be forgotten

### Technical Summary
**What Changes:**
- New `AnonymizationService`: Generate/manage statistical IDs, strip PII
- New `CSVExportService`: Format data for GrowthTrack import
- Settings UI: "Data Collaboration" section with opt-in toggle
- Export buttons: SessionLog CSV, Measurements CSV
- Privacy education: Clear explanation of what's shared/not shared

**What Stays the Same:**
- All user data in app (read-only export, no modifications)
- Existing JSON export feature (unchanged)
- Privacy policy (updated with collaboration mention)

### Stories (5)
1. Anonymous Statistical ID Generation & Management
2. Session Log CSV Export
3. Measurement CSV Export
4. Opt-In Consent & Privacy Settings UI
5. CSV Format Validation & GrowthTrack Testing

### CSV Format (Coordinate with Karl)
**Session Log Export:**
```csv
anonymous_id,date,category,duration_minutes,pre_bpel_mm,pre_bpfsl_mm,pre_mseg_mm,post_bpel_mm,post_bpfsl_mm,post_mseg_mm
GT-ABC123,2025-01-15,lengthwork,30,152,165,115,158,170,118
```

**Measurement Export:**
```csv
anonymous_id,date,bpel_mm,nbpel_mm,bpfsl_mm,mseg_mm,beg_mm,heg_mm,erection_quality
GT-ABC123,2025-01-15,155,143,168,117,122,107,9
```

**Conversions:**
- Units: Inches → Millimeters (×25.4, rounded)
- Date: Full timestamp → Date only (YYYY-MM-DD)
- PII: All identifiers stripped

### Collaboration Requirements
- **Schema validation** with Karl (u/karlwikman)
- **Test import** into GrowthTrack platform
- **Format iteration** based on import feedback
- **Documentation** for users on uploading to GrowthTrack

---

## Implementation Timeline

### Phase 1: Epic 10 (v1.2.0)
**Duration:** 3-4 weeks
**Focus:** Data structure alignment

1. Week 1: SessionLog model extension + validation system
2. Week 2: Pre/post measurement capture UI
3. Week 3: Yield calculation + analytics
4. Week 4: Testing + refinement

**Deliverable:** Growth Training tracks session measurements like GrowthTrack

### Phase 2: Epic 11 (v1.3.0)
**Duration:** 3-4 weeks
**Focus:** Privacy-preserving export

1. Week 1: AnonymizationService + CSV export logic
2. Week 2: Settings UI + consent flow
3. Week 3: Karl collaboration (schema validation, import testing)
4. Week 4: Privacy review + user acceptance testing

**Deliverable:** Users can contribute data to GrowthTrack research

---

## Risk Mitigation

### Epic 10 Risks
| Risk | Mitigation |
|------|-----------|
| Schema migration complexity | All fields optional, no migration needed |
| User confusion (temp vs permanent gains) | In-app education, help text, community resources |
| Data quality (typos, outliers) | Hard/soft validation limits |

### Epic 11 Risks
| Risk | Mitigation |
|------|-----------|
| **Privacy breach (PII in export)** | Whitelist approach, code review, user testing |
| **CSV format mismatch** | Direct collaboration with Karl, validation testing |
| **User confusion (anonymization)** | Prominent privacy education, confirmation dialogs |

---

## Success Metrics

### Epic 10 Success
- [ ] 80%+ of users with measurements provide pre-session measurements
- [ ] Yield calculation accurate (matches manual calculations)
- [ ] Zero data quality incidents (outliers prevented by validation)
- [ ] Positive user feedback on yield insights

### Epic 11 Success
- [ ] CSV import success rate: 100% (tested with Karl)
- [ ] Zero PII incidents (verified via code review + testing)
- [ ] 10%+ of active users opt-in to export (early adoption)
- [ ] Karl confirms data quality meets research standards

---

## Alignment with GrowthTrack

Based on Karl's Reddit posts and Discord conversation:

### GrowthTrack Capabilities ✅
- Pre/post session measurements (BPEL, BPFSL, MSEG) → **Epic 10**
- Yield/fatigue calculation → **Epic 10**
- Input validation (hard/soft limits) → **Epic 10**
- CSV bulk import → **Epic 11**
- Anonymized research dataset → **Epic 11**
- Statistical analysis (future, with more data) → **Epic 11 enables**

### Growth Training Capabilities (Post-Epics)
- Pre/post session measurements (BPEL, BPFSL, MSEG) ✅
- Yield/fatigue calculation ✅
- Input validation (hard/soft limits) ✅
- CSV export compatible with GrowthTrack ✅
- Anonymous data contribution ✅

**Result:** Full data interoperability for PE research collaboration

---

## Community Value

### For r/TheScienceOfPE
- Contributes to evidence-based PE research
- Strengthens Growth Training credibility
- Demonstrates science-first approach
- Supports Karl's research mission

### For Karl's GrowthTrack
- Increases research dataset size (566 → 566 + Growth Training users)
- Mobile app users contribute data (GrowthTrack is web-based)
- Data validation across platforms
- Stronger statistical power for analysis

### For Growth Training Users
- Immediate session feedback (yield tracking)
- Contribute to science (optional, privacy-protected)
- Access to research insights (future bidirectional sync)
- Better understanding of PE effectiveness

---

## Next Steps

1. **Review Epics:** Confirm scope and priorities
2. **Coordinate with Karl:** Share Epic 11 details, confirm CSV schema
3. **Story Creation:** Story Manager develops detailed user stories
4. **Implementation:** Dev team executes Epic 10 → Epic 11 sequentially
5. **Testing:** Privacy review, GrowthTrack import testing
6. **Release:** v1.2.0 (Epic 10), v1.3.0 (Epic 11)
7. **Community Announcement:** Reddit post on data collaboration

---

## Questions for Review

1. **Scope Confirmation:** Are both epics appropriately sized? Should anything be added/removed?
2. **Priority Alignment:** Epic 10 = High, Epic 11 = Medium - correct?
3. **Timeline Realistic:** 3-4 weeks per epic feasible for team?
4. **Karl Coordination:** When should we reach out about CSV schema?
5. **Privacy Concerns:** Any additional privacy considerations for Epic 11?

---

**Status:** Awaiting Product Owner review and approval to proceed with story creation.
