//
//  RootView.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        Group {
            if session.isLoading {
                // Splash / bootstrap screen
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)
                    ProgressView()
                }
            } else if session.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.default, value: session.isAuthenticated)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            BookSearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            MyBooksView()
                .tabItem {
                    Label("My Books", systemImage: "books.vertical")
                }

            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "trophy")
                }

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
        }
    }
}
