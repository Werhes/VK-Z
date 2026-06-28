import SwiftUI
import AuthenticationServices
import WebKit

// MARK: - VK Auth View
struct VKAuthView: View {
    @StateObject private var authManager = VKAuthManager()
    @State private var showWebView = false
    @State private var authMode: AuthMode = .token
    @State private var tokenInput = ""
    @State private var phoneInput = ""
    @State private var passwordInput = ""
    @State private var twoFactorCode = ""
    @State private var showTwoFactor = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var twoFactorContinuation: ((String) -> Void)?
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var contentOffset: CGFloat = 50
    
    enum AuthMode: String, CaseIterable {
        case token = "По токену"
        case phone = "По телефону"
    }
    
    var body: some View {
        ZStack {
            AppColors.authGradient.ignoresSafeArea()
            
            // Animated background circles
            ZStack {
                Circle()
                    .fill(AppColors.accentBlue.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -120, y: -200)
                
                Circle()
                    .fill(AppColors.accentPurple.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: 140, y: -150)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 60)
                    
                    // Logo
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: AppColors.accentBlue.opacity(0.4), radius: 25, y: 8)
                            
                            Image(systemName: "music.note.list")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        
                        Text("VK Z")
                            .font(.custom("VKSansDisplay-Bold", size: 36))
                            .foregroundColor(.white)
                            .opacity(logoOpacity)
                        
                        Text("Музыка ВКонтакте\nбез ограничений")
                            .font(.custom("VKSansDisplay-Regular", size: 15))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .opacity(logoOpacity)
                    }
                    .offset(y: contentOffset)
                    
                    Spacer().frame(height: 10)
                    
                    // Auth mode picker
                    Picker("Способ входа", selection: $authMode) {
                        ForEach(AuthMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)
                    .offset(y: contentOffset)
                    .opacity(logoOpacity)
                    
                    // Token input
                    if authMode == .token {
                        VStack(spacing: 12) {
                            Text("Введите токен доступа")
                                .font(.custom("VKSansDisplay-Regular", size: 13))
                                .foregroundColor(AppColors.textSecondary)
                            
                            SecureField("Токен VK", text: $tokenInput)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(AppColors.surfaceLight)
                                .cornerRadius(14)
                                .foregroundColor(.white)
                                .font(.custom("VKSansDisplay-Regular", size: 15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 40)
                        .offset(y: contentOffset)
                        .opacity(logoOpacity)
                    }
                    
                    // Phone + Password input
                    if authMode == .phone {
                        VStack(spacing: 12) {
                            TextField("Номер телефона", text: $phoneInput)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(AppColors.surfaceLight)
                                .cornerRadius(14)
                                .foregroundColor(.white)
                                .font(.custom("VKSansDisplay-Regular", size: 15))
                                .keyboardType(.phonePad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                            
                            SecureField("Пароль", text: $passwordInput)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(AppColors.surfaceLight)
                                .cornerRadius(14)
                                .foregroundColor(.white)
                                .font(.custom("VKSansDisplay-Regular", size: 15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 40)
                        .offset(y: contentOffset)
                        .opacity(logoOpacity)
                        
                        // 2FA Code Input
                        if showTwoFactor {
                            VStack(spacing: 8) {
                                Text("Код двухфакторной авторизации")
                                    .font(.custom("VKSansDisplay-Regular", size: 13))
                                    .foregroundColor(AppColors.accentOrange)
                                
                                TextField("Код", text: $twoFactorCode)
                                    .textFieldStyle(.plain)
                                    .padding(14)
                                    .background(AppColors.surfaceLight)
                                    .cornerRadius(14)
                                    .foregroundColor(.white)
                                    .font(.custom("VKSansDisplay-Regular", size: 15))
                                    .keyboardType(.numberPad)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(AppColors.accentOrange.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 40)
                            .offset(y: contentOffset)
                            .opacity(logoOpacity)
                        }
                    }
                    
                    // WebView auth button
                    if authMode == .token {
                        Button(action: { showWebView = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "vk")
                                    .font(.title2)
                                Text("Войти через VK")
                                    .font(.custom("VKSansDisplay-Medium", size: 17))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.primaryGradient)
                            .cornerRadius(16)
                            .shadow(color: AppColors.accentBlue.opacity(0.3), radius: 12, y: 6)
                        }
                        .padding(.horizontal, 40)
                        .offset(y: contentOffset)
                        .opacity(logoOpacity)
                    }
                    
                    // Login button
                    Button(action: performAuth) {
                        Text(authMode == .token ? "Войти по токену" : showTwoFactor ? "Отправить код 2FA" : "Войти")
                            .font(.custom("VKSansDisplay-Medium", size: 17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [AppColors.accentBlue.opacity(0.8), AppColors.accentBlue.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                    .disabled(isLoading)
                    .offset(y: contentOffset)
                    .opacity(logoOpacity)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.custom("VKSansDisplay-Regular", size: 13))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Text("v1.0 · by Werhes")
                        .font(.custom("VKSansDisplay-Regular", size: 12))
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.bottom, 20)
                }
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
                contentOffset = 0
            }
        }
    }
    
    private func performAuth() {
        isLoading = true
        errorMessage = nil
        
        if authMode == .token {
            let token = tokenInput.trimmingCharacters(in: .whitespaces)
            guard !token.isEmpty else {
                errorMessage = "Введите токен доступа"
                isLoading = false
                return
            }
            VKApiService.shared.configure(token: token, userId: 0)
            authManager.saveToken(token, userId: 0)
            authManager.isAuthenticated = true
            isLoading = false
        } else {
            let phone = phoneInput.trimmingCharacters(in: .whitespaces)
            let password = passwordInput
            
            guard !phone.isEmpty, !password.isEmpty else {
                errorMessage = "Введите номер телефона и пароль"
                isLoading = false
                return
            }
            
            if showTwoFactor, let continuation = twoFactorContinuation {
                let code = twoFactorCode.trimmingCharacters(in: .whitespaces)
                guard !code.isEmpty else {
                    errorMessage = "Введите код двухфакторной авторизации"
                    isLoading = false
                    return
                }
                continuation(code)
                twoFactorContinuation = nil
                showTwoFactor = false
                twoFactorCode = ""
                isLoading = false
                return
            }
            
            Task {
                do {
                    try await VKApiService.shared.authorizeWithLogin(
                        login: phone,
                        password: password,
                        twoFactorCode: { completion in
                            DispatchQueue.main.async {
                                self.showTwoFactor = true
                                self.twoFactorContinuation = completion
                                self.isLoading = false
                            }
                        }
                    )
                    
                    await MainActor.run {
                        let token = UserDefaults.standard.string(forKey: "vk_access_token") ?? ""
                        let userId = UserDefaults.standard.integer(forKey: "vk_user_id")
                        VKApiService.shared.configure(token: token, userId: userId)
                        authManager.saveToken(token, userId: userId)
                        authManager.isAuthenticated = true
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isLoading = false
                    }
                }
            }
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
    
    func saveToken(_ token: String, userId: Int) {
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