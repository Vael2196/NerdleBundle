//
//  LeaderboardView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import Combine

/// Global leaderboard screen – swaps between daily / weekly / all-time.
struct LeaderboardView: View {
    @State private var period: LeaderboardPeriod = .daily
    @StateObject private var vm = LeaderboardVM()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Header(title: "Leaderboard")

                // Segmented control to switch which list is shown.
                Picker("Period", selection: $period) {
                    Text("Daily").tag(LeaderboardPeriod.daily)
                    Text("Weekly").tag(LeaderboardPeriod.weekly)
                    Text("All-time").tag(LeaderboardPeriod.allTime)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    ForEach(Array(itemsForPeriod.enumerated()), id: \.element.id) { idx, entry in
                        HStack(spacing: 12) {
                            RankBadge(rank: idx + 1)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.username).font(.headline)
                                Text("\(entry.points) points")
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
            .onAppear { vm.onAppear() }
            .onDisappear { vm.onDisappear() }
        }
    }

    /// Picks which leaderboard array to show based on the current segment.
    private var itemsForPeriod: [LeaderboardEntry] {
        switch period {
        case .daily: return vm.daily
        case .weekly: return vm.weekly
        case .allTime: return vm.allTime
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

/// Squarish badge that shows the rank number (#1, #2, etc.).
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

/// Minimal view model that listens to `LeaderboardService`
/// and fans out updates into three arrays (daily/weekly/all-time).
private final class LeaderboardVM: ObservableObject, LeaderboardListener {
    @Published var daily: [LeaderboardEntry] = []
    @Published var weekly: [LeaderboardEntry] = []
    @Published var allTime: [LeaderboardEntry] = []

    func onAppear() {
        // Hook in when the view shows up.
        LeaderboardService.shared.listeners.addDelegate(self)
        LeaderboardService.shared.start(span: .daily)
        LeaderboardService.shared.start(span: .weekly)
        LeaderboardService.shared.start(span: .allTime)
    }

    func onDisappear() {
        // Unhook to avoid leaking listeners / extra Firestore reads.
        LeaderboardService.shared.listeners.removeDelegate(self)
        LeaderboardService.shared.stop(span: .daily)
        LeaderboardService.shared.stop(span: .weekly)
        LeaderboardService.shared.stop(span: .allTime)
    }

    func leaderboardUpdated(span: LeaderboardSpan, items: [LeaderboardEntry]) {
        // Firestore callbacks are not guaranteed to be on main,
        // so list updates are marshalled back onto the main thread.
        DispatchQueue.main.async {
            switch span {
            case .daily: self.daily = items
            case .weekly: self.weekly = items
            case .allTime: self.allTime = items
            }
        }
    }
}
