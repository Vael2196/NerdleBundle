//
//  FilmConnectionsGameView.swift
//  NerdleBundle
//
//  Created by V on 17/10/2025.
//

import SwiftUI
import Combine


struct FilmConnectionsGameView: View {
    let payload: FCDailyPayload

    @State private var timerActive = false
    @State private var elapsed: TimeInterval = 0

    @State private var path: [FCNode] = []
    @State private var items: [ListRow] = []
    @State private var error: String?
    @State private var finished = false
    @State private var computed: ComputedResult?
    @State private var query: String = ""

    struct ComputedResult { let distance: Int; let points: Int }

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

    private var filteredItems: [ListRow] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return items }
        let q = query.lowercased()
        return items.filter { row in
            row.title.lowercased().contains(q)
        }
    }

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

            HStack(spacing: 12) {
                SelectionCard(node: lastSelected, label: "Current")
                SelectionCardMovie(movie: payload.movieB, label: "Target")
            }
            .padding(.horizontal)

            if let error { Text(error).foregroundStyle(.red) }

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

            Spacer()

            if finished {
                NavigationLink {
                    FilmConnectionsResultView(
                        payload: payload,
                        finishedPath: path,
                        distance: computed?.distance ?? 0,
                        elapsed: Int(elapsed),
                        points: computed?.points ?? 0
                    )
                } label: {
                    Text("View result")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color.nbHeader)
                .clipShape(RoundedRectangle(cornerRadius: 72))
                .overlay(RoundedRectangle(cornerRadius: 72).stroke(Color.nbCrimson.opacity(0.4), lineWidth: 0.8))
                .foregroundStyle(Color.nbTextPrimary)
                .padding(.horizontal)
            }
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .onAppear { startOrJumpIfFinished() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if timerActive { elapsed += 0.1 }
        }
    }

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

    private func startOrJumpIfFinished() {
        if let local = FCLocalStore.shared.load(dayId: payload.dayId) {
            path = local.path
            elapsed = TimeInterval(local.durationSec)
            computed = .init(distance: local.distance, points: local.points)
            finished = true
            timerActive = false
            items = []
            return
        }

        timerActive = true
        path = [FCNode(type: .movie,
                       id: payload.movieA.id,
                       title: payload.movieA.title,
                       name: nil,
                       posterPath: payload.movieA.posterPath,
                       releaseDate: payload.movieA.releaseDate)]
        Task { await loadCast(for: payload.movieA.id) }
    }

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

    private func handleTap(_ row: ListRow) {
        switch row {
        case .person(let p):
            path.append(FCNode(type: .person,
                               id: p.id,
                               title: nil,
                               name: p.name,
                               posterPath: p.profilePath,
                               releaseDate: nil))
            Task { await loadMovies(for: p.id) }
        case .movie(let m):
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

    private func currentDistance() -> Int {
        path.filter { $0.type == .person }.count
    }

    private func finishGame() {
        timerActive = false
        let distance = currentDistance()
        let shortest = payload.shortestDistance ?? distance
        let over = max(0, distance - shortest)
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
    }

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
