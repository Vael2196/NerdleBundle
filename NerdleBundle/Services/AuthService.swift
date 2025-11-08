//
//  AuthService.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Listener protocol for anything that wants to react to auth changes
/// (e.g. AppState updating the current NBUser).
protocol AuthServiceListener: AnyObject {
    func authStateChanged(user: User?)
}

/// Tiny wrapper around FirebaseAuth + Firestore user bootstrap.
/// This type keeps all auth logic in one place instead of sprinkling it everywhere.
final class AuthService {
    static let shared = AuthService()
    private let fm = FirebaseManager.shared

    let listeners = MulticastDelegate<AuthServiceListener>()

    private init() {
        // This listener is basically the "global auth event bus".
        fm.auth.addStateDidChangeListener { [weak self] _, user in
            self?.listeners.invoke { $0.authStateChanged(user: user) }
        }
    }

    /// Signs the user up and creates a matching /users/{uid} doc.
    func signUp(email: String, password: String, username: String) async throws {
        let result = try await fm.auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let doc: [String: Any] = [
            "email": email,
            "username": username,
            "avatarPath": NSNull(),
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await fm.db.collection("users").document(uid).setData(doc, merge: true)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await fm.auth.signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try fm.auth.signOut()
    }

    func currentUID() -> String? { fm.auth.currentUser?.uid }
}
