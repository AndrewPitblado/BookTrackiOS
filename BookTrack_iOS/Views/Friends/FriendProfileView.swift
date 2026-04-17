//
//  FriendProfileView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-16.
//

import SwiftUI

struct FriendProfileView: View {
    let friendId: Int
    let friendName: String

    @StateObject private var vm: FriendProfileViewModel

    init(friendId: Int, friendName: String) {
        self.friendId = friendId
        self.friendName = friendName
        // FriendService will be created inline using the shared NetworkClient
        // We'll inject it from the environment in a moment — for now use a factory.
        _vm = StateObject(wrappedValue: FriendProfileViewModel(
            service: FriendProfileView.sharedService!,
            userId: friendId
        ))
    }

    // Set by FriendsView before navigation
    nonisolated(unsafe) static var sharedService: FriendService?

    var body: some View {
        ScrollView {
            if vm.isLoading {
                ProgressView()
                    .padding(.top, 60)
            } else if let error = vm.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                VStack(spacing: 20) {
                    profileHeader
                    statsGrid
                    booksSection
                    achievementsSection
                }
                .padding()
            }
        }
        .navigationTitle("\(friendName)'s Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load()
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text(vm.user?.username ?? friendName)
                .font(.title2.bold())

            if let date = vm.user?.createdAt {
                Text("Member since \(String(date.prefix(10)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(value: "\(vm.stats?.reading ?? 0)", label: "Reading", icon: "book", color: .blue)
            StatCard(value: "\(vm.stats?.finished ?? 0)", label: "Finished", icon: "checkmark.circle", color: .green)
            StatCard(value: "\(vm.stats?.achievements ?? 0)", label: "Achievements", icon: "trophy", color: .orange)
            StatCard(value: "\(vm.stats?.totalPoints ?? 0)", label: "Points", icon: "star.fill", color: .yellow)
        }
    }

    // MARK: - Books Section

    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Books (\(vm.books.count))", systemImage: "books.vertical")
                .font(.headline)

            if vm.books.isEmpty {
                Text("No books yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.books) { userBook in
                    FriendBookRow(userBook: userBook)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Achievements (\(vm.achievements.count))", systemImage: "trophy")
                .font(.headline)

            if vm.achievements.isEmpty {
                Text("No achievements yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.achievements) { ua in
                    FriendAchievementRow(achievement: ua.achievement)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Friend Book Row

private struct FriendBookRow: View {
    let userBook: FriendBookDTO

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let urlStr = userBook.book?.thumbnail,
               let url = URL(string: urlStr.replacingOccurrences(of: "http://", with: "https://")) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 40, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(userBook.book?.title ?? "Unknown")
                    .font(.subheadline.bold())
                    .lineLimit(1)

                if let authors = userBook.book?.displayAuthors {
                    Text(authors)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Rating for finished books
                if userBook.status == "finished", let rating = userBook.rating, rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: Double(star) <= rating ? "star.fill" :
                                    Double(star) - 0.5 <= rating ? "star.leadinghalf.filled" : "star")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                // Progress for reading books
                if userBook.status == "reading",
                   let current = userBook.currentPage,
                   let pageCount = userBook.book?.pageCount,
                   pageCount > 0 {
                    ProgressView(value: Double(current), total: Double(pageCount))
                        .tint(.blue)
                }
            }

            Spacer()

            Text(userBook.status.capitalized)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch userBook.status {
        case "reading": return .blue
        case "finished": return .green
        case "dropped": return .red
        default: return .gray
        }
    }
}

// MARK: - Friend Achievement Row

private struct FriendAchievementRow: View {
    let achievement: AchievementDTO

    #if DEBUG
        #if targetEnvironment(simulator)
        private static let baseURL = URL(string: "http://localhost:5001")!
        #else
        private static let baseURL = URL(string: "http://192.168.2.162:5001")!
        #endif
    #else
    private static let baseURL = URL(string: "https://api.booktrack.apitblado.com")!
    #endif

    private var iconURL: URL? {
        guard let icon = achievement.icon, !icon.isEmpty else { return nil }
        let pngPath = icon
            .replacingOccurrences(of: "/achievement-icons/", with: "/achievement-icons-png/")
            .replacingOccurrences(of: ".svg", with: ".png")
        return Self.baseURL.appendingPathComponent(pngPath)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.fill.tertiary)
                    .frame(width: 36, height: 36)

                if iconURL != nil {
                    RemoteImageView(url: iconURL, fallbackSystemName: "trophy.fill")
                        .frame(width: 20, height: 20)
                } else {
                    Text(achievement.tier.emoji)
                        .font(.body)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.subheadline.bold())
                if let desc = achievement.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text("\(achievement.points) pts")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
