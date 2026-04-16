//
//  BookTrackApp.swift
//  BookTrack_iOS
//
//  Created by Andrew Pitblado on 2026-04-15.
//

import SwiftUI

@main
struct BookTrackApp: App {
    @StateObject private var sessionStore: SessionStore
    @StateObject private var booksVM: BooksViewModel
    @StateObject private var dashboardVM: DashboardViewModel
    @StateObject private var achievementsVM: AchievementsViewModel
    @StateObject private var friendsVM: FriendsViewModel

    init() {
        #if DEBUG
            #if targetEnvironment(simulator)
            let baseURL = URL(string: "http://localhost:5001/api")!
            #else
            let baseURL = URL(string: "http://192.168.2.162:5001/api")!
            #endif
        #else
        let baseURL = URL(string: "https://api.booktrack.apitblado.com/api")!
        #endif
        let tokenStore = KeychainTokenStore(service: "com.booktrack.ios")
        let networkClient = NetworkClient(baseURL: baseURL, tokenStore: tokenStore)
        let authService = AuthService(client: networkClient, tokenStore: tokenStore)
        let bookService = BookService(client: networkClient)
        let achievementService = AchievementService(client: networkClient)
        let friendService = FriendService(client: networkClient)

        // Keep nil for now since backend currently returns one token.
        networkClient.refreshHandler = nil

        // Allow FriendProfileView to create its own ViewModel with the shared service
        FriendProfileView.sharedService = friendService

        _sessionStore = StateObject(
            wrappedValue: SessionStore(authService: authService, tokenStore: tokenStore)
        )
        _booksVM = StateObject(
            wrappedValue: BooksViewModel(bookService: bookService)
        )
        _dashboardVM = StateObject(
            wrappedValue: DashboardViewModel(bookService: bookService)
        )
        _achievementsVM = StateObject(
            wrappedValue: AchievementsViewModel(service: achievementService)
        )
        _friendsVM = StateObject(
            wrappedValue: FriendsViewModel(service: friendService)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .environmentObject(booksVM)
                .environmentObject(dashboardVM)
                .environmentObject(achievementsVM)
                .environmentObject(friendsVM)
                .task {
                    await sessionStore.bootstrap()
                }
        }
    }
}
