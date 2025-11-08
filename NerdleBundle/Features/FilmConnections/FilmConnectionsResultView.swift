//
//  FilmConnectionsResultView.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Post-game summary screen for Film Connections.
/// Shows the player’s chain, the optimal chain, and handles sharing to Firestore.
struct FilmConnectionsResultView: View {
    let payload: FCDailyPayload
    let finishedPath: [FCNode]
    let distance: Int
    let elapsed: Int
    let points: Int

    @EnvironmentObject private var app: AppState

    @State private var shareError: String?
    @State private var sharing = false

    @State private var showLoginAlert = false
    @State private var showAlreadyAlert = false
    @State private var showSuccessAlert = false

    @State private var goHome = false

    var body: some View {
        NavigationStack {
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

                    ShareButton(disabled: sharing) {
                        Task {
                            await handleShareTap()
                        }
                    }

                    Button {
                        goHome = true
                    } label: {
                        Text("Back to Home")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .background(Color.nbCard)
                    .clipShape(RoundedRectangle(cornerRadius: 72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 72)
                            .stroke(Color.nbCrimson.opacity(0.25), lineWidth: 0.8)
                    )
                    .foregroundStyle(.nbTextPrimary)
                    .padding(.horizontal)

                    // Little hacky nav link trigger to reset back to home.
                    NavigationLink(
                        destination: HomeView(tab: .constant(.home))
                            .navigationBarBackButtonHidden(true),
                        isActive: $goHome
                    ) { EmptyView() }
                    .hidden()

                    Spacer(minLength: 40)
                }
            }
            .background(Color.nbBackground.ignoresSafeArea())
            // Three tiny alerts for different sharing outcomes.
            .alert("Sign in required", isPresented: $showLoginAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Log in to share your result with the community.")
            }
            .alert("Already shared", isPresented: $showAlreadyAlert) {
                Button("OK") { }
            } message: {
                Text("Your results are already on today’s leaderboard. Well done!")
            }
            .alert("Shared successfully", isPresented: $showSuccessAlert) {
                Button("Nice!") { }
            } message: {
                Text("Your results have been added to today’s leaderboard.")
            }
        }
    }

    /// Orchestrates the whole share flow: login check -> duplicate check -> submit score.
    private func handleShareTap() async {
        shareError = nil

        guard isLoggedInNow() else {
            await MainActor.run { showLoginAlert = true }
            return
        }

        if await alreadySharedToday() {
            await MainActor.run { showAlreadyAlert = true }
            return
        }

        await MainActor.run { sharing = true }
        do {
            let result = FCResult(
                dayId: payload.dayId,
                path: finishedPath,
                distance: distance,
                durationSec: elapsed,
                points: points,
                finishedAt: Date()
            )
            try await FCScoreService().submit(result: result)
            await MainActor.run { showSuccessAlert = true }
        } catch {
            await MainActor.run { shareError = error.localizedDescription }
        }
        await MainActor.run { sharing = false }
    }

    /// Very small helper so the logic reads nicer.
    private func isLoggedInNow() -> Bool {
        if let u = Auth.auth().currentUser, !u.isAnonymous { return true }
        return false
    }

    /// Prevents double-posting scores for the same day / game / user.
    private func alreadySharedToday() async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let db = Firestore.firestore()
        do {
            let snap = try await db.collection("scores")
                .whereField("uid", isEqualTo: uid)
                .whereField("game", isEqualTo: "film_connections")
                .whereField("dayId", isEqualTo: payload.dayId)
                .limit(to: 1)
                .getDocuments()
            return !snap.documents.isEmpty
        } catch {
            return false
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

/// Row of three stat tiles (distance / time / points).
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

/// Reusable section that renders a chain (either player’s or shortest).
private struct PathSection: View {
    let title: String
    let nodes: [FCNode]
    let faded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)

            ForEach(nodes.indices, id: \.self) { idx in
                let n = nodes[idx]
                ResultRow(node: n, faded: faded)
            }
        }
        .padding(.horizontal)
    }
}

/// Single node row inside the chain display.
private struct ResultRow: View {
    let node: FCNode
    let faded: Bool

    var body: some View {
        HStack(spacing: 12) {
            thumb
                .frame(width: 40, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.08), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(node.display)
                    .foregroundStyle(.nbTextPrimary)
                    .lineLimit(2)
                Text(node.type == .person ? "Actor" : "Movie")
                    .foregroundStyle(.nbTextSecondary)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background((faded ? Color.nbCard.opacity(0.7) : Color.nbCard))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var thumb: some View {
        if let url = TMDBImage.url(node.posterPath, size: "w92") {
            AsyncImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                placeholder
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.nbCard.opacity(0.6)
            Image(systemName: node.type == .movie ? "film" : "person.crop.square")
                .opacity(0.4)
        }
    }
}

/// Generic “Share” button with optional spinner.
private struct ShareButton: View {
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("Share Results")
                    .font(.system(size: 20, weight: .bold))
                if disabled {
                    ProgressView().scaleEffect(0.9)
                }
            }
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
