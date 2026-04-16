//
//  FriendService.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

@MainActor
final class FriendService {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    // MARK: - Friends list

    func getFriends() async throws -> [FriendDTO] {
        let endpoint = Endpoint(path: "friends", method: "GET")
        let response: FriendsListResponse = try await client.send(endpoint)
        return response.friends
    }

    // MARK: - Search

    func searchUsers(query: String) async throws -> [UserSearchResultDTO] {
        let endpoint = Endpoint(path: "friends/search", method: "GET", queryItems: [
            URLQueryItem(name: "username", value: query)
        ])
        let response: UserSearchResponse = try await client.send(endpoint)
        return response.users
    }

    // MARK: - Requests

    func getRequests() async throws -> [FriendshipDTO] {
        let endpoint = Endpoint(path: "friends/requests", method: "GET")
        let response: FriendRequestsResponse = try await client.send(endpoint)
        return response.requests
    }

    func sendRequest(friendId: Int) async throws {
        let body = try JSONBody.encode(["friendId": friendId])
        let endpoint = Endpoint(path: "friends/request", method: "POST", body: body)
        let _: FriendshipActionResponse = try await client.send(endpoint)
    }

    func acceptRequest(id: Int) async throws {
        let endpoint = Endpoint(path: "friends/accept/\(id)", method: "PUT")
        let _: FriendshipActionResponse = try await client.send(endpoint)
    }

    func remove(id: Int) async throws {
        let endpoint = Endpoint(path: "friends/remove/\(id)", method: "DELETE")
        try await client.sendVoid(endpoint)
    }

    // MARK: - Friend Profile

    func getStats(userId: Int) async throws -> FriendStatsResponse {
        let endpoint = Endpoint(path: "friends/\(userId)/stats", method: "GET")
        return try await client.send(endpoint)
    }

    func getBooks(userId: Int) async throws -> [FriendBookDTO] {
        let endpoint = Endpoint(path: "friends/\(userId)/books", method: "GET")
        let response: FriendBooksResponse = try await client.send(endpoint)
        return response.userBooks
    }

    func getAchievements(userId: Int) async throws -> [UserAchievementDTO] {
        let endpoint = Endpoint(path: "friends/\(userId)/achievements", method: "GET")
        let response: FriendAchievementsResponse = try await client.send(endpoint)
        return response.userAchievements
    }
}
