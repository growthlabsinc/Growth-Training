# App Store Review Fix - Guideline 2.5.4

## Submission Details
- **Submission ID**: 2f812c3d-7b1a-4b4a-95e3-bfb34f019412
- **Review Date**: September 17, 2025
- **Version Reviewed**: 1.1.1

## Issue
**Guideline 2.5.4 - Performance - Software Requirements**

The app declared support for audio in the UIBackgroundModes key in Info.plist but Apple was unable to locate any features that require persistent audio.

## Root Cause
The app had `audio` listed in UIBackgroundModes but doesn't actually need it. The app only plays short timer notification sounds using AVAudioPlayer, which don't require background audio mode.

## Fix Applied

### Removed from Info.plist
- **File**: `/Growth/Resources/Plist/App/Info.plist`
- **Removed**: `<string>audio</string>` from UIBackgroundModes array

### Background Modes Still Required
The app legitimately needs these background modes:
- **processing** - For Live Activity updates and timer background processing
- **remote-notification** - For Firebase push notifications and Live Activity push updates

## Audio Features Analysis
The app uses AVAudioPlayer in `TimerService.swift` for:
- Timer completion sounds
- Interval change alerts
- Overexertion warnings

These are all brief notification sounds that play while the app is in the foreground. They do NOT require background audio mode.

## Background Audio Mode Guidelines
Background audio mode should only be used for apps that:
- Play music continuously in the background (music players)
- Stream audio content (podcasts, audiobooks, radio)
- Create music or audio content
- Provide navigation voice guidance

## Response to Apple
You can reply to Apple with:

"We have removed the 'audio' background mode from our Info.plist file. Our app only plays brief timer notification sounds while in the foreground, which don't require persistent audio background mode. The app retains 'processing' and 'remote-notification' background modes which are necessary for our Live Activity updates and push notifications functionality."

## Testing
After this change:
1. Timer sounds still work when app is in foreground ✓
2. Live Activities continue to update via push notifications ✓
3. Firebase push notifications still work ✓
4. No audio plays when app is in background (as intended) ✓