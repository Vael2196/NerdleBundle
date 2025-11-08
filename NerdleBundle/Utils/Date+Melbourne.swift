//
//  Date+Melbourne.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import Foundation

/// Helper date utilities that treat "time" as Australia/Melbourne.
/// Used for anything that should follow local time (e.g. daily/weekly quotas in the app).
extension Date {
    /// Calendar locked to Melbourne time, Monday-start week, Aussie locale.
    static var melCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_AU")
        cal.timeZone = TimeZone(identifier: "Australia/Melbourne") ?? .current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    /// Returns [start, end) for the given day in Melbourne time.
    /// End is literally "next midnight", so it's safe for Firestore range queries.
    static func melDayBounds(from date: Date = Date()) -> (Date, Date) {
        let cal = melCalendar
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    /// Returns [start, end) for the current week (Mon–Sun) in Melbourne time.
    /// Uses `dateInterval(of: .weekOfYear)` when possible, with a manual fallback.
    static func melWeekBounds(from date: Date = Date()) -> (Date, Date) {
        let cal = melCalendar
        if let interval = cal.dateInterval(of: .weekOfYear, for: date) {
            return (interval.start, interval.end)
        }
        // Fallback just in case...
        let (dStart, _) = melDayBounds(from: date)
        let weekday = cal.component(.weekday, from: dStart)
        // This math basically determines "how far is this from Monday?"
        let daysFromMonday = (weekday >= 2) ? (weekday - 2) : (7 - (2 - weekday))
        let start = cal.date(byAdding: .day, value: -daysFromMonday, to: dStart)!
        let end = cal.date(byAdding: .day, value: 7, to: start)!
        return (start, end)
    }
}
