import SwiftUI

struct PostMatchView: View {
    let result: MatchResult
    let gameManager: GameManager
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                scoreHeader
                playerRatingsSection
                matchStatsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.pitchGreen, in: .rect(cornerRadius: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Full Time")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scoreHeader: some View {
        VStack(spacing: 12) {
            Text("FULL TIME")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSecondary)

            HStack {
                Text(result.homeTeam)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(result.homeScore)")
                        .font(.system(size: 44, weight: .black))
                    Text("-")
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\(result.awayScore)")
                        .font(.system(size: 44, weight: .black))
                }
                .foregroundStyle(AppTheme.textPrimary)

                Text(result.awayTeam)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }

            let goalEvents = result.events.filter { $0.type == .goal }
            if !goalEvents.isEmpty {
                VStack(spacing: 4) {
                    ForEach(goalEvents) { event in
                        HStack {
                            if event.team == .home {
                                Text("\(event.playerName ?? "") \(event.minute)'")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                Text("⚽")
                                    .font(.caption)
                                Color.clear.frame(maxWidth: .infinity)
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                                Text("⚽")
                                    .font(.caption)
                                Text("\(event.playerName ?? "") \(event.minute)'")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.surface, in: .rect(cornerRadius: 16))
    }

    private var playerRatingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Player Ratings")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(result.playerRatings.sorted { $0.rating > $1.rating }) { rating in
                HStack(spacing: 10) {
                    Text(rating.position)
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 28)

                    Text(rating.playerName)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    if rating.goals > 0 {
                        HStack(spacing: 2) {
                            Text("⚽")
                                .font(.caption2)
                            if rating.goals > 1 {
                                Text("×\(rating.goals)")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }

                    if rating.assists > 0 {
                        HStack(spacing: 2) {
                            Text("🅰️")
                                .font(.caption2)
                            if rating.assists > 1 {
                                Text("×\(rating.assists)")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }

                    Text(String(format: "%.1f", rating.rating))
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.matchRatingColor(rating.rating))
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(AppTheme.surface, in: .rect(cornerRadius: 8))
            }
        }
    }

    private var matchStatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Match Stats")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 8) {
                statRow(label: "Possession", home: "\(result.homeStats.possession)%", away: "\(result.awayStats.possession)%", homeVal: result.homeStats.possession, awayVal: result.awayStats.possession)
                statRow(label: "Shots", home: "\(result.homeStats.shots)", away: "\(result.awayStats.shots)", homeVal: result.homeStats.shots, awayVal: result.awayStats.shots)
                statRow(label: "On Target", home: "\(result.homeStats.shotsOnTarget)", away: "\(result.awayStats.shotsOnTarget)", homeVal: result.homeStats.shotsOnTarget, awayVal: result.awayStats.shotsOnTarget)
                statRow(label: "Corners", home: "\(result.homeStats.corners)", away: "\(result.awayStats.corners)", homeVal: result.homeStats.corners, awayVal: result.awayStats.corners)
                statRow(label: "Fouls", home: "\(result.homeStats.fouls)", away: "\(result.awayStats.fouls)", homeVal: result.homeStats.fouls, awayVal: result.awayStats.fouls)
                statRow(label: "Yellow Cards", home: "\(result.homeStats.yellowCards)", away: "\(result.awayStats.yellowCards)", homeVal: result.homeStats.yellowCards, awayVal: result.awayStats.yellowCards)
            }
            .padding(16)
            .background(AppTheme.surface, in: .rect(cornerRadius: 14))
        }
    }

    private func statRow(label: String, home: String, away: String, homeVal: Int, awayVal: Int) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(home)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 50, alignment: .trailing)
                Spacer()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(away)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 50, alignment: .leading)
            }

            GeometryReader { geo in
                let total = max(homeVal + awayVal, 1)
                let homeWidth = geo.size.width * Double(homeVal) / Double(total)
                HStack(spacing: 2) {
                    Capsule()
                        .fill(AppTheme.pitchGreen)
                        .frame(width: max(homeWidth, 2), height: 4)
                    Spacer(minLength: 0)
                    Capsule()
                        .fill(AppTheme.textSecondary.opacity(0.5))
                        .frame(width: max(geo.size.width - homeWidth - 2, 2), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}
