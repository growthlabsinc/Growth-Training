# PaywallContext Ambiguity Fixed

## Problem
- PaywallContext was defined in two places:
  1. `/Growth/Core/Models/PaywallContext.swift` (original)
  2. `/Growth/Core/Models/Analytics/FunnelEvent.swift` (duplicate I added)
- This caused "ambiguous for type lookup" errors
- The `fromString` method was missing from the original

## Solution

### 1. Removed Duplicate Definition
- Removed the duplicate PaywallContext enum from FunnelEvent.swift
- Kept only the original definition in PaywallContext.swift

### 2. Added Missing Methods to Original
Added to PaywallContext.swift:
- `toString()` method that returns the description
- `fromString(_:)` static method for converting strings back to PaywallContext

### 3. Cleaned Up FunnelEvent.swift
- Removed the duplicate PaywallContext extension
- Added comment indicating extensions are in PaywallContext.swift

## Files Modified

### PaywallContext.swift
- Added `toString()` instance method
- Added `fromString(_:)` static method
- These methods handle all cases including feature gates

### FunnelEvent.swift
- Removed duplicate PaywallContext enum definition
- Removed duplicate extension with toString/fromString methods
- Now uses the single definition from PaywallContext.swift

## Result
- No more ambiguity errors
- PaywallContext is defined in one place only
- All required methods (toString, fromString) are available
- FunnelEvent.swift can properly encode/decode PaywallContext