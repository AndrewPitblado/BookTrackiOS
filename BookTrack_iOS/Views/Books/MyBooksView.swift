//
//  MyBooksView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct MyBooksView: View {
    @EnvironmentObject private var booksVM: BooksViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status filter picker
                Picker("Filter", selection: $booksVM.statusFilter) {
                    Text("All").tag(ReadingStatus?.none)
                    ForEach(ReadingStatus.allCases) { status in
                        Label(status.label, systemImage: status.icon)
                            .tag(ReadingStatus?.some(status))
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if booksVM.filteredBooks.isEmpty && !booksVM.isLoadingLibrary {
                    ContentUnavailableView(
                        "No Books Yet",
                        systemImage: "books.vertical",
                        description: Text("Search for books and add them to your library.")
                    )
                } else {
                    List {
                        ForEach(booksVM.filteredBooks) { userBook in
                            NavigationLink(value: userBook.id) {
                                UserBookRow(userBook: userBook)
                            }
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { booksVM.filteredBooks[$0].id }
                            for id in ids {
                                Task { await booksVM.removeBook(id: id) }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Books")
            .navigationDestination(for: Int.self) { userBookId in
                if let userBook = booksVM.userBooks.first(where: { $0.id == userBookId }) {
                    BookDetailView(userBook: userBook)
                }
            }
            .refreshable {
                await booksVM.loadUserBooks()
            }
            .overlay {
                if booksVM.isLoadingLibrary {
                    ProgressView()
                }
            }
            .task {
                if booksVM.userBooks.isEmpty {
                    await booksVM.loadUserBooks()
                }
            }
        }
    }
}

// MARK: - User Book Row

private struct UserBookRow: View {
    let userBook: UserBookDTO

    var body: some View {
        HStack(spacing: 8) {
            // Thumbnail
            AsyncImage(url: userBook.book.thumbnailURL) { image in
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

            VStack(alignment: .leading, spacing: 4) {
                Text(userBook.book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(userBook.book.displayAuthors)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    MetadataLabel(
                        text: userBook.status.label,
                        systemImage: userBook.status.icon,
                        color: statusColor(userBook.status)
                    )

                    if let rating = userBook.rating, rating > 0 {
                        MetadataLabel(
                            text: String(format: "%.1f", rating),
                            systemImage: "star.fill",
                            color: .orange
                        )
                    }
                }
            }

            Spacer()

            if userBook.status == .reading, let pages = userBook.book.pageCount, pages > 0 {
                Text("\(userBook.currentPage)/\(pages)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusColor(_ status: ReadingStatus) -> Color {
        switch status {
        case .reading: return .blue
        case .finished: return .green
        case .dropped: return .red
        }
    }
}

private struct MetadataLabel: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .frame(width: 12)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(color)
    }
}

#Preview {
    MyBooksView()
        .environmentObject(SessionStore())
        .environmentObject(BooksViewModel())
}
