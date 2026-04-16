//
//  NetworkManager.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation
import Security

// MARK: - API Error

enum APIError: LocalizedError {
    case unauthorized
    case badRequest(String)
    case notFound
    case serverError
    case decodingError(Error)
    case networkError(Error)
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please log in again."
        case .badRequest(let message):
            return message
        case .notFound:
            return "Resource not found."
        case .serverError:
            return "Server error. Please try again later."
        case .decodingError:
            return "Unexpected response format."
        case .networkError(let error):
            return error.localizedDescription
        case .unknown(let code):
            return "Unexpected error (HTTP \(code))."
        }
    }
}

// MARK: - Token Store

protocol TokenStore: Sendable {
    func getAccessToken() -> String?
    func save(accessToken: String, refreshToken: String?) throws
    func clear() throws
}

final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account = "access_token"

    init(service: String) {
        self.service = service
    }

    func getAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(accessToken: String, refreshToken: String?) throws {
        // Delete existing first
        try? clear()
        guard let data = accessToken.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let s): return "Keychain save failed (status \(s))"
        case .deleteFailed(let s): return "Keychain delete failed (status \(s))"
        }
    }
}

// MARK: - Endpoint

struct Endpoint {
    let path: String
    let method: String
    var body: Data? = nil
    var queryItems: [URLQueryItem]? = nil
    var requiresAuth: Bool = true

    init(path: String, method: String, body: Data? = nil, queryItems: [URLQueryItem]? = nil, requiresAuth: Bool = true) {
        self.path = path
        self.method = method
        self.body = body
        self.queryItems = queryItems
        self.requiresAuth = requiresAuth
    }
}

// MARK: - JSON Body Helper

enum JSONBody {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(value)
    }
}

// MARK: - Error Response

private struct ErrorResponse: Decodable {
    let message: String
}

// MARK: - Network Client

final class NetworkClient: Sendable {
    let baseURL: URL
    private let tokenStore: TokenStore
    private let session: URLSession
    private let decoder: JSONDecoder

    /// Optional refresh handler (unused for now — single token flow).
    nonisolated(unsafe) var refreshHandler: (() async throws -> Void)?

    init(baseURL: URL, tokenStore: TokenStore, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(0)
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 400:
            if let body = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.badRequest(body.message)
            }
            throw APIError.badRequest("Bad request")
        case 401:
            try? tokenStore.clear()
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }

    /// Fire-and-forget variant for DELETE endpoints that return no meaningful body.
    func sendVoid(_ endpoint: Endpoint) async throws {
        let request = try buildRequest(for: endpoint)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(0)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            if let body = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.badRequest(body.message)
            }
            throw APIError.badRequest("Bad request")
        case 401:
            try? tokenStore.clear()
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }

    // MARK: - Private

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)!
        components.queryItems = endpoint.queryItems

        guard let url = components.url else {
            throw APIError.badRequest("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if endpoint.requiresAuth, let token = tokenStore.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = endpoint.body
        return request
    }
}

// MARK: - Notification

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
}
