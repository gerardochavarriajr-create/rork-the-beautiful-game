import SwiftUI
import Foundation

@Observable
@MainActor
class MatchEngine {
    var matchResult: MatchResult?
    var isSimulating: Bool = false
    var speed: Double = 1.0
    private var simulationTask: Task<Void, Never>?

    /// FM14 simulation resources — loaded once, reused across matches
    private let matrix: FM14EventMatrix
    private let params: FM14MatchParams

    init() {
        // Try loading real event matrix from bundled JSON, fall back to defaults
        self.matrix = FM14EventMatrix.loadFromBundle() ?? .fallback
        self.params = .default
    }

    func startMatch(home: String, away: String, homeClub: Club?, awayClub: Club?, week: Int, competition: String, venue: String, lineup: [String: String], formation: Formation, gameManager: GameManager) {
        let homePrestige = homeClub?.prestige ?? 5
        let awayPrestige = awayClub?.prestige ?? 5

        matchResult = MatchResult(
            id: UUID().uuidString,
            homeTeam: home,
            awayTeam: away,
            homeScore: 0,
            awayScore: 0,
            events: [],
            homeStats: MatchStats(possession: 50, shots: 0, shotsOnTarget: 0, corners: 0, fouls: 0, yellowCards: 0, redCards: 0),
            awayStats: MatchStats(possession: 50, shots: 0, shotsOnTarget: 0, corners: 0, fouls: 0, yellowCards: 0, redCards: 0),
            playerRatings: generateInitialRatings(homeClub: homeClub, awayClub: awayClub, lineup: lineup, formation: formation, isUserHome: home == gameManager.userClub?.name),
            state: .inProgress,
            week: week,
            competition: competition,
            venue: venue,
            currentMinute: 0
        )

        addEvent(minute: 0, type: .kickoff, team: .home, description: "Kick-off! The match is underway.")
        isSimulating = true

        simulationTask = Task {
            await simulateMatch(
                homePrestige: homePrestige,
                awayPrestige: awayPrestige,
                homeClub: homeClub,
                awayClub: awayClub
            )
        }
    }

    func stopSimulation() {
        simulationTask?.cancel()
        isSimulating = false
    }

    func instantResult() {
        guard var result = matchResult, result.state != .finished else { return }
        stopSimulation()

        // Fast-forward remaining minutes using FM14 probabilities (no delay)
        let homeClubPlayers = result.playerRatings // just for reference
        let startMinute = result.currentMinute + 1

        for minute in startMinute...90 {
            result.currentMinute = minute
        }

        result.state = .finished
        matchResult = result
        addEvent(minute: 90, type: .fulltime, team: .home, description: "Full time! The final whistle blows.")
    }

    // MARK: - FM14-Driven Match Simulation

    private func simulateMatch(homePrestige: Int, awayPrestige: Int, homeClub: Club?, awayClub: Club?) async {
        let homePlayers = homeClub?.players.filter { !$0.isInjured && !$0.isSuspended } ?? []
        let awayPlayers = awayClub?.players.filter { !$0.isInjured && !$0.isSuspended } ?? []

        for minute in 1...90 {
            guard !Task.isCancelled else { return }

            // Streaming delay — controlled by speed slider
            let delay = max(0.02, 0.3 / speed)
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))

            matchResult?.currentMinute = minute

            // Halftime break
            if minute == 45 {
                matchResult?.state = .halftime
                addEvent(minute: 45, type: .halftime, team: .home, description: "Half time! The referee blows for the break.")
                let htDelay = max(0.5, 2.0 / speed)
                try? await Task.sleep(for: .milliseconds(Int(htDelay * 1000)))
                matchResult?.state = .inProgress
            }

            // --- HOME TEAM EVENT ---
            if let event = FM14EventGenerator.rollEvent(
                minute: minute,
                isHome: true,
                teamPlayers: homePlayers,
                opponentPrestige: awayPrestige,
                params: params,
                matrix: matrix
            ) {
                applyEvent(event, team: .home, minute: minute, homePrestige: homePrestige, awayPrestige: awayPrestige)
            }

            // --- AWAY TEAM EVENT ---
            if let event = FM14EventGenerator.rollEvent(
                minute: minute,
                isHome: false,
                teamPlayers: awayPlayers,
                opponentPrestige: homePrestige,
                params: params,
                matrix: matrix
            ) {
                applyEvent(event, team: .away, minute: minute, homePrestige: homePrestige, awayPrestige: awayPrestige)
            }

            // Update possession based on prestige differential
            updatePossession(homePrestige: homePrestige, awayPrestige: awayPrestige)
        }

        matchResult?.state = .finished
        matchResult?.currentMinute = 90
        addEvent(
            minute: 90,
            type: .fulltime,
            team: .home,
            description: "Full time! The final whistle blows. \(matchResult?.homeTeam ?? "") \(matchResult?.homeScore ?? 0) - \(matchResult?.awayScore ?? 0) \(matchResult?.awayTeam ?? "")"
        )
        isSimulating = false
    }

    // MARK: - Event Application

    private func applyEvent(
        _ event: (type: MatchEventType, player: Player?, assist: Player?, description: String),
        team: MatchTeamSide,
        minute: Int,
        homePrestige: Int,
        awayPrestige: Int
    ) {
        let isHome = team == .home

        switch event.type {
        case .goal:
            if isHome {
                matchResult?.homeScore += 1
                matchResult?.homeStats.shotsOnTarget += 1
                matchResult?.homeStats.shots += 1
            } else {
                matchResult?.awayScore += 1
                matchResult?.awayStats.shotsOnTarget += 1
                matchResult?.awayStats.shots += 1
            }
            addEvent(minute: minute, type: .goal, team: team,
                     playerName: event.player?.shortName,
                     assistPlayerName: event.assist?.shortName,
                     description: event.description)

            // Update player rating for scorer
            if let scorerName = event.player?.shortName,
               let idx = matchResult?.playerRatings.firstIndex(where: { $0.playerName == scorerName }) {
                matchResult?.playerRatings[idx].goals += 1
                matchResult?.playerRatings[idx].rating = min(10.0, (matchResult?.playerRatings[idx].rating ?? 6.5) + 0.5)
            }
            // Update assist provider rating
            if let assistName = event.assist?.shortName,
               let idx = matchResult?.playerRatings.firstIndex(where: { $0.playerName == assistName }) {
                matchResult?.playerRatings[idx].assists += 1
                matchResult?.playerRatings[idx].rating = min(10.0, (matchResult?.playerRatings[idx].rating ?? 6.5) + 0.2)
            }

        case .shot:
            if isHome { matchResult?.homeStats.shots += 1 } else { matchResult?.awayStats.shots += 1 }
            addEvent(minute: minute, type: .shot, team: team,
                     playerName: event.player?.shortName, description: event.description)

        case .save:
            if isHome { matchResult?.homeStats.shotsOnTarget += 1; matchResult?.homeStats.shots += 1 }
            else { matchResult?.awayStats.shotsOnTarget += 1; matchResult?.awayStats.shots += 1 }
            addEvent(minute: minute, type: .save, team: team,
                     playerName: event.player?.shortName, description: event.description)

        case .yellowCard:
            if isHome { matchResult?.homeStats.yellowCards += 1; matchResult?.homeStats.fouls += 1 }
            else { matchResult?.awayStats.yellowCards += 1; matchResult?.awayStats.fouls += 1 }
            addEvent(minute: minute, type: .yellowCard, team: team,
                     playerName: event.player?.shortName, description: event.description)

        case .redCard:
            if isHome { matchResult?.homeStats.redCards += 1; matchResult?.homeStats.fouls += 1 }
            else { matchResult?.awayStats.redCards += 1; matchResult?.awayStats.fouls += 1 }
            addEvent(minute: minute, type: .redCard, team: team,
                     playerName: event.player?.shortName, description: event.description)

        case .foul:
            if isHome { matchResult?.homeStats.fouls += 1 } else { matchResult?.awayStats.fouls += 1 }
            addEvent(minute: minute, type: .foul, team: team,
                     playerName: event.player?.shortName, description: event.description)

        case .corner:
            if isHome { matchResult?.homeStats.corners += 1 } else { matchResult?.awayStats.corners += 1 }
            addEvent(minute: minute, type: .corner, team: team, description: event.description)

        case .offside, .freeKick:
            addEvent(minute: minute, type: event.type, team: team, description: event.description)

        default:
            addEvent(minute: minute, type: event.type, team: team, description: event.description)
        }
    }

    // MARK: - Helpers

    private func updatePossession(homePrestige: Int, awayPrestige: Int) {
        let homePoss = 45 + (homePrestige - awayPrestige) * 2 + Int.random(in: -5...5)
        matchResult?.homeStats.possession = max(30, min(70, homePoss))
        matchResult?.awayStats.possession = 100 - (matchResult?.homeStats.possession ?? 50)
    }

    private func addEvent(minute: Int, type: MatchEventType, team: MatchTeamSide, playerName: String? = nil, assistPlayerName: String? = nil, description: String) {
        let event = MatchEvent(
            id: UUID().uuidString,
            minute: minute,
            type: type,
            team: team,
            playerName: playerName,
            assistPlayerName: assistPlayerName,
            description: description
        )
        matchResult?.events.append(event)
    }

    private func generateInitialRatings(homeClub: Club?, awayClub: Club?, lineup: [String: String], formation: Formation, isUserHome: Bool) -> [PlayerMatchRating] {
        var ratings: [PlayerMatchRating] = []
        let userClub = isUserHome ? homeClub : awayClub

        if let club = userClub {
            for slot in formation.slots {
                if let playerID = lineup[slot.id],
                   let player = club.players.first(where: { $0.id == playerID }) {
                    // Base rating influenced by player overall + form + fitness
                    let formBonus = Double(player.form - 10) * 0.05
                    let fitnessBonus = Double(player.currentFitness - 80) * 0.02
                    let baseRating = 5.5 + Double(player.overallRating) * 0.015 + formBonus + fitnessBonus + Double.random(in: 0...0.8)
                    let clampedRating = max(4.0, min(8.5, baseRating))

                    ratings.append(PlayerMatchRating(
                        id: UUID().uuidString,
                        playerName: player.shortName,
                        position: slot.position.rawValue,
                        rating: clampedRating,
                        goals: 0, assists: 0, tackles: 0, saves: 0
                    ))
                }
            }
        }
        return ratings
    }
}
