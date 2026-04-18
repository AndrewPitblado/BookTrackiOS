import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
final class PushNotificationManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var deviceToken: String?

    private let client: NetworkClient
    private var cancellable: AnyCancellable?

    init(client: NetworkClient) {
        self.client = client

        // Listen for device token from AppDelegate
        cancellable = NotificationCenter.default
            .publisher(for: .didReceiveDeviceToken)
            .compactMap { $0.userInfo?["token"] as? String }
            .receive(on: RunLoop.main)
            .sink { [weak self] token in
                self?.deviceToken = token
                Task { [weak self] in
                    await self?.registerTokenWithServer(token)
                }
            }
    }

    /// Request notification permission and register for remote notifications.
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
        }
    }

    /// Check current authorization status (e.g. on app launch).
    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized

        if isAuthorized {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// Send device token to backend.
    func registerTokenWithServer(_ token: String) async {
        do {
            let body = try JSONBody.encode(["token": token, "platform": "ios"])
            let endpoint = Endpoint(path: "device-tokens", method: "POST", body: body)
            try await client.sendVoid(endpoint)
            print("Device token registered with server")
        } catch {
            print("Failed to register device token: \(error.localizedDescription)")
        }
    }

    /// Remove device token from backend (call on logout).
    func unregisterToken() async {
        guard let token = deviceToken else { return }
        do {
            let body = try JSONBody.encode(["token": token])
            let endpoint = Endpoint(path: "device-tokens", method: "DELETE", body: body)
            try await client.sendVoid(endpoint)
            print("Device token unregistered from server")
        } catch {
            print("Failed to unregister device token: \(error.localizedDescription)")
        }
    }
}
