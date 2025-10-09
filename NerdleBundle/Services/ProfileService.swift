//
//  ProfileService.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

final class ProfileService {
    static let shared = ProfileService()
    private let fm = FirebaseManager.shared
    private init() {}

    func updateUsername(_ username: String) async throws {
        guard let uid = fm.auth.currentUser?.uid else { throw NSError(domain: "auth", code: 401) }
        try await fm.db.collection("users").document(uid).setData(["username": username], merge: true)
    }

    func uploadAvatar(image: UIImage) async throws {
        guard let uid = fm.auth.currentUser?.uid else { throw NSError(domain: "auth", code: 401) }
        guard let data = image.jpegData(compressionQuality: 0.85) else { throw NSError(domain: "img", code: 0) }

        let path = "avatars/\(uid).jpg"
        let ref = fm.storage.reference(withPath: path)
        _ = try await ref.putDataAsync(data, metadata: nil)

        try await fm.db.collection("users").document(uid).setData([
            "avatarPath": path
        ], merge: true)
    }
}
