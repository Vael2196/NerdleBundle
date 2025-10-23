//
//  SteamdleView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI

struct SteamdleView: View {
    @State private var payload: SteamdleDailyPayload?
    @State private var loading = true
    @State private var error: String?

    @State private var roundIndex = 0
    @State private var perRoundPoints: [Int] = [0,0,0]
    @State private var perRoundAttemptsUsed: [Int] = [0,0,0]
    @State private var goResults = false

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
                        SteamdleRoundView(
                            game: p.games[roundIndex],
                            onFinished: { points, attempts in
                                perRoundPoints[roundIndex] = points
                                perRoundAttemptsUsed[roundIndex] = attempts
                                if roundIndex < 2 {
                                    roundIndex += 1
                                } else {
                                    goResults = true
                                }
                            }
                        )
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

    private func load() async {
        loading = true; error = nil
        do {
            let res = try await SteamdleBackend.shared.getToday()
            await MainActor.run { payload = res }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
        loading = false
    }
}

fileprivate struct SteamdleRoundView: View {
    let game: SteamdleGame
    let onFinished: (_ points: Int, _ attemptsUsed: Int) -> Void

    struct Attempt {
        let guess: Double
        let state: GuessState
    }

    enum GuessState { case pending, tooLow, tooHigh, correct }

    @State private var attempts: [Attempt?] = Array(repeating: nil, count: 5)
    @State private var currentRaw: String = ""
    @FocusState private var focused: Bool
    @State private var revealed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
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

                if revealed {
                    Text("Price: \(formatAUD(game.priceAUD))")
                        .font(.headline)
                        .foregroundStyle(.nbGold)
                        .padding(.top, 2)
                }

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
        .onAppear { resetForGame() }
        .onChange(of: game.appid) { _ in resetForGame() }
    }

    @ViewBuilder
    private func attemptRow(_ index: Int) -> some View {
        let activeIndex = firstPendingIndex()
        let isActive = !revealed && (activeIndex == index)

        HStack(alignment: .center, spacing: 8) {
            Text("#\(index + 1)")
                .font(.caption)
                .foregroundStyle(.nbTextSecondary)
                .frame(width: 28)

            if let att = attempts[index] {
                HStack(spacing: 8) {
                    Text(formatAUD(att.guess))
                        .foregroundStyle(.nbTextPrimary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.nbCard.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    icon(for: att.state)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor(for: att.state), lineWidth: 1)
                )
                .accessibilityLabel("Guess \(index + 1): \(formatAUD(att.guess))")
            } else if isActive {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .accessibilityHint("Active field. Enter your guess and tap Guess.")
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Guess") { submit(index) }
                    }
                }
                .onAppear { focused = true }
            } else {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
                .accessibilityLabel("Attempt \(index + 1) locked until previous guess is submitted")
            }
        }
        .padding(.vertical, 2)
    }

    private func resetForGame() {
        attempts = Array(repeating: nil, count: 5)
        currentRaw = ""
        revealed = false
        focused = true
    }

    private func firstPendingIndex() -> Int? {
        for i in 0..<5 where attempts[i] == nil { return i }
        return nil
    }

    private func submit(_ index: Int) {
        guard !revealed else { return }
        guard let value = parse(currentRaw) else { return }

        let state: GuessState
        if isCorrect(value) {
            state = .correct
        } else {
            state = value < game.priceAUD ? .tooLow : .tooHigh
        }

        attempts[index] = Attempt(guess: value, state: state)

        if case .correct = state {
            revealNow()
            return
        }

        currentRaw = ""
        if firstPendingIndex() == nil {
            revealNow()
        }
    }

    private func revealNow() {
        revealed = true
        focused = false
    }

    private func attemptsUsed() -> Int {
        if let idx = attempts.firstIndex(where: { $0?.state == .correct }) {
            return idx + 1
        }
        return 5
    }

    private func score() -> Int {
        if let idx = attempts.firstIndex(where: { $0?.state == .correct }) {
            return max(0, 5 - idx)
        }
        return 0
    }

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
        case .pending:
            EmptyView()
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
        case .pending: return .white.opacity(0.08)
        case .tooLow, .tooHigh: return .nbCrimson.opacity(0.5)
        case .correct: return .nbGold
        }
    }
}
