# Epic 10: Pre/Post Session Measurement Tracking Enhancement

## Epic Status
**Status:** Draft
**Priority:** High
**Target Release:** v1.2.0
**Dependencies:** None
**Related Epics:** Epic 11 (Anonymous Data Export to GrowthTrack)

## Epic Goal

Enable comprehensive pre-session and post-session measurement tracking with automatic yield/fatigue calculation to align Growth Training data structure with GrowthTrack research standards, enabling future data collaboration and providing users with immediate session-specific feedback on temporary gains.

## Epic Description

### Existing System Context

**Current Measurement System:**
- `GainsEntry` model tracks standalone measurements with comprehensive `MeasurementType` taxonomy (BPEL, NBPEL, BPFSL, MSEG, BEG, HEG, etc.)
- `SessionLog` model tracks practice sessions with duration, mood, intensity, but NO measurements
- Loose coupling: `GainsEntry.sessionId` exists but SessionLog doesn't store measurement data
- Users track long-term progress via separate GainsEntry submissions

**Technology Stack:**
- Swift/SwiftUI native iOS app
- Firebase Firestore for data persistence
- Existing models: `SessionLog`, `GainsEntry`, `MeasurementType` enum
- Validation: Currently only basic range validation in UI forms

**Integration Points:**
- Session completion flow (post-timer completion)
- Manual session logging (LogSessionView)
- GainsEntry creation (already has sessionId field)
- Progress charts and analytics

### Enhancement Details

**What's Being Added:**

1. **Pre-Session Measurement Capture**
   - Optional pre-session measurement prompt when starting timer/session
   - Store BPEL, BPFSL, MSEG (primary metrics per GrowthTrack standards)
   - Link pre-measurements to SessionLog via new fields

2. **Post-Session Measurement Capture**
   - Enhanced post-session flow to capture same metrics (BPEL, BPFSL, MSEG)
   - Link post-measurements to SessionLog
   - Auto-create GainsEntry if user provides measurements

3. **Yield/Fatigue Calculation**
   - Calculate percentage difference: `((post - pre) / pre) * 100`
   - Store calculated yield in SessionLog
   - Display yield immediately after session completion
   - Track yield trends over time in analytics

4. **Input Validation System**
   - **Hard Limits** (reject immediately):
     - BPEL: 3.0" - 11.0" (75mm - 280mm)
     - BPFSL: 3.0" - 11.0" (75mm - 280mm)
     - MSEG: 3.0" - 8.0" (75mm - 200mm)
   - **Soft Limits** (confirmation dialog):
     - BPEL: 4.0" - 10.0" (100mm - 250mm)
     - BPFSL: 4.0" - 10.0" (100mm - 250mm)
     - MSEG: 3.5" - 6.5" (90mm - 165mm)
   - Display warning for outlier values without blocking (data integrity protection)

**How It Integrates:**

- **SessionLog model extension:** Add optional `preMeasurements` and `postMeasurements` dictionaries, plus `yieldPercentage` fields
- **Session completion flow:** Enhanced SessionCompletionView with measurement prompts
- **Manual logging:** Enhanced LogSessionView with pre/post measurement fields
- **GainsEntry linking:** Auto-create GainsEntry when post-session measurements provided
- **Analytics enhancement:** New yield tracking charts and statistics
- **Firestore schema:** Backward-compatible additions (optional fields)

**Success Criteria:**

1. Users can optionally record pre-session measurements (BPEL, BPFSL, MSEG) before starting timer
2. Users can optionally record post-session measurements immediately after session completion
3. App automatically calculates and displays yield percentage for each metric
4. Input validation prevents data quality issues (outliers, typos)
5. SessionLog and GainsEntry remain properly linked via sessionId
6. Existing sessions without measurements remain functional (backward compatibility)
7. Data structure aligns with GrowthTrack standards for future CSV export (Epic 11)

## Stories

### Story 10.1: Extend SessionLog Model for Pre/Post Measurements
**Goal:** Add measurement storage fields to SessionLog model
**Scope:**
- Add optional `preMeasurements: [MeasurementType: Double]?` field
- Add optional `postMeasurements: [MeasurementType: Double]?` field
- Add optional `yieldPercentages: [MeasurementType: Double]?` field (calculated)
- Update Firestore serialization/deserialization (CodingKeys)
- Ensure backward compatibility (optional fields)
- Update FirestoreService to save/load new fields

### Story 10.2: Pre-Session Measurement Capture UI
**Goal:** Prompt users to record pre-session measurements before starting timer
**Scope:**
- Add opt-in prompt when user starts session (can skip)
- Measurement input for BPEL, BPFSL, MSEG only (primary metrics)
- Apply hard/soft limit validation
- Store in memory until session completes
- Persist to SessionLog when session finishes
- Handle both timer-based and manual session logging

### Story 10.3: Post-Session Measurement Capture & Yield Calculation
**Goal:** Enhanced post-session flow with measurement capture and yield display
**Scope:**
- Enhance SessionCompletionView with measurement inputs
- Measurement input for BPEL, BPFSL, MSEG (match pre-session metrics)
- Apply hard/soft limit validation
- Calculate yield percentage for each metric: `((post - pre) / pre) * 100`
- Display yield immediately in completion UI ("BPEL +5.2% temporary gain")
- Persist measurements and calculated yield to SessionLog
- Auto-create GainsEntry linked to session if measurements provided

### Story 10.4: Input Validation System (Soft/Hard Limits)
**Goal:** Implement GrowthTrack-compatible validation to prevent data quality issues
**Scope:**
- Create `MeasurementValidator` utility class
- Hard limits: 3.0-11.0" BPEL/BPFSL, 3.0-8.0" MSEG (immediate rejection)
- Soft limits: 4.0-10.0" BPEL/BPFSL, 3.5-6.5" MSEG (confirmation dialog)
- Confirmation dialog: "This value is outside the typical range. Are you sure?"
- Apply validation to all measurement input fields (pre, post, manual logging)
- Support both imperial (inches) and metric (cm) units
- Clear error messages for user education

### Story 10.5: Yield Tracking Analytics
**Goal:** Display yield trends and statistics in progress analytics
**Scope:**
- New "Session Yield" chart showing yield percentage over time
- Filter by measurement type (BPEL, BPFSL, MSEG)
- Statistics: Average yield, max yield, yield trend direction
- Session detail view shows yield for that specific session
- Help text explaining what yield/fatigue means
- Link to Reddit resources on temporary gains vs permanent gains

## Compatibility Requirements

- [x] Existing SessionLog documents load correctly (optional fields = nil)
- [x] Existing GainsEntry flow unchanged (still supports standalone measurements)
- [x] SessionLog without measurements remains valid and functional
- [x] Firestore queries remain performant (indexed fields if needed)
- [x] UI gracefully handles sessions without yield data (show "N/A")
- [x] Measurement unit preferences (imperial/metric) respected throughout

## Risk Mitigation

**Primary Risk:** Data quality issues from user input errors (typos, unit confusion)
**Mitigation:** Hard/soft validation limits, clear UI labels, confirmation dialogs, help text

**Secondary Risk:** Schema migration complexity for existing sessions
**Mitigation:** All new fields are optional, no data migration required

**Tertiary Risk:** User confusion about temporary vs permanent gains
**Mitigation:** In-app education, help text, link to community resources

**Rollback Plan:**
- Revert SessionLog model changes
- Remove measurement prompts from UI
- Existing sessions unaffected (optional fields ignored)
- No data loss (new fields simply not populated)

## Definition of Done

- [x] SessionLog model supports pre/post measurements and yield calculation
- [x] Pre-session measurement prompt functional (can skip)
- [x] Post-session measurement capture functional with yield display
- [x] Input validation prevents outlier data (hard/soft limits working)
- [x] Yield tracking analytics visible in Progress tab
- [x] All existing SessionLog functionality unchanged (regression tested)
- [x] Data structure documented for Epic 11 (CSV export)
- [x] Help documentation updated with yield explanation
- [x] User acceptance testing confirms value proposition

## Technical Notes

### Data Model Changes

**SessionLog.swift additions:**
```swift
// Optional pre-session measurements (BPEL, BPFSL, MSEG)
var preMeasurements: [MeasurementType: Double]?

// Optional post-session measurements (BPEL, BPFSL, MSEG)
var postMeasurements: [MeasurementType: Double]?

// Calculated yield percentages for each metric
var yieldPercentages: [MeasurementType: Double]? {
    guard let pre = preMeasurements, let post = postMeasurements else { return nil }
    var yields: [MeasurementType: Double] = [:]
    for (type, preValue) in pre {
        if let postValue = post[type], preValue > 0 {
            yields[type] = ((postValue - preValue) / preValue) * 100
        }
    }
    return yields
}
```

### Validation Limits

Based on GrowthTrack standards and CalcSD research data:

**Hard Limits (Reject):**
- BPEL/BPFSL: 3.0" - 11.0" (75mm - 280mm)
- MSEG: 3.0" - 8.0" (75mm - 200mm)

**Soft Limits (Warn):**
- BPEL/BPFSL: 4.0" - 10.0" (100mm - 250mm)
- MSEG: 3.5" - 6.5" (90mm - 165mm)

### Firestore Schema (Backward Compatible)

```json
{
  "sessionLogs/{sessionId}": {
    // Existing fields (unchanged)
    "userId": "string",
    "duration": "number",
    "startTime": "timestamp",
    "endTime": "timestamp",

    // New optional fields
    "preMeasurements": {
      "bpel": 5.5,      // inches
      "bpfsl": 5.8,     // inches
      "mseg": 4.5       // inches
    },
    "postMeasurements": {
      "bpel": 5.75,     // inches
      "bpfsl": 6.0,     // inches
      "mseg": 4.7       // inches
    }
    // yieldPercentages calculated client-side, not stored
  }
}
```

## Alignment with GrowthTrack

This epic establishes data parity with GrowthTrack's measurement system:

**GrowthTrack Tracks:**
- Pre-session: BPEL, BPFSL, MSEG ✅
- Post-session: BPEL, BPFSL, MSEG ✅
- Yield/Fatigue calculation ✅
- Input validation (soft/hard limits) ✅

**Growth Training Will Track:**
- Same metrics ✅
- Same calculation method ✅
- Same validation approach ✅
- Ready for CSV export (Epic 11) ✅

## User Value Proposition

**For Individual Users:**
- Immediate feedback on temporary gains after each session
- Understand which routines produce the most "pump" (yield)
- Track yield trends to optimize training intensity
- Prevent accidental data quality issues (validation)

**For Research Collaboration:**
- Data structure aligns with GrowthTrack standards
- Enables future opt-in data sharing (Epic 11)
- Contributes to PE research dataset
- Strengthens Growth Training/GrowthTrack partnership

## Dependencies for Epic 11 (Data Export)

This epic is a prerequisite for Epic 11 (Anonymous CSV Export to GrowthTrack):
- ✅ SessionLog contains pre/post measurements
- ✅ Yield calculation method matches GrowthTrack
- ✅ Data validation ensures quality export data
- ✅ Measurement types align (BPEL, BPFSL, MSEG)
- ✅ Schema documented for CSV generation

## Story Manager Handoff

Please develop detailed user stories for this brownfield epic. Key considerations:

**Existing System:**
- iOS/Swift/SwiftUI native app with Firebase Firestore
- Integration points: SessionLog model, GainsEntry model, session completion flow, manual logging, progress analytics
- Existing patterns: Optional fields, Firestore serialization, backward compatibility
- Models to extend: `SessionLog.swift`, measurement validation utilities

**Critical Compatibility Requirements:**
- All new SessionLog fields must be optional (no migration needed)
- Existing sessions without measurements must load/display correctly
- GainsEntry flow remains independent (can still create standalone measurements)
- UI must gracefully handle sessions with/without yield data
- Validation must support both imperial and metric units

**Each Story Must Include:**
1. Verification that existing SessionLog functionality unchanged
2. Backward compatibility testing (sessions without new fields)
3. Integration testing with GainsEntry (sessionId linking)
4. User acceptance criteria from GrowthTrack collaboration perspective

The epic should maintain system integrity while delivering **GrowthTrack-compatible session measurement tracking with yield calculation and data quality validation**.
