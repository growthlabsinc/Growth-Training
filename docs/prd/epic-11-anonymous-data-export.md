# Epic 11: Anonymous CSV Export to GrowthTrack

## Epic Status
**Status:** Draft
**Priority:** Medium
**Target Release:** v1.3.0
**Dependencies:** Epic 10 (Pre/Post Session Measurement Tracking)
**Related Epics:** Epic 10
**External Collaboration:** Karl Wikman (GrowthTrack platform)

## Epic Goal

Enable Growth Training users to export their anonymized session and measurement data as CSV files compatible with GrowthTrack's bulk import format, facilitating data collaboration between platforms and contributing to the PE research dataset while maintaining strict user privacy and opt-in consent.

## Epic Description

### Existing System Context

**Current Data Structure (Post-Epic 10):**
- `SessionLog` with pre/post measurements (BPEL, BPFSL, MSEG) and yield calculation
- `GainsEntry` with comprehensive measurement types and tracking
- Firebase Firestore storage for user data
- Existing data export in Settings (basic JSON export)
- No CSV export capability currently

**Technology Stack:**
- Swift/SwiftUI native iOS app
- Firebase Firestore for data persistence
- Firebase Auth for user identification
- Models: `SessionLog`, `GainsEntry`, `MeasurementType` enum

**Integration Points:**
- Settings → Export Data view (existing)
- SessionLog fetch from Firestore
- GainsEntry fetch from Firestore
- File sharing via iOS share sheet
- Measurement unit conversion utilities

### Enhancement Details

**What's Being Added:**

1. **Anonymous CSV Export for Session Logs**
   - Export SessionLog data in GrowthTrack's CSV format
   - Include: date, session category, duration, pre/post measurements (BPEL, BPFSL, MSEG), yield
   - **Strip all PII:** No userId, no email, no userNotes, no identifiable data
   - Generate random anonymous statistical ID (persist per-user for consistency)
   - Convert measurements to millimeters (GrowthTrack standard)
   - Format: GrowthTrack bulk upload CSV template

2. **Anonymous CSV Export for Measurements**
   - Export GainsEntry data in GrowthTrack's measurement CSV format
   - Include: date, BPEL, NBPEL, BPFSL, MSEG, BEG, erection quality
   - **Strip all PII:** No userId, no email, no notes with identifying info
   - Use same anonymous statistical ID as session export
   - Convert to millimeters
   - Format: GrowthTrack measurement upload CSV template

3. **Opt-In Consent & Privacy UI**
   - Explicit opt-in toggle in Settings
   - Clear explanation of what data is shared (and NOT shared)
   - Privacy notice: "Your data is anonymized. No personally identifiable information (name, email, notes) is included."
   - Link to privacy policy
   - Option to regenerate anonymous ID (break linkage for extra privacy)

4. **CSV Template Alignment with GrowthTrack**
   - Coordinate with Karl (u/karlwikman) on exact CSV schema
   - Match GrowthTrack's column names, units (mm), data types
   - Include only fields GrowthTrack can ingest
   - Validate CSV format before export (prevent user frustration)

**How It Integrates:**

- **Settings → Export Data:** Add "Export for GrowthTrack" button
- **AnonymizationService:** New service to strip PII and generate statistical IDs
- **CSVExportService:** New service to format data as GrowthTrack-compatible CSV
- **File sharing:** Use iOS share sheet to save/share CSV file
- **UserDefaults:** Store anonymous ID and opt-in consent flag
- **Firestore:** No changes needed (read-only data access)

**Success Criteria:**

1. Users can export anonymized session logs as CSV compatible with GrowthTrack bulk upload
2. Users can export anonymized measurements as CSV compatible with GrowthTrack measurement upload
3. All PII is stripped from exported data (no userId, email, identifiable notes)
4. CSV format exactly matches GrowthTrack's import template
5. Measurements converted to millimeters (GrowthTrack standard)
6. Opt-in consent flow is clear and explicit
7. Anonymous statistical ID is consistent per-user (for GrowthTrack's longitudinal analysis)
8. CSV files can be successfully imported into GrowthTrack (validated with Karl)

## Stories

### Story 11.1: Anonymous Statistical ID Generation & Management
**Goal:** Generate and persist anonymous IDs for users who export data
**Scope:**
- Create `AnonymizationService` utility
- Generate random statistical ID on first export (UUID-based)
- Store in UserDefaults (persist across exports for consistency)
- Provide "Regenerate ID" option in Settings (break linkage if user wants)
- Never transmit real userId or Firebase Auth UID in exports
- Help text explaining what statistical ID is and why it's used

### Story 11.2: Session Log CSV Export
**Goal:** Export anonymized SessionLog data in GrowthTrack bulk upload format
**Scope:**
- Create `CSVExportService` for SessionLog
- Fetch all SessionLog entries for current user
- Strip PII: Remove userId, userNotes, methodId (could be identifying)
- Convert measurements to millimeters (from inches)
- Include: anonymousId, date, session category, duration, pre/post BPEL/BPFSL/MSEG (mm), effective time
- Generate CSV matching GrowthTrack's template (column names, order, data types)
- Handle missing data gracefully (empty cells for optional fields)
- Save CSV file to device via iOS share sheet
- File naming: `growth-training-sessions-{date}.csv`

### Story 11.3: Measurement CSV Export
**Goal:** Export anonymized GainsEntry data in GrowthTrack measurement format
**Scope:**
- Create `CSVExportService` for GainsEntry
- Fetch all GainsEntry records for current user
- Strip PII: Remove userId, notes (if they contain identifying info)
- Convert all measurements to millimeters
- Include: anonymousId, date, BPEL, NBPEL, BPFSL, MSEG, BEG, HEG (if available), erection quality
- Generate CSV matching GrowthTrack's measurement template
- Handle missing measurement types (not all users track all metrics)
- Save CSV via iOS share sheet
- File naming: `growth-training-measurements-{date}.csv`

### Story 11.4: Opt-In Consent & Privacy Settings UI
**Goal:** Explicit user consent flow for data export with privacy education
**Scope:**
- Add "Data Collaboration" section in Settings → Export Data
- Toggle: "Enable GrowthTrack Export" (default: OFF)
- Privacy notice explaining anonymization process
- List of what IS exported vs what IS NOT exported
- "Regenerate Anonymous ID" button (with confirmation dialog)
- Link to Privacy Policy (mention data collaboration)
- Disable export buttons unless opt-in enabled
- Analytics event when user enables/disables export

### Story 11.5: CSV Format Validation & GrowthTrack Testing
**Goal:** Ensure exported CSVs are successfully importable into GrowthTrack
**Scope:**
- Define exact CSV schema with Karl (column names, units, data types)
- Implement CSV format validator (check headers, data types before export)
- Test CSV import with Karl's GrowthTrack platform
- Handle edge cases: missing data, outlier values, special characters
- Error handling: Display user-friendly error if export fails
- Success message with instructions on how to upload to GrowthTrack
- Provide example CSV for testing purposes
- Document CSV schema in Help section

## Compatibility Requirements

- [x] Existing SessionLog and GainsEntry data unchanged (read-only export)
- [x] Export feature is completely optional (no impact if user doesn't use it)
- [x] Measurements in inches (app default) correctly converted to millimeters
- [x] CSV export doesn't interfere with existing JSON export functionality
- [x] iOS share sheet integration works across all iOS versions (16.0+)
- [x] File naming conventions avoid conflicts with existing exports

## Risk Mitigation

**Primary Risk:** Privacy breach if PII accidentally included in export
**Mitigation:**
- Comprehensive PII stripping (whitelist approach: only export known-safe fields)
- Code review with privacy checklist
- User testing to verify no PII in exported files
- Open source anonymization logic for community audit

**Secondary Risk:** CSV format mismatch causes import failures in GrowthTrack
**Mitigation:**
- Direct collaboration with Karl on schema definition
- CSV format validator before export
- Beta testing with Karl's platform
- Clear error messages if validation fails

**Tertiary Risk:** User confusion about anonymization (think data is private but share CSV publicly)
**Mitigation:**
- Prominent privacy education in Settings
- Confirmation dialog before export: "This data is anonymized but will be linked by statistical ID. Don't share your ID publicly if you want maximum privacy."
- Help documentation on responsible data sharing

**Rollback Plan:**
- Disable export feature via feature flag (no code deployment needed)
- Remove opt-in toggle from Settings
- No data loss (export is read-only)
- No Firestore changes to revert

## Definition of Done

- [x] Anonymous statistical ID generation and persistence working
- [x] Session log CSV export generates GrowthTrack-compatible files
- [x] Measurement CSV export generates GrowthTrack-compatible files
- [x] All PII successfully stripped (verified via code review)
- [x] Opt-in consent flow implemented with privacy education
- [x] CSV format validated with Karl's GrowthTrack platform
- [x] Successful test import into GrowthTrack confirmed
- [x] Help documentation updated with export instructions
- [x] Privacy policy updated to mention data collaboration option
- [x] User acceptance testing confirms ease of use

## Technical Notes

### GrowthTrack CSV Schema (Coordinate with Karl)

**Session Log CSV Format:**
```csv
anonymous_id,date,category,duration_minutes,effective_time_minutes,pre_bpel_mm,pre_bpfsl_mm,pre_mseg_mm,post_bpel_mm,post_bpfsl_mm,post_mseg_mm
GT-ABC123,2025-01-15,lengthwork,30,28,152,165,115,158,170,118
GT-ABC123,2025-01-16,girthwork,25,25,152,165,115,154,167,120
```

**Measurement CSV Format:**
```csv
anonymous_id,date,bpel_mm,nbpel_mm,bpfsl_mm,mseg_mm,beg_mm,heg_mm,erection_quality
GT-ABC123,2025-01-01,152,140,165,115,120,105,8
GT-ABC123,2025-01-15,155,143,168,117,122,107,9
```

**Field Mapping:**

| Growth Training Field | GrowthTrack Field | Conversion |
|----------------------|-------------------|------------|
| SessionLog.startTime | date | Date only (YYYY-MM-DD) |
| SessionLog.duration | duration_minutes | Direct |
| SessionLog.preMeasurements[.bpel] | pre_bpel_mm | inches × 25.4 |
| SessionLog.preMeasurements[.bpfsl] | pre_bpfsl_mm | inches × 25.4 |
| SessionLog.preMeasurements[.mseg] | pre_mseg_mm | inches × 25.4 |
| SessionLog.postMeasurements[.bpel] | post_bpel_mm | inches × 25.4 |
| GainsEntry.measurements[.bpel] | bpel_mm | inches × 25.4 |
| GainsEntry.erectionQuality | erection_quality | Direct (1-10) |

### AnonymizationService Pseudocode

```swift
class AnonymizationService {
    private let anonymousIdKey = "com.growthlabs.anonymousStatID"

    func getOrCreateAnonymousId() -> String {
        if let existing = UserDefaults.standard.string(forKey: anonymousIdKey) {
            return existing
        }
        let newId = "GT-" + UUID().uuidString.prefix(8).uppercased()
        UserDefaults.standard.set(newId, forKey: anonymousIdKey)
        return newId
    }

    func regenerateAnonymousId() -> String {
        let newId = "GT-" + UUID().uuidString.prefix(8).uppercased()
        UserDefaults.standard.set(newId, forKey: anonymousIdKey)
        return newId
    }

    func stripPII(from sessionLog: SessionLog) -> AnonymousSessionLog {
        AnonymousSessionLog(
            anonymousId: getOrCreateAnonymousId(),
            date: sessionLog.startTime, // Date only, no time
            duration: sessionLog.duration,
            preMeasurements: sessionLog.preMeasurements, // No PII
            postMeasurements: sessionLog.postMeasurements, // No PII
            // Exclude: userId, userNotes, methodId
        )
    }
}
```

### Measurement Unit Conversion

**Inches to Millimeters:** `value * 25.4`

**Example:**
- BPEL: 6.0" → 152.4mm → round to 152mm
- MSEG: 4.5" → 114.3mm → round to 114mm

**Rounding:** Round to nearest millimeter (GrowthTrack standard per Karl's posts)

### CSV Export Service Pseudocode

```swift
class CSVExportService {
    func exportSessionLogs(for userId: String) async throws -> URL {
        let sessions = try await fetchSessionLogs(userId: userId)
        let anonymousId = AnonymizationService.shared.getOrCreateAnonymousId()

        var csvContent = "anonymous_id,date,category,duration_minutes,pre_bpel_mm,pre_bpfsl_mm,pre_mseg_mm,post_bpel_mm,post_bpfsl_mm,post_mseg_mm\n"

        for session in sessions {
            guard let pre = session.preMeasurements,
                  let post = session.postMeasurements else { continue }

            let row = [
                anonymousId,
                dateFormatter.string(from: session.startTime), // YYYY-MM-DD
                session.methodCategory ?? "hybrid",
                "\(session.duration)",
                convertToMM(pre[.bpel]),
                convertToMM(pre[.bpfsl]),
                convertToMM(pre[.mseg]),
                convertToMM(post[.bpel]),
                convertToMM(post[.bpfsl]),
                convertToMM(post[.mseg])
            ].joined(separator: ",")

            csvContent += row + "\n"
        }

        return try saveCSVFile(content: csvContent, filename: "sessions")
    }

    private func convertToMM(_ inches: Double?) -> String {
        guard let inches = inches else { return "" }
        return "\(Int(round(inches * 25.4)))"
    }
}
```

## Collaboration with GrowthTrack (Karl Wikman)

**Coordination Required:**
1. **CSV Schema Validation:** Share sample export files with Karl for testing
2. **Column Names:** Confirm exact header names match GrowthTrack's bulk import
3. **Data Types:** Verify number formats, date formats, null handling
4. **Unit Confirmation:** Verify millimeters is correct unit (confirmed in Discord conversation)
5. **Import Testing:** Karl tests importing Growth Training CSVs into GrowthTrack
6. **Feedback Loop:** Iterate on format based on Karl's import results
7. **Documentation:** Karl documents Growth Training as compatible export source

**Communication Channels:**
- Discord DM with Karl
- Email: wikman.karl@gmail.com
- Reddit: u/karlwikman
- GrowthTrack GitHub (if open source)

**Timeline:**
- Epic 10 completion: v1.2.0 (prerequisite)
- CSV schema design: 1 week after Epic 10 done
- Karl validation testing: 2 weeks
- Epic 11 release: v1.3.0 (with confirmed GrowthTrack compatibility)

## User Value Proposition

**For Individual Users:**
- Contribute to PE research without privacy risk
- Support evidence-based PE science
- Access GrowthTrack's advanced analytics (future integration potential)
- Backup data in standardized format

**For PE Community:**
- Larger research dataset improves statistical power
- Cross-platform data validation strengthens findings
- Evidence-based recommendations benefit everyone
- Strengthens Growth Training/GrowthTrack collaboration

**For Growth Training:**
- Demonstrates commitment to science (not just profit)
- Builds credibility in PE community
- Aligns with community values (r/TheScienceOfPE)
- Differentiates from generic fitness apps

## Privacy & Ethics

**Anonymization Standards:**
- No direct identifiers (userId, email, name)
- No quasi-identifiers (IP address, device ID)
- No free-text notes (could contain PII)
- Statistical ID cannot be reversed to real identity
- Option to regenerate ID breaks longitudinal linkage (user choice)

**Informed Consent:**
- Opt-in only (default: OFF)
- Clear explanation of what data is shared
- Explanation of anonymization process
- User understands data will be in research dataset
- Can disable export at any time (opt-out)

**GDPR/Privacy Compliance:**
- Right to anonymity (statistical ID, not real identity)
- Right to withdraw (disable export, regenerate ID)
- Right to be forgotten (delete local data, ID becomes orphaned in dataset)
- Transparency (exactly what fields are exported is documented)

## Dependencies for Future Enhancements

This epic enables future direct API integration:
- ✅ CSV format established and validated
- ✅ Anonymization service proven
- ✅ Privacy consent flow established
- 🔮 Future: Direct API sync to GrowthTrack (no manual CSV upload)
- 🔮 Future: Bidirectional sync (import GrowthTrack insights back to Growth Training)

## Story Manager Handoff

Please develop detailed user stories for this brownfield epic. Key considerations:

**Existing System:**
- iOS/Swift/SwiftUI native app with Firebase Firestore
- Integration points: Settings → Export Data, SessionLog fetching, GainsEntry fetching, iOS share sheet
- Existing patterns: JSON export, file sharing, UserDefaults for preferences
- Services to create: `AnonymizationService`, `CSVExportService`

**Critical Privacy Requirements:**
- ALL PII must be stripped (whitelist approach: only export safe fields)
- Anonymous statistical ID must be random and persistent
- Opt-in consent is mandatory (cannot export without explicit user action)
- CSV format validator prevents accidental PII inclusion
- Code review with privacy checklist required before merge

**Critical Collaboration Requirements:**
- CSV schema must match GrowthTrack's format exactly
- Coordinate with Karl (u/karlwikman) on schema, testing, validation
- Successful test import into GrowthTrack required before release
- Documentation must include instructions for uploading to GrowthTrack

**Each Story Must Include:**
1. Privacy verification testing (no PII in exported files)
2. CSV format validation (matches GrowthTrack schema)
3. Unit conversion accuracy testing (inches → mm)
4. GrowthTrack import testing (with Karl's platform)
5. User acceptance criteria from privacy and usability perspectives

The epic should maintain strict privacy standards while delivering **GrowthTrack-compatible anonymous data export for PE research collaboration**.
