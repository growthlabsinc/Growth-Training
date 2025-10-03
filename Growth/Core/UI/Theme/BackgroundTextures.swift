import SwiftUI

/// A collection of subtle background textures used in the Growth app.
/// These are intentionally light so they do not distract from content.
/// Usage: `BackgroundTexture.dotPattern` or embed `DotPatternBackground()` view.
///
/// Story 14.1 – Visual Design Refresh.
public enum BackgroundTexture {
    /// A tiny dot pattern rendered with ultra-thin opacity.
    public static var dotPattern: some View {
        DotPatternBackground()
    }
}

/// A view that renders an endlessly tiling dot pattern.
/// The dots automatically adapt to dark/light mode by using secondary label color.
private struct DotPatternBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    private let dotSize: CGFloat = 2
    private let spacing: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            let columns = Int(proxy.size.width / spacing)
            let rows = Int(proxy.size.height / spacing)

            Canvas { context, size in
                let color = Color.secondary.opacity(colorScheme == .dark ? 0.08 : 0.04)
                for row in 0...rows {
                    for column in 0...columns {
                        let x = CGFloat(column) * spacing
                        let y = CGFloat(row) * spacing
                        let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                        context.fill(Path(ellipseIn: rect), with: .color(color))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#if DEBUG
struct BackgroundTexture_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundTexture.dotPattern
            Text("Subtle Background")
                .font(AppTheme.Typography.title1Font())
        }
    }
}
#endif 