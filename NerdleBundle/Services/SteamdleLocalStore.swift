//
//  SteamdleLocalStore.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import Foundation

/// Saved state for a single guess in Steamdle.
/// This gets encoded into UserDefaults via `SteamdleProgress`.
enum SteamdleGuessState: String, Codable { case tooLow, tooHigh, correct }

struct SteamdleSavedAttempt: Codable {
    let guess: Double
    let state: SteamdleGuessState
}

/// Snapshot of where the player is in today’s Steamdle run:
/// which round, what guesses they’ve made, and which games are revealed.
struct SteamdleProgress: Codable {
    var dayId: String
    var roundIndex: Int
    var attempts: [[SteamdleSavedAttempt]]
    var revealed: [Bool]
}

/// Local store for Steamdle progress.
/// Used to prevent cheating and to restore an in-progress session per day.
final class SteamdleLocalStore {
    static let shared = SteamdleLocalStore()
    private let key = "nb.steamdle.progress"

    func load(dayId: String) -> SteamdleProgress? {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let progress = try? JSONDecoder().decode(SteamdleProgress.self, from: data),
            progress.dayId == dayId
        else { return nil }
        // `sanitized()` makes sure the array shapes are valid (3 rounds, etc.).
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
    /// Ensures the struct is in a safe shape:
    ///  - `attempts` and `revealed` always have 3 entries
    ///  - `roundIndex` stays in [0, 2]
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
