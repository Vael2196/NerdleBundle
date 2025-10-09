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

final class FirebaseManager {
    static let shared = FirebaseManager()
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    private init() {}
}
