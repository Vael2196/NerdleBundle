//
//  SettingsView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

/// Basic settings screen: theming, text size, and links to About / Contact.
struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @State private var showContactAlert = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
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

                    // Theme + text scale block.
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

                    // Info actions: Contact and About.
                    VStack(spacing: 0) {
                        settingsRow(title: "Contact Us") {
                            // Just shows an alert with the email right now.
                            showContactAlert = true
                        }
                        Divider().background(.white.opacity(0.1))
                        settingsRow(title: "About") {
                            showAbout = true
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
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
        }
        .alert("Contact us", isPresented: $showContactAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("If you have any questions or feedback about the app, please email me at\n\nvadimfilyakin@gmail.com")
        }
    }

    /// Generic settings row with trailing chevron – used for navigation-style rows.
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
