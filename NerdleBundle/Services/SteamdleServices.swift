//
//  SteamdleServices.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import Foundation
import FirebaseFunctions

final class SteamdleBackend {
    static let shared = SteamdleBackend()
    private let functions = Functions.functions(region: "australia-southeast2")

    func getToday() async throws -> SteamdleDailyPayload {
        let result = try await functions.httpsCallable("getTodaySteamdle").call()
        guard let dict = result.data as? [String: Any] else {
            throw NSError(domain: "SteamdleBackend", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad payload"])
        }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        return try JSONDecoder().decode(SteamdleDailyPayload.self, from: data)
    }
}
