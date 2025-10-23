//
//  Date+Melbourne.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import Foundation

extension Date {
    static var melCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_AU")
        cal.timeZone = TimeZone(identifier: "Australia/Melbourne") ?? .current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    static func melDayBounds(from date: Date = Date()) -> (Date, Date) {
        let cal = melCalendar
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    static func melWeekBounds(from date: Date = Date()) -> (Date, Date) {
        let cal = melCalendar
        if let interval = cal.dateInterval(of: .weekOfYear, for: date) {
            return (interval.start, interval.end)
        }
        let (dStart, _) = melDayBounds(from: date)
        let weekday = cal.component(.weekday, from: dStart)
        let daysFromMonday = (weekday >= 2) ? (weekday - 2) : (7 - (2 - weekday))
        let start = cal.date(byAdding: .day, value: -daysFromMonday, to: dStart)!
        let end = cal.date(byAdding: .day, value: 7, to: start)!
        return (start, end)
    }
}
