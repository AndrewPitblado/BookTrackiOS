//
//  AuthViewModel.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published var user: UserDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isAuthenticated: Bool { user != nil }

    private let authService: AuthService
    private let tokenStore: TokenStore
    private var cancellable: AnyCancellable?

    init(authService: AuthService, tokenStore: TokenStore) {
        self.authService = authService
        self.tokenStore = tokenStore

        // Listen for 401 notifications from NetworkClient
        cancellable = NotificationCenter.default
            .publisher(for: .authSessionExpired)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.user = nil
            }
    }

    /// No-argument initialiser for SwiftUI previews.
    init() {
        let tokenStore = KeychainTokenStore(service: "com.booktrack.ios.preview")
        let client = NetworkClient(
            baseURL: URL(string: "http://localhost:5001/api")!,
            tokenStore: tokenStore
        )
        self.authService = AuthService(client: client, tokenStore: tokenStore)
        self.tokenStore = tokenStore
    }

    /// Called once on app launch to restore session from Keychain token.
    func bootstrap() async {
        guard tokenStore.getAccessToken() != nil else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await authService.me()
        } catch {
            // Token invalid or expired — clear it
            try? tokenStore.clear()
            user = nil
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            user = try await authService.login(email: email, password: password)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register(username: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            user = try await authService.register(username: username, email: email, password: password)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var pushManager: PushNotificationManager?

    func logout() {
        Task { await pushManager?.unregisterToken() }
        authService.logout()
        user = nil
    }

    func clearError() {
        errorMessage = nil
    }
}
