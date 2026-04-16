//
//  Friend.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

// MARK: - User Search Result

struct UserSearchResultDTO: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let createdAt: String
    let friendshipStatus: String?
    let isPending: Bool?
    let isFriend: Bool?
    let requestSentByMe: Bool?
}

struct UserSearchResponse: Decodable {
    let users: [UserSearchResultDTO]
}

// MARK: - Friendship / Friend Request

struct FriendshipDTO: Codable, Identifiable {
    let id: Int
    let userId: Int
    let friendId: Int
    let status: String
    let createdAt: String?
    let user: FriendUserDTO?

    struct FriendUserDTO: Codable {
        let id: Int
        let username: String
        let email: String
        let createdAt: String
    }
}

struct FriendRequestsResponse: Decodable {
    let requests: [FriendshipDTO]
}

struct FriendshipActionResponse: Decodable {
    let message: String
}

// MARK: - Friend (from GET /friends)

struct FriendDTO: Codable, Identifiable {
    let friendshipId: Int
    let id: Int
    let username: String
    let email: String
    let createdAt: String
}

struct FriendsListResponse: Decodable {
    let friends: [FriendDTO]
}

// MARK: - Friend Profile

struct FriendStatsDTO: Decodable {
    let reading: Int
    let finished: Int
    let achievements: Int
    let totalPoints: Int
}

struct FriendStatsResponse: Decodable {
    let user: FriendProfileUserDTO
    let stats: FriendStatsDTO
}

struct FriendProfileUserDTO: Decodable {
    let id: Int
    let username: String
    let createdAt: String
}

// Friend's books reuse UserBookDTO from UserBook.swift
struct FriendBooksResponse: Decodable {
    let userBooks: [FriendBookDTO]
}

struct FriendBookDTO: Decodable, Identifiable {
    let id: Int
    let status: String
    let currentPage: Int?
    let rating: Double?
    let notes: String?
    let Book: BookDTO?

    var book: BookDTO? { Book }
}

// Friend's achievements reuse UserAchievementDTO from Achievement.swift
struct FriendAchievementsResponse: Decodable {
    let userAchievements: [UserAchievementDTO]
}
