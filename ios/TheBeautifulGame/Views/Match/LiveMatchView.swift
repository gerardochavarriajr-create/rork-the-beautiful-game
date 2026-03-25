import SwiftUI

struct LiveMatchView: View {
    let gameManager: GameManager
    @Bindable var matchEngine: MatchEngine
    let onMatchEnd: () -> Void
    @State private var goalTrigger: Int = 0
    @State private var cardTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            scoreboard
            matchTimeline
            controlBar
        }
        .navigationTitle("Live Match")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: matchEngine.matchResult?.state) { _, newValue in
            if newValue == .finished {
                onMatchEnd()
            }
        }
        .onChange(of: matchEngine.matchResult?.homeScore) { _, _ in
            goalTrigger += 1
        }
        .onChange(of: matchEngine.matchResult?.awayScore) { _, _ in
            goalTrigger += 1
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: goalTrigger)
        .sensoryFeedback(.warning, trigger: cardTrigger)
    }

    private var scoreboard: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(spacing: 4) {
                    Text(matchEngine.matchResult?.homeTeam ?? "")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    HStack(spacing: 12) {
                        Text("\(matchEngine.matchResult?.homeScore ?? 0)")
                            .font(.system(size: 40, weight: .black, design: .default))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("-")
                            .font(.title.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(matchEngine.matchResult?.awayScore ?? 0)")
                            .font(.system(size: 40, weight: .black, design: .default))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Text("\(matchEngine.matchResult?.currentMinute ?? 0)'")
                        .font(.headline)
                        .foregroundStyle(AppTheme.golden)
                }

                VStack(spacing: 4) {
                    Text(matchEngine.matchResult?.awayTeam ?? "")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }

            matchProgressBar

            if let result = matchEngine.matchResult {
                HStack(spacing: 24) {
                    statPill(label: "Poss", home: "\(result.homeStats.possession)%", away: "\(result.awayStats.possession)%")
                    statPill(label: "Shots", home: "\(result.homeStats.shots)", away: "\(result.awayStats.shots)")
                    statPill(label: "On Target", home: "\(result.homeStats.shotsOnTarget)", away: "\(result.awayStats.shotsOnTarget)")
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
    }

    private var matchProgressBar: some View {
        GeometryReader { geo in
            let progress = Double(matchEngine.matchResult?.currentMinute ?? 0) / 90.0
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "7fe084").opacity(0.3))
                    .frame(height: 4)
                Capsule()
                    .fill(Color(hex: "ed6b02"))
                    .frame(width: geo.size.width * min(progress, 1.0), height: 4)
            }
        }
        .frame(height: 4)
    }

    private func statPill(label: String, home: String, away: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 6) {
                Text(home)
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text("-")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(away)
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }

    private var matchTimeline: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(matchEngine.matchResult?.events ?? []) { event in
                        eventCard(event: event)
                            .id(event.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: matchEngine.matchResult?.events.count) { _, _ in
                if let lastEvent = matchEngine.matchResult?.events.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastEvent.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func eventCard(event: MatchEvent) -> some View {
        let isGoal = event.type == .goal
        let isCard = event.type == .yellowCard || event.type == .redCard
        let isUserTeam = (event.team == .home && matchEngine.matchResult?.homeTeam == gameManager.userClub?.name) ||
                         (event.team == .away && matchEngine.matchResult?.awayTeam == gameManager.userClub?.name)

        let bgColor: Color = {
            if isGoal && isUserTeam { return Color.green.opacity(0.15) }
            if isGoal && !isUserTeam { return Color.red.opacity(0.15) }
            if event.type == .yellowCard { return Color.yellow.opacity(0.1) }
            if event.type == .redCard { return Color.red.opacity(0.15) }
            if event.type == .halftime || event.type == .fulltime { return AppTheme.surfaceElevated }
            return AppTheme.surface
        }()

        let borderColor: Color = isGoal ? AppTheme.golden : .clear

        return HStack(alignment: .top, spacing: 10) {
            Text("\(event.minute)'")
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 32, alignment: .trailing)

            Text(event.type.icon)
                .font(.body)

            Text(event.description)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(bgColor, in: .rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: isGoal ? 1.5 : 0)
        )
    }

    private var controlBar: some View {
        HStack(spacing: 16) {
            speedButton(label: "1x", speed: 1.0)
            speedButton(label: "2x", speed: 2.0)
            speedButton(label: "5x", speed: 5.0)

            Divider()
                .frame(height: 24)

            Button {
                matchEngine.instantResult()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "forward.end.fill")
                    Text("Instant")
                }
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.danger.opacity(0.2), in: Capsule())
                .foregroundStyle(AppTheme.danger)
            }
        }
        .padding(12)
        .background(AppTheme.surface)
    }

    private func speedButton(label: String, speed: Double) -> some View {
        Button {
            matchEngine.speed = speed
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(matchEngine.speed == speed ? AppTheme.pitchGreen : AppTheme.surfaceElevated, in: Capsule())
                .foregroundStyle(matchEngine.speed == speed ? .white : AppTheme.textSecondary)
        }
    }
}
