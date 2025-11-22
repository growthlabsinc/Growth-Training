# TestFlight Testing Notes - Measurement System Update

## What's New in This Build

**Millimeters Support** - Added millimeters (mm) as a third measurement unit option alongside inches and centimeters.

---

## What to Test

### 1. Unit Selection ✓
**Where:** Settings → Units & Measurements

**Test:**
- Select each unit option: Inches, Centimeters, Millimeters
- Verify the selection persists after closing and reopening the app
- Check that the unit buttons display as "in", "cm", "mm" (not truncated)

**Expected:** All three units available and working properly

---

### 2. Measurement Input ✓
**Where:** Gains tab → Track Measurements

**Test:**
- Open measurement tracking
- Try all three units and verify:
  - **Inches:** Shows decimal keyboard, accepts values like 6.5"
  - **Centimeters:** Shows decimal keyboard, accepts values like 16.5cm
  - **Millimeters:** Shows number pad (no decimals), accepts values like 165mm
- Verify sliders move in small increments:
  - Inches: 0.1" steps
  - Centimeters: 0.1cm steps
  - Millimeters: 1mm steps

**Expected:** Correct keyboard type for each unit, smooth slider movement

---

### 3. Unit Conversion ✓
**Where:** Gains tab → Track Measurements

**Test:**
1. Set BPEL to 152mm
2. Switch to inches → should show ~6.0"
3. Switch to centimeters → should show ~15.2cm
4. Switch back to millimeters → should return to 152mm

**Expected:** Values convert accurately between units, no data loss

---

### 4. Slider Default Position ✓
**Where:** Gains tab → Track Measurements (first time opening)

**Test:**
- Open measurement tracking for the first time
- Check slider starting positions

**Expected:**
- Sliders start in the middle of the range (not at max)
- BPEL around 165mm / 16.5cm / 6.5"
- MSEG around 114mm / 11.4cm / 4.5"

---

### 5. Measurement Display ✓
**Where:** Progress → Gains tab

**Test:**
- View existing measurements in all three units
- Check formatting:
  - Inches: 6.25" (2 decimal places)
  - Centimeters: 15.8cm (1 decimal place)
  - Millimeters: 152mm (whole numbers only)

**Expected:** Proper formatting with correct decimal places

---

## Known Behaviors (Not Bugs)

✅ **All measurements stored as inches internally** - Switching units only changes display, not stored data

✅ **Millimeters show whole numbers** - No decimals for mm (e.g., 152mm not 152.4mm)

✅ **Time period selector** - Now shows "This Week", "This Month", etc. instead of truncated text

---

## What to Report

🐛 **Report if you see:**
- Unit conversion showing wrong values (e.g., 111mm → 111")
- Sliders starting at maximum instead of middle
- Text truncation on unit buttons
- Measurements not persisting after app restart
- Crashes when switching units
- Incorrect decimal places for any unit

---

## Questions?

If anything seems off or you're unsure about expected behavior, please include:
1. Screenshot of the issue
2. Steps to reproduce
3. Which unit you were using
4. Device model and iOS version

Thank you for testing! 🙏