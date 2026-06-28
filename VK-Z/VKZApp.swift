import SwiftUI

// MARK: - VK Z App
@main
struct VKZApp: App {
    @State private var isAuthenticated = false
    @State private var isLoading = true
    
    var body: some Scene {
        WindowGroup {
            if isLoading {
                splashScreen
            } else if isAuthenticated {
                MainTabView()
                    .preferredColorScheme(.dark)
            } else {
                VKAuthView()
                    .preferredColorScheme(.dark)
            }
        }
    }
    
    private var splashScreen: some View {
        ZStack {
            Color.vkBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Text("VK Z")
                    .font(.custom("VKSansDisplay-Bold", size: 40))
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .onAppear { checkAuth() }
    }
    
    private func checkAuth() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAuthenticated = VKAuthManager.restoreSession()
            isLoading = false
        }
    }
}