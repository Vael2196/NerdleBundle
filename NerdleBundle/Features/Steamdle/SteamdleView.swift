//
//  SteamdleView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

/// Top-level Steamdle flow: loads today’s payload, manages rounds and local progress,
/// and pushes to results once all 3 games are done.
struct SteamdleView: View {
    @State private var payload: SteamdleDailyPayload?
    @State private var loading = true
    @State private var error: String?

    @State private var roundIndex = 0
    @State private var perRoundPoints: [Int] = [0,0,0]
    @State private var perRoundAttemptsUsed: [Int] = [0,0,0]
    @State private var goResults = false

    @State private var saved: SteamdleProgress?

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    VStack(spacing: 16) {
                        header
                        ProgressView().tint(.nbCrimson)
                        if let error { Text(error).foregroundStyle(.red) }
                    }
                    .padding()
                } else if let p = payload, p.games.count == 3 {
                    VStack(spacing: 0) {
                        header
                        Spacer().frame(height: 6)

                        // Single-round view; roundIndex controls which of the three games is shown.
                        SteamdleRoundView(
                            game: p.games[roundIndex],
                            initialAttempts: initialAttempts(for: roundIndex),
                            initiallyRevealed: initiallyRevealed(for: roundIndex),
                            onProgressChanged: { attempts, revealed in
                                updateSaved(round: roundIndex, attempts: attempts, revealed: revealed)
                            },
                            onFinished: { points, attempts in
                                perRoundPoints[roundIndex] = points
                                perRoundAttemptsUsed[roundIndex] = attempts

                                // Mark that round as fully revealed in local storage.
                                updateSaved(round: roundIndex, attempts: initialAttempts(for: roundIndex), revealed: true)

                                if roundIndex < 2 {
                                    roundIndex += 1
                                    persistIndex(roundIndex)
                                } else {
                                    goResults = true
                                }
                            }
                        )
                        // Force SwiftUI to treat each game as a fresh view when appid changes.
                        .id(p.games[roundIndex].appid)

                        NavigationLink(
                            destination: SteamdleResultView(
                                dayId: p.dayId,
                                games: p.games,
                                totalPoints: perRoundPoints.reduce(0,+),
                                totalAttempts: perRoundAttemptsUsed.reduce(0,+)
                            )
                            .navigationBarBackButtonHidden(true),
                            isActive: $goResults
                        ) { EmptyView() }
                        .hidden()
                    }
                } else {
                    VStack(spacing: 16) {
                        header
                        Text("Today’s games aren’t ready yet. Try again in a bit.")
                            .foregroundStyle(.nbTextSecondary)
                    }
                }
            }
            .background(Color.nbBackground.ignoresSafeArea())
            .onAppear { Task { await load() } }
        }
    }

    private var header: some View {
        Text("Steamdle")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nbHeader)
            .foregroundStyle(.nbTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 8)
    }

    /// Grabs today’s daily payload and then restores any local progress if it exists.
    private func load() async {
        loading = true; error = nil
        do {
            let res = try await SteamdleBackend.shared.getToday()
            await MainActor.run {
                self.payload = res
                restoreProgressIfAny(for: res.dayId)
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
        loading = false
    }

    /// Pulls saved Steamdle progress for today, or injects a fresh empty state.
    private func restoreProgressIfAny(for dayId: String) {
        let store = SteamdleLocalStore.shared
        if let p = store.load(dayId: dayId) {
            self.saved = p
            self.roundIndex = min(max(p.roundIndex, 0), 2)

            for r in 0..<3 {
                let attempts = p.attempts[safe: r] ?? []
                let (pts, used) = scoreAndAttempts(from: attempts)
                self.perRoundPoints[r] = pts
                self.perRoundAttemptsUsed[r] = used
            }
        } else {
            self.saved = SteamdleProgress(dayId: dayId,
                                          roundIndex: 0,
                                          attempts: [[],[],[]],
                                          revealed: [false,false,false])
            store.save(self.saved!)
        }
    }

    /// Recomputes points/attempts from saved attempts for a round.
    private func scoreAndAttempts(from attempts: [SteamdleSavedAttempt]) -> (Int, Int) {
        if let idx = attempts.firstIndex(where: { $0.state == .correct }) {
            return (max(0, 5 - idx), idx + 1)
        }
        return (0, min(5, attempts.count))
    }

    /// Converts saved attempts into the live `SteamdleRoundView.Attempt` model.
    private func initialAttempts(for round: Int) -> [SteamdleRoundView.Attempt] {
        guard let saved else { return [] }
        let list = saved.attempts[safe: round] ?? []
        return list.map {
            .init(guess: $0.guess, state: SteamdleRoundView.GuessState($0.state))
        }
    }

    private func initiallyRevealed(for round: Int) -> Bool {
        saved?.revealed[safe: round] ?? false
    }

    /// Updates the locally persisted progress whenever a round changes.
    private func updateSaved(round: Int, attempts: [SteamdleRoundView.Attempt], revealed: Bool) {
        guard var s = saved else { return }
        let mapped = attempts.map { SteamdleSavedAttempt(guess: $0.guess, state: $0.state.stringValue) }
        if s.attempts.indices.contains(round) { s.attempts[round] = mapped }
        if s.revealed.indices.contains(round) { s.revealed[round] = revealed }
        self.saved = s
        SteamdleLocalStore.shared.save(s)
    }

    /// Just persists which round the player is currently on.
    private func persistIndex(_ idx: Int) {
        guard var s = saved else { return }
        s.roundIndex = idx
        self.saved = s
        SteamdleLocalStore.shared.save(s)
    }
}

fileprivate struct SteamdleRoundView: View {
    let game: SteamdleGame
    let initialAttempts: [Attempt]
    let initiallyRevealed: Bool
    let onProgressChanged: (_ attempts: [Attempt], _ revealed: Bool) -> Void
    let onFinished: (_ points: Int, _ attemptsUsed: Int) -> Void

    struct Attempt: Equatable {
        let guess: Double
        let state: GuessState
    }

    /// UI-level guess state; wraps the Codable enum used in storage.
    enum GuessState: Equatable {
        case tooLow, tooHigh, correct

        init(_ saved: SteamdleGuessState) {
            switch saved {
            case .tooLow: self = .tooLow
            case .tooHigh: self = .tooHigh
            case .correct: self = .correct
            }
        }

        var stringValue: SteamdleGuessState {
            switch self {
            case .tooLow: return .tooLow
            case .tooHigh: return .tooHigh
            case .correct: return .correct
            }
        }
    }

    @State private var attempts: [Attempt] = []
    @State private var currentRaw: String = ""
    @FocusState private var focused: Bool
    @State private var revealed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Main header image for the current game.
                RoundedRectangle(cornerRadius: NB.corner)
                    .fill(Color.nbCard)
                    .overlay(
                        AsyncImage(url: URL(string: game.headerImage)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ProgressView().padding() }
                        .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                    )
                    .frame(height: 180)
                    .padding(.horizontal)
                    .padding(.top, 6)

                // Game title + genres.
                VStack(spacing: 4) {
                    Text(game.name)
                        .font(.title3).bold()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.nbTextPrimary)
                    if !game.genres.isEmpty {
                        Text(game.genres.joined(separator: " • "))
                            .font(.footnote)
                            .foregroundStyle(.nbTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                // Price reveal once the round is done.
                if revealed {
                    Text("Price: \(formatAUD(game.priceAUD))")
                        .font(.headline)
                        .foregroundStyle(.nbGold)
                        .padding(.top, 2)
                }

                // Horizontal screenshot rail, purely vibes.
                if !game.screenshots.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(game.screenshots, id: \.self) { urlStr in
                                AsyncImage(url: URL(string: urlStr)) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    ZStack { Color.nbCard; ProgressView() }
                                }
                                .frame(width: 180, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Up to 5 attempts slots.
                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        attemptRow(i)
                    }
                }
                .padding(.horizontal)

                if revealed {
                    Button {
                        onFinished(score(), attemptsUsed())
                    } label: {
                        Text("Next Game")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .background(Color.nbHeader)
                    .clipShape(RoundedRectangle(cornerRadius: 64))
                    .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.nbCrimson.opacity(0.4), lineWidth: 0.8))
                    .foregroundStyle(.nbTextPrimary)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.nbBackground)
        .onAppear {
            // Rehydrate state when the view first loads.
            attempts = initialAttempts
            revealed = initiallyRevealed || isRoundExhaustedOrCorrect()
            onProgressChanged(attempts, revealed)
        }
        .onChange(of: game.appid) { _ in
            // When the parent swaps to another game, reset with its saved state.
            attempts = initialAttempts
            revealed = initiallyRevealed || isRoundExhaustedOrCorrect()
            onProgressChanged(attempts, revealed)
        }
    }

    /// Renders one of the five rows: either a past guess, an active input, or a locked slot.
    @ViewBuilder
    private func attemptRow(_ index: Int) -> some View {
        let activeIndex = firstPendingIndex()
        let isActive = !revealed && (activeIndex == index)

        HStack(alignment: .center, spacing: 8) {
            Text("#\(index + 1)")
                .font(.caption)
                .foregroundStyle(.nbTextSecondary)
                .frame(width: 28)

            if let att = attempts[safe: index] {
                // Already submitted guess.
                HStack(spacing: 8) {
                    Text(formatAUD(att.guess))
                        .foregroundStyle(.nbTextPrimary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.nbCard.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor(for: att.state), lineWidth: 1)
                        )

                    icon(for: att.state)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Guess \(index + 1): \(formatAUD(att.guess))")
            } else if isActive {
                // Current live input row.
                HStack(spacing: 8) {
                    TextField("Enter price (AUD)", text: $currentRaw)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.nbCard)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .focused($focused)

                    Button(action: { submit(index) }) {
                        Text("Guess")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .background(.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .accessibilityHint("Active field. Enter your guess and tap Guess.")
                .onAppear { focused = true }

            } else {
                // Not yet unlocked – waiting for previous attempt.
                HStack(spacing: 8) {
                    Text("Locked")
                        .foregroundStyle(.nbTextSecondary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.nbCard.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Image(systemName: "lock.fill")
                        .foregroundStyle(.nbTextSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Attempt \(index + 1) locked until previous guess is submitted")
            }
        }
        .padding(.vertical, 2)
    }


    /// Index of the first empty attempt slot.
    private func firstPendingIndex() -> Int? {
        for i in 0..<5 where attempts[safe: i] == nil { return i }
        return nil
    }

    /// Handles submitting a guess for the current active row.
    private func submit(_ index: Int) {
        guard !revealed else { return }
        guard let value = parse(currentRaw) else { return }

        let state: GuessState = isCorrect(value) ? .correct : (value < game.priceAUD ? .tooLow : .tooHigh)
        attempts.append(.init(guess: value, state: state))

        currentRaw = ""
        onProgressChanged(attempts, revealed)

        // Round ends if guessed correctly or all 5 attempts are used.
        if state == .correct || attempts.count >= 5 {
            revealNow()
            return
        }
    }

    private func revealNow() {
        revealed = true
        focused = false
        onProgressChanged(attempts, revealed)
    }

    /// Checks if the round has already finished (correct or out of attempts).
    private func isRoundExhaustedOrCorrect() -> Bool {
        attempts.contains(where: { $0.state == .correct }) || attempts.count >= 5
    }

    private func attemptsUsed() -> Int {
        if let idx = attempts.firstIndex(where: { $0.state == .correct }) {
            return idx + 1
        }
        return min(5, attempts.count)
    }

    /// Simple scoring: start at 5 and lose 1 point per extra attempt.
    private func score() -> Int {
        if let idx = attempts.firstIndex(where: { $0.state == .correct }) {
            return max(0, 5 - idx)
        }
        return 0
    }

    /// “Correct enough” is defined as within A$1.00 of the real price.
    private func isCorrect(_ guess: Double) -> Bool {
        abs(guess - game.priceAUD) <= 1.0
    }

    private func parse(_ s: String) -> Double? {
        let cleaned = s.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }

    private func formatAUD(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "AUD"
        return f.string(from: NSNumber(value: v)) ?? String(format: "A$%.2f", v)
    }

    @ViewBuilder
    private func icon(for state: GuessState) -> some View {
        switch state {
        case .tooLow:
            Image(systemName: "arrow.up.circle.fill").foregroundStyle(.nbCrimson)
        case .tooHigh:
            Image(systemName: "arrow.down.circle.fill").foregroundStyle(.nbCrimson)
        case .correct:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.nbGold)
        }
    }

    private func borderColor(for state: GuessState) -> Color {
        switch state {
        case .tooLow, .tooHigh: return .nbCrimson.opacity(0.7)
        case .correct: return .nbGold
        }
    }
}

/// Safety wrapper for array indexing so out-of-bounds doesn't explode the app.
fileprivate extension Array {
    subscript(safe idx: Int) -> Element? { indices.contains(idx) ? self[idx] : nil }
}
