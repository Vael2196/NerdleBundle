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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Settings")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.nbHeader)
                    .foregroundStyle(.nbTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 8)

                VStack(spacing: 12) {
                    HStack {
                        Text("Dark Mode").foregroundStyle(.nbTextPrimary)
                        Spacer()
                        Toggle("", isOn: app.darkModeBinding)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Text Size")
                            .foregroundStyle(.nbTextPrimary)
                        Slider(value: app.textScaleBinding, in: 0.85...1.3, step: 0.05)
                        Text(String(format: "Scale: %.2fx", app.textScale))
                            .font(.caption)
                            .foregroundStyle(.nbTextSecondary)
                    }
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                VStack(spacing: 0) {
                    settingsRow(title: "Contact Us") {
                        //TODO: Contact us form
                    }
                    Divider().background(.white.opacity(0.1))
                    settingsRow(title: "Report a problem") {
                        //TODO: report form
                    }
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .background(Color.nbBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func settingsRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(.nbTextPrimary)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.nbTextSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
    }
}
