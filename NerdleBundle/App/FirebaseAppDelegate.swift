//
//  FirebaseAppDelegate.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import SwiftUI
import FirebaseCore

/// Actual app delegate that wires up Firebase at launch.
/// Hooked into SwiftUI via `@UIApplicationDelegateAdaptor` in `NerdleBundleApp`.
final class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // One-liner that spins up Auth, Firestore, Storage, etc based on GoogleService-Info.plist.
        FirebaseApp.configure()
        return true
    }
}
