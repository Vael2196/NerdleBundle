//
//  TabShellView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

/// Root tab bar for the whole app.
/// Every major section lives under one of these tabs.
struct TabShellView: View {
    enum Tab { case home, leaderboard, account, settings }
    /// Currently selected tab. Also passed down to `HomeView` so it can jump tabs.
    @State private var tab: Tab = .home

    var body: some View {
        TabView(selection: $tab) {
            HomeView(tab: $tab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "crown.fill") }
                .tag(Tab.leaderboard)

            AccountRouterView()
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
                .tag(Tab.account)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .tint(.nbGold)
        .background(Color.nbBackground)
    }
}
