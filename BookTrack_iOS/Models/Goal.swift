//
//  Goal.swift
//  BookTrack_iOS
//
//  Created by Codex on 2026-04-15.
//

import Foundation

enum GoalPeriod: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }

    var shortTitle: String {
        switch self {
        case .daily:
            return "Today"
        case .weekly:
            return "This Week"
        case .monthly:
            return "This Month"
        case .yearly:
            return "This Year"
        }
    }
}

enum GoalMetric: String, Codable, CaseIterable, Identifiable {
    case pages
    case books

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pages:
            return "Pages"
        case .books:
            return "Books"
        }
    }

    var singularTitle: String {
        switch self {
        case .pages:
            return "page"
        case .books:
            return "book"
        }
    }

    var icon: String {
        switch self {
        case .pages:
            return "doc.text.fill"
        case .books:
            return "books.vertical.fill"
        }
    }
}

struct GoalDTO: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let period: GoalPeriod
    let metric: GoalMetric
    let target: Int
    let startDate: String?
    let endDate: String?
    let isActive: Bool
    let isPrimary: Bool?
    let progress: GoalServerProgressDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case period = "type"
        case metric
        case target
        case startDate
        case endDate
        case isActive
        case isPrimary
        case progress
    }
}

struct GoalServerProgressDTO: Codable, Hashable {
    let currentValue: Int
    let target: Int?
    let remaining: Int?
    let isComplete: Bool?
    let percentComplete: Double?
    let periodStart: String?
    let periodEnd: String?
}

struct GoalsResponse: Decodable {
    let goals: [GoalDTO]
}

struct SingleGoalResponse: Decodable {
    let goal: GoalDTO
    let message: String?
}

struct CreateGoalRequest: Encodable {
    let period: GoalPeriod
    let metric: GoalMetric
    let target: Int
    let startDate: String?
    let endDate: String?
    let isActive: Bool
    let isPrimary: Bool?

    enum CodingKeys: String, CodingKey {
        case period = "type"
        case metric
        case target
        case startDate
        case endDate
        case isActive
        case isPrimary
    }
}

struct UpdateGoalRequest: Encodable {
    let target: Int?
    let startDate: String?
    let endDate: String?
    let isActive: Bool?
    let isPrimary: Bool?
}

struct GoalProgress: Identifiable, Hashable {
    let goal: GoalDTO
    let progress: Int

    var id: Int { goal.id }

    var progressFraction: Double {
        guard goal.target > 0 else { return 0 }
        return min(Double(progress) / Double(goal.target), 1)
    }

    var isCompleted: Bool {
        progress >= goal.target
    }

    var summaryText: String {
        "\(progress)/\(goal.target) \(goal.metric.title.lowercased())"
    }
}
