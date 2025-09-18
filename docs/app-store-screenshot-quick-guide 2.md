# App Store Screenshot Quick Guide

## 📱 Required Screenshots

### iPhone (Choose One)
- **iPhone 15 Pro Max**: 1290 × 2796 px ✅ (Recommended)
- **iPhone 11 Pro Max**: 1242 × 2688 px
- **iPhone 8 Plus**: 1242 × 2208 px

### iPad (Required for Universal Apps)
- **iPad Pro 12.9"**: 2048 × 2732 px ✅

## 📸 6 Essential Screenshots

1. **Dashboard** - Home screen with weekly calendar
2. **Methods Library** - Show variety of growth methods
3. **Active Timer** - Training in progress
4. **Progress View** - Stats, calendar, achievements
5. **AI Coach** - Premium chat feature
6. **Subscription** - Premium features overview

## ⚙️ Simulator Setup

```bash
# Set perfect status bar (9:41 AM, full bars, 100% battery)
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --cellularBars 4
```

## 🎯 Quick Capture Script

```bash
# Run the automated capture script
./scripts/capture-app-store-screenshots.sh
```

## ✅ Pre-Screenshot Checklist

- [ ] Test account with 30+ days of data
- [ ] Light mode enabled
- [ ] No notifications visible
- [ ] Appealing routine selected
- [ ] Some achievements unlocked
- [ ] Premium features accessible

## 📤 Upload Format

- **Format**: PNG or JPEG
- **No transparency**
- **2-10 screenshots per size**
- **Lead with strongest features**

## 💡 Pro Tips

1. First 2-3 screenshots are crucial
2. Show progression: Problem → Solution → Results
3. Keep any text large and minimal
4. Use consistent color theme
5. Hide personal information

Ready to capture? Run: `./scripts/capture-app-store-screenshots.sh`