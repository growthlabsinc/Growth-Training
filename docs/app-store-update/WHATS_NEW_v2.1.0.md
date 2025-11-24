# What's New in Version 2.1.0

## For Apple Review Team

### New Features
**Millimeters Measurement Unit Support**
- Added millimeters (mm) as a third measurement unit option alongside inches and centimeters
- Implementation includes:
  - New `MeasurementUnit.millimeters` case in enum
  - Universal conversion utilities via `MeasurementValidator` class
  - Number pad keyboard type for whole-number mm input (vs decimal pad for in/cm)
  - Proper formatting: 0 decimal places for mm, 1 for cm, 2 for inches
  - All measurements stored internally as inches for consistency
  - Automatic conversion when switching between units
  - Updated UI throughout: Settings, measurement input cards, charts, statistics

### Bug Fixes
1. **Session Completion Sheet Dismissal**
   - Fixed: Completion sheet was auto-dismissing before users could enter post-session measurements
   - Resolution: Sheet now persists until user explicitly submits or dismisses

2. **Unit Selector Text Truncation**
   - Fixed: Segmented picker was truncating "Centimeters" → "Centim..." and "Millimeters" → "Millimet..."
   - Resolution: Changed to short unit labels ("in", "cm", "mm") in picker controls

3. **Measurement Slider Defaults**
   - Fixed: Sliders were initializing at maximum value instead of reasonable defaults
   - Resolution: Sliders now initialize at middle of valid range for each measurement type

4. **Unit Conversion Accuracy**
   - Fixed: When switching units, numeric values weren't converting (e.g., 111mm became 111in)
   - Resolution: Implemented proper conversion tracking and value transformation

### Technical Details
**Files Modified:**
- Core Models: `GainsEntry.swift`, `MeasurementType.swift`
- Utilities: `MeasurementValidator.swift`, `MeasurementFormatter.swift` (new)
- UI Components: `GainsInputCard.swift`, `EnhancedGainsInputCard.swift`, `UnitsSettingsView.swift`
- Display Views: `SessionDetailView.swift`, `GainsProgressView.swift`, `MeasurementTypeChart.swift`
- Progress: `DetailedProgressStatsView.swift`

**Test Coverage:**
- Automated tests: `test-millimeters-implementation.js`, `test-unit-persistence.js`
- Manual testing guide: `docs/MILLIMETERS_TESTING_GUIDE.md`
- UI validation checklist: `docs/MILLIMETERS_UI_CHECKLIST.md`

**Backward Compatibility:**
- All existing data preserved (stored as inches internally)
- Users on previous versions see no data loss
- New unit preference defaults to user's previous setting

### Privacy & Data
- No changes to data collection practices
- No new permissions required
- Measurement data remains locally stored and optionally synced via Firebase
- No third-party analytics or tracking added

### Testing Recommendations
1. Settings → Units & Measurements → Select each unit (in/cm/mm)
2. Gains → Track Measurements → Enter values in each unit
3. Switch between units and verify conversion accuracy
4. Complete a session and verify completion sheet persists
5. Check Progress → Stats → Time period selector displays properly

---

## For App Store Users

### What's New in 2.1.0

**📏 Millimeters Support**
Now track your measurements in millimeters! Based on user feedback, we've added mm as a third unit option for those who prefer whole numbers.

• Choose between inches, centimeters, or millimeters
• Automatic conversion when you switch units
• Clean, easy-to-read whole numbers for mm (e.g., 152mm vs 15.2cm)
• Smart keyboard: number pad for mm, decimal pad for in/cm

**🐛 Bug Fixes**
• Fixed session completion sheet dismissing too early
• Fixed text truncation in unit selector buttons
• Fixed measurement sliders starting at maximum value
• Fixed unit conversion not updating values properly

**✨ Improvements**
• Progress stats time selector now displays full labels
• Measurement sliders start at sensible middle values
• Better formatting consistency across all displays
• Smoother experience when switching between units

---

## Version History Note

**Previous Version (2.0.x):**
- Live Activities and Dynamic Island support
- Session tracking and progress charts
- Custom routine builder
- Privacy and security features

**Current Version (2.1.0):**
- Millimeters measurement support
- Session completion improvements
- UI/UX refinements

---

## Character-Limited Versions

### App Store "What's New" (4000 character limit)

```
NEW: Millimeters Support 📏

Based on your feedback, we've added millimeters (mm) as a third measurement unit option!

• Track in inches, centimeters, or millimeters
• Automatic conversion when switching units
• Clean whole numbers for mm (152mm instead of 15.2cm)
• Smart keyboard types for each unit

BUG FIXES 🐛

• Session completion sheet now stays open until you submit
• Fixed text truncation in unit selector
• Sliders now start at middle of range (not maximum)
• Unit conversion properly updates values

IMPROVEMENTS ✨

• Better time period selector display
• Smoother unit switching experience
• Improved formatting consistency
• More precise slider increments (0.1in, 0.1cm, 1mm)

We're constantly improving based on your feedback. Keep the suggestions coming!
```

### TestFlight Beta Notes (Short)

```
Testing v2.1.0 - Millimeters Support + Fixes

NEW:
- Millimeters unit option (Settings → Units)
- Smart keyboards: number pad for mm, decimal for in/cm

FIXED:
- Completion sheet auto-dismissal
- Text truncation in unit buttons
- Slider defaults and conversions

TEST:
1. Switch between in/cm/mm units
2. Enter measurements in each unit
3. Verify conversions are accurate
4. Check completion sheet stays open
5. Test slider increments

Report any issues via in-app feedback!
```

### Ultra-Short Version (Tweet/Social)

```
🆕 Growth Training v2.1.0

📏 Millimeters support
🐛 Completion sheet fix
✨ Better UI/UX
🎯 Smoother conversions

Update now!
```

---

## Release Checklist

**Before Submission:**
- [ ] Version number updated in Xcode (2.1.0)
- [ ] Build number incremented
- [ ] All tests passing
- [ ] TestFlight build validated
- [ ] Screenshots updated (if UI changed significantly)
- [ ] "What's New" text prepared in both languages (if applicable)

**Apple Review Notes:**
- Millimeters feature is purely additive - no functionality removed
- All bug fixes improve existing features - no breaking changes
- No new permissions requested
- No changes to in-app purchases or subscription logic
- Standard update - no expedited review needed

**Post-Approval:**
- [ ] Monitor crash reports for 48 hours
- [ ] Check user reviews for feedback
- [ ] Update Reddit post with availability
- [ ] Notify TestFlight testers of public release

---

## Support Responses

**If users ask "Why millimeters?"**
> "Based on user feedback from those who track in metric, millimeters provides cleaner whole numbers (152mm vs 15.2cm) that are easier to read and track. It's completely optional - you can still use inches or centimeters."

**If users report conversion issues:**
> "Please verify you're on version 2.1.0. Go to Settings → Units and try switching between units - values should convert automatically (e.g., 152mm = 6.0in = 15.2cm). If you still see issues, please send us the specific conversion that's incorrect via Settings → Send Feedback."

**If users ask about data safety:**
> "All your existing measurements are safe. We store everything internally in inches, so switching units only changes the display - your actual data is never modified or lost."