//
//  SettingsView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

//TODO: The whole thing is pretty much a placeholder as of now. Gotta make the notifications, and some screens for the respective forms first
struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @State private var notifications = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Header(title: "Settings")

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Dark Mode", isOn: $app.isDarkMode)
                    HStack {
                        Text("Text Size")
                        Spacer()
                        Stepper(value: $app.textScale, in: 0.9...1.4, step: 0.1) {
                            Text(String(format: "%.1fx", app.textScale))
                        }.labelsHidden()
                    }
                    .padding(.top, 6)
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Button("Contact Us") { /* TODO */ }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    Button("Report a Problem") { /* TODO */ }
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.nbBackground.ignoresSafeArea())
        }
    }
}

private struct Header: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nbHeader)
            .foregroundStyle(.nbTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 8)
    }
}
