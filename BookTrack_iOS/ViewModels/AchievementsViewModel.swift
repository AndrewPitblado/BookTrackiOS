//
//  AchievementsViewModel.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Combine
import Foundation

enum AchievementFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unlocked = "Unlocked"
    case locked = "Locked"

    var id: String { rawValue }
}

enum AchievementSort: String, CaseIterable, Identifiable {
    case tier = "Tier"
    case name = "Name"
    case points = "Points"
    case progress = "Progress"

    var id: String { rawValue }
}

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var progress: [AchievementProgressDTO] = []
    @Published var isLoading = false
    @Published var isChecking = false
    @Published var errorMessage: String?
    @Published var checkResultMessage: String?
    @Published var filter: AchievementFilter = .all
    @Published var sortBy: AchievementSort = .tier

    private let service: AchievementService

    init(service: AchievementService) {
        self.service = service
    }

    // MARK: - Computed

    var unlockedCount: Int {
        progress.filter(\.unlocked).count
    }

    var totalPoints: Int {
        progress.filter(\.unlocked).reduce(0) { $0 + $1.points }
    }

    var displayedAchievements: [AchievementProgressDTO] {
        let filtered: [AchievementProgressDTO]
        switch filter {
        case .all: filtered = progress
        case .unlocked: filtered = progress.filter(\.unlocked)
        case .locked: filtered = progress.filter { !$0.unlocked }
        }

        return filtered.sorted { a, b in
            switch sortBy {
            case .tier:
                if a.tier != b.tier { return a.tier < b.tier }
                return a.name < b.name
            case .name:
                return a.name < b.name
            case .points:
                return a.points > b.points
            case .progress:
                return a.progress.percentage > b.progress.percentage
            }
        }
    }

    // MARK: - Actions

    func loadProgress() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            progress = try await service.getProgress()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkForNew() async {
        isChecking = true
        checkResultMessage = nil
        defer { isChecking = false }

        do {
            let result = try await service.checkAchievements()
            checkResultMessage = result.message

            let unlocked = result.newlyUnlocked?.count ?? 0
            let revoked = result.newlyRevoked?.count ?? 0
            if unlocked > 0 || revoked > 0 {
                // Refresh progress after changes
                await loadProgress()
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
