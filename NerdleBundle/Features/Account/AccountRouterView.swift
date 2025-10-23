//
//  AccountRouterView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountRouterView: View {
    @EnvironmentObject private var app: AppState

    @State private var checkingAuth = true
    @State private var authHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        ZStack {
            Color.nbBackground.ignoresSafeArea()

            if checkingAuth {
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
    func attachAuthListener() {
        // If we already attached, skip
        if authHandle != nil { return }

        checkingAuth = true

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

    func detachAuthListener() {
        if let h = authHandle {
            Auth.auth().removeStateDidChangeListener(h)
            authHandle = nil
        }
    }

    func loadUserProfile(uid: String) async {
        do {
            let snap = try await Firestore.firestore()
                .collection("users").document(uid).getDocument()

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
            await MainActor.run { app.user = nil }
        }
    }
}
