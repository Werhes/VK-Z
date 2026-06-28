import SwiftUI
import AuthenticationServices
import WebKit

// MARK: - VK Auth View
struct VKAuthView: View {
    @StateObject private var authManager = VKAuthManager()
    @State private var showWebView = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.20, blue: 0.30),
                    Color(red: 0.05, green: 0.08, blue: 0.15)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("VK Z")
                        .font(.custom("VKSansDisplay-Bold", size: 42))
                        .foregroundColor(.white)
                    
                    Text("Музыка ВКонтакте\nбез ограничений")
                        .font(.custom("VKSansDisplay-Regular", size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                Button(action: { showWebView = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "vk")
                            .font(.title2)
                        Text("Войти через VK")
                            .font(.custom("VKSansDisplay-Medium", size: 17))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.4), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .disabled(authManager.isLoading)
                
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
                
                if let error = authManager.error {
                    Text(error)
                        .font(.custom("VKSansDisplay-Regular", size: 13))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Text("v1.0 · by Werhes")
                    .font(.custom("VKSansDisplay-Regular", size: 12))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showWebView) {
            VKAuthWebView(
                url: VKApiService.shared.getAuthUrl()!,
                onTokenReceived: { token, userId in
                    authManager.handleToken(token: token, userId: userId)
                }
            )
        }
        .onOpenURL { url in
            authManager.handleUrl(url)
        }
    }
}

// MARK: - Auth Manager
final class VKAuthManager: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var isAuthenticated = false
    
    func handleUrl(_ url: URL) {
        isLoading = true
        error = nil
        
        if let result = VKApiService.shared.handleAuthCallback(url: url) {
            VKApiService.shared.configure(token: result.token, userId: result.userId)
            saveToken(result.token, userId: result.userId)
            isAuthenticated = true
        } else {
            error = "Не удалось авторизоваться"
        }
        
        isLoading = false
    }
    
    func handleToken(token: String, userId: Int) {
        isLoading = true
        error = nil
        
        VKApiService.shared.configure(token: token, userId: userId)
        saveToken(token, userId: userId)
        isAuthenticated = true
        
        isLoading = false
    }
    
    private func saveToken(_ token: String, userId: Int) {
        UserDefaults.standard.set(token, forKey: "vk_access_token")
        UserDefaults.standard.set(userId, forKey: "vk_user_id")
    }
    
    static func restoreSession() -> Bool {
        guard let token = UserDefaults.standard.string(forKey: "vk_access_token"),
              let userId = UserDefaults.standard.object(forKey: "vk_user_id") as? Int else {
            return false
        }
        VKApiService.shared.configure(token: token, userId: userId)
        return true
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "vk_access_token")
        UserDefaults.standard.removeObject(forKey: "vk_user_id")
        isAuthenticated = false
    }
}

// MARK: - WebView for VK Auth
struct VKAuthWebView: UIViewRepresentable {
    let url: URL
    let onTokenReceived: (String, Int) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: VKAuthWebView
        
        init(_ parent: VKAuthWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.absoluteString.hasPrefix("vk://vkz/auth") {
                
                if let fragment = url.fragment {
                    let params = fragment
                        .components(separatedBy: "&")
                        .reduce(into: [String: String]()) { result, pair in
                            let parts = pair.components(separatedBy: "=")
                            if parts.count == 2 {
                                result[parts[0]] = parts[1]
                            }
                        }
                    
                    if let token = params["access_token"],
                       let userIdString = params["user_id"],
                       let userId = Int(userIdString) {
                        parent.onTokenReceived(token, userId)
                    }
                }
                
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
    }
}

#Preview {
    VKAuthView()
}