//
//  Models.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import Foundation

struct User: Identifiable, Equatable {
    let id: String
    var username: String
    var email: String
    var avatarURL: URL?
}

enum GameType: String, CaseIterable, Codable {
    case filmConnections
    case steamdle
}

enum LeaderboardPeriod: String, CaseIterable {
    case daily, weekly, allTime
}

struct ScoreEntry: Identifiable {
    let id = UUID().uuidString
    let username: String
    let points: Int
    let game: GameType
    let date: Date
}
