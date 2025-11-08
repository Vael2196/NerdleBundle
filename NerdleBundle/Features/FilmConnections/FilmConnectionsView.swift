//
//  FilmConnectionsView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import Combine

/// Old prototype view for Film Connections – kept around as a simple timer demo, not used in main flow anymore
/// (I'll use it for the archive feature sometime later).
struct FilmConnectionsView: View {
    @State private var timerActive = false
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        VStack(spacing: 12) {
            Text("Film Connections")
                .font(.title).bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.nbHeader)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)

            HStack {
                StatChip(label: "TIME", value: format(elapsed))
                Divider().frame(height: 36).background(.white.opacity(0.1))
                StatChip(label: "DISTANCE", value: "—")
                Divider().frame(height: 36).background(.white.opacity(0.1))
                StatChip(label: "POINTS", value: "—")
            }
            .padding()
            .background(Color.nbCard)
            .clipShape(RoundedRectangle(cornerRadius: NB.corner))
            .padding(.horizontal)

            Spacer()
            Text("Posters, cast list, and selections go here.")
                .foregroundStyle(.nbTextSecondary)
            Spacer()

            Button(timerActive ? "Stop" : "Start") { timerActive.toggle() }
                .buttonStyle(.borderedProminent)
                .tint(.nbGold)
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if timerActive { elapsed += 0.1 }
        }
    }

    func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct StatChip: View {
    let label: String
    let value: String
    var body: some View {
        VStack {
            Text(label).font(.caption).foregroundStyle(.nbTextSecondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}
