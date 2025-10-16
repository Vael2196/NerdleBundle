//
//  FilmConnectionsResultView.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import SwiftUI
import FirebaseAuth

struct FilmConnectionsResultView: View {
    let payload: FCDailyPayload
    let finishedPath: [FCNode]
    let distance: Int
    let elapsed: Int
    let points: Int

    @EnvironmentObject private var app: AppState
    @State private var shareError: String?
    @State private var sharing = false
    @State private var sharedOK = false
    @State private var showLoginPrompt = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ResultHeader(title: "Your result")

                StatRow(distance: distance, elapsed: elapsed, points: points)

                PathSection(title: "Your chain", nodes: finishedPath, faded: false)

                PathSection(title: "Shortest chain",
                            nodes: payload.shortestPath ?? [],
                            faded: true)

                if let shareError {
                    Text(shareError).foregroundStyle(.red)
                }

                ShareButton(
                    isLoggedIn: Auth.auth().currentUser != nil,
                    sharedOK: sharedOK,
                    disabled: sharing || sharedOK
                ) {
                    if Auth.auth().currentUser == nil {
                        showLoginPrompt = true
                        return
                    }
                    Task {
                        do {
                            sharing = true; shareError = nil
                            let result = FCResult(
                                dayId: payload.dayId,
                                path: finishedPath,
                                distance: distance,
                                durationSec: elapsed,
                                points: points,
                                finishedAt: Date()
                            )
                            try await FCScoreService().submit(result: result)
                            sharedOK = true
                        } catch {
                            shareError = error.localizedDescription
                        }
                        sharing = false
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .alert("Sign in required", isPresented: $showLoginPrompt) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Log in to share your result with the community.")
        }
    }
}

private struct ResultHeader: View {
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

private struct StatRow: View {
    let distance: Int
    let elapsed: Int
    let points: Int

    var body: some View {
        HStack {
            StatTile(title: "Distance", value: "\(distance)")
            Divider().frame(height: 60).background(.white.opacity(0.1))
            StatTile(title: "Time", value: "\(elapsed)s")
            Divider().frame(height: 60).background(.white.opacity(0.1))
            StatTile(title: "Points", value: "\(points)")
        }
        .padding()
        .background(Color.nbCard)
        .clipShape(RoundedRectangle(cornerRadius: NB.corner))
        .padding(.horizontal)
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundStyle(.nbTextSecondary)
            Text(value).font(.headline).foregroundStyle(.nbTextPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PathSection: View {
    let title: String
    let nodes: [FCNode]
    let faded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)

            ForEach(nodes.indices, id: \.self) { idx in
                let n = nodes[idx]
                NodeRow(node: n, faded: faded)
            }
        }
        .padding(.horizontal)
    }
}

private struct NodeRow: View {
    let node: FCNode
    let faded: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(node.type == .movie ? Color.nbGold : Color.nbCrimson)
                .frame(width: 8, height: 8)

            Text(node.display)
            Spacer()
            Text(node.type == .person ? "(Actor)" : "(Movie)")
                .foregroundStyle(.nbTextSecondary)
                .font(.caption)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background((faded ? Color.nbCard.opacity(0.7) : Color.nbCard))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ShareButton: View {
    let isLoggedIn: Bool
    let sharedOK: Bool
    let disabled: Bool
    let action: () -> Void

    var labelText: String {
        if !isLoggedIn { return "Log in to share" }
        return sharedOK ? "Shared!" : "Share with community"
    }

    var body: some View {
        Button(action: action) {
            Text(labelText)
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .disabled(disabled)
        .background(Color.nbHeader)
        .clipShape(RoundedRectangle(cornerRadius: 72))
        .overlay(
            RoundedRectangle(cornerRadius: 72)
                .stroke(Color.nbCrimson.opacity(0.4), lineWidth: 0.8)
        )
        .foregroundStyle(Color.nbTextPrimary)
        .padding(.horizontal)
    }
}
