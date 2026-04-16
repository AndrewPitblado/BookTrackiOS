//
//  BooksViewModel.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Combine
import Foundation

@MainActor
final class BooksViewModel: ObservableObject {
    // MARK: - Search state
    @Published var searchQuery = ""
    @Published var searchResults: [BookDTO] = []
    @Published var isSearching = false

    // MARK: - Library state
    @Published var userBooks: [UserBookDTO] = []
    @Published var isLoadingLibrary = false
    @Published var statusFilter: ReadingStatus?

    // MARK: - Shared
    @Published var errorMessage: String?

    private let bookService: BookService

    init(bookService: BookService) {
        self.bookService = bookService
    }

    // MARK: - Computed

    var filteredBooks: [UserBookDTO] {
        guard let filter = statusFilter else { return userBooks }
        return userBooks.filter { $0.status == filter }
    }

    var currentlyReading: [UserBookDTO] {
        userBooks.filter { $0.status == .reading }
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

    // MARK: - Search

    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            searchResults = try await bookService.searchBooks(query: query)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Library

    func loadUserBooks() async {
        isLoadingLibrary = true
        errorMessage = nil
        defer { isLoadingLibrary = false }

        do {
            userBooks = try await bookService.getUserBooks()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Add a search result to the user's library.
    /// First creates the book on the backend, then adds to user's list.
    func addToLibrary(_ book: BookDTO, status: ReadingStatus = .reading) async {
        errorMessage = nil
        do {
            let savedBook = try await bookService.createBook(from: book)
            guard let bookId = savedBook.id else { return }
            let userBook = try await bookService.addToLibrary(bookId: bookId, status: status)
            userBooks.insert(userBook, at: 0)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateBook(id: Int, status: ReadingStatus? = nil, currentPage: Int? = nil, rating: Double? = nil, notes: String? = nil) async {
        errorMessage = nil
        do {
            let updated = try await bookService.updateUserBook(id: id, status: status, currentPage: currentPage, rating: rating, notes: notes)
            if let index = userBooks.firstIndex(where: { $0.id == id }) {
                userBooks[index] = updated
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeBook(id: Int) async {
        errorMessage = nil
        do {
            try await bookService.removeFromLibrary(id: id)
            userBooks.removeAll { $0.id == id }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Check if a book (by googleBooksId) is already in the user's library.
    func isInLibrary(_ book: BookDTO) -> Bool {
        guard let gid = book.googleBooksId else { return false }
        return userBooks.contains { $0.book.googleBooksId == gid }
    }
}
