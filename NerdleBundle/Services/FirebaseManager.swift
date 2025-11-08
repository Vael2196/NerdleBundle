//
//  FirebaseManager.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Central place for all Firebase singletons used by the app.
/// This keeps the rest of the code from calling `Auth.auth()` etc. directly.
final class FirebaseManager {
    static let shared = FirebaseManager()
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    private init() {}
}
