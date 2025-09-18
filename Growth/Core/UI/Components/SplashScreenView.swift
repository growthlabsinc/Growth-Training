import SwiftUI

struct SplashScreenView: View {
    /// Action to perform when the user taps the "Get Started" button (navigates to account creation)
    var onGetStarted: () -> Void
    
    /// Action to perform when the user taps the "Log in" button
    var onLogin: () -> Void
    
    // Use AppTheme font
    private let titleFont = AppTheme.Typography.gravityBoldFont(48)

    var body: some View {
        ZStack {
            // Background image
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title at top of page with blurred shadow
                Text("GROWTH")
                    .font(titleFont)
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.6), radius: 15, x: 0, y: 0) // Blurred shadow with no offset
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 0)  // Additional shadow for depth
                    .padding(.top, 30)
                
                Spacer()
                
                // Bottom third - Card with content
                VStack(spacing: 24) {
                    // Headline text on separate lines
                    VStack(spacing: 0) {
                        Text("Grow Stronger,")
                            .font(AppTheme.Typography.gravityBoldFont(32))
                            .foregroundColor(.white)
                        
                        Text("Live Better")
                            .font(AppTheme.Typography.gravityBoldFont(32))
                            .foregroundColor(.white)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    
                    // Subtitle text
                    Text("YOUR GROWTH JOURNEY IS ABOUT TO BEGIN")
                        .font(AppTheme.Typography.gravitySemibold(16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                    
                    // Primary button
                    Button(action: onGetStarted) {
                        Text("GET STARTED")
                            .font(AppTheme.Typography.gravityBoldFont(18))
                            .foregroundColor(Color("GrowthGreen"))
                            .frame(width: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 20)
                    
                    // Subtle login button
                    Button(action: onLogin) {
                        Text("Already have an account? Log in")
                            .font(AppTheme.Typography.gravityBook(16))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 8)
                    }
                    .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
                .cornerRadius(40, corners: [.topLeft, .topRight])
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// Extension to allow rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    SplashScreenView(
        onGetStarted: {},
        onLogin: {}
    )
} 