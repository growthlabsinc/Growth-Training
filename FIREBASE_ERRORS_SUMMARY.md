# Firebase Functions Error Summary

## Current Errors

### 1. **BadDeviceToken (400)** in `updateLiveActivity`
- **Cause**: Development push tokens from Xcode being sent to production APNs endpoint
- **Attempted Fix**: Added retry logic to use development endpoint
- **New Error**: InvalidProviderToken (403) when using development endpoint
- **Solution**: Need to test with TestFlight/Ad Hoc build for production tokens

### 2. **InvalidProviderToken (403)** in `updateLiveActivity` 
- **Cause**: When retrying with development endpoint, the APNs auth key is rejected
- **Possible Issues**:
  - APNs auth key might not support both dev and prod environments
  - Key might be incorrectly formatted
  - Team ID or Key ID mismatch

### 3. **App Check Token Validation Failures**
- **Error**: "Decoding App Check token failed"
- **Status**: Warnings only - requests are allowed through (enforcement disabled)
- **Fix Required**: Configure App Check in Firebase Console

### 4. **Parse Error: Expected HTTP/** in `manageLiveActivityUpdates`
- **Cause**: Was using axios (HTTP/1.1) instead of http2 for APNs
- **Fix Applied**: Replaced axios with http2 module
- **Status**: Fix deployed, waiting for new function invocations to verify

## Fixes Applied

1. **Extended Live Activity dismissal time**: 6 seconds → 300 seconds (5 minutes)
2. **Fixed URL construction**: Added proper HTTP/2 implementation
3. **Updated bundle IDs**: Changed to `com.growthlabs.growthmethod`
4. **Added retry logic**: Automatic fallback to development endpoint

## Testing Recommendations

1. **For Immediate Testing**:
   - Build app for TestFlight or Ad Hoc distribution
   - This generates production tokens that work correctly

2. **Configure App Check**:
   - Go to Firebase Console > App Check
   - Register app with bundle ID: `com.growthlabs.growthmethod`
   - Enable DeviceCheck and Debug providers

3. **Verify APNs Configuration**:
   - Check that the .p8 key file is correct
   - Verify Team ID: 62T6J77P6R
   - Verify Key ID: 3G84L8G52R

## Current Function Status

- `updateLiveActivity`: Has retry logic but failing with token mismatch
- `manageLiveActivityUpdates`: Fixed HTTP/2 implementation deployed
- `onTimerStateChange`: Failing with same BadDeviceToken error

The main issue is the development/production token mismatch when running from Xcode.