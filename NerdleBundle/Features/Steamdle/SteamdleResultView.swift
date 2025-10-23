//
//  SteamdleResultView.swift
//  NerdleBundle
//
//  Created by V on 24/10/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SteamdleResultView: View {
    let dayId: String
    let games: [SteamdleGame]
    let totalPoints: Int
    let totalAttempts: Int

    @State private var sharing = false
    @State private var shareError: String?
    @State private var showLoginAlert = false
    @State private var showAlreadyAlert = false
    @State private var showSuccessAlert = false

    @State private var goHome = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    HStack {
                        StatTile(title: "GAMES", value: "\(games.count)")
                        Divider().frame(height: 60).background(.white.opacity(0.1))
                        StatTile(title: "ATTEMPTS", value: "\(totalAttempts)")
                        Divider().frame(height: 60).background(.white.opacity(0.1))
                        StatTile(title: "POINTS", value: "\(totalPoints)")
                    }
                    .padding()
                    .background(Color.nbCard)
                    .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today’s picks").font(.headline)
                        ForEach(games) { g in
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: g.headerImage)) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: { Color.nbCard.opacity(0.6) }
                                .frame(width: 60, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(g.name).foregroundStyle(.nbTextPrimary).lineLimit(2)
                                    Text("Price: \(formatAUD(g.priceAUD))")
                                        .font(.caption).foregroundStyle(.nbTextSecondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.nbCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)

                    if let shareError { Text(shareError).foregroundStyle(.red) }

                    Button {
                        Task { await shareTap() }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Share Results")
                                .font(.system(size: 20, weight: .bold))
                            if sharing { ProgressView().scaleEffect(0.9) }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .disabled(sharing)
                    .background(Color.nbHeader)
                    .clipShape(RoundedRectangle(cornerRadius: 72))
                    .overlay(RoundedRectangle(cornerRadius: 72).stroke(Color.nbCrimson.opacity(0.4), lineWidth: 0.8))
                    .foregroundStyle(Color.nbTextPrimary)
                    .padding(.horizontal)

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
                    .overlay(RoundedRectangle(cornerRadius: 72).stroke(Color.nbCrimson.opacity(0.25), lineWidth: 0.8))
                    .foregroundStyle(.nbTextPrimary)
                    .padding(.horizontal)

                    NavigationLink(
                        destination: HomeView(tab: .constant(.home)).navigationBarBackButtonHidden(true),
                        isActive: $goHome
                    ) { EmptyView() }.hidden()

                    Spacer(minLength: 40)
                }
            }
            .background(Color.nbBackground.ignoresSafeArea())
            .alert("Sign in required", isPresented: $showLoginAlert) { Button("OK", role: .cancel) { } } message: {
                Text("Log in to share your result with the community.")
            }
            .alert("Already shared", isPresented: $showAlreadyAlert) { Button("OK") { } } message: {
                Text("Your results are already on today’s leaderboard. Well done!")
            }
            .alert("Shared successfully", isPresented: $showSuccessAlert) { Button("Nice!") { } } message: {
                Text("Your results have been added to today’s leaderboard.")
            }
        }
    }

    private var header: some View {
        Text("Steamdle Results")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nbHeader)
            .foregroundStyle(.nbTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 8)
    }

    private func shareTap() async {
        shareError = nil
        guard let u = Auth.auth().currentUser, !u.isAnonymous else {
            await MainActor.run { showLoginAlert = true }
            return
        }

        if await alreadySharedToday() {
            await MainActor.run { showAlreadyAlert = true }
            return
        }

        await MainActor.run { sharing = true }
        do {
            try await SteamdleScoreService().submit(dayId: dayId, points: totalPoints, attemptsUsed: totalAttempts)
            await MainActor.run { showSuccessAlert = true }
        } catch {
            await MainActor.run { shareError = error.localizedDescription }
        }
        await MainActor.run { sharing = false }
    }

    private func alreadySharedToday() async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let db = Firestore.firestore()
        do {
            let snap = try await db.collection("scores")
                .whereField("uid", isEqualTo: uid)
                .whereField("game", isEqualTo: "steamdle")
                .whereField("dayId", isEqualTo: dayId)
                .limit(to: 1)
                .getDocuments()
            return !snap.documents.isEmpty
        } catch {
            return false
        }
    }

    private func formatAUD(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "AUD"
        return f.string(from: NSNumber(value: v)) ?? String(format: "A$%.2f", v)
    }
}

fileprivate struct StatTile: View {
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
