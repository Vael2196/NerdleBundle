//
//  Models.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import Foundation

/// UI-facing selection for leaderboard tabs.
/// Different from `LeaderboardSpan` (which is more backend/query oriented).
enum LeaderboardPeriod: String, CaseIterable {
    case daily, weekly, allTime
}

/// Supported game types in the app.
/// Raw values match what's written to Firestore.
enum GameType: String, Codable {
    case filmConnections = "film_connections"
    case steamdle = "steamdle"
}

/// Top-level user profile stored in Firestore.
/// This is basically the "account" object used throughout the app.
struct NBUser: Codable, Identifiable, Equatable {
    var id: String
    var email: String
    var username: String
    var avatarPath: String?
    var createdAt: Date
}

/// Single score entry written into the `scores` collection.
/// Different games may use different extra fields depending on what makes sense.
struct Score: Codable, Identifiable, Equatable {
    /// Local UUID so it can behave nicely as `Identifiable` even before Firestore writes.
    var id: String = UUID().uuidString
    var uid: String
    var game: GameType
    var points: Int
    var createdAt: Date

    /// Optional extra metadata depending on the game type.
    var durationSec: Int?
    var distance: Int?
    var attemptsUsed: Int?
}
