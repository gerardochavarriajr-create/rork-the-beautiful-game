import SwiftUI

struct PreMatchView: View {
    let gameManager: GameManager
    let matchEngine: MatchEngine
    let onStartMatch: () -> Void
    @State private var showFormation: Bool = false
    @State private var mentality: Double = 0.5
    @State private var tempo: Double = 0.5

    var body: some View {
        Group {
            if let fixture = gameManager.nextFixture {
                ScrollView {
                    VStack(spacing: 20) {
                        matchHeader(fixture: fixture)
                        lineupSection
                        opponentPreview(fixture: fixture)
                        tacticsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .safeAreaInset(edge: .bottom) {
                    playMatchButton
                }
                .sheet(isPresented: $showFormation) {
                    FormationPickerView(gameManager: gameManager)
                }
            } else {
                ContentUnavailableView("No Upcoming Match", systemImage: "sportscourt", description: Text("Advance the week to schedule new fixtures."))
            }
        }
        .navigationTitle("Match Day")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func matchHeader(fixture: Fixture) -> some View {
        VStack(spacing: 14) {
            Text(fixture.competition.uppercased())
                .font(.caption.bold())
                .foregroundStyle(AppTheme.pitchGreen)

            HStack {
                VStack(spacing: 6) {
                    clubBadge(name: fixture.homeTeam)
                    Text(fixture.homeTeam)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                Text("vs")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(spacing: 6) {
                    clubBadge(name: fixture.awayTeam)
                    Text(fixture.awayTeam)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }

            Label(fixture.venue, systemImage: "mappin.circle.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(20)
        .background(AppTheme.surface, in: .rect(cornerRadius: 16))
    }

    private var lineupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Lineup")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button("Edit") { showFormation = true }
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.pitchGreen)
            }

            Text("Formation: \(gameManager.selectedFormation.name)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            let filledCount = gameManager.lineupPlayerIDs.count
            let totalSlots = gameManager.selectedFormation.slots.count

            if filledCount < totalSlots {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("\(filledCount)/\(totalSlots) positions filled")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("Auto Fill") {
                        gameManager.autoFillLineup()
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.pitchGreen)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Lineup complete")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private func opponentPreview(fixture: Fixture) -> some View {
        let opponentName = fixture.homeTeam == gameManager.userClub?.name ? fixture.awayTeam : fixture.homeTeam
        let opponent = gameManager.league?.clubs.first { $0.name == opponentName }
        let opponentRow = gameManager.leagueTable.first { $0.teamName == opponentName }

        return VStack(alignment: .leading, spacing: 10) {
            Text("Opponent")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if let opponent {
                HStack(spacing: 12) {
                    clubBadge(name: opponent.name)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(opponent.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        if let row = opponentRow {
                            Text("P\(row.played) W\(row.won) D\(row.drawn) L\(row.lost) • \(row.points) pts")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    Spacer()
                }

                if let form = opponentRow?.form, !form.isEmpty {
                    HStack(spacing: 4) {
                        Text("Form:")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        ForEach(Array(form.enumerated()), id: \.offset) { _, result in
                            Text(result)
                                .font(.caption2.bold())
                                .frame(width: 22, height: 22)
                                .background(AppTheme.formResultColor(result), in: Circle())
                                .foregroundStyle(.white)
                        }
                    }
                }

                let topPlayers = opponent.players.sorted { $0.overallRating > $1.overallRating }.prefix(3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Players")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                    ForEach(Array(topPlayers)) { player in
                        HStack {
                            Text(player.primaryPosition.rawValue)
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.positionColor(player.primaryPosition.category))
                            Text(player.shortName)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("\(player.overallRating)")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.ratingColor(player.overallRating))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private var tacticsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tactics")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Mentality")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text(mentalityLabel)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.pitchGreen)
                }
                Slider(value: $mentality, in: 0...1)
                    .tint(AppTheme.pitchGreen)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Tempo")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text(tempoLabel)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.pitchGreen)
                }
                Slider(value: $tempo, in: 0...1)
                    .tint(AppTheme.pitchGreen)
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: 14))
    }

    private var mentalityLabel: String {
        switch mentality {
        case 0..<0.3: "Defensive"
        case 0.3..<0.7: "Balanced"
        default: "Attacking"
        }
    }

    private var tempoLabel: String {
        switch tempo {
        case 0..<0.3: "Slow"
        case 0.3..<0.7: "Normal"
        default: "High"
        }
    }

    private var playMatchButton: some View {
        Button {
            if gameManager.lineupPlayerIDs.isEmpty {
                gameManager.autoFillLineup()
            }
            onStartMatch()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Play Match")
                    .font(.headline)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.golden, in: .rect(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func clubBadge(name: String) -> some View {
        let club = gameManager.league?.clubs.first { $0.name == name }
        return Circle()
            .fill(Color(hex: club?.primaryColor ?? "#333333"))
            .frame(width: 44, height: 44)
            .overlay {
                Text(String(club?.shortName.prefix(2) ?? "??"))
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
    }
}
