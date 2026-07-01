import SwiftUI

// MARK: - App Colors
enum AppColors {
    // Backgrounds
    static let background = Color(red: 0.04, green: 0.06, blue: 0.12)
    static let surface = Color(red: 0.08, green: 0.10, blue: 0.18)
    static let surfaceLight = Color(red: 0.12, green: 0.15, blue: 0.24)
    static let cardBackground = Color(red: 0.10, green: 0.13, blue: 0.20)
    static let elevatedBackground = Color(red: 0.14, green: 0.17, blue: 0.26)
    
    // Accent
    static let accentBlue = Color(red: 0.25, green: 0.52, blue: 1.0)
    static let accentBlueLight = Color(red: 0.35, green: 0.62, blue: 1.0)
    static let accentPurple = Color(red: 0.55, green: 0.35, blue: 1.0)
    static let accentPink = Color(red: 1.0, green: 0.35, blue: 0.65)
    static let accentGreen = Color(red: 0.20, green: 0.85, blue: 0.50)
    static let accentOrange = Color(red: 1.0, green: 0.60, blue: 0.20)
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.65)
    static let textTertiary = Color(red: 0.35, green: 0.38, blue: 0.45)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [accentBlue, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [accentOrange, accentPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let coolGradient = LinearGradient(
        colors: [accentBlue, accentGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let authGradient = LinearGradient(
        colors: [
            Color(red: 0.18, green: 0.22, blue: 0.35),
            Color(red: 0.04, green: 0.06, blue: 0.12)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - App Shadows
struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func apply(to view: some View) -> some View {
        view.shadow(color: color, radius: radius, x: x, y: y)
    }
}

enum AppShadows {
    static let small = AppShadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    static let medium = AppShadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    static let large = AppShadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
    static let glow = AppShadow(color: AppColors.accentBlue.opacity(0.3), radius: 20, x: 0, y: 0)
    static let purpleGlow = AppShadow(color: AppColors.accentPurple.opacity(0.3), radius: 20, x: 0, y: 0)
}

extension View {
    func appShadow(_ shadow: AppShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Glass Effect
struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color.black.opacity(0.4)
                    AppColors.glassGradient
                }
            )
            .background(.ultraThinMaterial)
    }
}

extension View {
    func glassBackground() -> some View {
        modifier(GlassBackground())
    }
    
    func cardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    func accentButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.primaryGradient)
            .cornerRadius(16)
            .shadow(color: AppColors.accentBlue.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Animations
enum AppAnimation {
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let slow = Animation.easeInOut(duration: 0.5)
}