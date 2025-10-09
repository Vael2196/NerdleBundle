//
//  Models.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import Foundation

enum LeaderboardPeriod: String, CaseIterable {
    case daily, weekly, allTime
}

enum GameType: String, Codable {
    case filmConnections = "film_connections"
    case steamdle = "steamdle"
}

struct NBUser: Codable, Identifiable, Equatable {
    var id: String
    var email: String
    var username: String
    var avatarPath: String?
    var createdAt: Date
}

struct Score: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var uid: String
    var game: GameType
    var points: Int
    var createdAt: Date

    var durationSec: Int?
    var distance: Int?
    var attemptsUsed: Int?
}
