//
//  HomeView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

struct HomeView: View {
    @Binding var tab: TabShellView.Tab

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Header(title: "NerdleBundle")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Dailies")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.nbTextPrimary)

                    HStack(spacing: 12) {
                        NavigationLink {
                            FilmConnectionsStartView()
                        } label: {
                            GameCard(titleTop: "Movie", titleBottom: "Connections")
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())

                        NavigationLink {
                            SteamdleView()
                        } label: {
                            GameCard(titleTop: "Guess the Price", titleBottom: "(Steamdle)")
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Quick links (Alternative to the footer, didn't like those initially, but might repurpose them for "back" "forward" in-game nav)
//                HStack(spacing: 12) {
//                    NavPill(text: "Leaderboard") { tab = .leaderboard }
//                    NavPill(text: "Account") { tab = .account }
//                }
//                .padding(.bottom, 12)
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

private struct GameCard: View {
    var titleTop: String
    var titleBottom: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: NB.corner)
                .fill(Color.nbMutedRed)
                .frame(height: 140)

            VStack(spacing: 4) {
                Text(titleTop)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.nbTextPrimary)
                Text(titleBottom)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.nbTextPrimary)
            }
            .padding()
        }
        .contentShape(Rectangle())
    }
}

private struct NavPill: View {
    var text: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.nbTextPrimary)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.nbGold)
                .clipShape(Capsule())
        }
    }
}
