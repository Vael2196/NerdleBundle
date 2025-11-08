//
//  FilmConnectionsGameView.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import SwiftUI
import Combine

/// Main Film Connections gameplay screen – timer, search, and step-by-step path builder.
struct FilmConnectionsGameView: View {
    let payload: FCDailyPayload

    // Simple in-view timer for the round.
    @State private var timerActive = false
    @State private var elapsed: TimeInterval = 0

    // Current chain the player is building.
    @State private var path: [FCNode] = []
    // Current selectable list
    @State private var items: [ListRow] = []
    @State private var error: String?
    @State private var finished = false
    @State private var computed: ComputedResult?
    @State private var query: String = ""
    @State private var goResult = false

    /// Compact bucket for what’s needed on the result screen.
    struct ComputedResult { let distance: Int; let points: Int }

    /// Enum representing one row in the list (actor or movie).
    enum ListRow: Identifiable {
        case person(FCPerson)
        case movie(FCMovie)
        var id: String {
            switch self {
            case .person(let p): return "p-\(p.id)"
            case .movie(let m): return "m-\(m.id)"
            }
        }
        var title: String {
            switch self {
            case .person(let p): return p.name
            case .movie(let m): return m.title
            }
        }
    }

    /// Basic search filter over the current list – tiny in-memory filter, nothing fancy.
    private var filteredItems: [ListRow] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return items }
        let q = query.lowercased()
        return items.filter { $0.title.lowercased().contains(q) }
    }

    /// Fallback to movieA if nothing is in the path yet.
    private var lastSelected: FCNode {
        path.last
        ?? FCNode(type: .movie,
                  id: payload.movieA.id,
                  title: payload.movieA.title,
                  name: nil,
                  posterPath: payload.movieA.posterPath,
                  releaseDate: payload.movieA.releaseDate)
    }

    var body: some View {
        VStack(spacing: 12) {
            Header

            // Top stats row: timer, path distance (actors), and points once finished.
            HStack {
                StatChip(label: "TIME", value: format(elapsed))
                Divider().frame(height: 36).background(.white.opacity(0.1))
                StatChip(label: "DISTANCE", value: "\(currentDistance())")
                Divider().frame(height: 36).background(.white.opacity(0.1))
                StatChip(label: "POINTS", value: finished ? "\(computed?.points ?? 0)" : "—")
            }
            .padding()
            .background(Color.nbCard)
            .clipShape(RoundedRectangle(cornerRadius: NB.corner))
            .padding(.horizontal)

            // Current node on the left, target movie on the right.
            HStack(spacing: 12) {
                SelectionCard(node: lastSelected, label: "Current")
                SelectionCardMovie(movie: payload.movieB, label: "Target")
            }
            .padding(.horizontal)

            if let error { Text(error).foregroundStyle(.red) }

            // Quick search over cast / movies.
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.nbTextSecondary)
                TextField("Search cast or movies", text: $query)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.nbCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Tap-through list for picking next step in the chain.
            List {
                ForEach(filteredItems) { row in
                    Button { handleTap(row) } label: {
                        RowCell(row: row)
                    }
                    .listRowBackground(Color.nbCard)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.nbBackground)

            Spacer(minLength: 12)
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .onAppear { startOrJumpIfFinished() }
        // Super basic timer ticking every 0.1s while active.
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if timerActive { elapsed += 0.1 }
        }
        // Auto-navigate to result screen when `goResult` flips.
        .navigationDestination(isPresented: $goResult) {
            FilmConnectionsResultView(
                payload: payload,
                finishedPath: path,
                distance: computed?.distance ?? 0,
                elapsed: Int(elapsed),
                points: computed?.points ?? 0
            )
        }
    }

    /// Big title banner for this screen.
    private var Header: some View {
        Text("Film Connections")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nbHeader)
            .foregroundStyle(.nbTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 8)
    }

    /// Either resume last attempt from local storage or spin up a fresh run.
    private func startOrJumpIfFinished() {
        if let local = FCLocalStore.shared.load(dayId: payload.dayId) {
            // Already completed today – jump straight to results.
            path = local.path
            elapsed = TimeInterval(local.durationSec)
            computed = .init(distance: local.distance, points: local.points)
            finished = true
            timerActive = false
            items = []
            DispatchQueue.main.async { goResult = true }
            return
        }

        // First time playing today – set up start node and fetch cast.
        timerActive = true
        path = [FCNode(type: .movie,
                       id: payload.movieA.id,
                       title: payload.movieA.title,
                       name: nil,
                       posterPath: payload.movieA.posterPath,
                       releaseDate: payload.movieA.releaseDate)]
        Task { await loadCast(for: payload.movieA.id) }
    }

    /// Pull cast for a movie and show them as clickable people.
    private func loadCast(for movieId: Int) async {
        do {
            error = nil
            let cast = try await FCBackend.shared.getCast(movieId: movieId)
            items = cast.map { .person($0) }
        } catch {
            self.error = error.localizedDescription
            items = []
        }
    }

    /// Pull movies for a person and show them as clickable films.
    private func loadMovies(for personId: Int) async {
        do {
            error = nil
            let movies = try await FCBackend.shared.getMovies(personId: personId)
            items = movies.map { .movie($0) }
        } catch {
            self.error = error.localizedDescription
            items = []
        }
    }

    /// Handles user tapping either a person or a movie in the list.
    private func handleTap(_ row: ListRow) {
        switch row {
        case .person(let p):
            // Append actor node and then load their filmography.
            path.append(FCNode(type: .person,
                               id: p.id,
                               title: nil,
                               name: p.name,
                               posterPath: p.profilePath,
                               releaseDate: nil))
            Task { await loadMovies(for: p.id) }
        case .movie(let m):
            // Append movie node and either finish or load cast.
            path.append(FCNode(type: .movie,
                               id: m.id,
                               title: m.title,
                               name: nil,
                               posterPath: m.posterPath,
                               releaseDate: m.releaseDate))
            if m.id == payload.movieB.id {
                finishGame()
            } else {
                Task { await loadCast(for: m.id) }
            }
        }
    }

    /// Distance is defined as number of actor hops in the chain.
    private func currentDistance() -> Int {
        path.filter { $0.type == .person }.count
    }

    /// Locks in the result, computes scoring, and persists it locally.
    private func finishGame() {
        timerActive = false
        let distance = currentDistance()
        let shortest = payload.shortestDistance ?? distance
        let over = max(0, distance - shortest)
        // Start at 10 points and lose 1 for each hop over the optimal distance.
        let points = max(0, 10 - over)
        computed = .init(distance: distance, points: points)
        finished = true

        let result = FCResult(
            dayId: payload.dayId,
            path: path,
            distance: distance,
            durationSec: Int(elapsed),
            points: points,
            finishedAt: Date()
        )
        FCLocalStore.shared.save(result)

        DispatchQueue.main.async { goResult = true }
    }

    /// Tiny mm:ss formatter for the timer label.
    private func format(_ t: TimeInterval) -> String {
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

/// Generic row for either a person or movie inside the list.
private struct RowCell: View {
    let row: FilmConnectionsGameView.ListRow

    var body: some View {
        HStack(spacing: 12) {
            thumb
                .frame(width: 40, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.08), lineWidth: 1))

            Text(title)
                .foregroundStyle(.nbTextPrimary)

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.nbTextSecondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }

    private var title: String {
        switch row {
        case .person(let p): return p.name
        case .movie(let m):  return m.title
        }
    }

    @ViewBuilder private var thumb: some View {
        switch row {
        case .person(let p):
            if let url = TMDBImage.url(p.profilePath, size: "w92") {
                AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { placeholder }
            } else { placeholder }
        case .movie(let m):
            if let url = TMDBImage.url(m.posterPath, size: "w92") {
                AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { placeholder }
            } else { placeholder }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.nbCard.opacity(0.6)
            Image(systemName: "person.crop.square" )
                .opacity(0.4)
        }
    }
}

/// Card used to show the current node in the chain.
private struct SelectionCard: View {
    let node: FCNode
    let label: String

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: NB.corner).fill(Color.nbCard)
                if let url = TMDBImage.url(node.posterPath, size: "w185") {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                    } placeholder: { ProgressView().padding() }
                } else {
                    Image(systemName: node.type == .movie ? "film" : "person")
                        .font(.largeTitle).foregroundStyle(.nbTextSecondary)
                }
            }
            .frame(width: 120, height: 180)

            Text(node.display)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 120)
                .foregroundStyle(.nbTextPrimary)

            Text(label).font(.caption2).foregroundStyle(.nbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Same as `SelectionCard` but specialized for the fixed target movie.
private struct SelectionCardMovie: View {
    let movie: FCMovie
    let label: String

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: NB.corner).fill(Color.nbCard)
                if let url = TMDBImage.url(movie.posterPath, size: "w185") {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                    } placeholder: { ProgressView().padding() }
                } else {
                    Image(systemName: "film")
                        .font(.largeTitle).foregroundStyle(.nbTextSecondary)
                }
            }
            .frame(width: 120, height: 180)

            Text(movie.title)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 120)
                .foregroundStyle(.nbTextPrimary)

            Text(label).font(.caption2).foregroundStyle(.nbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
