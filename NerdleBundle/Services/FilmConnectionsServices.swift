//
//  FilmConnectionsServices.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore

final class FCBackend {
    static let shared = FCBackend()
    private let functions = Functions.functions(region: "australia-southeast2")

    func getToday() async throws -> FCDailyPayload {
        let result = try await functions.httpsCallable("getTodayFilmPair").call()
        guard let dict = result.data as? [String: Any] else {
            throw NSError(domain: "FCBackend", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad payload"])
        }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        return try JSONDecoder().decode(FCDailyPayload.self, from: data)
    }

    func getCast(movieId: Int) async throws -> [FCPerson] {
        let res = try await functions.httpsCallable("getMovieCast").call(["movieId": movieId])
        guard let dict = res.data as? [String: Any] else { return [] }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        struct Envelope: Codable { let cast: [FCPerson] }
        return try JSONDecoder().decode(Envelope.self, from: data).cast
    }

    func getMovies(personId: Int) async throws -> [FCMovie] {
        let res = try await functions.httpsCallable("getPersonMovies").call(["personId": personId])
        guard let dict = res.data as? [String: Any] else { return [] }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        struct Envelope: Codable { let movies: [FCMovie] }
        return try JSONDecoder().decode(Envelope.self, from: data).movies
    }
}

final class FCLocalStore {
    static let shared = FCLocalStore()
    private let key = "nb.fc.result"

    func load(dayId: String) -> FCResult? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        guard let result = try? JSONDecoder().decode(FCResult.self, from: data) else { return nil }
        return result.dayId == dayId ? result : nil
    }

    func save(_ result: FCResult) {
        if let data = try? JSONEncoder().encode(result) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clear() { UserDefaults.standard.removeObject(forKey: key) }
}

final class FCScoreService {
    func submit(result: FCResult) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "nb", code: 401, userInfo: [NSLocalizedDescriptionKey: "Sign in required"])
        }
        let db = Firestore.firestore()
        let doc = db.collection("scores").document()
        try await doc.setData([
            "id": doc.documentID,
            "uid": uid,
            "game": "film_connections",
            "points": result.points,
            "createdAt": FieldValue.serverTimestamp(),
            "durationSec": result.durationSec,
            "distance": result.distance,
            "dayId": result.dayId,
        ])
    }
}
