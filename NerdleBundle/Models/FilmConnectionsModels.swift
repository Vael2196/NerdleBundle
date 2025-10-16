//
//  FilmConnectionsModels.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import Foundation


struct FCMovie: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let posterPath: String?
    let releaseDate: String?
}

enum FCNodeType: String, Codable { case movie, person }

struct FCNode: Codable, Identifiable, Equatable {
    let type: FCNodeType
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let releaseDate: String?

    var display: String { title ?? name ?? "—" }
}

struct FCDailyPayload: Codable {
    let dayId: String
    let movieA: FCMovie
    let movieB: FCMovie
    let shortestPath: [FCNode]?
    let shortestDistance: Int?
    let status: String?
}

struct FCResult: Codable {
    let dayId: String
    let path: [FCNode]
    let distance: Int
    let durationSec: Int
    let points: Int
    let finishedAt: Date
}

struct FCPerson: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let profilePath: String?
}
