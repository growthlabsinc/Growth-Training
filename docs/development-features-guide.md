# Development Features Guide

## Overview

This guide documents the development features added to the Growth app for testing purposes, particularly the App Tour reset functionality.

## Development Tools Access

### How to Access Developer Options

1. Open the app and navigate to **Settings**
2. Scroll down to find **Developer Options** (only visible in DEBUG builds)
3. Tap to access development tools

### Available Development Tools

#### 1. App Tour Testing

- **Reset App Tour**: Clears the tour completion state, allowing you to see the tour on next app launch
- **Show App Tour Now**: Immediately triggers the app tour without restarting the app

#### 2. Onboarding Testing

- **Reset Onboarding**: Clears all onboarding progress (requires logout/login to see effect)

#### 3. Cache Management

- **Clear Local Cache**: Removes all locally cached data

#### 4. Debug Information

- Shows current user ID
- Shows tour completion status
- Shows tour seen status

## Testing the App Tour Workflow

### Method 1: Full Reset Test

1. Navigate to Settings > Developer Options
2. Tap "Reset App Tour"
3. Close the app completely (swipe up and remove from app switcher)
4. Reopen the app
5. The tour should appear automatically on the dashboard

### Method 2: Immediate Test

1. Navigate to Settings > Developer Options
2. Tap "Show App Tour Now"
3. The tour will immediately appear on screen

### Method 3: Logout/Login Test

1. Navigate to Settings > Developer Options
2. Tap "Reset App Tour"
3. Log out from the main Settings screen
4. Log back in with your credentials
5. Complete any required onboarding steps
6. The tour should appear when you reach the dashboard

## Code Structure

### Files Added/Modified

1. **DevelopmentToolsView.swift** - Main development tools interface
2. **SettingsView.swift** - Added conditional navigation to developer options
3. **AppTourService.swift** - Added `resetTourState()` method
4. **NotificationName+Extensions.swift** - Added `triggerAppTour` notification name

### Important Notes

- Notification names are defined in multiple files:
  - Navigation notifications: `SmartNavigationService.swift`
  - Progress notifications: `LogSessionViewModel.swift`
  - App tour notifications: `NotificationName+Extensions.swift`
- Avoid duplicate declarations when adding new notifications

### Conditional Compilation

All development features are wrapped in `#if DEBUG ... #endif` blocks, ensuring they're only included in debug builds.

## Removing Development Features for Production

### Automatic Removal

Run the provided script to identify all development-related code:

```bash
cd scripts
./remove-development-features.sh
```

### Manual Removal Steps

1. **Remove Development Tools Section from Settings**
   - In `SettingsView.swift`, remove the entire `#if DEBUG` section containing Developer Options

2. **Delete Development Files**
   - Delete `DevelopmentToolsView.swift`
   - Remove any other files marked as development-only

3. **Clean Up Methods**
   - Consider removing or making private the `resetTourState()` method in `AppTourService`
   - Remove any other public methods only used for testing

4. **Search and Remove**
   - Search for `#if DEBUG` blocks and evaluate each one
   - Remove or relocate test-specific code

### Build Configuration

For production builds, ensure:
- Build configuration is set to "Release"
- DEBUG flag is not defined
- Swift compiler optimization is enabled

## Best Practices

1. **Always Test After Removal**: After removing development features, thoroughly test the app
2. **Use Feature Flags**: For more complex scenarios, consider using remote feature flags
3. **Document Changes**: Keep track of what was removed for future reference
4. **Version Control**: Commit development feature removal as a separate commit

## Security Considerations

- Development tools should NEVER be included in production builds
- The `resetTourState()` method is safe as it only affects local state and the current user's data
- No sensitive information is exposed through these tools

## Troubleshooting

### Tour Not Appearing After Reset

1. Ensure you've completely closed the app
2. Check that you're logged in
3. Verify you're on the home/dashboard tab
4. Check debug console for any errors
5. Look for these log messages:
   - "DevelopmentTools: Posting triggerAppTour notification"
   - "MainView: Received triggerAppTour notification"
   - "AppTourViewModel: Starting tour"
   - "AppTourViewModel: Tour has X steps"

### Tour Shows But No Content

This is expected! The tour framework is implemented but the actual tour steps will be added in stories 20.2-20.6. Currently, there's only a test step visible in DEBUG builds.

### Development Options Not Visible

1. Ensure you're running a DEBUG build
2. Check that `#if DEBUG` preprocessor is working
3. Try cleaning and rebuilding the project

### Testing the Tour Without Steps

To verify the tour framework is working:
1. Use "Test Notification Only" button
2. Check console for log messages
3. The overlay should dim the screen (if steps are configured)

## Future Enhancements

Consider adding:
- Feature flag toggles
- Network request inspector
- Performance metrics display
- UI element inspector
- Database state viewer

Remember: These tools are for development only and should never reach production users.