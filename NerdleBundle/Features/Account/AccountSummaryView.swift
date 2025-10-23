//
//  AccountSummaryView.swift
//  NerdleBundle
//
//  Created by V on 8/10/2025.
//

import SwiftUI
import Charts

struct AccountSummaryView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var vm = AccountSummaryVM()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Header(title: "Account")

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

                Picker("", selection: $vm.chartMode) {
                    Text("% Better").tag(AccountSummaryVM.ChartMode.percentile)
                    Text("Avg / day").tag(AccountSummaryVM.ChartMode.dailyAvg)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    switch vm.chartMode {
                    case .percentile:
                        PercentileDonut(percent: vm.percentile)
                            .frame(width: 160, height: 160)
                            .padding(.top, 6)
                        Text("You are better than \(Int(round(vm.percentile)))% of players")
                            .foregroundStyle(.nbTextSecondary)
                            .padding(.horizontal)

                    case .dailyAvg:
                        DailyAverageChart(series: vm.last7Days, maxPerDay: 25)
                            .frame(height: 180)
                            .padding(.horizontal)
                        Text("Your score per day (last 7 days, max 25)")
                            .foregroundStyle(.nbTextSecondary)
                    }
                }

                HStack {
                    StatTile(title: "DAILY POINTS", value: "\(vm.dailyPoints)")
                    Divider().frame(height: 60).background(.white.opacity(0.1))
                    StatTile(title: "WEEKLY POINTS", value: "\(vm.weeklyPoints)")
                    Divider().frame(height: 60).background(.white.opacity(0.1))
                    StatTile(title: "ALL-TIME RANK", value: vm.allTimeRankText)
                }
                .padding()
                .background(Color.nbCard)
                .clipShape(RoundedRectangle(cornerRadius: NB.corner))
                .padding(.horizontal)

                Button("Sign out") {
                    do { try AuthService.shared.signOut() } catch { }
                    app.user = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.nbCrimson)

                Spacer(minLength: 40)
            }
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .onAppear { vm.onAppear() }
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

fileprivate struct PercentileDonut: View {
    let percent: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .foregroundStyle(.white.opacity(0.18))
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, percent/100.0))))
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundStyle(.nbGold)
                .rotationEffect(.degrees(-90))
            Text("\(Int(round(percent)))%")
                .font(.title).bold()
        }
    }
}

fileprivate struct DailyAverageChart: View {
    let series: [AccountSummaryVM.DayPoint]
    let maxPerDay: Int

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(series) { dp in
                BarMark(
                    x: .value("Day", dp.date, unit: .day),
                    y: .value("Score", dp.total)
                )
                .cornerRadius(6)
            }
            .chartYScale(domain: 0...maxPerDay)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.06))
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 5, 10, 15, 20, 25]) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.06))
                    AxisValueLabel()
                }
            }
        } else {
            VStack(spacing: 8) {
                ForEach(series) { dp in
                    HStack {
                        Text(dp.date, format: .dateTime.weekday(.abbreviated))
                            .frame(width: 36, alignment: .leading)
                            .foregroundStyle(.nbTextSecondary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.nbGold)
                            .frame(width: CGFloat(dp.total) / CGFloat(maxPerDay) * 220.0, height: 10)
                        Spacer()
                        Text("\(dp.total)")
                            .foregroundStyle(.nbTextPrimary)
                    }
                }
            }
        }
    }
}
