//
//  Book.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import Foundation

// MARK: - Author

struct AuthorDTO: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}

// MARK: - Book

/// Unified book model that handles both search results (authors as [String])
/// and library results (authors as [AuthorDTO]).
struct BookDTO: Codable, Identifiable, Hashable {
    let id: Int?
    let googleBooksId: String?
    let title: String
    let description: String?
    let thumbnail: String?
    let pageCount: Int?
    let publishedDate: String?
    let genres: [String]?
    let categories: [String]?

    /// Populated when returned from library/book-detail endpoints.
    let authors: [AuthorDTO]?

    /// Populated in search results where authors come as plain strings.
    let authorNames: [String]?

    var displayAuthors: String {
        if let authors, !authors.isEmpty {
            return authors.map(\.name).joined(separator: ", ")
        }
        if let authorNames, !authorNames.isEmpty {
            return authorNames.joined(separator: ", ")
        }
        return "Unknown Author"
    }

    var displayGenres: [String] {
        genres ?? categories ?? []
    }

    var thumbnailURL: URL? {
        guard let thumbnail else { return nil }
        // Google Books returns http URLs; upgrade to https
        let secure = thumbnail.replacingOccurrences(of: "http://", with: "https://")
        return URL(string: secure)
    }

    // Custom decoding to handle the dual authors format
    enum CodingKeys: String, CodingKey {
        case id, googleBooksId, title, description, thumbnail
        case pageCount, publishedDate, genres, categories, authors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        googleBooksId = try container.decodeIfPresent(String.self, forKey: .googleBooksId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount)
        publishedDate = try container.decodeIfPresent(String.self, forKey: .publishedDate)
        genres = try container.decodeIfPresent([String].self, forKey: .genres)
        categories = try container.decodeIfPresent([String].self, forKey: .categories)

        // Try decoding authors as [AuthorDTO] first, then fall back to [String]
        if let authorObjects = try? container.decodeIfPresent([AuthorDTO].self, forKey: .authors) {
            authors = authorObjects
            authorNames = nil
        } else if let authorStrings = try? container.decodeIfPresent([String].self, forKey: .authors) {
            authors = nil
            authorNames = authorStrings
        } else {
            authors = nil
            authorNames = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(googleBooksId, forKey: .googleBooksId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(pageCount, forKey: .pageCount)
        try container.encodeIfPresent(publishedDate, forKey: .publishedDate)
        try container.encodeIfPresent(genres, forKey: .genres)
        try container.encodeIfPresent(categories, forKey: .categories)
        if let authors {
            try container.encode(authors, forKey: .authors)
        } else if let authorNames {
            try container.encode(authorNames, forKey: .authors)
        }
    }

    // Hashable conformance using googleBooksId or id
    func hash(into hasher: inout Hasher) {
        hasher.combine(googleBooksId)
        hasher.combine(id)
        hasher.combine(title)
    }

    static func == (lhs: BookDTO, rhs: BookDTO) -> Bool {
        if let lhsGid = lhs.googleBooksId, let rhsGid = rhs.googleBooksId {
            return lhsGid == rhsGid
        }
        if let lhsId = lhs.id, let rhsId = rhs.id {
            return lhsId == rhsId
        }
        return lhs.title == rhs.title
    }
}

// MARK: - Response wrappers

struct BookSearchResponse: Decodable {
    let books: [BookDTO]
}

struct SingleBookResponse: Decodable {
    let book: BookDTO
    let message: String?
}

// MARK: - Create book request (for POST /api/books)

struct CreateBookRequest: Encodable {
    let googleBooksId: String?
    let title: String
    let authors: [String]
    let description: String?
    let thumbnail: String?
    let pageCount: Int?
    let publishedDate: String?
    let categories: [String]
}
