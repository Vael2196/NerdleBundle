//
//  AccountRouterView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Tiny state machine for the Account tab.
/// Shows either the account summary or the auth flow depending on Firebase.
struct AccountRouterView: View {
    @EnvironmentObject private var app: AppState

    /// Used to gate the UI with a spinner while Firebase boots up.
    @State private var checkingAuth = true
    /// Handle for the Firebase auth listener so it can be cleaned up properly.
    @State private var authHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        ZStack {
            Color.nbBackground.ignoresSafeArea()

            if checkingAuth {
                // "Please hold" spinner while auth state is resolved.
                ProgressView()
                    .tint(.nbCrimson)
            } else {
                Group {
                    if app.user != nil {
                        AccountSummaryView()
                    } else {
                        LoginView()
                    }
                }
            }
        }
        .onAppear { attachAuthListener() }
        .onDisappear { detachAuthListener() }
    }
}

private extension AccountRouterView {
    /// Hooks into Firebase Auth and keeps `app.user` in sync with the backend user.
    func attachAuthListener() {
        // Already listening? Cool, do nothing.
        if authHandle != nil { return }

        checkingAuth = true

        // Live listener: reacts to sign in / sign out / token refresh.
        authHandle = Auth.auth().addStateDidChangeListener { _, user in
            Task {
                if let user, !user.isAnonymous {
                    await loadUserProfile(uid: user.uid)
                } else {
                    await MainActor.run { app.user = nil }
                }
                await MainActor.run { checkingAuth = false }
            }
        }

        // One-off check so the UI doesn't flash empty on launch.
        Task {
            let current = Auth.auth().currentUser
            if let u = current, !u.isAnonymous {
                await loadUserProfile(uid: u.uid)
            } else {
                await MainActor.run { app.user = nil }
            }
            await MainActor.run { checkingAuth = false }
        }
    }

    /// Drops the Firebase auth listener when the view goes away.
    func detachAuthListener() {
        if let h = authHandle {
            Auth.auth().removeStateDidChangeListener(h)
            authHandle = nil
        }
    }

    /// Loads the `/users/{uid}` document and hydrates `app.user`.
    func loadUserProfile(uid: String) async {
        do {
            let snap = try await Firestore.firestore()
                .collection("users").document(uid).getDocument()

            // If there is no user doc yet, a default "Player" profile is built locally.
            guard let data = snap.data() else {
                let authUser = Auth.auth().currentUser
                let nbUser = NBUser(
                    id: uid,
                    email: authUser?.email ?? "",
                    username: "Player",
                    avatarPath: nil,
                    createdAt: Date()
                )
                await MainActor.run { app.user = nbUser }
                return
            }

            let username = (data["username"] as? String) ?? "Player"
            let email = (data["email"] as? String) ?? (Auth.auth().currentUser?.email ?? "")
            let avatarPath = data["avatarPath"] as? String
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

            let nbUser = NBUser(id: uid, email: email, username: username, avatarPath: avatarPath, createdAt: createdAt)
            await MainActor.run { app.user = nbUser }
        } catch {
            // If anything explodes here, just treat it as "no user".
            await MainActor.run { app.user = nil }
        }
    }
}
