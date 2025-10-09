//
//  AppState.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import Combine


final class AppState: ObservableObject {
    @AppStorage("nb.isDarkMode") var isDarkMode: Bool = true
    @AppStorage("nb.textScale") var textScale: Double = 1.0

    @Published var user: NBUser? = nil
}

extension AppState {
    var dynamicTypeSize: DynamicTypeSize {
        switch textScale {
        case ..<0.95: return .small
        case 0.95..<1.05: return .medium
        case 1.05..<1.2: return .large
        default: return .xLarge
        }
    }

    var darkModeBinding: Binding<Bool> {
        Binding(get: { self.isDarkMode }, set: { self.isDarkMode = $0 })
    }
    var textScaleBinding: Binding<Double> {
        Binding(get: { self.textScale }, set: { self.textScale = $0 })
    }
}
