//
//  NBPriceField.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import SwiftUI

/// Number-only input used for price guessing.
/// Binds straight to a `Double?` so it can be easily reset/validated.
struct NBPriceField: View {
    let placeholder: String
    @Binding var value: Double?

    @Environment(\.colorScheme) private var scheme

    /// Same vibe as NBInputField, just reused for numeric entry.
    private var fieldBackground: Color {
        scheme == .dark ? Color(red: 0.18, green: 0.19, blue: 0.22) : .white
    }
    private var placeholderColor: Color {
        scheme == .dark ? Color(white: 0.78) : Color(white: 0.55)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder only shows when there's no numeric value yet.
            if value == nil {
                Text(placeholder)
                    .foregroundColor(placeholderColor)
                    .padding(.horizontal, 16)
            }

            TextField(
                "",
                value: $value,
                // Allows 0–2 decimal places, which is plenty for prices.
                format: .number.precision(.fractionLength(0...2))
            )
            .keyboardType(.decimalPad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .foregroundStyle(Color.nbTextPrimary)
            .padding(.horizontal, 16)
        }
        .frame(height: 48)
        .background(fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
