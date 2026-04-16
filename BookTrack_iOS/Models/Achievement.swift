//
//  Achievement.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

// MARK: - Tier

enum AchievementTier: String, Codable, CaseIterable, Comparable {
    case bronze
    case silver
    case gold
    case platinum

    var label: String { rawValue.capitalized }

    var emoji: String {
        switch self {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        case .platinum: return "💎"
        }
    }

    var sortOrder: Int {
        switch self {
        case .platinum: return 0
        case .gold: return 1
        case .silver: return 2
        case .bronze: return 3
        }
    }

    static func < (lhs: AchievementTier, rhs: AchievementTier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Achievement

struct AchievementDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let tier: AchievementTier
    let icon: String?
    let isSecret: Bool
    let points: Int
}

// MARK: - User Achievement (unlocked)

struct UserAchievementDTO: Codable, Identifiable {
    let id: Int
    let userId: Int
    let achievementId: Int
    let unlockedAt: String
    let Achievement: AchievementDTO

    var achievement: AchievementDTO { Achievement }
}

// MARK: - Achievement Progress

struct AchievementProgressDTO: Codable, Identifiable {
    let achievementId: Int
    let name: String
    let description: String?
    let tier: AchievementTier
    let icon: String?
    let isSecret: Bool
    let points: Int
    let unlocked: Bool
    let progress: ProgressInfo

    var id: Int { achievementId }

    struct ProgressInfo: Codable {
        let current: Int
        let target: Int
        let percentage: Double
    }
}

// MARK: - Check Response

struct CheckAchievementsResponse: Decodable {
    let newlyUnlocked: [UserAchievementDTO]?
    let newlyRevoked: [UserAchievementDTO]?
    let message: String
}

// MARK: - Response wrappers

struct AchievementsListResponse: Decodable {
    let achievements: [AchievementDTO]
}

struct UserAchievementsResponse: Decodable {
    let userAchievements: [UserAchievementDTO]
}

struct AchievementProgressResponse: Decodable {
    let progress: [AchievementProgressDTO]
}
