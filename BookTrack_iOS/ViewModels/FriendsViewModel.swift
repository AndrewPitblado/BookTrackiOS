//
//  FriendsViewModel.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-16.
//

import Combine
import Foundation

enum FriendsTab: String, CaseIterable, Identifiable {
    case friends = "My Friends"
    case requests = "Requests"
    case search = "Find Friends"

    var id: String { rawValue }
}

@MainActor
final class FriendsViewModel: ObservableObject {
    // MARK: - Published state

    @Published var activeTab: FriendsTab = .friends
    @Published var friends: [FriendDTO] = []
    @Published var requests: [FriendshipDTO] = []
    @Published var searchResults: [UserSearchResultDTO] = []
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service: FriendService

    init(service: FriendService) {
        self.service = service
    }

    // MARK: - Friends

    func loadFriends() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            friends = try await service.getFriends()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Requests

    func loadRequests() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            requests = try await service.getRequests()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search

    func searchUsers() async {
        guard searchQuery.count >= 2 else {
            errorMessage = "Enter at least 2 characters"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            searchResults = try await service.searchUsers(query: searchQuery)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Actions

    func sendRequest(to userId: Int) async {
        do {
            try await service.sendRequest(friendId: userId)
            successMessage = "Friend request sent!"
            await searchUsers() // refresh status badges
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptRequest(_ id: Int) async {
        do {
            try await service.acceptRequest(id: id)
            successMessage = "Friend request accepted!"
            await loadRequests()
            await loadFriends()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rejectRequest(_ id: Int) async {
        do {
            try await service.remove(id: id)
            successMessage = "Request rejected"
            await loadRequests()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(_ friendshipId: Int) async {
        do {
            try await service.remove(id: friendshipId)
            successMessage = "Friend removed"
            await loadFriends()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Friend Profile ViewModel

@MainActor
final class FriendProfileViewModel: ObservableObject {
    @Published var user: FriendProfileUserDTO?
    @Published var stats: FriendStatsDTO?
    @Published var books: [FriendBookDTO] = []
    @Published var achievements: [UserAchievementDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: FriendService
    let userId: Int

    init(service: FriendService, userId: Int) {
        self.service = service
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let statsReq = service.getStats(userId: userId)
            async let booksReq = service.getBooks(userId: userId)
            async let achievementsReq = service.getAchievements(userId: userId)

            let (statsResponse, booksResponse, achievementsResponse) = try await (statsReq, booksReq, achievementsReq)

            user = statsResponse.user
            stats = statsResponse.stats
            books = booksResponse
            achievements = achievementsResponse
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
