//
//  NBInputField.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import SwiftUI

/// Reusable text input used across auth/settings screens.
/// Handles placeholder styling + secure vs normal field in one place.
struct NBInputField: View {
    let placeholder: String
    @Binding var text: String
    var secure: Bool = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    @Environment(\.colorScheme) private var scheme

    /// Background color tweaks slightly for light/dark so it blends with cards.
    private var fieldBackground: Color {
        scheme == .dark ? Color(red: 0.18, green: 0.19, blue: 0.22) : .white
    }
    /// Placeholder text color, muted more in dark mode.
    private var placeholderColor: Color {
        scheme == .dark ? Color(white: 0.78) : Color(white: 0.55)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Custom placeholder so the style matches both SecureField and TextField.
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(placeholderColor)
                    .padding(.horizontal, 16)
            }

            if secure {
                SecureField("", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .foregroundStyle(Color.nbTextPrimary)
                    .padding(.horizontal, 16)
            } else {
                TextField("", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .foregroundStyle(Color.nbTextPrimary)
                    .padding(.horizontal, 16)
            }
        }
        .frame(height: 48)
        .background(fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
