//
//  BookService.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

@MainActor
final class BookService {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    // MARK: - Books

    /// Search Google Books via backend proxy.
    func searchBooks(query: String?, author: String? = nil, genre: String? = nil, maxResults: Int = 20) async throws -> [BookDTO] {
        var items: [URLQueryItem] = []
        if let query, !query.isEmpty { items.append(.init(name: "q", value: query)) }
        if let author, !author.isEmpty { items.append(.init(name: "author", value: author)) }
        if let genre, !genre.isEmpty { items.append(.init(name: "genre", value: genre)) }
        items.append(.init(name: "maxResults", value: "\(maxResults)"))

        let endpoint = Endpoint(path: "books/search", method: "GET", queryItems: items)
        let response: BookSearchResponse = try await client.send(endpoint)
        return response.books
    }

    /// Save a book from search results to the backend database.
    func createBook(from book: BookDTO) async throws -> BookDTO {
        let request = CreateBookRequest(
            googleBooksId: book.googleBooksId,
            title: book.title,
            authors: book.authorNames ?? book.authors?.map(\.name) ?? [],
            description: book.description,
            thumbnail: book.thumbnail,
            pageCount: book.pageCount,
            publishedDate: book.publishedDate,
            categories: book.displayGenres
        )
        let body = try JSONBody.encode(request)
        let endpoint = Endpoint(path: "books", method: "POST", body: body)
        let response: SingleBookResponse = try await client.send(endpoint)
        return response.book
    }

    // MARK: - User Books

    /// Get all books in the user's library, optionally filtered by status.
    func getUserBooks(status: ReadingStatus? = nil) async throws -> [UserBookDTO] {
        var items: [URLQueryItem] = []
        if let status { items.append(.init(name: "status", value: status.rawValue)) }
        let endpoint = Endpoint(path: "user-books", method: "GET", queryItems: items.isEmpty ? nil : items)
        let response: UserBooksResponse = try await client.send(endpoint)
        return response.userBooks
    }

    /// Add a book to the user's library.
    func addToLibrary(bookId: Int, status: ReadingStatus = .reading, rating: Double? = nil, notes: String? = nil) async throws -> UserBookDTO {
        let request = AddUserBookRequest(
            bookId: bookId,
            status: status.rawValue,
            startDate: nil,
            endDate: nil,
            currentPage: nil,
            rating: rating,
            notes: notes
        )
        let body = try JSONBody.encode(request)
        let endpoint = Endpoint(path: "user-books", method: "POST", body: body)
        let response: SingleUserBookResponse = try await client.send(endpoint)
        return response.userBook
    }

    /// Update a user book (status, rating, notes, page progress).
    func updateUserBook(id: Int, status: ReadingStatus? = nil, currentPage: Int? = nil, rating: Double? = nil, notes: String? = nil, endDate: String? = nil) async throws -> UserBookDTO {
        let request = UpdateUserBookRequest(
            status: status?.rawValue,
            startDate: nil,
            endDate: endDate,
            currentPage: currentPage,
            rating: rating,
            notes: notes
        )
        let body = try JSONBody.encode(request)
        let endpoint = Endpoint(path: "user-books/\(id)", method: "PUT", body: body)
        let response: SingleUserBookResponse = try await client.send(endpoint)
        return response.userBook
    }

    /// Remove a book from the user's library.
    func removeFromLibrary(id: Int) async throws {
        let endpoint = Endpoint(path: "user-books/\(id)", method: "DELETE")
        try await client.sendVoid(endpoint)
    }

    /// Get the user's read history.
    func getReadHistory() async throws -> [ReadHistoryDTO] {
        let endpoint = Endpoint(path: "user-books/history", method: "GET")
        let response: ReadHistoryResponse = try await client.send(endpoint)
        return response.history
    }
}
