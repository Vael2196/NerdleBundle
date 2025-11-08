//
//  AccountSummaryVM.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// View model that powers the Account summary screen:
/// pulls scores from Firestore, builds the donut chart data,
/// and computes the "how cracked are you" percentile.
@MainActor
final class AccountSummaryVM: ObservableObject {
    @Published var dailyPoints: Int = 0
    @Published var weeklyPoints: Int = 0

    @Published var last7Days: [DayPoint] = []
    @Published var percentile: Double = 0
    @Published var allTimeRankText: String = "#—"

    /// Controls what the donut chart is showing right now.
    enum ChartMode { case percentile, dailyAvg }
    @Published var chartMode: ChartMode = .percentile

    /// bucket for "points per day" in the last 7 days.
    struct DayPoint: Identifiable {
        var id: String { key }
        let date: Date
        let key: String
        let total: Int
    }

    private let db = Firestore.firestore()

    func onAppear() {
        Task { await refreshAll() }
    }

    /// This function kicks off all Firestore reads in parallel,
    /// so the Account tab doesn’t go into sleep mode
    func refreshAll() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let a = refreshDailyAndWeekly(uid: uid)
        async let b = refreshLast7Days(uid: uid)
        async let c = refreshAllTimeRankAndPercentile(uid: uid)
        _ = await (a, b, c)
    }

    private func refreshDailyAndWeekly(uid: String) async {
        let (dStart, dEnd) = Date.melDayBounds()
        let (wStart, wEnd) = Date.melWeekBounds()

        do {
            let dailySnap = try await db.collection("scores")
                .whereField("uid", isEqualTo: uid)
                .whereField("createdAt", isGreaterThanOrEqualTo: dStart)
                .whereField("createdAt", isLessThan: dEnd)
                .getDocuments()

            let dTotal = dailySnap.documents.reduce(0) { $0 + ( $1.data()["points"] as? Int ?? 0 ) }

            let weeklySnap = try await db.collection("scores")
                .whereField("uid", isEqualTo: uid)
                .whereField("createdAt", isGreaterThanOrEqualTo: wStart)
                .whereField("createdAt", isLessThan: wEnd)
                .getDocuments()

            let wTotal = weeklySnap.documents.reduce(0) { $0 + ( $1.data()["points"] as? Int ?? 0 ) }

            self.dailyPoints = dTotal
            self.weeklyPoints = wTotal
        } catch {
            print("refreshDailyAndWeekly error:", error.localizedDescription)
        }
    }

    private func refreshLast7Days(uid: String) async {
        let cal = Date.melCalendar
        let todayStart = cal.startOfDay(for: Date())
        let start7 = cal.date(byAdding: .day, value: -6, to: todayStart)!
        let end7   = cal.date(byAdding: .day, value: 1,  to: todayStart)!

        do {
            let snap = try await db.collection("scores")
                .whereField("uid", isEqualTo: uid)
                .whereField("createdAt", isGreaterThanOrEqualTo: start7)
                .whereField("createdAt", isLessThan: end7)
                .getDocuments()

            var buckets: [String: Int] = [:]
            // Pre-seed all 7 days so missing days show up as 0 instead of vanishing.
            for i in 0..<7 {
                let day = cal.date(byAdding: .day, value: i, to: start7)!
                let key = Self.key(for: day)
                buckets[key] = 0
            }

            // Bucket scores by yyyy-MM-dd in Melbourne time.
            for d in snap.documents {
                guard let ts = d.data()["createdAt"] as? Timestamp else { continue }
                let stamp = ts.dateValue()
                let key = Self.key(for: cal.startOfDay(for: stamp))
                buckets[key, default: 0] += (d.data()["points"] as? Int ?? 0)
            }

            // Daily points are capped at 25 (10 FC + 15 Steamdle max).
            for (k, v) in buckets {
                buckets[k] = min(25, v)
            }

            let series: [DayPoint] = buckets.keys.sorted().compactMap { key in
                if let total = buckets[key],
                   let date = Self.date(fromKey: key) {
                    return DayPoint(date: date, key: key, total: total)
                }
                return nil
            }

            self.last7Days = series
        } catch {
            print("refreshLast7Days error:", error.localizedDescription)
        }
    }

    /// This function crunches:
    ///  - all-time total points for the current user
    ///  - rank among all users
    ///  - percentile *excluding* the user from the denominator,
    /// so #1 player gets a clean 100%.
    private func refreshAllTimeRankAndPercentile(uid: String) async {
        do {
            let snap = try await db.collection("scores").getDocuments()

            var totals: [String: Int] = [:]
            for d in snap.documents {
                let data = d.data()
                guard let u = data["uid"] as? String else { continue }
                totals[u, default: 0] += (data["points"] as? Int ?? 0)
            }

            let my = totals[uid] ?? 0
            let others = totals.filter { $0.key != uid }
            let totalOthers = others.count
            let betterThanCount = others.filter { $0.value < my }.count
            let higherCount = others.filter { $0.value > my }.count

            let rank = higherCount + 1
            let pct  = totalOthers > 0 ? (Double(betterThanCount) / Double(totalOthers)) * 100.0 : 100.0

            self.allTimeRankText = "#\(rank)"
            self.percentile = max(0, min(100, pct))
        } catch {
            print("refreshAllTimeRankAndPercentile error:", error.localizedDescription)
        }
    }

    /// Turns a Date into a yyyy-MM-dd string in Melbourne time.
    private static func key(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Date.melCalendar
        f.timeZone = Date.melCalendar.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Parses a yyyy-MM-dd string back into a Date in Melbourne time.
    private static func date(fromKey key: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Date.melCalendar
        f.timeZone = Date.melCalendar.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }
}
