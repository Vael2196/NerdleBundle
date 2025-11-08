//
//  SteamdleModels.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import Foundation

/// One Steamdle game "card" pulled from the backend.
/// Maps pretty closely to Steam app details but trimmed for what the UI needs.
struct SteamdleGame: Codable, Identifiable, Equatable {
    /// Use `appid` as the SwiftUI `id` so lists stay stable.
    var id: Int { appid }
    let appid: Int
    let name: String
    let headerImage: String
    let screenshots: [String]
    let genres: [String]
    let priceAUD: Double
}

/// Payload for the daily Steamdle set (3 games per day).
struct SteamdleDailyPayload: Codable {
    let dayId: String
    let games: [SteamdleGame]
    /// Backend status: ready / choosing / error / etc.
    let status: String?
}
