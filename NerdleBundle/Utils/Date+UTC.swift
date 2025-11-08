//
//  Date+UTC.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import Foundation

/// High-level spans used by leaderboard queries.
enum LeaderboardSpan { case daily, weekly, allTime }

/// UTC-based helpers for anything that should be timezone-agnostic
/// or consistent with server/Firestore semantics.
/// (mostly the latter)
extension Date {
    static func utcNow() -> Date {
        let now = Date()
        let tz = TimeZone(secondsFromGMT: 0)!
        let secs = TimeInterval(tz.secondsFromGMT(for: now))
        return Date(timeInterval: -secs, since: now)
    }

    static func utcDayBounds(for date: Date = Date()) -> (start: Date, end: Date) {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    static func utcWeekBounds(for date: Date = Date()) -> (start: Date, end: Date) {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let end = cal.date(byAdding: .day, value: 7, to: start)!
        return (start, end)
    }
}
