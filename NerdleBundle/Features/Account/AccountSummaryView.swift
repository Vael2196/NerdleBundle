import SwiftUI

struct AccountSummaryView: View {
    @EnvironmentObject private var app: AppState
    @State private var weeklyPlayed = 4
    @State private var weeklyGoal = 7
    @State private var dailyPoints = 390
    @State private var weeklyPoints = 1337
    @State private var worldRank = 2

    var progress: Double { min(Double(weeklyPlayed) / Double(weeklyGoal), 1.0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Header(title: "Account")

                // TODO: Prollly will have to rebind for the Firebase
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: NB.corner)
                        .fill(Color.nbMutedRed)
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading) {
                        Text("Welcome, \(app.user?.username ?? "Player")")
                        Text(app.user?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.nbTextSecondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                // The round chart thingy. Looks horrible, I know, but I gotta make it dynamic sometime later on, got no energy rn
                // TODO: Change the way this looks in light mode (not gonna bother for now)
                VStack(spacing: 8) {
                    ZStack {
                        Circle().stroke(lineWidth: 8).foregroundStyle(.white.opacity(0.2)).frame(width: 150, height: 150)
                        Circle().trim(from: 0, to: progress).stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round)).foregroundStyle(.nbGold).rotationEffect(.degrees(-90)).frame(width: 150, height: 150)
                        VStack {
                            Text("\(weeklyPlayed)/\(weeklyGoal)").font(.title).bold()
                            Text("played").foregroundStyle(.nbTextSecondary)
                        }
                    }
                    Text("You have played a total of \(weeklyPlayed) trivia games this week!")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                HStack {
                    StatTile(title: "Daily POINTS", value: "\(dailyPoints)")
                    Divider().frame(height: 60).background(.white.opacity(0.1))
                    StatTile(title: "Weekly POINTS", value: "\(weeklyPoints)")
                    Divider().frame(height: 60).background(.white.opacity(0.1))
                    StatTile(title: "WORLD RANK", value: "#\(worldRank)")
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                Button("Sign out") { app.user = nil }
                    .buttonStyle(.borderedProminent)
                    .tint(.nbCrimson)

                Spacer(minLength: 40)
            }
        }
        .background(Color.nbBackground.ignoresSafeArea())
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
