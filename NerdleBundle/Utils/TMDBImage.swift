//
//  TMDBImage.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import Foundation

enum TMDBImage {
    static func url(_ path: String?, size: String = "w500") -> URL? {
        guard let p = path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(p)")
    }
}
