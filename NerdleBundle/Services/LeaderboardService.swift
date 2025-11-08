//
//  LeaderboardService.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import Foundation
import FirebaseFirestore

/// Anything that wants live leaderboard updates implements this.
protocol LeaderboardListener: AnyObject {
    func leaderboardUpdated(span: LeaderboardSpan, items: [LeaderboardEntry])
}

/// Simple value type for a ranked user row.
struct LeaderboardEntry: Identifiable {
    let id: String
    let username: String
    let points: Int
    let uid: String
}

/// Service that streams leaderboards from Firestore and aggregates
/// scores per user (daily/weekly/all-time).
final class LeaderboardService {
    static let shared = LeaderboardService()
    private let fm = FirebaseManager.shared
    private var listenersBySpan: [LeaderboardSpan: ListenerRegistration] = [:]

    /// Tiny username cache to avoid re-fetching /users/{uid} for every snapshot.
    private var usernameCache: [String: String] = [:]

    let listeners = MulticastDelegate<LeaderboardListener>()
    private init() {}

    /// Starts listening for a leaderboard span and notifies all delegates.
    func start(span: LeaderboardSpan, limit: Int = 100) {
        stop(span: span)

        let scores = fm.db.collection("scores")
        let q: Query

        switch span {
        case .daily:
            let (start, end) = Date.utcDayBounds()
            q = scores
                .whereField("createdAt", isGreaterThanOrEqualTo: start)
                .whereField("createdAt", isLessThan: end)

        case .weekly:
            let (start, end) = Date.utcWeekBounds()
            q = scores
                .whereField("createdAt", isGreaterThanOrEqualTo: start)
                .whereField("createdAt", isLessThan: end)

        case .allTime:
            q = scores
        }

        listenersBySpan[span] = q.addSnapshotListener { [weak self] snap, _ in
            guard let self = self, let docs = snap?.documents else { return }
            // Docs here are raw score entries; this call folds them into per-user totals.
            self.aggregateAndResolve(docs: docs, limit: limit) { entries in
                self.listeners.invoke { $0.leaderboardUpdated(span: span, items: entries) }
            }
        }
    }

    func stop(span: LeaderboardSpan) {
        listenersBySpan[span]?.remove()
        listenersBySpan.removeValue(forKey: span)
    }

    /// This function:
    ///  - groups all score docs by uid
    ///  - resolves usernames (with a tiny cache)
    ///  - sorts by total points and trims to `limit`
    private func aggregateAndResolve(docs: [QueryDocumentSnapshot],
                                     limit: Int,
                                     completion: @escaping ([LeaderboardEntry]) -> Void) {
        var totals: [String: Int] = [:]
        for d in docs {
            let data = d.data()
            guard let uid = data["uid"] as? String else { continue }
            let pts = data["points"] as? Int ?? 0
            totals[uid, default: 0] += pts
        }

        let uids = Array(totals.keys)
        var resolved: [LeaderboardEntry] = []
        let group = DispatchGroup()

        for uid in uids {
            if let name = usernameCache[uid] {
                resolved.append(LeaderboardEntry(id: uid, username: name, points: totals[uid] ?? 0, uid: uid))
                continue
            }

            group.enter()
            fm.db.collection("users").document(uid).getDocument { [weak self] snap, _ in
                let name = (snap?.data()?["username"] as? String) ?? "Player"
                self?.usernameCache[uid] = name
                resolved.append(LeaderboardEntry(id: uid, username: name, points: totals[uid] ?? 0, uid: uid))
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let sorted = resolved.sorted {
                if $0.points == $1.points { return $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
                return $0.points > $1.points
            }

            completion(Array(sorted.prefix(limit)))
        }
    }

    /// Computes percentile based on how many players have strictly higher points.
    /// Uses Firestore count aggregations so the client doesn’t need to download everything.
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
}
