//
//  NerdleBundleApp.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

/// Main SwiftUI entry point.
/// Wires up Firebase, global app state, and the tab shell.
@main
struct NerdleBundleApp: App {
    /// Bridges UIKit app lifecycle so Firebase can hook into it.
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var appDelegate
    /// Shared app state instance for the entire app.
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
