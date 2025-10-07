//
//  LeaderboardView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

struct LeaderboardView: View {
    @State private var period: LeaderboardPeriod = .daily

    private let mock: [ScoreEntry] = [
        .init(username: "Bruce Wayne", points: 2569, game: .filmConnections, date: .now),
        .init(username: "BatBoy1337", points: 1337, game: .steamdle, date: .now),
        .init(username: "zZDarkKnightZz", points: 1053, game: .filmConnections, date: .now),
        .init(username: "V1g1l4nte", points: 590,  game: .filmConnections, date: .now),
        .init(username: "TheManHimself228", points: 448, game: .steamdle, date: .now)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Header(title: "Leaderboard")

                Picker("Period", selection: $period) {
                    Text("Daily").tag(LeaderboardPeriod.daily)
                    Text("Weekly").tag(LeaderboardPeriod.weekly)
                    Text("All-time").tag(LeaderboardPeriod.allTime)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    ForEach(Array(mock.enumerated()), id: \.element.id) { idx, entry in
                        HStack(spacing: 12) {
                            RankBadge(rank: idx + 1)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.username).font(.headline)
                                Text("\(entry.points) points - \(entry.game == .steamdle ? "Steamdle" : "Film Connections")")
                                    .font(.subheadline)
                                    .foregroundStyle(.nbTextSecondary)
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.nbCard)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.nbBackground)
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

private struct RankBadge: View {
    let rank: Int
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.nbCard)
                .frame(width: 40, height: 40)
            Text("#\(rank)").bold()
        }
    }
}
