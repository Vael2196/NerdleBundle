//
//  FilmConnectionsStartView.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import SwiftUI
import FirebaseFirestore


struct FilmConnectionsStartView: View {
    @State private var daily: FCDailyPayload?
    @State private var loading = true
    @State private var error: String?
    @State private var goPlay = false

    @State private var listener: ListenerRegistration?

    private var canStart: Bool { daily?.movieA.id != nil && daily?.movieB.id != nil }

    private var isReady: Bool {
        guard let d = daily else { return false }
        return d.shortestDistance != nil || d.status == "ready"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("NerdleBundle")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.nbHeader)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                Text("Connect the movie on the left to the movie on the right")
                    .font(.system(size: 16))
                    .foregroundStyle(.nbTextSecondary)

                HStack(spacing: 12) {
                    poster(daily?.movieA)
                    poster(daily?.movieB)
                }
                .padding(.horizontal)

                if let error {
                    Text(error).foregroundStyle(.red)
                } else if loading {
                    ProgressView().padding(.top, 8)
                } else if !isReady {
                    Text("Preparing today’s optimal path… you can start now.")
                        .foregroundStyle(.nbTextSecondary)
                        .padding(.top, 4)
                }

                Button {
                    goPlay = true
                } label: {
                    Text("Give it a try")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color.nbHeader)
                .clipShape(RoundedRectangle(cornerRadius: 72))
                .overlay(RoundedRectangle(cornerRadius: 72).stroke(Color.nbCrimson.opacity(0.4), lineWidth: 0.8))
                .foregroundStyle(Color.nbTextPrimary)
                .padding(.horizontal)
                .disabled(!canStart)

                Spacer(minLength: 24)
            }
            .background(Color.nbBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $goPlay) {
                if let daily { FilmConnectionsGameView(payload: daily) }
            }
            .task { await initialFetchAndListen() }
            .onDisappear { listener?.remove(); listener = nil }
            .refreshable { await fetchOnce() }
        }
    }

    @ViewBuilder
    private func poster(_ movie: FCMovie?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color.nbCard)
                .frame(width: 180, height: 270)
            if let url = TMDBImage.url(movie?.posterPath) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: { ProgressView() }
                .frame(width: 180, height: 270)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text(movie?.title ?? "—")
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }

    private func initialFetchAndListen() async {
        await fetchOnce()
        guard let d = daily else { return }
        startListening(dayId: d.dayId)
    }

    private func fetchOnce() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            let d = try await FCBackend.shared.getToday()
            self.daily = d
            startListening(dayId: d.dayId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func startListening(dayId: String) {
        guard listener == nil else { return }
        let doc = Firestore.firestore().collection("fc_daily").document(dayId)
        listener = doc.addSnapshotListener { snap, err in
            if let err {
                self.error = err.localizedDescription
                return
            }
            guard let data = snap?.data() else { return }

            guard
                let movieAmap = data["movieA"] as? [String: Any],
                let movieBmap = data["movieB"] as? [String: Any],
                let aId = movieAmap["id"] as? Int,
                let bId = movieBmap["id"] as? Int,
                let aTitle = movieAmap["title"] as? String,
                let bTitle = movieBmap["title"] as? String
            else { return }

            let a = FCMovie(
                id: aId,
                title: aTitle,
                posterPath: movieAmap["posterPath"] as? String,
                releaseDate: movieAmap["releaseDate"] as? String
            )
            let b = FCMovie(
                id: bId,
                title: bTitle,
                posterPath: movieBmap["posterPath"] as? String,
                releaseDate: movieBmap["releaseDate"] as? String
            )

            var sp: [FCNode]? = nil
            if let arr = data["shortestPath"] as? [[String: Any]] {
                sp = arr.compactMap { dict in
                    guard
                        let typeStr = dict["type"] as? String,
                        let type = FCNodeType(rawValue: typeStr),
                        let nid = dict["id"] as? Int
                    else { return nil }
                    return FCNode(
                        type: type,
                        id: nid,
                        title: dict["title"] as? String,
                        name: dict["name"] as? String,
                        posterPath: dict["posterPath"] as? String,
                        releaseDate: dict["releaseDate"] as? String
                    )
                }
            }

            let sd = data["shortestDistance"] as? Int
            let status = data["status"] as? String
            let day = (data["dayId"] as? String) ?? dayId

            self.daily = FCDailyPayload(
                dayId: day,
                movieA: a,
                movieB: b,
                shortestPath: sp,
                shortestDistance: sd,
                status: status
            )
        }
    }
}
