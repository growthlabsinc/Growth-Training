# Authentication Implementation Notes

## Overview

This document provides information about the authentication system implementation in the Growth app, including known issues and requirements.

## Firestore Integration

The authentication system uses Firebase Authentication for user accounts and Firestore for storing user profile data. The implementation follows these patterns:

- Authentication state management via Combine publishers
- Typed data models that conform to `Codable` for Firestore integration
- Separation of authentication logic from UI via MVVM architecture

## Required Dependencies

The implementation requires the following CocoaPods dependencies:

```ruby
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
pod 'FirebaseFirestoreSwift'  # Required for @DocumentID property wrapper
```

The Podfile has been updated to include these dependencies, but `pod install` needs to be run to complete the setup.

## Resolved Issues

### AuthUser Model

- The `User` model was renamed to `AuthUser` to avoid conflicts with an existing `User` model in `Core/Models/User.swift`.
- This resolved build errors related to duplicate string data files being generated.

### AuthErrorCode Usage

- Fixed issues with `AuthErrorCode` usage in error handling.
- The correct pattern is to use `AuthErrorCode(rawValue: nsError.code)` to extract the error code enum from an NSError.
- This pattern is used in both the authentication (sign in) and account creation methods.

### App Entry Point

- Fixed duplicate `@main` attribute error by:
  - Keeping `@main` only in `GrowthAppApp.swift`
  - Removing `@main` from `GrowthApp.swift`
  - Ensuring proper Firebase initialization happens in the main app entry point.
  
## Temporary Workarounds

### @DocumentID Property Wrapper

The `AuthUser` model ideally should use the `@DocumentID` property wrapper for its `id` field:

```swift
@DocumentID var id: String?
```

However, this requires the `FirebaseFirestoreSwift` pod to be installed. Until the pod installation is completed:

1. The `id` property is temporarily defined without the property wrapper:
   ```swift
   var id: String?
   ```
   
2. A TODO comment has been added to remind developers to update this once the pod is installed.

## Future Enhancements

1. **Complete Pod Installation**: Run `pod install` to complete the setup of all required dependencies.

2. **Update AuthUser Model**: Reintroduce the `@DocumentID` property wrapper for the `id` field in the `AuthUser` model once the pod is installed.

3. **Error Testing**: Consider adding more comprehensive error handling tests, especially for network errors and authentication edge cases.

4. **Biometric Authentication**: Consider adding biometric authentication (Face ID/Touch ID) for a better user experience.

5. **Password Reset**: Implement a password reset flow for users who forget their passwords.

## Usage Notes

When working with the authentication system:

1. Always access the current user via the `AuthViewModel.user` property
2. Subscribe to authentication state changes using the `authStatePublisher`
3. Perform all user-related operations through the `AuthService` protocol
4. Handle authentication errors using the error states provided in the view model

## Future Improvements

- Consider refactoring to use a unified user model that works for both authentication and app features
- Add support for additional authentication methods (social login, phone, etc.)
- Implement more comprehensive profile management features 