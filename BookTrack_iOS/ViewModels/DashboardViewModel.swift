//
//  DashboardViewModel.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var userBooks: [UserBookDTO] = []
    @Published var goals: [GoalDTO] = []
    @Published var readingStreak: ReadingStreakDTO?
    @Published var recentReadingLogs: [ReadingLogDTO] = []
    @Published var isLoading = false
    @Published var isSavingGoal = false
    @Published var errorMessage: String?
    @Published var goalErrorMessage: String?

    private let bookService: BookService
    private let goalsService: GoalsService

    init(bookService: BookService, goalsService: GoalsService) {
        self.bookService = bookService
        self.goalsService = goalsService
    }

    /// No-argument initialiser for SwiftUI previews.
    init() {
        let tokenStore = KeychainTokenStore(service: "com.booktrack.ios.preview")
        let client = NetworkClient(
            baseURL: URL(string: "http://localhost:5001/api")!,
            tokenStore: tokenStore
        )
        self.bookService = BookService(client: client)
        self.goalsService = GoalsService(client: client)
    }

    // MARK: - Computed stats

    var readingCount: Int {
        userBooks.filter { $0.status == .reading }.count
    }

    var finishedCount: Int {
        userBooks.filter { $0.status == .finished }.count
    }
    var totalPages: Int {
        let finishedPages = userBooks
            .filter { $0.status == .finished }
            .compactMap { $0.book.pageCount }
            .reduce(0, +)
        let readingPages = userBooks
            .filter { $0.status == .reading }
            .map { $0.currentPage }
            .reduce(0, +)
        return finishedPages + readingPages
    }

    var currentStreak: Int {
        readingStreak?.currentStreak ?? 0
    }

    var longestStreak: Int {
        readingStreak?.longestStreak ?? 0
    }

    var currentlyReading: [UserBookDTO] {
        userBooks.filter { $0.status == .reading }
    }

    var recentBooks: [UserBookDTO] {
        Array(userBooks.prefix(5))
    }

    var activeGoalProgress: [GoalProgress] {
        goals
            .filter(\.isActive)
            .map {
                let serverProgress = $0.progress?.currentValue
                return GoalProgress(goal: $0, progress: serverProgress ?? progress(for: $0))
            }
            .sorted(by: goalProgressSort)
    }

    var highlightedGoalProgress: [GoalProgress] {
        Array(activeGoalProgress.prefix(3))
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            userBooks = try await bookService.getUserBooks()
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        await loadGoals()
        await loadRecentReadingLogs()
    }

    /// Loads streak totals separately so the dashboard can adopt the new endpoint
    /// without making the current library load dependent on backend rollout timing.
    func loadReadingStreak() async {
        do {
            readingStreak = try await bookService.getReadingStreak()
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            // Ignore until the server exposes the new endpoint.
        }
    }

    func loadRecentReadingLogs(limit: Int = 10) async {
        do {
            let logs = try await bookService.getReadingLogs()
            recentReadingLogs = Array(logs.prefix(limit))
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            // Ignore until the server exposes the new endpoint.
        }
    }

    func loadGoals() async {
        do {
            goals = try await goalsService.getGoals()
            goalErrorMessage = nil
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch let error as APIError {
            goalErrorMessage = error.errorDescription
        } catch {
            goalErrorMessage = error.localizedDescription
        }
    }

    func createGoal(
        period: GoalPeriod,
        metric: GoalMetric,
        target: Int,
        isActive: Bool = true,
        isPrimary: Bool = false
    ) async -> Bool {
        isSavingGoal = true
        goalErrorMessage = nil
        defer { isSavingGoal = false }

        do {
            let createdGoal = try await goalsService.createGoal(
                period: period,
                metric: metric,
                target: target,
                isActive: isActive,
                isPrimary: isPrimary
            )
            goals.append(createdGoal)
            goals.sort(by: sortGoals)
            return true
        } catch let error as APIError {
            goalErrorMessage = error.errorDescription
        } catch {
            goalErrorMessage = error.localizedDescription
        }

        return false
    }

    func updateGoal(
        id: Int,
        target: Int,
        isActive: Bool,
        isPrimary: Bool
    ) async -> Bool {
        isSavingGoal = true
        goalErrorMessage = nil
        defer { isSavingGoal = false }

        do {
            let updatedGoal = try await goalsService.updateGoal(
                id: id,
                target: target,
                isActive: isActive,
                isPrimary: isPrimary
            )
            if let index = goals.firstIndex(where: { $0.id == id }) {
                goals[index] = updatedGoal
                goals.sort(by: sortGoals)
            }
            return true
        } catch let error as APIError {
            goalErrorMessage = error.errorDescription
        } catch {
            goalErrorMessage = error.localizedDescription
        }

        return false
    }

    func deleteGoal(id: Int) async -> Bool {
        isSavingGoal = true
        goalErrorMessage = nil
        defer { isSavingGoal = false }

        do {
            try await goalsService.deleteGoal(id: id)
            goals.removeAll { $0.id == id }
            return true
        } catch let error as APIError {
            goalErrorMessage = error.errorDescription
        } catch {
            goalErrorMessage = error.localizedDescription
        }

        return false
    }

    func applyUpdatedBook(_ userBook: UserBookDTO) {
        if let index = userBooks.firstIndex(where: { $0.id == userBook.id }) {
            userBooks[index] = userBook
        } else {
            userBooks.insert(userBook, at: 0)
        }
    }

    func removeBook(id: Int) {
        userBooks.removeAll { $0.id == id }
    }

    // MARK: - Goal Progress

    private func progress(for goal: GoalDTO) -> Int {
        switch goal.metric {
        case .pages:
            return recentReadingLogs
                .filter { isDate($0.loggedAt, within: goal.period) }
                .reduce(0) { $0 + $1.pagesRead }
        case .books:
            return userBooks
                .filter { $0.status == .finished }
                .filter { isDate($0.endDate, within: goal.period) }
                .count
        }
    }

    private func goalProgressSort(lhs: GoalProgress, rhs: GoalProgress) -> Bool {
        sortGoals(lhs: lhs.goal, rhs: rhs.goal)
    }

    private func sortGoals(lhs: GoalDTO, rhs: GoalDTO) -> Bool {
        if lhs.isActive != rhs.isActive {
            return lhs.isActive && !rhs.isActive
        }
        if lhs.period != rhs.period {
            return periodRank(lhs.period) < periodRank(rhs.period)
        }
        if lhs.isPrimary != rhs.isPrimary {
            return lhs.isPrimary == true
        }
        if lhs.metric != rhs.metric {
            return metricRank(lhs.metric) < metricRank(rhs.metric)
        }
        return lhs.target < rhs.target
    }

    private func periodRank(_ period: GoalPeriod) -> Int {
        switch period {
        case .daily:
            return 0
        case .weekly:
            return 1
        case .monthly:
            return 2
        case .yearly:
            return 3
        }
    }

    private func metricRank(_ metric: GoalMetric) -> Int {
        switch metric {
        case .pages:
            return 0
        case .books:
            return 1
        }
    }

    private func isDate(_ rawValue: String?, within period: GoalPeriod) -> Bool {
        guard let date = parseDate(rawValue) else { return false }
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .daily:
            return calendar.isDate(date, inSameDayAs: now)
        case .weekly:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .monthly:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .yearly:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }

    private func parseDate(_ rawValue: String?) -> Date? {
        guard let rawValue, !rawValue.isEmpty else { return nil }

        if let date = ISO8601DateFormatter().date(from: rawValue) {
            return date
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: rawValue)
    }
}
