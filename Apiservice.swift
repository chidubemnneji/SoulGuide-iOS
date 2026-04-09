import Foundation

class APIService {
    static let shared = APIService()
    let base = "https://spirit-guide-ai-production.up.railway.app"

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.httpCookieAcceptPolicy = .always
        c.httpShouldSetCookies = true
        c.httpCookieStorage = HTTPCookieStorage.shared
        return URLSession(configuration: c)
    }()

    func request<T: Decodable>(path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: base + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 { throw APIError.unauthorized }
        if http.statusCode >= 400 { throw APIError.serverError(http.statusCode) }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    func streamChat(conversationId: Int, content: String, mood: String? = nil) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let url = URL(string: "\(base)/api/conversations/\(conversationId)/messages") else {
                    continuation.finish(throwing: APIError.invalidURL); return
                }
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                var bodyDict: [String: Any] = ["content": content]
                if let mood = mood { bodyDict["mood"] = mood }
                req.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)
                do {
                    let (bytes, _) = try await session.bytes(for: req)
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let json = String(line.dropFirst(6))
                            if json == "[DONE]" { break }
                            if let d = json.data(using: .utf8),
                               let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                                if let c = obj["content"] as? String { continuation.yield(c) }
                                if let done = obj["done"] as? Bool, done { break }
                            }
                        }
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL, invalidResponse, unauthorized, serverError(Int)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .unauthorized: return "Please sign in again"
        case .serverError(let c): return "Server error \(c)"
        }
    }
}

    func requestVoid(path: String, method: String = "DELETE") async throws {
        guard let url = URL(string: base + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 { throw APIError.unauthorized }
        if http.statusCode >= 400 { throw APIError.serverError(http.statusCode) }
    }
