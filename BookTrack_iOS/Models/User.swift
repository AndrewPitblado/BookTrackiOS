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
