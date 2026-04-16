//
//  UserBook.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

// MARK: - Reading Status

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case reading
    case finished
    case dropped

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reading: return "Reading"
        case .finished: return "Finished"
        case .dropped: return "Dropped"
        }
    }

    var icon: String {
        switch self {
        case .reading: return "book.fill"
        case .finished: return "checkmark.circle.fill"
        case .dropped: return "xmark.circle.fill"
        }
    }
}

// MARK: - UserBook

struct UserBookDTO: Codable, Identifiable {
    let id: Int
    let userId: Int
    let bookId: Int
    let status: ReadingStatus
    let startDate: String?
    let endDate: String?
    let currentPage: Int
    let rating: Double?
    let notes: String?
    let readHistoryId: Int?

    // Nested book – key is uppercase "Book" from backend
    let Book: BookDTO

    var book: BookDTO { Book }
}

struct UserBooksResponse: Decodable {
    let userBooks: [UserBookDTO]
}

struct SingleUserBookResponse: Decodable {
    let userBook: UserBookDTO
    let message: String?
}

// MARK: - Request DTOs

struct AddUserBookRequest: Encodable {
    let bookId: Int
    let status: String
    let startDate: String?
    let endDate: String?
    let currentPage: Int?
    let rating: Double?
    let notes: String?
}

struct UpdateUserBookRequest: Encodable {
    let status: String?
    let startDate: String?
    let endDate: String?
    let currentPage: Int?
    let rating: Double?
    let notes: String?
}

// MARK: - Read History

struct ReadHistoryDTO: Codable, Identifiable {
    let id: Int
    let userId: Int
    let bookId: Int
    let startDate: String?
    let endDate: String?
    let rating: Double?
    let notes: String?
    let Book: BookDTO

    var book: BookDTO { Book }
}

struct ReadHistoryResponse: Decodable {
    let history: [ReadHistoryDTO]
}
