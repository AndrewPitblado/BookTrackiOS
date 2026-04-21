//
//  DashboardView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var dashboardVM: DashboardViewModel
    @State private var showingGoalsSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(session.user?.username ?? "Reader")
                                .font(.title.bold())
                        }
                        Spacer()
                        Button {
                            session.logout()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Reading", value: "\(dashboardVM.readingCount)", icon: "book.fill", color: .blue)
                        StatCard(title: "Finished", value: "\(dashboardVM.finishedCount)", icon: "checkmark.circle.fill", color: .green)
                        StatCard(title: "Pages", value: "\(dashboardVM.totalPages)", icon: "doc.text", color: .purple)
                        StatCard(title: "Streak", value: "\(dashboardVM.currentStreak)", icon: "flame.fill", color: .orange)
                    }
                    .padding(.horizontal)

                    goalsSection

                    // Currently reading
                    if !dashboardVM.currentlyReading.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Currently Reading")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(dashboardVM.currentlyReading) { userBook in
                                        NavigationLink {
                                            BookDetailView(userBook:userBook)
                                        } label: {
                                            CurrentlyReadingCard(userBook: userBook)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Recent activity
                    if !dashboardVM.recentBooks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(dashboardVM.recentBooks) { userBook in
                                NavigationLink {
                                    BookDetailView(userBook: userBook)
                                } label: {
                                    RecentBookRow(userBook: userBook)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }

                    if dashboardVM.userBooks.isEmpty && !dashboardVM.isLoading {
                        ContentUnavailableView(
                            "No Books Yet",
                            systemImage: "book",
                            description: Text("Search for books and add them to your library to get started.")
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await dashboardVM.load()
            }
            .overlay {
                if dashboardVM.isLoading {
                    ProgressView()
                }
            }
            .task {
                await dashboardVM.load()
            }
            .task {
                await dashboardVM.loadReadingStreak()
            }
            .sheet(isPresented: $showingGoalsSheet) {
                GoalsManagementView()
                    .environmentObject(dashboardVM)
            }
        }
    }

    @ViewBuilder
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goals")
                    .font(.headline)
                Spacer()
                if !dashboardVM.activeGoalProgress.isEmpty {
                    Text("\(dashboardVM.activeGoalProgress.count) active")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Button("Manage") {
                    showingGoalsSheet = true
                }
                .font(.caption.weight(.semibold))
            }
            .padding(.horizontal)

            if dashboardVM.highlightedGoalProgress.isEmpty {
                ContentUnavailableView {
                    Label("No Active Goals", systemImage: "target")
                } description: {
                    Text("Add your first reading goal to get started.")
                } actions: {
                    Button("Add Goal") {
                        showingGoalsSheet = true
                    }
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(dashboardVM.highlightedGoalProgress) { goalProgress in
                        GoalProgressCard(goalProgress: goalProgress)
                    }

                    if dashboardVM.activeGoalProgress.count > dashboardVM.highlightedGoalProgress.count {
                        Button("View All Goals") {
                            showingGoalsSheet = true
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Currently Reading Card

private struct CurrentlyReadingCard: View {
    let userBook: UserBookDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: userBook.book.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.fill.tertiary)
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 100, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(userBook.book.title)
                .font(.caption.bold())
                .lineLimit(1)
                .frame(width: 125, alignment: .leading)

            if let pages = userBook.book.pageCount, pages > 0 {
                ProgressView(value: Double(userBook.currentPage), total: Double(pages))
                    .frame(width: 100)
                Text("\(userBook.currentPage)/\(pages)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Recent Book Row

private struct RecentBookRow: View {
    let userBook: UserBookDTO

    private var statusColor: Color {
        switch userBook.status {
        case .reading:
            return .blue
        case .finished:
            return .green
        case .dropped:
            return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: userBook.book.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.fill.tertiary)
            }
            .frame(width: 36, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(userBook.book.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(userBook.book.displayAuthors)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Label(userBook.status.label, systemImage: userBook.status.icon)
                .font(.caption)
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Goal Progress Card

private struct GoalProgressCard: View {
    let goalProgress: GoalProgress

    private var tint: Color {
        switch goalProgress.goal.metric {
        case .pages:
            return .indigo
        case .books:
            return .blue
        }
    }

    private var targetLabel: String {
        let target = goalProgress.goal.target
        let metric = target == 1 ? goalProgress.goal.metric.singularTitle : goalProgress.goal.metric.title.lowercased()
        return "\(goalProgress.goal.period.shortTitle) • \(target) \(metric)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Label(goalProgress.goal.metric.title, systemImage: goalProgress.goal.metric.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)

                Spacer()

                Text(goalProgress.goal.period.title)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.12))
                    .foregroundStyle(tint)
                    .clipShape(Capsule())
            }

            Text(targetLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)

            ProgressView(value: goalProgress.progressFraction)
                .tint(tint)

            HStack {
                Text(goalProgress.summaryText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                Text(goalProgress.isCompleted ? "Complete" : "\(Int(goalProgress.progressFraction * 100))%")
                    .font(.caption)
                    .foregroundStyle(goalProgress.isCompleted ? .green : .secondary)
            }
        }
        .padding()
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DashboardView()
        .environmentObject(SessionStore())
        .environmentObject(DashboardViewModel())
}
