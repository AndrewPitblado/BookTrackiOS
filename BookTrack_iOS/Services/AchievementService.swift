//
//  AchievementService.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

@MainActor
final class AchievementService {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    /// Fetch all achievement definitions.
    func getAllAchievements() async throws -> [AchievementDTO] {
        let endpoint = Endpoint(path: "achievements", method: "GET")
        let response: AchievementsListResponse = try await client.send(endpoint)
        return response.achievements
    }

    /// Fetch user's unlocked achievements (triggers server-side reconciliation).
    func getUserAchievements() async throws -> [UserAchievementDTO] {
        let endpoint = Endpoint(path: "achievements/user", method: "GET")
        let response: UserAchievementsResponse = try await client.send(endpoint)
        return response.userAchievements
    }

    /// Fetch progress for all achievements (triggers server-side reconciliation).
    func getProgress() async throws -> [AchievementProgressDTO] {
        let endpoint = Endpoint(path: "achievements/progress", method: "GET")
        let response: AchievementProgressResponse = try await client.send(endpoint)
        return response.progress
    }

    /// Trigger achievement check and return newly unlocked/revoked.
    func checkAchievements() async throws -> CheckAchievementsResponse {
        let endpoint = Endpoint(path: "achievements/check", method: "POST")
        return try await client.send(endpoint)
    }
}
