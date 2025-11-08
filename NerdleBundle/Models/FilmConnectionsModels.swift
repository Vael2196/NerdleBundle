//
//  FilmConnectionsModels.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import Foundation

/// Core movie info used across FilmConnections screens.
/// This mirrors what comes back from TMDB (but trimmed down).
struct FCMovie: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let posterPath: String?
    let releaseDate: String?
}

/// Node type in the FilmConnections graph: either a movie or a person (actor).
enum FCNodeType: String, Codable { case movie, person }

/// Generic graph node used for paths: can represent movies or people.
/// This is what gets shown in the connection chain.
struct FCNode: Codable, Identifiable, Equatable {
    let type: FCNodeType
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let releaseDate: String?

    var display: String { title ?? name ?? "—" }
}

/// Payload from the Cloud Function for the daily FilmConnections puzzle.
/// Contains the two endpoints and the (optionally precomputed) shortest path.
struct FCDailyPayload: Codable {
    let dayId: String
    let movieA: FCMovie
    let movieB: FCMovie
    let shortestPath: [FCNode]?
    let shortestDistance: Int?
    /// Status string from backend (ready / pending / error / etc.).
    let status: String?
}

/// Saved result for a completed FilmConnections run.
/// Used both for local storage and for sending scores.
struct FCResult: Codable {
    let dayId: String
    let path: [FCNode]
    let distance: Int
    let durationSec: Int
    let points: Int
    let finishedAt: Date
}

/// Minimal person model used when browsing cast/filmography.
/// This lines up with TMDB "person" objects.
struct FCPerson: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let profilePath: String?
}
