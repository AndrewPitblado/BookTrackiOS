//
//  GoalsService.swift
//  BookTrack_iOS
//
//  Created by Codex on 2026-04-15.
//

import Foundation

@MainActor
final class GoalsService {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func getGoals(activeOnly: Bool = true) async throws -> [GoalDTO] {
        var items: [URLQueryItem] = []
        if activeOnly {
            items.append(.init(name: "activeOnly", value: "true"))
        }

        let endpoint = Endpoint(
            path: "goals",
            method: "GET",
            queryItems: items.isEmpty ? nil : items
        )
        let response: GoalsResponse = try await client.send(endpoint)
        return response.goals
    }

    func createGoal(
        period: GoalPeriod,
        metric: GoalMetric,
        target: Int,
        startDate: String? = nil,
        endDate: String? = nil,
        isActive: Bool = true,
        isPrimary: Bool? = nil
    ) async throws -> GoalDTO {
        let request = CreateGoalRequest(
            period: period,
            metric: metric,
            target: target,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            isPrimary: isPrimary
        )
        let body = try JSONBody.encode(request)
        let endpoint = Endpoint(path: "goals", method: "POST", body: body)
        let response: SingleGoalResponse = try await client.send(endpoint)
        return response.goal
    }

    func updateGoal(
        id: Int,
        target: Int? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        isActive: Bool? = nil,
        isPrimary: Bool? = nil
    ) async throws -> GoalDTO {
        let request = UpdateGoalRequest(
            target: target,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            isPrimary: isPrimary
        )
        let body = try JSONBody.encode(request)
        let endpoint = Endpoint(path: "goals/\(id)", method: "PUT", body: body)
        let response: SingleGoalResponse = try await client.send(endpoint)
        return response.goal
    }

    func deleteGoal(id: Int) async throws {
        let endpoint = Endpoint(path: "goals/\(id)", method: "DELETE")
        try await client.sendVoid(endpoint)
    }
}
