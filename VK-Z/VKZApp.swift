import SwiftUI

// MARK: - VK Z App
@main
struct VKZApp: App {
    @State private var isAuthenticated = false
    @State private var isLoading = true
    @State private var splashOpacity: Double = 1.0
    @State private var splashScale: CGFloat = 1.0
    
    var body: some Scene {
        WindowGroup {
            if isLoading {
                splashScreen
                    .transition(.opacity)
            } else if isAuthenticated {
                MainTabView()
                    .preferredColorScheme(.dark)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else {
                VKAuthView()
                    .preferredColorScheme(.dark)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
        }
    }
    
    private var splashScreen: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Animated logo icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accentBlue, AppColors.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: AppColors.accentBlue.opacity(0.4), radius: 30, y: 10)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                .scaleEffect(splashScale)
                .opacity(splashOpacity)
                
                Text("VK Z")
                    .font(.custom("VKSansDisplay-Bold", size: 42))
                    .foregroundColor(.white)
                    .opacity(splashOpacity)
                
                Text("Музыка без границ")
                    .font(.custom("VKSansDisplay-Regular", size: 15))
                    .foregroundColor(.gray)
                    .opacity(splashOpacity)
                
                Spacer()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                    .scaleEffect(1.2)
                    .padding(.bottom, 60)
                    .opacity(splashOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                splashScale = 1.0
                splashOpacity = 1.0
            }
            checkAuth()
        }
    }
    
    private func checkAuth() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                splashOpacity = 0
                splashScale = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isAuthenticated = VKAuthManager.restoreSession()
                isLoading = false
            }
        }
    }
}