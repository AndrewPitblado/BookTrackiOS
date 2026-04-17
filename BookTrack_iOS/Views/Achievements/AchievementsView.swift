//
//  AchievementsView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var vm: AchievementsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter & sort controls
                controlsBar

                // Achievement grid
                if vm.displayedAchievements.isEmpty && !vm.isLoading {
                    ContentUnavailableView(
                        "No Achievements",
                        systemImage: "trophy",
                        description: Text("Keep reading to unlock achievements!")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(vm.displayedAchievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Achievements")
                            .font(.title3.bold())
                        Text("\(vm.unlockedCount)/\(vm.progress.count) unlocked • \(vm.totalPoints) pts")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.checkForNew() }
                    } label: {
                        if vm.isChecking {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(vm.isChecking)
                }
            }
            .overlay {
                if vm.isLoading {
                    ProgressView()
                }
            }
            .refreshable {
                await vm.loadProgress()
            }
            .task {
                if vm.progress.isEmpty {
                    await vm.loadProgress()
                }
            }
            .alert("Achievement Check", isPresented: .init(
                get: { vm.checkResultMessage != nil },
                set: { if !$0 { vm.checkResultMessage = nil } }
            )) {
                Button("OK") { vm.checkResultMessage = nil }
            } message: {
                Text(vm.checkResultMessage ?? "")
            }
        }
    }

    // MARK: - Controls

    private var controlsBar: some View {
        HStack {
            Picker("Filter", selection: $vm.filter) {
                ForEach(AchievementFilter.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)

            Menu {
                ForEach(AchievementSort.allCases) { s in
                    Button {
                        vm.sortBy = s
                    } label: {
                        Label(s.rawValue, systemImage: vm.sortBy == s ? "checkmark" : "")
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Achievement Card

private struct AchievementCard: View {
    let achievement: AchievementProgressDTO

    #if DEBUG
        #if targetEnvironment(simulator)
        private static let baseURL = URL(string: "http://localhost:5001")!
        #else
        private static let baseURL = URL(string: "http://192.168.2.162:5001")!
        #endif
    #else
    private static let baseURL = URL(string: "https://api.booktrack.apitblado.com")!
    #endif

    private var showDetails: Bool {
        !achievement.isSecret || achievement.unlocked
    }

    private var iconURL: URL? {
        guard let icon = achievement.icon, !icon.isEmpty else { return nil }
        // Backend serves PNGs at /achievement-icons-png/<name>.png
        let pngPath = icon
            .replacingOccurrences(of: "/achievement-icons/", with: "/achievement-icons-png/")
            .replacingOccurrences(of: ".svg", with: ".png")
        return Self.baseURL.appendingPathComponent(pngPath)
    }

    var body: some View {
        VStack(spacing: 10) {
            // Tier & points header
            HStack {
                Text(achievement.tier.emoji)
                    .font(.caption)
                Spacer()
                Text("\(achievement.points) pts")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            // Icon
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? tierGradient : lockedGradient)
                    .frame(width: 56, height: 56)

                if achievement.unlocked {
                    if iconURL != nil {
                        RemoteImageView(url: iconURL, fallbackSystemName: "trophy.fill")
                            .frame(width: 28, height: 28)
                    } else {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            // Name & description
            Text(showDetails ? achievement.name : "???")
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(showDetails ? (achievement.description ?? "") : "Secret Achievement")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Progress bar
            VStack(spacing: 4) {
                ProgressView(value: achievement.progress.percentage, total: 100)
                    .tint(achievement.unlocked ? .green : Color.accentColor)

                Text("\(achievement.progress.current)/\(achievement.progress.target)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(achievement.unlocked ? Color.green.opacity(0.05) : Color.clear)
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(achievement.unlocked ? 1 : 0.75)
    }

    private var tierGradient: AnyShapeStyle {
        switch achievement.tier {
        case .bronze:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.35, blue: 0.1)], startPoint: .top, endPoint: .bottom)
            )
        case .silver:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.75, green: 0.75, blue: 0.75), Color(red: 0.55, green: 0.55, blue: 0.55)], startPoint: .top, endPoint: .bottom)
            )
        case .gold:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.85, green: 0.65, blue: 0.0)], startPoint: .top, endPoint: .bottom)
            )
        case .platinum:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.53, green: 0.81, blue: 0.92), Color(red: 0.3, green: 0.55, blue: 0.75)], startPoint: .top, endPoint: .bottom)
            )
        }
    }

    private var lockedGradient: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
        )
    }
}

#Preview {
    AchievementsView()
        .environmentObject(SessionStore())
        .environmentObject(AchievementsViewModel())
    
}
