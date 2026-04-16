//
//  AuthService.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}

struct RegisterRequestDTO: Encodable {
    let username: String
    let email: String
    let password: String
}

@MainActor
final class AuthService {
    private let client: NetworkClient
    private let tokenStore: TokenStore

    init(client: NetworkClient, tokenStore: TokenStore) {
        self.client = client
        self.tokenStore = tokenStore
    }

    func login(email: String, password: String) async throws -> UserDTO {
        let body = try JSONBody.encode(LoginRequestDTO(email: email, password: password))
        let endpoint = Endpoint(path: "auth/login", method: "POST", body: body)
        let response: AuthResponseDTO = try await client.send(endpoint)
        try tokenStore.save(accessToken: response.token, refreshToken: nil)
        return response.user
    }

    func register(username: String, email: String, password: String) async throws -> UserDTO {
        let body = try JSONBody.encode(RegisterRequestDTO(username: username, email: email, password: password))
        let endpoint = Endpoint(path: "auth/register", method: "POST", body: body)
        let response: AuthResponseDTO = try await client.send(endpoint)
        try tokenStore.save(accessToken: response.token, refreshToken: nil)
        return response.user
    }

    func me() async throws -> UserDTO {
        let endpoint = Endpoint(path: "auth/me", method: "GET", requiresAuth: true)
        let response: MeResponseDTO = try await client.send(endpoint)
        return response.user
    }

    func logout() {
        try? tokenStore.clear()
    }
}
