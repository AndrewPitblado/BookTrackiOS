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
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let bookService: BookService

    init(bookService: BookService) {
        self.bookService = bookService
    }

    // MARK: - Computed stats

    var readingCount: Int {
        userBooks.filter { $0.status == .reading }.count
    }

    var finishedCount: Int {
        userBooks.filter { $0.status == .finished }.count
    }

    var totalPages: Int {
        userBooks
            .filter { $0.status == .finished }
            .compactMap { $0.book.pageCount }
            .reduce(0, +)
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
}
