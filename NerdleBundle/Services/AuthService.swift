//
//  AuthService.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol AuthServiceListener: AnyObject {
    func authStateChanged(user: User?)
}

final class AuthService {
    static let shared = AuthService()
    private let fm = FirebaseManager.shared

    let listeners = MulticastDelegate<AuthServiceListener>()

    private init() {
        fm.auth.addStateDidChangeListener { [weak self] _, user in
            self?.listeners.invoke { $0.authStateChanged(user: user) }
        }
    }

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
