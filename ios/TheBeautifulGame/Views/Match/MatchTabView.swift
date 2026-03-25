import SwiftUI

struct MatchTabView: View {
    let gameManager: GameManager
    @State private var matchEngine = MatchEngine()
    @State private var matchPhase: MatchPhase = .preMatch

    var body: some View {
        NavigationStack {
            Group {
                switch matchPhase {
                case .preMatch:
                    PreMatchView(gameManager: gameManager, matchEngine: matchEngine, onStartMatch: startMatch)
                case .live:
                    LiveMatchView(gameManager: gameManager, matchEngine: matchEngine, onMatchEnd: endMatch)
                case .postMatch:
                    if let result = matchEngine.matchResult {
                        PostMatchView(result: result, gameManager: gameManager, onContinue: resetToPreMatch)
                    }
                }
            }
            .background(AppTheme.background)
        }
        .preferredColorScheme(.dark)
    }

    private func startMatch() {
        guard let fixture = gameManager.nextFixture, let userClub = gameManager.userClub else { return }
        let isHome = fixture.homeTeam == userClub.name
        let opponentName = isHome ? fixture.awayTeam : fixture.homeTeam
        let opponentClub = gameManager.league?.clubs.first { $0.name == opponentName }

        if gameManager.lineupPlayerIDs.isEmpty {
            gameManager.autoFillLineup()
        }

        matchEngine.startMatch(
            home: fixture.homeTeam,
            away: fixture.awayTeam,
            homeClub: isHome ? userClub : opponentClub,
            awayClub: isHome ? opponentClub : userClub,
            week: fixture.week,
            competition: fixture.competition,
            venue: fixture.venue,
            lineup: gameManager.lineupPlayerIDs,
            formation: gameManager.selectedFormation,
            gameManager: gameManager
        )
        withAnimation { matchPhase = .live }
    }

    private func endMatch() {
        withAnimation { matchPhase = .postMatch }
    }

    private func resetToPreMatch() {
        if let result = matchEngine.matchResult {
            gameManager.recordMatchResult(result)
            gameManager.addNews(NewsArticle(
                id: UUID().uuidString,
                headline: "\(result.homeTeam) \(result.homeScore) - \(result.awayScore) \(result.awayTeam)",
                subheadline: "Matchday \(result.week) result",
                body: "In a \(result.competition) clash, \(result.homeTeam) hosted \(result.awayTeam) at \(result.venue). The final score was \(result.homeScore)-\(result.awayScore).",
                date: "Week \(gameManager.currentWeek)",
                source: "Match Report",
                type: .matchResult,
                isRead: false,
                week: gameManager.currentWeek
            ))
            gameManager.save()
        }
        matchEngine.matchResult = nil
        withAnimation { matchPhase = .preMatch }
    }
}

private enum MatchPhase {
    case preMatch, live, postMatch
}
