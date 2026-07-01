import Foundation
import Alamofire
import AuthenticationServices

// MARK: - VK API Constants
struct VKApiConstants {
    static let apiVersion = "5.199"
    static let baseUrl = "https://api.vk.com/method/"
    static let authUrl = "https://oauth.vk.com/authorize"
    static let tokenUrl = "https://oauth.vk.com/access_token"
    static let redirectUri = "vk://vkz/auth"
    
    // VK Kate App credentials
    static let clientId = "51632119"
    static let clientSecret = "hTZ3mHq8vKpL5xR7wNfJ2gBc4sYdA6eU"
    
    static let scope = "audio,offline"
}

// MARK: - VK API Service
final class VKApiService {
    static let shared = VKApiService()
    
    private let session: Session
    private var token: String?
    private var userId: Int?
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = Session(configuration: configuration)
    }
    
    // MARK: - Auth
    func configure(token: String, userId: Int) {
        self.token = token
        self.userId = userId
    }
    
    func isAuthenticated() -> Bool {
        return token != nil
    }
    
    func getAuthUrl() -> URL? {
        var components = URLComponents(string: VKApiConstants.authUrl)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: VKApiConstants.clientId),
            URLQueryItem(name: "display", value: "mobile"),
            URLQueryItem(name: "redirect_uri", value: VKApiConstants.redirectUri),
            URLQueryItem(name: "scope", value: VKApiConstants.scope),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "v", value: VKApiConstants.apiVersion),
            URLQueryItem(name: "revoke", value: "1")
        ]
        return components?.url
    }
    
    func handleAuthCallback(url: URL) -> (token: String, userId: Int)? {
        guard let fragment = url.fragment else { return nil }
        let params = fragment
            .components(separatedBy: "&")
            .reduce(into: [String: String]()) { result, pair in
                let parts = pair.components(separatedBy: "=")
                if parts.count == 2 {
                    result[parts[0]] = parts[1]
                }
            }
        
        guard let token = params["access_token"],
              let userIdString = params["user_id"],
              let userId = Int(userIdString) else {
            return nil
        }
        
        self.token = token
        self.userId = userId
        return (token, userId)
    }
    
    // MARK: - Auth by Phone + Password + 2FA
    func authorizeWithLogin(login: String, password: String, twoFactorCode: @escaping (@escaping (String) -> Void) -> Void) async throws {
        let url = URL(string: "https://api.vk.com/method/auth.login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("VK-Z/1.0 (iPhone; iOS 17.0; Scale/3.0)", forHTTPHeaderField: "User-Agent")
        
        // Build form body
        var bodyComponents = URLComponents()
        var queryItems = [
            URLQueryItem(name: "client_id", value: VKApiConstants.clientId),
            URLQueryItem(name: "client_secret", value: VKApiConstants.clientSecret),
            URLQueryItem(name: "username", value: login),
            URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "v", value: VKApiConstants.apiVersion),
            URLQueryItem(name: "scope", value: VKApiConstants.scope),
            URLQueryItem(name: "grant_type", value: "password")
        ]
        bodyComponents.queryItems = queryItems
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        
        // First attempt without 2FA
        var (data, _) = try await URLSession.shared.data(for: request)
        var response = try JSONDecoder().decode(VKAuthResponse.self, from: data)
        
        // If 2FA required
        if response.error == "need_validation" || response.validationType == "2fa" || response.error == "need_captcha" {
            let code = await withCheckedContinuation { continuation in
                twoFactorCode { code in
                    continuation.resume(returning: code)
                }
            }
            
            // Add 2FA code and retry
            queryItems.append(URLQueryItem(name: "code", value: code))
            bodyComponents.queryItems = queryItems
            request.httpBody = bodyComponents.query?.data(using: .utf8)
            
            (data, _) = try await URLSession.shared.data(for: request)
            response = try JSONDecoder().decode(VKAuthResponse.self, from: data)
        }
        
        // Check for error response
        if let error = response.error {
            throw VKError.apiError(error)
        }
        
        guard let accessToken = response.accessToken, let uid = response.userId else {
            throw VKError.apiError("Не удалось получить токен. Проверьте логин и пароль.")
        }
        
        self.token = accessToken
        self.userId = uid
        
        // Save to UserDefaults
        UserDefaults.standard.set(accessToken, forKey: "vk_access_token")
        UserDefaults.standard.set(uid, forKey: "vk_user_id")
    }
    
    // MARK: - API Requests
    private func request<T: Codable>(
        _ method: String,
        parameters: [String: Any] = [:],
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let token = token else {
            completion(.failure(VKError.notAuthenticated))
            return
        }
        
        var params = parameters
        params["access_token"] = token
        params["v"] = VKApiConstants.apiVersion
        
        let url = VKApiConstants.baseUrl + method
        
        session.request(url, method: .post, parameters: params)
            .validate()
            .responseDecodable(of: VKApiResponse<T>.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    if let error = apiResponse.error {
                        completion(.failure(VKError.apiError(error.errorMsg)))
                    } else if let data = apiResponse.response {
                        completion(.success(data))
                    } else {
                        completion(.failure(VKError.noData))
                    }
                case .failure(let error):
                    completion(.failure(VKError.networkError(error.localizedDescription)))
                }
            }
    }
    
    // MARK: - Audio Methods
    
    /// Получить аудиозаписи пользователя
    func getAudio(
        userId: Int? = nil,
        offset: Int = 0,
        count: Int = 50,
        completion: @escaping (Result<[VKTrack], Error>) -> Void
    ) {
        var params: [String: Any] = [
            "offset": offset,
            "count": count
        ]
        if let userId = userId {
            params["owner_id"] = userId
        }
        
        request("audio.get", parameters: params) { (result: Result<VKMusicResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Получить плейлисты пользователя
    func getPlaylists(
        userId: Int? = nil,
        offset: Int = 0,
        count: Int = 50,
        completion: @escaping (Result<[VKPlaylist], Error>) -> Void
    ) {
        var params: [String: Any] = [
            "offset": offset,
            "count": count
        ]
        if let userId = userId {
            params["owner_id"] = userId
        }
        
        request("audio.get_playlists", parameters: params) { (result: Result<VKPlaylistsResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Получить треки плейлиста
    func getPlaylistTracks(
        playlistId: Int,
        ownerId: Int,
        accessKey: String? = nil,
        offset: Int = 0,
        count: Int = 100,
        completion: @escaping (Result<[VKTrack], Error>) -> Void
    ) {
        var params: [String: Any] = [
            "playlist_id": playlistId,
            "owner_id": ownerId,
            "offset": offset,
            "count": count
        ]
        if let accessKey = accessKey {
            params["access_key"] = accessKey
        }
        
        request("audio.get_playlist_tracks", parameters: params) { (result: Result<VKMusicResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Поиск аудиозаписей
    func searchAudio(
        query: String,
        offset: Int = 0,
        count: Int = 50,
        completion: @escaping (Result<[VKTrack], Error>) -> Void
    ) {
        let params: [String: Any] = [
            "q": query,
            "offset": offset,
            "count": count,
            "autocomplete": 1,
            "sort": 2
        ]
        
        request("audio.search", parameters: params) { (result: Result<VKSearchResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Получить рекомендации
    func getRecommendations(
        count: Int = 30,
        completion: @escaping (Result<[VKTrack], Error>) -> Void
    ) {
        let params: [String: Any] = ["count": count]
        
        request("audio.get_recommendations", parameters: params) { (result: Result<VKMusicResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Получить популярное
    func getPopular(
        genreId: Int? = nil,
        count: Int = 30,
        completion: @escaping (Result<[VKTrack], Error>) -> Void
    ) {
        var params: [String: Any] = ["count": count]
        if let genreId = genreId {
            params["genre_id"] = genreId
        }
        
        request("audio.get_popular", parameters: params) { (result: Result<VKMusicResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Получить каталог
    func getCatalog(
        completion: @escaping (Result<[VKCatalogSection], Error>) -> Void
    ) {
        request("audio.get_catalog", parameters: [:]) { (result: Result<[VKCatalogSection], Error>) in
            switch result {
            case .success(let sections):
                completion(.success(sections))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - VK Mix Methods
    
    /// Получить список миксов
    func getMixes(
        count: Int = 20,
        completion: @escaping (Result<[VKMix], Error>) -> Void
    ) {
        let params: [String: Any] = [
            "count": count
        ]
        
        request("audio.get_mixes", parameters: params) { (result: Result<VKMixResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Получить треки микса
    func getMixTracks(
        mixId: String,
        count: Int = 30,
        completion: @escaping (Result<[VKTrack], Error>) -> Void
    ) {
        let params: [String: Any] = [
            "mix_id": mixId,
            "count": count
        ]
        
        request("audio.get_mix_tracks", parameters: params) { (result: Result<VKMixTracksResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Создать микс на основе трека
    func createMix(
        trackId: Int,
        ownerId: Int,
        count: Int = 30,
        completion: @escaping (Result<[VKTrack], Error>) -> Void
    ) {
        let params: [String: Any] = [
            "track_id": trackId,
            "owner_id": ownerId,
            "count": count
        ]
        
        request("audio.create_mix", parameters: params) { (result: Result<VKMixTracksResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Auth Response Models
struct VKAuthResponse: Decodable {
    let accessToken: String?
    let userId: Int?
    let error: String?
    let errorCode: Int?
    let validationType: String?
    let validationSid: String?
    let phoneMask: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case userId = "user_id"
        case error = "error"
        case errorCode = "error_code"
        case validationType = "validation_type"
        case validationSid = "validation_sid"
        case phoneMask = "phone_mask"
    }
}

// MARK: - Errors
enum VKError: LocalizedError {
    case notAuthenticated
    case apiError(String)
    case networkError(String)
    case noData
    case invalidUrl
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Не авторизован. Пожалуйста, войдите в VK."
        case .apiError(let message):
            return "Ошибка VK API: \(message)"
        case .networkError(let message):
            return "Ошибка сети: \(message)"
        case .noData:
            return "Нет данных от сервера"
        case .invalidUrl:
            return "Некорректный URL"
        }
    }
}