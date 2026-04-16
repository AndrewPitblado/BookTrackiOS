//
//  BookSearchView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct BookSearchView: View {
    @EnvironmentObject private var booksVM: BooksViewModel

    var body: some View {
        NavigationStack {
            List {
                if booksVM.searchResults.isEmpty && !booksVM.isSearching {
                    ContentUnavailableView(
                        "Search for Books",
                        systemImage: "magnifyingglass",
                        description: Text("Find books by title, author, or genre.")
                    )
                }

                ForEach(booksVM.searchResults, id: \.self) { book in
                    SearchResultRow(book: book, isInLibrary: booksVM.isInLibrary(book)) {
                        Task { await booksVM.addToLibrary(book) }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $booksVM.searchQuery, prompt: "Title, author, or genre")
            .onSubmit(of: .search) {
                Task { await booksVM.search() }
            }
            .overlay {
                if booksVM.isSearching {
                    ProgressView("Searching...")
                }
            }
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let book: BookDTO
    let isInLibrary: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: book.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.fill.tertiary)
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 50, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.displayAuthors)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let pages = book.pageCount {
                    Text("\(pages) pages")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Add button
            if isInLibrary {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookSearchView()
}
