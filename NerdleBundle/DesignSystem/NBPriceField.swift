//
//  NBPriceField.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import SwiftUI

struct NBPriceField: View {
    let placeholder: String
    @Binding var value: Double?

    @Environment(\.colorScheme) private var scheme

    private var fieldBackground: Color {
        scheme == .dark ? Color(red: 0.18, green: 0.19, blue: 0.22) : .white
    }
    private var placeholderColor: Color {
        scheme == .dark ? Color(white: 0.78) : Color(white: 0.55)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if value == nil {
                Text(placeholder)
                    .foregroundColor(placeholderColor)
                    .padding(.horizontal, 16)
            }

            TextField(
                "",
                value: $value,
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
