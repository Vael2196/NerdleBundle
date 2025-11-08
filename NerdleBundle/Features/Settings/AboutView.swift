//
//  AboutView.swift
//  NerdleBundle
//
//  Created by V on 8/11/2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Header(title: "About")

                VStack(alignment: .leading, spacing: 8) {
                    Text("About this app")
                        .font(.headline)
                        .foregroundStyle(.nbTextPrimary)

                    Text("All code in this app was developed by Vadim Filyakin as part of the FIT3178 at Monash University.")
                        .foregroundStyle(.nbTextSecondary)
                        .font(.subheadline)
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("The Movie Database (TMDB)")
                        .font(.headline)
                        .foregroundStyle(.nbTextPrimary)

                    Text("This app uses TMDB and the TMDB APIs to provide movie metadata and images.")
                        .foregroundStyle(.nbTextSecondary)
                        .font(.subheadline)

                    Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                        .font(.subheadline)
                        .foregroundStyle(.nbTextSecondary)
                        .italic()

                    Text("Use of TMDB and the TMDB APIs is governed by TMDB’s API Terms of Use and Terms of Use. For full legal terms, please refer to TMDB’s official website.")
                        .foregroundStyle(.nbTextSecondary)
                        .font(.footnote)
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Steam / Steam Web API")
                        .font(.headline)
                        .foregroundStyle(.nbTextPrimary)

                    Text("This app uses data provided by the Steam store and/or Steam Web API for the Steamdle game mode.")
                        .foregroundStyle(.nbTextSecondary)
                        .font(.subheadline)

                    Text("Steam and the Steam logo are trademarks and/or registered trademarks of Valve Corporation. Use of Steam services and APIs is subject to Valve’s terms and conditions.")
                        .foregroundStyle(.nbTextSecondary)
                        .font(.footnote)
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Firebase")
                        .font(.headline)
                        .foregroundStyle(.nbTextPrimary)

                    Text("This app uses Google Firebase for authentication, data storage, and backend services such as Firestore, Cloud Functions, and Firebase Authentication.")
                        .foregroundStyle(.nbTextSecondary)
                        .font(.subheadline)

                    Text("Use of Firebase is subject to Google’s Firebase Terms of Service and Privacy Policy. All Firebase services remain the property of Google LLC and its licensors.")
                        .foregroundStyle(.nbTextSecondary)
                        .font(.footnote)
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Disclaimer")
                        .font(.headline)
                        .foregroundStyle(.nbTextPrimary)

                    Text("All third-party trademarks, logos, and data remain the property of their respective owners. This app is a student project and is not affiliated with, endorsed, certified, or approved by TMDB, Valve/Steam, Google/Firebase, or Monash University.")
                        .foregroundStyle(.nbTextSecondary)
                        .font(.footnote)
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
