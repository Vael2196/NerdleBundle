//
//  FirebaseAppDelegate.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import SwiftUI
import FirebaseCore

final class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
