//
//  SteamdleModels.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import Foundation

struct SteamdleGame: Codable, Identifiable, Equatable {
    var id: Int { appid }
    let appid: Int
    let name: String
    let headerImage: String
    let screenshots: [String]
    let genres: [String]
    let priceAUD: Double
}

struct SteamdleDailyPayload: Codable {
    let dayId: String
    let games: [SteamdleGame]
    let status: String?
}
