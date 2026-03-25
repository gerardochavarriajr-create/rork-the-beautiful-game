import SwiftUI

struct DashboardView: View {
    let gameManager: GameManager
    @State private var showLeagueTable: Bool = false
    @State private var showInbox: Bool = false
    @State private var advanceTrigger: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    nextMatchCard
                    newsPreview
                    leagueSnapshot
                    boardConfidenceCard
                    quickStats
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(AppTheme.background)
            .navigationTitle(gameManager.userClub?.name ?? "Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    clubBadge
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Week \(gameManager.currentWeek)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                advanceWeekButton
            }
            .sheet(isPresented: $showLeagueTable) {
                LeagueTableView(gameManager: gameManager)
            }
            .sheet(isPresented: $showInbox) {
                InboxView(gameManager: gameManager)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var clubBadge: some View {
        Group {
            if let club = gameManager.userClub {
                Circle()
                    .fill(Color(hex: club.primaryColor))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(club.shortName.prefix(2)))
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
            }
        }
    }

    private var nextMatchCard: some View {
        Group {
            if let fixture = gameManager.nextFixture {
                Button {
                    gameManager.selectedTab = 2
                } label: {
                    VStack(spacing: 12) {
                        Text("NEXT MATCH")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.pitchGreen)

                        HStack {
                            VStack(spacing: 4) {
                                clubIcon(name: fixture.homeTeam)
                                Text(fixture.homeTeam)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)

                            Text("vs")
                                .font(.title2.bold())
                                .foregroundStyle(AppTheme.textSecondary)

                            VStack(spacing: 4) {
                                clubIcon(name: fixture.awayTeam)
                                Text(fixture.awayTeam)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        HStack(spacing: 16) {
                            Label(fixture.competition, systemImage: "trophy.fill")
                            Label("Week \(fixture.week)", systemImage: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.surface, in: .rect(cornerRadius: 16))
                }
            }
        }
    }

    private var newsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("News")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button("See All") { showInbox = true }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.pitchGreen)
            }

            if gameManager.news.isEmpty {
                Text("No news yet")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(gameManager.news.prefix(3)) { article in
                    HStack(spacing: 12) {
                        Image(systemName: article.type.icon)
                            .font(.title3)
                            .foregroundStyle(article.isRead ? AppTheme.textSecondary : AppTheme.golden)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(article.headline)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(2)
                            Text(article.date)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        if !article.isRead {
                            Circle()
                                .fill(AppTheme.pitchGreen)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.surface, in: .rect(cornerRadius: 10))
                }
            }
        }
    }

    private var leagueSnapshot: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("League Table")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button("Full Table") { showLeagueTable = true }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.pitchGreen)
            }

            let table = gameManager.leagueTable
            let userIdx = table.firstIndex { $0.isUserTeam } ?? 0
            let startIdx = max(0, userIdx - 2)
            let endIdx = min(table.count, startIdx + 5)
            let visibleRows = Array(table[startIdx..<endIdx])

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("#").frame(width: 28, alignment: .center)
                    Text("Team").frame(maxWidth: .infinity, alignment: .leading)
                    Text("P").frame(width: 28, alignment: .center)
                    Text("GD").frame(width: 32, alignment: .center)
                    Text("Pts").frame(width: 32, alignment: .center)
                }
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)

                ForEach(Array(visibleRows.enumerated()), id: \.element.id) { offset, row in
                    let position = startIdx + offset + 1
                    HStack(spacing: 0) {
                        Text("\(position)")
                            .frame(width: 28, alignment: .center)
                            .font(.caption.bold())
                        Text(row.teamName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text("\(row.played)")
                            .frame(width: 28, alignment: .center)
                            .font(.caption)
                        Text("\(row.goalDifference > 0 ? "+" : "")\(row.goalDifference)")
                            .frame(width: 32, alignment: .center)
                            .font(.caption)
                        Text("\(row.points)")
                            .frame(width: 32, alignment: .center)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(row.isUserTeam ? AppTheme.pitchGreen : AppTheme.textPrimary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(row.isUserTeam ? AppTheme.pitchGreen.opacity(0.1) : .clear)
                }
            }
            .background(AppTheme.surface, in: .rect(cornerRadius: 12))
        }
    }

    private var boardConfidenceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Board Confidence")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            let confidence = gameManager.userClub?.boardConfidence ?? 50
            let color: Color = confidence > 60 ? .green : confidence > 30 ? .orange : .red
            let label = confidence > 60 ? "Satisfied" : confidence > 30 ? "Concerned" : "Unhappy"

            HStack {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.surfaceElevated)
                            .frame(height: 10)
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * Double(confidence) / 100.0, height: 10)
                    }
                }
                .frame(height: 10)

                Text("\(confidence)%")
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                    .frame(width: 50, alignment: .trailing)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 12))
    }

    private var quickStats: some View {
        let record = gameManager.seasonRecord
        let gd = gameManager.goalDifference
        let budget = gameManager.userClub?.budget.transfer ?? 0
        let scorer = gameManager.topScorer

        return ScrollView(.horizontal) {
            HStack(spacing: 12) {
                statCard(title: "Record", value: "W\(record.wins) D\(record.draws) L\(record.losses)", icon: "chart.bar.fill")
                statCard(title: "Goal Diff", value: "\(gd > 0 ? "+" : "")\(gd)", icon: "plusminus")
                statCard(title: "Budget", value: "€\(formatMoney(budget))", icon: "banknote.fill")
                if let scorer {
                    statCard(title: "Top Scorer", value: "\(scorer.name) (\(scorer.goals))", icon: "flame.fill")
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.pitchGreen)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .frame(width: 140, alignment: .leading)
        .background(AppTheme.surface, in: .rect(cornerRadius: 12))
    }

    private var advanceWeekButton: some View {
        Button {
            advanceTrigger += 1
            gameManager.advanceWeek()
            gameManager.save()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "forward.fill")
                Text("Advance Week")
                    .font(.headline)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.pitchGreen, in: .rect(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .sensoryFeedback(.impact(weight: .medium), trigger: advanceTrigger)
    }

    private func clubIcon(name: String) -> some View {
        let club = gameManager.league?.clubs.first { $0.name == name }
        return Circle()
            .fill(Color(hex: club?.primaryColor ?? "#333333"))
            .frame(width: 40, height: 40)
            .overlay {
                Text(String(club?.shortName.prefix(2) ?? "??"))
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
            }
    }

    private func formatMoney(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.1fM", Double(amount) / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.0fK", Double(amount) / 1_000)
        }
        return "\(amount)"
    }
}
