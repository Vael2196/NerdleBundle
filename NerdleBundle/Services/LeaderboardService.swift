//
//  LeaderboardService.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import Foundation
import FirebaseFirestore

protocol LeaderboardListener: AnyObject {
    func leaderboardUpdated(span: LeaderboardSpan, items: [LeaderboardEntry])
}

struct LeaderboardEntry: Identifiable {
    let id: String
    let username: String
    let points: Int
    let uid: String
}

final class LeaderboardService {
    static let shared = LeaderboardService()
    private let fm = FirebaseManager.shared
    private var listenersBySpan: [LeaderboardSpan: ListenerRegistration] = [:]

    let listeners = MulticastDelegate<LeaderboardListener>()
    private init() {}

    func start(span: LeaderboardSpan, limit: Int = 100) {
        stop(span: span)

        let q: Query
        let scores = fm.db.collection("scores")

        switch span {
        case .daily:
            let (start, end) = Date.utcDayBounds()
            q = scores
                .whereField("createdAt", isGreaterThanOrEqualTo: start)
                .whereField("createdAt", isLessThan: end)
                .order(by: "points", descending: true)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)

        case .weekly:
            let (start, end) = Date.utcWeekBounds()
            q = scores
                .whereField("createdAt", isGreaterThanOrEqualTo: start)
                .whereField("createdAt", isLessThan: end)
                .order(by: "points", descending: true)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)

        case .allTime:
            q = scores
                .order(by: "points", descending: true)
                .limit(to: limit)
        }

        listenersBySpan[span] = q.addSnapshotListener { [weak self] snap, _ in
            guard let self = self, let docs = snap?.documents else { return }
            self.resolveEntries(docs: docs) { entries in
                self.listeners.invoke { $0.leaderboardUpdated(span: span, items: entries) }
            }
        }
    }

    func stop(span: LeaderboardSpan) {
        listenersBySpan[span]?.remove()
        listenersBySpan.removeValue(forKey: span)
    }

    // TODO: I am yet to test this "You are smarter than 90% of the people in the room" ahh thing out, but I gotta figure out the score/point system and implement the actual games to give away those points first, I reckon
    func percentile(forPoints points: Int, span: LeaderboardSpan) async throws -> Double {
        let scores = fm.db.collection("scores")
        let q: Query
        switch span {
        case .daily:
            let (start, end) = Date.utcDayBounds()
            q = scores.whereField("createdAt", isGreaterThanOrEqualTo: start)
                      .whereField("createdAt", isLessThan: end)
        case .weekly:
            let (start, end) = Date.utcWeekBounds()
            q = scores.whereField("createdAt", isGreaterThanOrEqualTo: start)
                      .whereField("createdAt", isLessThan: end)
        case .allTime:
            q = scores
        }

        let totalAgg = try await q.count.getAggregation(source: .server)
        let total = totalAgg.count.intValue

        let higherAgg = try await q.whereField("points", isGreaterThan: points).count.getAggregation(source: .server)
        let higher = higherAgg.count.intValue

        guard total > 0 else { return 0 }
        let rank = higher + 1
        let percentile = (1.0 - Double(rank - 1) / Double(total)) * 100.0
        return max(0, min(100, percentile))
    }

    private func resolveEntries(docs: [QueryDocumentSnapshot], completion: @escaping ([LeaderboardEntry]) -> Void) {
        let group = DispatchGroup()
        var entries: [LeaderboardEntry] = []
        let db = fm.db

        for d in docs {
            let data = d.data()
            let uid = data["uid"] as? String ?? ""
            let points = data["points"] as? Int ?? 0

            group.enter()
            db.collection("users").document(uid).getDocument { snap, _ in
                let username = snap?.data()?["username"] as? String ?? "Player"
                entries.append(LeaderboardEntry(id: d.documentID, username: username, points: points, uid: uid))
                group.leave()
            }
        }
        group.notify(queue: .main) { completion(entries.sorted { $0.points > $1.points }) }
    }
}
