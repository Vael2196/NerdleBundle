//
//  NerdleBundleApp.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

@main
struct NerdleBundleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            TabShellView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                .dynamicTypeSize(appState.dynamicTypeSize)
        }
    }
}
