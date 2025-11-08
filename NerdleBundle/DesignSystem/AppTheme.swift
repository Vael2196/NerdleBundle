//
//  AppTheme.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

/// Global design tokens for the app.
/// Anything that feels "Nerdle-y" visually probably comes from here.
enum NB {
    static let corner: CGFloat = 20
}

private extension UIColor {
    /// Tiny helper that returns a color that auto-switches for light/dark mode.
    /// Basically "vibes, but dynamic".
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension Color {
    // Base palette for light mode.
    private static let lightBackground = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
    private static let lightHeader = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    private static let lightCard = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0)
    private static let lightTextPri = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
    private static let lightTextSec = UIColor(red: 0.40, green: 0.41, blue: 0.43, alpha: 1.0)
    private static let lightMutedRed = UIColor(red: 0.90, green: 0.65, blue: 0.68, alpha: 0.50)

    // Base palette for dark mode.
    private static let darkBackground = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)
    private static let darkHeader = UIColor(red: 0.11, green: 0.12, blue: 0.14, alpha: 1.0)
    private static let darkCard = UIColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1.0)
    private static let darkTextPri = UIColor.white
    private static let darkTextSec = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    private static let darkMutedRed = UIColor(red: 0.50, green: 0.23, blue: 0.27, alpha: 0.50)

    // Accent colors that stay the same across themes, 'cuz I am lazy
    private static let crimson = UIColor(red: 0.75, green: 0.00, blue: 0.01, alpha: 1.0)
    private static let gold = UIColor(red: 0.75, green: 0.53, blue: 0.13, alpha: 1.0)

    static var nbBackground: Color { Color(UIColor.dynamic(light: lightBackground, dark: darkBackground)) }
    static var nbHeader: Color { Color(UIColor.dynamic(light: lightHeader, dark: darkHeader)) }
    static var nbCard: Color { Color(UIColor.dynamic(light: lightCard, dark: darkCard)) }
    static var nbTextPrimary: Color { Color(UIColor.dynamic(light: lightTextPri, dark: darkTextPri)) }
    static var nbTextSecondary: Color { Color(UIColor.dynamic(light: lightTextSec, dark: darkTextSec)) }
    static var nbMutedRed: Color { Color(UIColor.dynamic(light: lightMutedRed, dark: darkMutedRed)) }
    static var nbCrimson: Color { Color(crimson) }
    static var nbGold: Color { Color(gold) }
}

extension ShapeStyle where Self == Color {
    /// These let `nbBackground` etc be used directly as a `ShapeStyle`,
    /// so stuff like `.fill(.nbCard)` just works.
    static var nbBackground: Color { Color.nbBackground }
    static var nbHeader: Color { Color.nbHeader }
    static var nbCard: Color { Color.nbCard }
    static var nbCrimson: Color { Color.nbCrimson }
    static var nbGold: Color { Color.nbGold }
    static var nbMutedRed: Color { Color.nbMutedRed }
    static var nbTextPrimary: Color { Color.nbTextPrimary }
    static var nbTextSecondary: Color { Color.nbTextSecondary }
}
