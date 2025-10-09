//
//  ScoreService.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class ScoreService {
    static let shared = ScoreService()
    private let fm = FirebaseManager.shared
    private init() {}

    func submitFilmConnections(points: Int, distance: Int, durationSec: Int) async throws {
        try await submit(game: .filmConnections, points: points,
                         extra: ["distance": distance, "durationSec": durationSec])
    }

    func submitSteamdle(points: Int, attemptsUsed: Int) async throws {
        try await submit(game: .steamdle, points: points,
                         extra: ["attemptsUsed": attemptsUsed])
    }

    private func submit(game: GameType, points: Int, extra: [String: Any]) async throws {
        guard let uid = fm.auth.currentUser?.uid else { throw NSError(domain: "auth", code: 401) }

        var data: [String: Any] = [
            "uid": uid,
            "game": game.rawValue,
            "points": points,
            "createdAt": FieldValue.serverTimestamp()
        ]
        extra.forEach { data[$0.key] = $0.value }

        _ = try await fm.db.collection("scores").addDocument(data: data)
    }
}
