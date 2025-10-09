//
//  NBInputField.swift
//  NerdleBundle
//
//  Created by V on 10/10/2025.
//

import SwiftUI

struct NBInputField: View {
    let placeholder: String
    @Binding var text: String
    var secure: Bool = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    @Environment(\.colorScheme) private var scheme

    private var fieldBackground: Color {
        scheme == .dark ? Color(red: 0.18, green: 0.19, blue: 0.22) : .white
    }
    private var placeholderColor: Color {
        scheme == .dark ? Color(white: 0.78) : Color(white: 0.55)
    }

    var body: some View {
        ZStack(alignment: .leading) {
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
