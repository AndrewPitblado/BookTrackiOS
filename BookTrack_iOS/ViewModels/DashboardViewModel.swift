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
    @Published var readingStreak: ReadingStreakDTO?
    @Published var recentReadingLogs: [ReadingLogDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let bookService: BookService

    init(bookService: BookService) {
        self.bookService = bookService
    }

    /// No-argument initialiser for SwiftUI previews.
    init() {
        let tokenStore = KeychainTokenStore(service: "com.booktrack.ios.preview")
        let client = NetworkClient(
            baseURL: URL(string: "http://localhost:5001/api")!,
            tokenStore: tokenStore
        )
        self.bookService = BookService(client: client)
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

    // MARK: - Load

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            userBooks = try await bookService.getUserBooks()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Loads streak totals separately so the dashboard can adopt the new endpoint
    /// without making the current library load dependent on backend rollout timing.
    func loadReadingStreak() async {
        do {
            readingStreak = try await bookService.getReadingStreak()
        } catch {
            // Ignore until the server exposes the new endpoint.
        }
    }

    func loadRecentReadingLogs(limit: Int = 10) async {
        do {
            recentReadingLogs = Array(try await bookService.getReadingLogs().prefix(limit))
        } catch {
            // Ignore until the server exposes the new endpoint.
        }
    }
}
