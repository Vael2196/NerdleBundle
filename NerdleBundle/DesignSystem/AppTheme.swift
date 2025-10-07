//
//  AppTheme.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

enum NB {
    static let corner: CGFloat = 20
}

extension Color {
    static let nbBackground = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let nbHeader = Color(red: 0.11, green: 0.12, blue: 0.14)
    static let nbCard = Color(red: 0.16, green: 0.17, blue: 0.20)
    static let nbCrimson = Color(red: 0.75, green: 0.00, blue: 0.01)
    static let nbGold = Color(red: 0.75, green: 0.53, blue: 0.13)
    static let nbMutedRed = Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50)
    static let nbTextPrimary = Color.white
    static let nbTextSecondary = Color(red: 0.85, green: 0.85, blue: 0.85)
}

extension ShapeStyle where Self == Color {
    static var nbBackground: Color { Color.nbBackground }
    static var nbHeader: Color { Color.nbHeader }
    static var nbCard: Color { Color.nbCard }
    static var nbCrimson: Color { Color.nbCrimson }
    static var nbGold: Color { Color.nbGold }
    static var nbMutedRed: Color { Color.nbMutedRed }
    static var nbTextPrimary: Color { Color.nbTextPrimary }
    static var nbTextSecondary: Color { Color.nbTextSecondary }
}
