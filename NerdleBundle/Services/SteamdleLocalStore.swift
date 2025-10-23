//
//  SteamdleLocalStore.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import Foundation


enum SteamdleGuessState: String, Codable { case tooLow, tooHigh, correct }

struct SteamdleSavedAttempt: Codable {
    let guess: Double
    let state: SteamdleGuessState
}

struct SteamdleProgress: Codable {
    var dayId: String
    var roundIndex: Int
    var attempts: [[SteamdleSavedAttempt]]
    var revealed: [Bool]
}

final class SteamdleLocalStore {
    static let shared = SteamdleLocalStore()
    private let key = "nb.steamdle.progress"

    func load(dayId: String) -> SteamdleProgress? {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let progress = try? JSONDecoder().decode(SteamdleProgress.self, from: data),
            progress.dayId == dayId
        else { return nil }
        return progress.sanitized()
    }

    func save(_ progress: SteamdleProgress) {
        guard let data = try? JSONEncoder().encode(progress.sanitized()) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

private extension SteamdleProgress {
    func sanitized() -> SteamdleProgress {
        var a = attempts
        var r = revealed
        if a.count < 3 { a.append(contentsOf: Array(repeating: [], count: 3 - a.count)) }
        if r.count < 3 { r.append(contentsOf: Array(repeating: false, count: 3 - r.count)) }
        return SteamdleProgress(dayId: dayId,
                                roundIndex: min(max(roundIndex, 0), 2),
                                attempts: Array(a.prefix(3)),
                                revealed: Array(r.prefix(3)))
    }
}
