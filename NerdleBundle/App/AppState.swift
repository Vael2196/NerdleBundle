//
//  AppState.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import Combine

/// Global app state that gets injected with `.environmentObject`.
/// Handles user session + UI prefs like dark mode and text scale.
final class AppState: ObservableObject {
    @AppStorage("nb.isDarkMode") var isDarkMode: Bool = true
    @AppStorage("nb.textScale") var textScale: Double = 1.0

    @Published var user: NBUser? = nil
}

extension AppState {
    /// Maps the custom `textScale` slider to a SwiftUI DynamicTypeSize.
    /// Not super precise, just vibes-based buckets that feel ok.
    var dynamicTypeSize: DynamicTypeSize {
        switch textScale {
        case ..<0.95: return .small
        case 0.95..<1.05: return .medium
        case 1.05..<1.2: return .large
        default: return .xLarge
        }
    }

    /// Handy binding for toggles that just want a Bool.
    var darkModeBinding: Binding<Bool> {
        Binding(get: { self.isDarkMode }, set: { self.isDarkMode = $0 })
    }
    
    /// Handy binding for the text size slider.
    var textScaleBinding: Binding<Double> {
        Binding(get: { self.textScale }, set: { self.textScale = $0 })
    }
}
