//
//  TMDBImage.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import Foundation

/// Tiny helper for building full TMDB image URLs from their relative `poster_path` / `profile_path`.
/// Keeps the base URL + size string in one place so it’s not hard-coded everywhere.
enum TMDBImage {
    static func url(_ path: String?, size: String = "w500") -> URL? {
        guard let p = path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(p)")
    }
}
