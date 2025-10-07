//
//  TabShellView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

struct TabShellView: View {
    enum Tab { case home, leaderboard, account, settings }
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
