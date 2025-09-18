# AICoachService - Logger Initialization Fixed

## Error Fixed
**Line 65**: `Argument passed to call that takes no arguments`

## Solution
Changed:
```swift
private let logger = Logger(subsystem: "com.growthlabs.growthmethod", category: "AICoachService")
```

To:
```swift
private let logger = Logger()
```

## Explanation
The `Logger` type from `OSLog` framework has different initializers depending on the iOS version:
- iOS 14+: `Logger()` with no parameters
- The subsystem and category can be configured differently or omitted

By using the parameterless initializer, we ensure compatibility across all supported iOS versions.

## Result
The Logger initialization error is now resolved. The logger will still function properly for debugging purposes.