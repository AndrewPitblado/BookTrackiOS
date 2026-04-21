//
//  User.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

// MARK: - User DTO

struct UserDTO: Codable, Identifiable, Sendable {
    let id: Int
    let username: String
    let email: String
    let createdAt: String?
    let currentStreak: Int?
    let longestStreak: Int?
    let lastReadingDate: String?
}

// MARK: - User Reading Stats

struct ReadingStreakDTO: Codable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let lastReadingDate: String?
}

struct ReadingStreakResponse: Decodable {
    let streak: ReadingStreakDTO
}

// MARK: - Auth Responses

struct AuthResponseDTO: Decodable {
    let message: String
    let token: String
    let user: UserDTO
}

struct MeResponseDTO: Decodable {
    let user: UserDTO
}
