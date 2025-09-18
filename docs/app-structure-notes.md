# App Structure Notes

## Overview

This document explains the structure of the Growth app's main application files and important entry points.

## App Entry Point

The Growth app follows the SwiftUI lifecycle and uses a single `@main` attribute to define the entry point:

- **GrowthAppApp.swift** in the `Application` directory is the main entry point
- The app uses `UIApplicationDelegateAdaptor` to maintain compatibility with UIKit patterns

## Key Components

### GrowthAppApp (Main Entry Point)

Located in `Growth/Application/GrowthAppApp.swift`, this is the primary app struct that:

- Serves as the entry point with the `@main` attribute
- Registers the AppDelegate using `UIApplicationDelegateAdaptor`
- Initializes Firebase
- Sets up Core Data with PersistenceController
- Configures the main app environment

### AppDelegate

Located in `Growth/Application/AppDelegate.swift`, it:

- Implements UIKit application lifecycle methods
- Configures Firebase in `didFinishLaunchingWithOptions`
- Sets up push notifications
- Handles Firebase Messaging

### MainView

The primary content view for the app that:
- Shows either authenticated or unauthenticated content based on auth state
- Provides the main navigation structure

## Recent Structure Changes

### Resolving Duplicate @main Attribute

The codebase previously had two files with the `@main` attribute, causing build errors:

1. `GrowthAppApp.swift`: Had `@main` and AppDelegate registration
2. `GrowthApp.swift`: Had `@main` and Firebase/CoreData setup

To resolve this issue:

1. **Removed `@main` from** `GrowthApp.swift`
2. **Integrated functionality from** `GrowthApp.swift` into `GrowthAppApp.swift`:
   - Added PersistenceController
   - Added Firebase setup code
   - Added Core Data environment

This consolidation ensures that the app has a single clear entry point while maintaining all necessary functionality. 