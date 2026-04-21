//
//  BookDetailView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject private var booksVM: BooksViewModel
    @Environment(\.dismiss) private var dismiss

    let userBook: UserBookDTO

    @State private var selectedStatus: ReadingStatus
    @State private var currentPage: String
    @State private var rating: Double
    @State private var notes: String
    @State private var savedState: SavedState
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case currentPage
        case notes
    }

    private struct SavedState {
        let status: ReadingStatus
        let currentPage: String
        let rating: Double
        let notes: String

        init(userBook: UserBookDTO) {
            status = userBook.status
            currentPage = "\(userBook.currentPage)"
            rating = userBook.rating ?? 0
            notes = userBook.notes ?? ""
        }

        init(updatedBook: UserBookDTO) {
            self.init(userBook: updatedBook)
        }
    }

    init(userBook: UserBookDTO) {
        self.userBook = userBook
        _selectedStatus = State(initialValue: userBook.status)
        _currentPage = State(initialValue: "\(userBook.currentPage)")
        _rating = State(initialValue: userBook.rating ?? 0)
        _notes = State(initialValue: userBook.notes ?? "")
        _savedState = State(initialValue: SavedState(userBook: userBook))
    }

    private var hasChanges: Bool {
        selectedStatus != savedState.status
        || currentPage != savedState.currentPage
        || rating != savedState.rating
        || notes != savedState.notes
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Book header
                bookHeader

                Divider()

                // Status section
                statusSection

                // Page progress (reading only)
                if selectedStatus == .reading {
                    pageProgressSection
                }

                // Rating (finished only)
                if selectedStatus == .finished {
                    ratingSection
                }

                // Notes
                notesSection

                // Save button
                if hasChanges {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSaving)
                    .padding(.horizontal)
                }

                // Delete button
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Remove from Library", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .confirmationDialog("Remove this book?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                Task {
                    await booksVM.removeBook(id: userBook.id)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Sections

    private var bookHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: userBook.book.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.fill.tertiary)
                    .overlay {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 100, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(userBook.book.title)
                    .font(.title3.bold())
                Text(userBook.book.displayAuthors)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let pages = userBook.book.pageCount {
                    Text("\(pages) pages")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if !userBook.book.displayGenres.isEmpty {
                    FlowLayout(spacing: 4) {
                        ForEach(userBook.book.displayGenres.prefix(3), id: \.self) { genre in
                            Text(genre)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.fill.tertiary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
            Picker("Status", selection: $selectedStatus) {
                ForEach(ReadingStatus.allCases) { status in
                    Label(status.label, systemImage: status.icon).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }

    private var pageProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Page Progress")
                .font(.headline)
            HStack {
                TextField("Current page", text: $currentPage)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .currentPage)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                if let total = userBook.book.pageCount {
                    Text("of \(total)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rating")
                .font(.headline)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: starImage(for: star))
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .onTapGesture {
                            if rating == Double(star) {
                                // Tap same full star → set to half
                                rating = Double(star) - 0.5
                            } else if rating == Double(star) - 0.5 {
                                // Tap same half star → clear
                                rating = 0
                            } else {
                                rating = Double(star)
                            }
                        }
                }
                if rating > 0 {
                    Text(String(format: "%.1f", rating))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(.horizontal)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            TextField("Add your thoughts...", text: $notes, axis: .vertical)
                .focused($focusedField, equals: .notes)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func starImage(for position: Int) -> String {
        if rating >= Double(position) {
            return "star.fill"
        } else if rating >= Double(position) - 0.5 {
            return "star.leadinghalf.filled"
        }
        return "star"
    }

    private func save() async {
        focusedField = nil
        isSaving = true
        defer { isSaving = false }

        let updatedBook = await booksVM.updateBook(
            id: userBook.id,
            status: selectedStatus != savedState.status ? selectedStatus : nil,
            currentPage: Int(currentPage),
            rating: selectedStatus == .finished && rating > 0 ? rating : nil,
            notes: notes.isEmpty ? nil : notes
        )

        if let updatedBook {
            savedState = SavedState(updatedBook: updatedBook)
            selectedStatus = updatedBook.status
            currentPage = "\(updatedBook.currentPage)"
            rating = updatedBook.rating ?? 0
            notes = updatedBook.notes ?? ""
        }
    }
}

// MARK: - Simple Flow Layout for genre tags

private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
