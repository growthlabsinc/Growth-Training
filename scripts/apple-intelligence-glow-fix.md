# Apple Intelligence Glow Effect Fix

## Problem
The Apple Intelligence glow effect on the Today's Progress card was rotating the entire rectangular shape instead of having the glow sweep around the edge of a stationary border.

## Root Cause
The previous implementation used `.rotationEffect(.degrees(rotationAngle))` on the entire ZStack containing all glow layers, which caused the whole shape to spin like a rotating rectangle.

## Solution
Changed from LinearGradient with rotation to AngularGradient (conic gradient) that sweeps around the border:

### Before:
```swift
RoundedRectangle(cornerRadius: cornerRadius)
    .strokeBorder(
        LinearGradient(
            gradient: animatedGradient(offset: offset),
            startPoint: gradientStartPoint,
            endPoint: gradientEndPoint
        ),
        lineWidth: width
    )
// Plus rotation effect on the entire ZStack
.rotationEffect(.degrees(rotationAngle))
```

### After:
```swift
RoundedRectangle(cornerRadius: cornerRadius)
    .stroke(
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Color("GrowthGreen").opacity(0.3), location: 0.1),
                .init(color: Color("BrightTeal").opacity(0.6), location: 0.2),
                .init(color: Color("MintGreen"), location: 0.3),
                .init(color: Color("BrightTeal").opacity(0.6), location: 0.4),
                .init(color: Color("GrowthGreen").opacity(0.3), location: 0.5),
                .init(color: .clear, location: 0.6),
                .init(color: .clear, location: 1.0)
            ]),
            center: .center,
            angle: .degrees((animationProgress + offset) * 360)
        ),
        lineWidth: width
    )
// No rotation effect on the shape itself
```

## Key Changes

1. **Removed rotationAngle state variable** - No longer needed
2. **Changed from LinearGradient to AngularGradient** - Creates a conic gradient
3. **Removed .rotationEffect() modifier** - Shape stays stationary
4. **Animated the angle parameter** - The gradient sweeps around the border
5. **Added gradient stops** - Creates a soft glow that fades at the edges

## Visual Effect
- The border shape remains stationary
- A glowing light sweeps around the edge of the border
- Multiple layers with different blur levels create depth
- Smooth fade in/out at the leading and trailing edges of the glow

## Performance
- More efficient than rotating the entire shape
- Uses native SwiftUI gradient rendering
- Reduced computational overhead

## Usage
The same `.appleIntelligenceGlow()` modifier works everywhere:
- Timer bezels (circular)
- Progress cards (rectangular)
- Any other shape with rounded corners

The effect automatically adapts to the shape's corner radius.