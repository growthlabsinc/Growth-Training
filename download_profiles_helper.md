# Quick Profile Download Guide

## Direct Links to Create Profiles

### 1. Main App Profile
Create "Growth App Store Distribution" profile:
1. Go to: https://developer.apple.com/account/resources/profiles/add
2. Select "App Store" distribution type
3. Select App ID: **com.growthlabs.growthmethod**
4. Select Certificate: **Apple Distribution: Jon Webb**
5. Name it: **Growth App Store Distribution**
6. Generate and Download

### 2. Widget Profile  
Create "Growth Timer Widget App Store" profile:
1. Go to: https://developer.apple.com/account/resources/profiles/add
2. Select "App Store" distribution type
3. Select App ID: **com.growthlabs.growthmethod.GrowthTimerWidget**
4. Select Certificate: **Apple Distribution: Jon Webb**
5. Name it: **Growth Timer Widget App Store**
6. Generate and Download

## Installation
After downloading both .mobileprovision files:
1. Double-click each file to install
2. Or drag them to Xcode icon

## Verify Installation
Run: `./verify_provisioning_profiles.sh`