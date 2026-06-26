import Flutter
import UIKit

/// VK API Plugin for iOS.
///
/// Чистый VK API клиент на Swift.
/// Использует прямые HTTP-запросы к VK API v5.131.
/// Авторизация через Kate Mobile (bypass audio).
///
/// API v5.131, Kate Mobile User-Agent, GET-запросы к api.vk.ru/method/
public class VkApiPlugin: NSObject, FlutterPlugin {
    
    private let apiBase = "https://api.vk.ru/method"
    private let apiVersion = "5.131"
    private let userAgent = "KateMobileAndroid/56 lite-460 (Android 4.4.2; SDK 19; x86; unknown Android SDK built for x86; en)"
    
    private var accessToken: String?
    private var userId: Int?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vk_api", binaryMessenger: registrar.messenger())
        let instance = VkApiPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setToken":
            let args = call.arguments as? [String: Any]
            accessToken = args?["token"] as? String
            userId = args?["userId"] as? Int
            result(true)
            
        case "call":
            guard let args = call.arguments as? [String: Any],
                  let method = args["method"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "method is required", details: nil))
                return
            }
            let params = args["params"] as? [String: String] ?? [:]
            callVkApi(method: method, params: params, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func callVkApi(method: String, params: [String: String], result: @escaping FlutterResult) {
        guard let token = accessToken else {
            result(FlutterError(code: "NOT_AUTHORIZED", message: "Not authorized", details: nil))
            return
        }
        
        var queryParams = params
        queryParams["access_token"] = token
        queryParams["v"] = apiVersion
        queryParams["lang"] = "ru"
        
        var components = URLComponents(string: "\(apiBase)/\(method)")!
        components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            result(FlutterError(code: "INVALID_URL", message: "Failed to build URL", details: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("ru", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 30
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NETWORK_ERROR", message: error.localizedDescription, details: nil))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_RESPONSE", message: "No response", details: nil))
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                DispatchQueue.main.async {
                    result(FlutterError(code: "HTTP_ERROR", message: "HTTP \(httpResponse.statusCode): \(body)", details: nil))
                }
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "INVALID_JSON", message: "Response is not a JSON object", details: nil))
                    }
                    return
                }
                
                if let error = json["error"] as? [String: Any] {
                    let code = error["error_code"] as? Int ?? 0
                    let msg = error["error_msg"] as? String ?? "Unknown"
                    DispatchQueue.main.async {
                        result(FlutterError(code: "VK_API_ERROR", message: "[\(code)] \(msg)", details: nil))
                    }
                    return
                }
                
                let responseData = json["response"] ?? json
                if let jsonData = try? JSONSerialization.data(withJSONObject: responseData),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    DispatchQueue.main.async {
                        result(jsonString)
                    }
                } else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "SERIALIZE_ERROR", message: "Failed to serialize response", details: nil))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "JSON_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
        task.resume()
    }
}