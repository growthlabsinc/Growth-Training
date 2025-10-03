import SwiftUI

/// A reusable logo component for the Growth app
struct AppLogo: View {
    var size: CGFloat = 80
    var showText: Bool = true
    var textColor: Color = .primary
    
    // Background color matching the app's brand color
    private let backgroundColor = Color(red: 0.039, green: 0.314, blue: 0.259) // #0A5042 (Core Green)
    
    var body: some View {
        VStack(spacing: 8) {
            // Logo with background
            ZStack {
                // Background square with rounded corners
                backgroundColor
                    .frame(width: size, height: size)
                    .cornerRadius(size * 0.25)
                
                // Logo image or fallback to SF Symbol
                if UIImage(named: "Logo") != nil {
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: size * 0.9, height: size * 0.9)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                } else {
                    // Fallback to SF Symbol
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .frame(width: size * 0.6, height: size * 0.6)
                }
            }
            .frame(width: size, height: size)
            
            if showText {
                Text("GROWTH")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(textColor)
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        AppLogo()
        AppLogo(size: 50)
        AppLogo(size: 30, showText: false)
        AppLogo(size: 100, textColor: Color(red: 0.039, green: 0.314, blue: 0.259))
    }
    .padding()
} 