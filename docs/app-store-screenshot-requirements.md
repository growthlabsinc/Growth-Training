# App Store Screenshot Requirements

## Overview

App Store screenshots are crucial for converting visitors into users. They should showcase the app's key features and value proposition clearly.

## Required Device Sizes

### iPhone Screenshots (Required)
Apple requires screenshots for at least one iPhone size. You must provide:

1. **6.7" Display (iPhone 15 Pro Max, 14 Pro Max, etc.)**
   - Resolution: 1290 × 2796 pixels
   - Required for App Store submission
   
2. **6.5" Display (iPhone 11 Pro Max, XS Max)**
   - Resolution: 1242 × 2688 pixels
   - Optional but recommended

3. **5.5" Display (iPhone 8 Plus, 7 Plus)**
   - Resolution: 1242 × 2208 pixels
   - Optional for older device support

### iPad Screenshots (Required for Universal Apps)
Since Growth supports iPad:

1. **12.9" iPad Pro (6th gen)**
   - Resolution: 2048 × 2732 pixels
   - Required if app supports iPad
   
2. **12.9" iPad Pro (2nd gen)**
   - Resolution: 2048 × 2732 pixels
   - Alternative option

## Screenshot Specifications

### Technical Requirements
- **Format**: PNG or JPEG
- **Color Space**: sRGB or P3
- **No alpha channel** (no transparency)
- **Minimum 2-10 screenshots** per device size
- **Maximum file size**: Not specified, but keep reasonable

### Content Guidelines
- No status bar required (Apple adds it automatically)
- Avoid showing personal/sensitive information
- Ensure text is legible at smaller sizes
- Show actual app UI, not mockups

## Recommended Screenshots for Growth App

### Screenshot 1: Dashboard/Home
**Purpose**: Show the main interface and daily routine
- Feature the weekly calendar
- Display today's focus
- Show routine progress

### Screenshot 2: Growth Methods Library
**Purpose**: Showcase the variety of training methods
- Display method cards with images
- Show progression stages
- Highlight different categories

### Screenshot 3: Timer with Live Activity
**Purpose**: Demonstrate the training experience
- Active timer interface
- Method instructions visible
- Live Activity preview if possible

### Screenshot 4: Progress Tracking
**Purpose**: Show results and motivation
- Calendar with completed sessions
- Stats and achievements
- Progress charts

### Screenshot 5: AI Coach
**Purpose**: Highlight premium features
- Chat interface with helpful responses
- Professional coaching aspect
- Personalized guidance

### Screenshot 6: Subscription/Premium Features
**Purpose**: Show value proposition
- Premium features overview
- Subscription tiers
- Exclusive content access

### Optional Screenshots
- Custom routine creation
- Educational resources
- Community features
- Settings and personalization

## Screenshot Creation Process

### 1. Prepare Test Data
```swift
// Create appealing test data:
- Consistent user profile
- 30+ days of progress data
- Variety of completed sessions
- Some achievements unlocked
- Active routine with good adherence
```

### 2. Device Setup
```bash
# Use these simulators for screenshots:
- iPhone 15 Pro Max (6.7")
- iPad Pro 12.9" (6th gen)

# Set device to:
- Light mode (unless showing dark mode feature)
- 100% battery
- 9:41 AM time (Apple's preference)
- Full cellular/WiFi bars
- No notifications
```

### 3. Capture Guidelines
- Use Xcode's screenshot tool or device
- Ensure consistent lighting/theme
- Capture in portrait orientation
- Include captions if needed (optional)

### 4. Screenshot Tools
- **Xcode**: Device simulator screenshots
- **Screenshot Studio**: Professional framing
- **Sketch/Figma**: Add device frames
- **Previewed**: Quick device mockups

## Localization Considerations

If supporting multiple languages:
- Capture screenshots for each language
- Ensure text translations fit properly
- Use region-appropriate content
- Consider cultural sensitivities

## App Store Optimization Tips

1. **First 2-3 screenshots are most important**
   - Users often don't scroll
   - Lead with strongest features
   
2. **Tell a story**
   - Show user journey
   - Problem → Solution → Results
   
3. **Use captions sparingly**
   - Only if they add value
   - Keep text minimal and large
   
4. **Show real content**
   - Avoid lorem ipsum
   - Use realistic data
   - Display actual features

## Checklist for Screenshot Submission

- [ ] 6.7" iPhone screenshots (1290 × 2796)
- [ ] 12.9" iPad screenshots (2048 × 2732)
- [ ] All screenshots in PNG or JPEG format
- [ ] No transparency/alpha channel
- [ ] No personal information visible
- [ ] Consistent theme and styling
- [ ] Key features highlighted
- [ ] Subscription value shown
- [ ] 2-10 screenshots per size

## File Naming Convention

Recommended naming for organization:
```
iPhone_6.7_01_Dashboard.png
iPhone_6.7_02_Methods.png
iPhone_6.7_03_Timer.png
iPhone_6.7_04_Progress.png
iPhone_6.7_05_AICoach.png
iPhone_6.7_06_Premium.png

iPad_12.9_01_Dashboard.png
iPad_12.9_02_Methods.png
[etc...]
```

## Next Steps

1. Set up test account with good sample data
2. Configure simulators with proper settings
3. Capture screenshots following the order above
4. Review for consistency and quality
5. Export in correct resolutions
6. Upload to App Store Connect

Remember: Screenshots are your app's first impression. Make them count!