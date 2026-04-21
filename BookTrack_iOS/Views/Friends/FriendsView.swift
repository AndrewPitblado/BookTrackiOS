//
//  FriendsView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var vm: FriendsViewModel
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Tab", selection: $vm.activeTab) {
                    ForEach(FriendsTab.allCases) { tab in
                        Text(tabLabel(tab)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                Group {
                    switch vm.activeTab {
                    case .friends:
                        friendsListSection
                    case .requests:
                        requestsSection
                    case .search:
                        searchSection
                    }
                }
            }
            .navigationTitle("Friends")
            .overlay {
                if vm.isLoading {
                    ProgressView()
                }
            }
            .alert("Success", isPresented: .init(
                get: { vm.successMessage != nil },
                set: { if !$0 { vm.successMessage = nil } }
            )) {
                Button("OK") { vm.successMessage = nil }
            } message: {
                Text(vm.successMessage ?? "")
            }
            .onChange(of: vm.activeTab) { _, newTab in
                Task {
                    switch newTab {
                    case .friends: await vm.loadFriends()
                    case .requests: await vm.loadRequests()
                    case .search: break
                    }
                }
            }
            .task {
                if vm.friends.isEmpty { await vm.loadFriends() }
                await vm.loadRequests() // always load to get badge count
            }
        }
    }

    private func tabLabel(_ tab: FriendsTab) -> String {
        switch tab {
        case .friends: return "Friends (\(vm.friends.count))"
        case .requests: return "Requests (\(vm.requests.count))"
        case .search: return "Find"
        }
    }

    // MARK: - Friends List

    private var friendsListSection: some View {
        Group {
            if vm.friends.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "No Friends Yet",
                    systemImage: "person.2",
                    description: Text("Search for users to add friends!")
                )
            } else {
                List {
                    ForEach(vm.friends) { friend in
                        NavigationLink {
                            FriendProfileView(friendId: friend.id, friendName: friend.username)
                        } label: {
                            FriendRow(friend: friend)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await vm.removeFriend(friend.friendshipId) }
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await vm.loadFriends()
                }
            }
        }
    }

    // MARK: - Requests

    private var requestsSection: some View {
        Group {
            if vm.requests.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "No Pending Requests",
                    systemImage: "envelope.open",
                    description: Text("Friend requests you receive will appear here.")
                )
            } else {
                List {
                    ForEach(vm.requests) { request in
                        RequestRow(request: request, onAccept: {
                            Task { await vm.acceptRequest(request.id) }
                        }, onReject: {
                            Task { await vm.rejectRequest(request.id) }
                        })
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await vm.loadRequests()
                }
            }
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        List {
            if vm.searchResults.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "Find Friends",
                    systemImage: "person.badge.plus",
                    description: Text("Search for users by username.")
                )
            }

            ForEach(vm.searchResults) { user in
                SearchResultRow(user: user, onAdd: {
                    Task { await vm.sendRequest(to: user.id) }
                })
            }
        }
        .listStyle(.plain)
        .searchable(text: $vm.searchQuery, prompt: "Enter a username")
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit(of: .search) {
            guard vm.searchQuery.count >= 2 else { return }
            Task { await vm.searchUsers() }
        }
        .refreshable {
            guard vm.searchQuery.count >= 2 else { return }
            await vm.searchUsers()
        }
    }
}

// MARK: - Row Views

private struct FriendRow: View {
    let friend: FriendDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.username)
                    .font(.headline)
                Text(friend.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct RequestRow: View {
    let request: FriendshipDTO
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(request.user?.username ?? "Unknown")
                    .font(.headline)
                if let date = request.createdAt {
                    Text("Sent \(date.prefix(10))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)

                Button(action: onReject) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SearchResultRow: View {
    let user: UserSearchResultDTO
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.headline)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if user.isFriend == true {
                Label("Friends", systemImage: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            } else if user.isPending == true {
                Text(user.requestSentByMe == true ? "Sent" : "Received")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FriendsView()
}
